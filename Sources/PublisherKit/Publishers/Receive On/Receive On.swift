//
//  Receive On.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

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
            
            let receiveOnSubscriber = Inner(downstream: subscriber, scheduler: scheduler, options: options)
            upstream.subscribe(receiveOnSubscriber)
        }
    }
}

extension Publishers.ReceiveOn {
    
    // MARK: RECEIVEON SINK
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let scheduler: Context
        
        private let options: Context.PKSchedulerOptions?
        
        private let downstreamLock = RecursiveLock()
        
        init(downstream: Downstream, scheduler: Context, options: Context.PKSchedulerOptions?) {
            self.scheduler = scheduler
            self.options = options
            super.init(downstream: downstream)
        }
        
        override func onSubscription(_ subscription: Subscription) {
            status = .subscribed(to: subscription)
            getLock().unlock()
            
            downstreamLock.lock()
            downstream?.receive(subscription: self)
            downstreamLock.unlock()
            
            subscription.request(.unlimited)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return .none }
            
            getLock().unlock()
            
            scheduler.schedule(options: options) { [weak self] in
                self?.downstreamLock.lock()
                _ = self?.downstream?.receive(input)
                self?.downstreamLock.unlock()
            }
            
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return }
            
            status = .terminated
            getLock().unlock()
            
            scheduler.schedule(options: options) { [weak self] in
                self?.end {
                    self?.downstream?.receive(completion: completion)
                }
            }
        }
        
        override func end(completion: () -> Void) {
            downstreamLock.lock()
            completion()
            downstreamLock.unlock()
            downstream = nil
        }
        
        override var description: String {
            "ReceiveOn"
        }
    }
}
