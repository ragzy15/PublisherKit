//
//  SubscribeOn.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 01/03/20.
//

extension Publishers {
    
    /// A publisher that receives elements from an upstream publisher on a specific scheduler.
    public struct SubscribeOn<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The scheduler the publisher should use to receive elements.
        public let scheduler: Context
        
        /// Scheduler options that customize the delivery of elements.
        public let options: Context.PKSchedulerOptions?
        
        public init(upstream: Upstream, scheduler: Context, options: Context.PKSchedulerOptions?) {
            self.upstream = upstream
            self.scheduler = scheduler
            self.options = options
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            scheduler.schedule(options: options) {
                self.upstream.subscribe(Inner(downstream: subscriber, parent: self))
            }
        }
    }
}

extension Publishers.SubscribeOn {
    
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        fileprivate typealias SubscribeOn = Publishers.SubscribeOn<Upstream, Context>
        
        private enum SubscriptionStatus {
            case awaiting(parent: SubscribeOn, downstream: Downstream)
            case subscribed(parent: SubscribeOn, downstream: Downstream, subscription: Subscription)
            case terminated
        }
        
        private var status: SubscriptionStatus
        
        private let lock = Lock()
        private let upstreamLock = Lock()
        
        init(downstream: Downstream, parent: SubscribeOn) {
            status = .awaiting(parent: parent, downstream: downstream)
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard case .awaiting(let parent, let downstream) = status else { lock.unlock(); return }
            status = .subscribed(parent: parent, downstream: downstream, subscription: subscription)
            lock.unlock()
            
            downstream.receive(subscription: self)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed(_, let downstream, _) = status else { lock.unlock(); return .none }
            lock.unlock()
            
            return downstream.receive(input)
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard case .subscribed(_, let downstream, _) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            downstream.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(let parent, _, let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            parent.scheduler.schedule(options: parent.options) { [weak self] in
                self?.upstreamLock.lock()
                subscription.request(demand)
                self?.upstreamLock.unlock()
            }
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let parent, _, let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            parent.scheduler.schedule(options: parent.options) { [weak self] in
                self?.upstreamLock.lock()
                subscription.cancel()
                self?.upstreamLock.unlock()
            }
        }
        
        var description: String {
            "SubscribeOn"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
