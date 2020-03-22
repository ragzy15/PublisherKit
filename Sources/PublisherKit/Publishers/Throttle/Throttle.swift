//
//  Throttle.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

extension Publishers {
    
    /// A publisher that publishes either the most-recent or first element published by the upstream publisher in a specified time interval.
    public struct Throttle<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The interval in which to find and emit the most recent element.
        public let interval: Context.PKSchedulerTimeType.Stride
        
        /// The scheduler on which to publish elements.
        public let scheduler: Context
        
        /// A Boolean value indicating whether to publish the most recent element.
        ///
        /// If `false`, the publisher emits the first element received during the interval.
        public let latest: Bool
        
        public init(upstream: Upstream, interval: Context.PKSchedulerTimeType.Stride, scheduler: Context, latest: Bool) {
            self.upstream = upstream
            self.interval = interval
            self.scheduler = scheduler
            self.latest = latest
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, parent: self))
        }
    }
}

extension Publishers.Throttle {
    
    // MARK: THROTTLE SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        fileprivate typealias Throttle = Publishers.Throttle<Upstream, Context>
        
        private enum SubscriptionStatus {
            case awaiting(parent: Throttle, downstream: Downstream)
            case subscribed(parent: Throttle, downstream: Downstream, subscription: Subscription)
            case terminated
        }
        
        private var status: SubscriptionStatus
        private var downstreamDemand: Subscribers.Demand = .none
        
        private let downstreamLock = RecursiveLock()
        private let lock = Lock()
        
        private var lastSentTime: Context.PKSchedulerTimeType? = nil
        private var sendCompletion = false
        
        private var lastestUnsentInput: Input?
        
        init(downstream: Downstream, parent: Throttle) {
            status = .awaiting(parent: parent, downstream: downstream)
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard case .awaiting(let parent, let downstream) = status else { lock.unlock(); return }
            status = .subscribed(parent: parent, downstream: downstream, subscription: subscription)
            lock.unlock()
            
            downstreamLock.lock()
            downstream.receive(subscription: self)
            downstreamLock.unlock()
            
            subscription.request(downstreamDemand)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed(let parent, _, _) = status else { lock.unlock(); return .none }
            
            let now = parent.scheduler.now
            
            let timeIntervalSinceLast: Context.PKSchedulerTimeType.Stride
            
            if let lastSendingTime = self.lastSentTime {
                timeIntervalSinceLast = now.distance(to: lastSendingTime)
            } else {
                timeIntervalSinceLast = parent.interval
            }
            
            let sendNow = timeIntervalSinceLast >= parent.interval
            
            if sendNow {
                lastestUnsentInput = input
                lock.unlock()
                parent.scheduler.schedule { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.lock.lock()
                    self.lastSentTime = parent.scheduler.now
                    self.emitToDownstream()
                }
                
                return downstreamDemand
            }
            
            if !parent.latest {
                lock.unlock()
                return .none
            }
            
            let sendingInProgress = lastestUnsentInput != nil
            
            self.lastestUnsentInput = input
            lock.unlock()
            
            if sendingInProgress {
                return .none
            }
            
            parent.scheduler.schedule(after: parent.scheduler.now.advanced(by: parent.interval - timeIntervalSinceLast)) { [weak self] in
                
                guard let `self` = self else { return }
                self.lock.lock()
                self.emitToDownstream()
            }
            
            return .none
        }
        
        private func emitToDownstream() {
            guard case .subscribed(_, let downstream, _) = status else { lock.unlock(); return }
            let _lastestUnsentInput = lastestUnsentInput
            lastestUnsentInput = nil
            let sendCompletion = self.sendCompletion
            lock.unlock()
            
            if let input = _lastestUnsentInput {
                downstreamLock.lock()
                _ = downstream.receive(input)
                downstreamLock.unlock()
            }
            
            if sendCompletion {
                downstreamLock.lock()
                downstream.receive(completion: .finished)
                downstreamLock.unlock()
            }
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard case .subscribed(let parent, let downstream, _) = status else { lock.unlock(); return }
            status = .terminated
            
            switch completion {
            case .finished:
                if lastestUnsentInput != nil {
                    sendCompletion = true
                    lock.unlock()
                } else {
                    lock.unlock()
                    parent.scheduler.schedule { [weak self] in
                        guard let `self` = self else { return }
                        
                        self.downstreamLock.lock()
                        downstream.receive(completion: .finished)
                        self.downstreamLock.unlock()
                    }
                }
                
            case .failure(let error):
                lastestUnsentInput = nil
                lock.unlock()
                
                parent.scheduler.schedule { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.downstreamLock.lock()
                    downstream.receive(completion: .failure(error))
                    self.downstreamLock.unlock()
                }
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(_, _, _) = status else { lock.unlock(); return }
            downstreamDemand += demand
            lock.unlock()
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "Throttle"
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
