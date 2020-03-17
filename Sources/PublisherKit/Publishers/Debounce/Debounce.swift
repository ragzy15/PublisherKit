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
            let inner = Inner(downstream: subscriber, dueTime: dueTime, scheduler: scheduler, options: options)
            inner.parent = self
            upstream.subscribe(inner)
        }
    }
}

extension Publishers.Debounce {
    
    // MARK: DEBOUNCE SINK
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var _id = 0
        
        private var currentValue: Output?
        
        private let dueTime: Context.PKSchedulerTimeType.Stride
        
        private let scheduler: Context
        
        private let options: Context.PKSchedulerOptions?
        
        fileprivate let downstreamLock = RecursiveLock()
        private let lock = Lock()
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        private var downstreamDemand: Subscribers.Demand = .none
        
        fileprivate var parent: Publishers.Debounce<Upstream, Context>?
        
        init(downstream: Downstream, dueTime: Context.PKSchedulerTimeType.Stride, scheduler: Context, options: Context.PKSchedulerOptions?) {
            self.scheduler = scheduler
            self.dueTime = dueTime
            self.options = options
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
            
            subscription.request(downstreamDemand)
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            lock.unlock()
            
            downstreamDemand = demand
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            currentValue = input
            _id += 1
            let currentId = _id
            lock.unlock()
            
            scheduler.schedule(after: scheduler.now.advanced(by: dueTime), tolerance: scheduler.minimumTolerance, options: options) { [weak self] in
                guard let `self` = self else { return }
                
                self.lock.lock()
                guard self.status.isSubscribed else { self.lock.unlock(); return }
                
                guard self._id == currentId, let value = self.currentValue else {
                    self.lock.unlock()
                    return
                }
                
                self.lock.unlock()
                
                self.downstreamLock.lock()
                _ = self.downstream?.receive(value)
                self.downstreamLock.unlock()
            }
            
            return downstreamDemand
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            scheduler.schedule(options: options) { [weak self] in
                self?.end {
                    self?.downstream?.receive(completion: completion)
                }
            }
        }
        
        func end(completion: () -> Void) {
            downstreamLock.lock()
            completion()
            downstreamLock.unlock()
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
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
            
            var subscription: Subscription? = nil
            if case .subscribed(let _subscription) = status {
                subscription = _subscription
            }
            
            let children: [Mirror.Child] = [
                ("upstream", parent?.upstream as Any),
                ("downstream", downstream as Any),
                ("upstreamSubscription", subscription as Any),
                ("downstreamDemand", downstreamDemand),
                ("currentValue", currentValue as Any)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
