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
                let subscribeOnSubscriber = Inner(downstream: subscriber, scheduler: self.scheduler, options: self.options)
                
                subscribeOnSubscriber.upstreamLock.lock()
                subscriber.receive(subscription: subscribeOnSubscriber)
                subscribeOnSubscriber.upstreamLock.unlock()
                
                self.upstream.subscribe(subscribeOnSubscriber)
            }
        }
    }
}

extension Publishers.SubscribeOn {
    
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: Subscribers.Inner<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let scheduler: Context
        
        private let options: Context.PKSchedulerOptions?
        
        fileprivate let upstreamLock = Lock()
        
        init(downstream: Downstream, scheduler: Context, options: Context.PKSchedulerOptions?) {
            self.scheduler = scheduler
            self.options = options
            super.init(downstream: downstream)
        }
        
        override func cancel() {
            getLock().lock()
            
            switch status {
            case .subscribed(let subscription):
                status = .terminated
                getLock().unlock()
                
                scheduler.schedule(options: options) { [weak self] in
                    self?.scheduledCancel(subscription: subscription)
                }
                
            case .multipleSubscription(let subscriptions):
                status = .terminated
                getLock().unlock()
                
                scheduler.schedule(options: options) { [weak self] in
                    self?.scheduledCancel(subscriptions: subscriptions)
                }
                
            default: getLock().unlock()
            }
            
            downstream = nil
        }
        
        private func scheduledCancel(subscription: Subscription) {
            upstreamLock.lock()
            subscription.cancel()
            upstreamLock.unlock()
        }
        
        private func scheduledCancel(subscriptions: [Subscription]) {
            upstreamLock.lock()
            subscriptions.forEach { (subscription) in
                subscription.cancel()
            }
            upstreamLock.unlock()
        }
        
        override var description: String {
            "SubscribeOn"
        }
    }
}
