//
//  Receive On.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

extension Publishers {
    
    /// A publisher that publishes elements to its downstream subscriber on a specific scheduler.
    public struct ReceiveOn<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The scheduler the publisher is to use for element delivery.
        public let scheduler: Context
        
        /// Scheduler options that customize the delivery of elements.
        public let options: Context.PKSchedulerOptions?
        
        public init(upstream: Upstream, scheduler: Context, options: Context.PKSchedulerOptions?) {
            self.upstream = upstream
            self.scheduler = scheduler
            self.options = options
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, parent: self))
        }
    }
}

extension Publishers.ReceiveOn {
    
    // MARK: RECEIVEON SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        fileprivate typealias ReceiveOn = Publishers.ReceiveOn<Upstream, Context>
        
        private enum SubscriptionStatus {
            case awaiting(parent: ReceiveOn, downstream: Downstream)
            case subscribed(parent: ReceiveOn, downstream: Downstream, subscription: Subscription)
            case terminated
        }
        
        private var status: SubscriptionStatus
        
        private let downstreamLock = RecursiveLock()
        private let lock = Lock()
        
        init(downstream: Downstream, parent: ReceiveOn) {
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
            
            parent.scheduler.schedule(options: parent.options) { [weak self] in
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
            
            parent.scheduler.schedule(options: parent.options) { [weak self] in
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
            "ReceiveOn"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
