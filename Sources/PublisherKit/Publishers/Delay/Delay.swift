//
//  Delay.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

extension Publishers {
    
    /// A publisher that delays delivery of elements and completion to the downstream receiver.
    public struct Delay<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The amount of time to delay.
        public let interval: Context.PKSchedulerTimeType.Stride
        
        /// The allowed tolerance in firing delayed events.
        public let tolerance: Context.PKSchedulerTimeType.Stride
        
        /// The scheduler to deliver the delayed events.
        public let scheduler: Context
        
        public let options: Context.PKSchedulerOptions?
        
        public init(upstream: Upstream, interval: Context.PKSchedulerTimeType.Stride,
                    tolerance: Context.PKSchedulerTimeType.Stride, scheduler: Context,
                    options: Context.PKSchedulerOptions? = nil) {
            
            self.upstream = upstream
            self.interval = interval
            self.tolerance = tolerance
            self.scheduler = scheduler
            self.options = options
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, parent: self))
        }
    }
}

extension Publishers.Delay {
    
    // MARK: DELAY SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        fileprivate typealias Delay = Publishers.Delay<Upstream, Context>
        
        private enum SubscriptionStatus {
            case awaiting(parent: Delay, downstream: Downstream)
            case subscribed(parent: Delay, downstream: Downstream, subscription: Subscription)
            case terminated
        }
        
        private var status: SubscriptionStatus
        
        private let downstreamLock = RecursiveLock()
        private let lock = Lock()
        
        init(downstream: Downstream, parent: Delay) {
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
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed(let parent, let downstream, _) = status else { lock.unlock(); return .none }
            lock.unlock()
            
            parent.scheduler.schedule(after: parent.scheduler.now.advanced(by: parent.interval), tolerance: parent.tolerance, options: parent.options) { [weak self] in
                guard let `self` = self else { return }
                
                self.downstreamLock.lock()
                _ = downstream.receive(input)
                self.downstreamLock.unlock()
            }
            
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard case .subscribed(let parent, let downstream, _) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            parent.scheduler.schedule(after: parent.scheduler.now.advanced(by: parent.interval), tolerance: parent.tolerance, options: parent.options) { [weak self] in
                guard let `self` = self else { return }
                
                self.downstreamLock.lock()
                downstream.receive(completion: completion)
                self.downstreamLock.unlock()
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "Delay"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
