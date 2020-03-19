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
            upstream.subscribe(Inner(downstream: subscriber, scheduler: scheduler, options: options))
        }
    }
}

extension Publishers.ReceiveOn {
    
    // MARK: RECEIVEON SINK
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let scheduler: Context
        
        private let options: Context.PKSchedulerOptions?
        
        private let downstreamLock = RecursiveLock()
        private let lock = Lock()
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        
        init(downstream: Downstream, scheduler: Context, options: Context.PKSchedulerOptions?) {
            self.scheduler = scheduler
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
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            lock.unlock()
            
            scheduler.schedule(options: options) { [weak self] in
                self?.downstreamLock.lock()
                _ = self?.downstream?.receive(input)
                self?.downstreamLock.unlock()
            }
            
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            scheduler.schedule(options: options) { [weak self] in
                self?.downstreamLock.lock()
                self?.downstream?.receive(completion: completion)
                self?.downstreamLock.unlock()
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
            "ReceiveOn"
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
