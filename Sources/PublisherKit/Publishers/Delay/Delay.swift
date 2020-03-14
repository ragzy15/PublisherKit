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
            
            let delaySubscriber = Inner(downstream: subscriber, interval: interval,
                                        tolerance: tolerance, scheduler: scheduler,
                                        options: options)
            upstream.subscribe(delaySubscriber)
        }
    }
}

extension Publishers.Delay {
    
    // MARK: DELAY SINK
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        let interval: Context.PKSchedulerTimeType.Stride
        
        let tolerance: Context.PKSchedulerTimeType.Stride
        
        let scheduler: Context
        
        let options: Context.PKSchedulerOptions?
        
        fileprivate let downstreamLock = RecursiveLock()
        
        init(downstream: Downstream, interval: Context.PKSchedulerTimeType.Stride,
             tolerance: Context.PKSchedulerTimeType.Stride, scheduler: Context,
             options: Context.PKSchedulerOptions?) {
            
            self.interval = interval
            self.tolerance = tolerance
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
        }
        
        override func request(_ demand: Subscribers.Demand) {
            getLock().lock()
            guard case let .subscribed(subscription) = status else { getLock().unlock(); return }
            getLock().unlock()
            
            subscription.request(demand)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return .none }
            
            getLock().unlock()
            
            scheduler.schedule(after: scheduler.now.advanced(by: interval), tolerance: tolerance, options: options) { [weak self] in
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
            
            scheduler.schedule(after: scheduler.now.advanced(by: interval), tolerance: tolerance, options: options) { [weak self] in
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
            "Delay"
        }
    }
}
