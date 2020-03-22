//
//  Debounce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

extension Publishers {
    
    /// A publisher that publishes elements only after a specified time interval elapses after receiving an element from upstream publisher, using the specified scheduler.
    public struct Debounce<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The amount of time the publisher should wait before publishing an element.
        public let dueTime: Context.PKSchedulerTimeType.Stride
        
        /// The scheduler on which this publisher delivers elements.
        public let scheduler: Context
        
        /// Scheduler options that customize this publisher’s delivery of elements.
        public let options: Context.PKSchedulerOptions?
        
        public init(upstream: Upstream, dueTime: Context.PKSchedulerTimeType.Stride, scheduler: Context, options: Context.PKSchedulerOptions?) {
            self.upstream = upstream
            self.dueTime = dueTime
            self.scheduler = scheduler
            self.options = options
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, parent: self))
        }
    }
}

extension Publishers.Debounce {
    
    // MARK: DEBOUNCE SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var _id = 0
        
        private var currentValue: Output?
        
        fileprivate typealias Debounce = Publishers.Debounce<Upstream, Context>
        
        private enum SubscriptionStatus {
            case awaiting(parent: Debounce, downstream: Downstream)
            case subscribed(parent: Debounce, downstream: Downstream, subscription: Subscription)
            case terminated
        }
        
        private var status: SubscriptionStatus
        private var downstreamDemand: Subscribers.Demand = .none
        
        private let downstreamLock = RecursiveLock()
        private let lock = Lock()
        
        init(downstream: Downstream, parent: Debounce) {
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
            guard case .subscribed(let parent, let downstream, _) = status else { lock.unlock(); return .none }
            currentValue = input
            _id += 1
            let currentId = _id
            lock.unlock()
            
            parent.scheduler.schedule(after: parent.scheduler.now.advanced(by: parent.dueTime), tolerance: parent.scheduler.minimumTolerance, options: parent.options) { [weak self] in
                guard let `self` = self else { return }
                
                self.lock.lock()
                guard case .subscribed(_,_,_) = self.status else { self.lock.unlock(); return }
                
                guard self._id == currentId, let value = self.currentValue else {
                    self.lock.unlock()
                    return
                }
                
                self.lock.unlock()
                
                self.downstreamLock.lock()
                _ = downstream.receive(value)
                self.downstreamLock.unlock()
            }
            
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard case .subscribed(let parent, let downstream, _) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            parent.scheduler.schedule(options: parent.options) { [weak self] in
                guard let `self` = self else { return }
                
                self.downstreamLock.lock()
                downstream.receive(completion: completion)
                self.downstreamLock.unlock()
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(_, _, _) = status else { lock.unlock(); return }
            lock.unlock()
            
            downstreamDemand = demand
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "Debounce"
        }
        
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }
            
            let upstream: Upstream?
            let downstream: Downstream?
            let subscription: Subscription?
            
            switch status {
            case .awaiting(let _parent, let _downstream):
                upstream = _parent.upstream
                downstream = _downstream
                subscription = nil
                
            case .subscribed(let _parent, let _downstream, let _subscription):
                upstream = _parent.upstream
                downstream = _downstream
                subscription = _subscription
                
            case .terminated:
                upstream = nil
                downstream = nil
                subscription = nil
            }
            
            let children: [Mirror.Child] = [
                ("upstream", upstream as Any),
                ("downstream", downstream as Any),
                ("upstreamSubscription", subscription as Any),
                ("downstreamDemand", downstreamDemand),
                ("currentValue", currentValue as Any)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
