//
//  Debounce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension Publishers {
    
    /// A publisher that publishes elements only after a specified time interval elapses after receiving an element from upstream publisher, using the specified scheduler.
    struct Debounce<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// Time the publisher should wait before publishing an element.
        public let dueTime: SchedulerTime
        
        /// The scheduler on which elements are published.
        public let scheduler: Context
        
        public init(upstream: Upstream, dueTime: SchedulerTime, on scheduler: Context) {
            self.upstream = upstream
            self.dueTime = dueTime
            self.scheduler = scheduler
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let debounceSubscriber = Inner(downstream: subscriber, scheduler: scheduler, dueTime: dueTime)
            upstream.subscribe(debounceSubscriber)
        }
    }
}

extension Publishers.Debounce {
    
    // MARK: DEBOUNCE SINK
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var outputCounter = 0
        
        private var newOutput: Output?
        
        private let dueTime: SchedulerTime
        
        private let scheduler: Context
        
        private let downstreamLock = RecursiveLock()
        
        init(downstream: Downstream, scheduler: Context, dueTime: SchedulerTime) {
            self.scheduler = scheduler
            self.dueTime = dueTime
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
        
        
        override func receive(_ input: Output) -> Subscribers.Demand {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return .none }
            
            newOutput = input
            
            outputCounter += 1
            getLock().unlock()
            
            scheduler.schedule(after: dueTime) { [weak self] in
                self?.sendInput()
            }
            
            return demand
        }
        
        private func sendInput() {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return }
            outputCounter -= 1
            getLock().unlock()
            
            getLock().lock()
            guard outputCounter <= 0, let output = newOutput else {
                getLock().unlock()
                return
            }
            
            getLock().unlock()
            
            downstreamLock.lock()
            _ = downstream?.receive(output)
            downstreamLock.unlock()
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return }
            
            status = .terminated
            getLock().unlock()
            
            scheduler.schedule { [weak self] in
                self?.end {
                    self?.downstream?.receive(completion: completion)
                }
            }
        }
        
        override func end(completion: () -> Void) {
            completion()
            downstream = nil
        }
        
        override var description: String {
            "Debounce"
        }
    }
}
