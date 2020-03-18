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
            
            let throttleSubscriber = Inner(downstream: subscriber, interval: interval,
                                           scheduler: scheduler, latest: latest)
            upstream.subscribe(throttleSubscriber)
        }
    }
}

extension Publishers.Throttle {
    
    // MARK: THROTTLE SINK
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        private var downstreamDemand: Subscribers.Demand = .none
        
        public let interval: Context.PKSchedulerTimeType.Stride
        
        public let scheduler: Context
        
        public let latest: Bool
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        private var lastSentTime: Context.PKSchedulerTimeType? = nil
        private var sendCompletion = false
        
        private var lastestUnsentInput: Input?
        
        init(downstream: Downstream, interval: Context.PKSchedulerTimeType.Stride, scheduler: Context, latest: Bool) {
            self.interval = interval
            self.scheduler = scheduler
            self.latest = latest
            self.downstream = downstream
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            
            downstreamLock.lock()
            downstream?.receive(subscription: self)
            downstreamLock.unlock()
            
            subscription.request(.unlimited)
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            downstreamDemand += demand
            lock.unlock()
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            
            let now = scheduler.now

            let timeIntervalSinceLast: Context.PKSchedulerTimeType.Stride

            if let lastSendingTime = self.lastSentTime {
                timeIntervalSinceLast = now.distance(to: lastSendingTime)
            } else {
                timeIntervalSinceLast = interval
            }

            let sendNow = timeIntervalSinceLast >= interval

            if sendNow {
                lastestUnsentInput = input
                lock.unlock()
                scheduler.schedule { [weak self] in
                    self?.lock.lock()
                    self?.lastSentTime = self?.scheduler.now
                    self?.emitToDownstream()
                }
                
                return downstreamDemand
            }

            if !latest {
                lock.unlock()
                return .none
            }
            
            let sendingInProgress = lastestUnsentInput != nil
            
            self.lastestUnsentInput = input
            lock.unlock()

            if sendingInProgress {
                return .none
            }
            
            scheduler.schedule(after: scheduler.now.advanced(by: interval - timeIntervalSinceLast)) { [weak self] in
                self?.lock.lock()
                self?.emitToDownstream()
            }
                        
            return downstreamDemand
        }
        
        private func emitToDownstream() {
            let _lastestUnsentInput = lastestUnsentInput
            lastestUnsentInput = nil
            let sendCompletion = self.sendCompletion
            lock.unlock()
            
            if let input = _lastestUnsentInput {
                downstreamLock.lock()
                _ = downstream?.receive(input)
                downstreamLock.unlock()
            }
            
            if sendCompletion {
                downstreamLock.lock()
                downstream?.receive(completion: .finished)
                downstreamLock.unlock()
            }
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            
            switch completion {
            case .finished:
                if lastestUnsentInput != nil {
                    sendCompletion = true
                    lock.unlock()
                } else {
                    lock.unlock()
                    scheduler.schedule { [weak self] in
                        self?.downstreamLock.lock()
                        self?.downstream?.receive(completion: .finished)
                        self?.downstreamLock.unlock()
                    }
                }
                
            case .failure(let error):
                lastestUnsentInput = nil
                lock.unlock()
                
                scheduler.schedule { [weak self] in
                    self?.downstreamLock.lock()
                    self?.downstream?.receive(completion: .failure(error))
                    self?.downstreamLock.unlock()
                }
            }
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
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
