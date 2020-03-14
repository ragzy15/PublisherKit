//
//  Throttle.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

extension Publishers {
    
    /// A publisher that publishes either the most-recent or first element published by the upstream publisher in a specified time interval.
    public struct Throttle<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The interval in which to find and emit the most recent element.
        public let interval: Context.PKSchedulerTimeType.Stride
        
        /// The scheduler on which to publish elements.
        public let scheduler: Context
        
        /// A Boolean value indicating whether to publish the most recent element.
        ///
        /// If `false`, the publisher emits the first element received during the interval.
        public let latest: Bool
        
        public init(upstream: Upstream, interval: Context.PKSchedulerTimeType.Stride, scheduler: Context, latest: Bool) {
            self.upstream = upstream
            self.interval = interval
            self.scheduler = scheduler
            self.latest = latest
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let throttleSubscriber = Inner(downstream: subscriber, interval: interval,
                                           scheduler: scheduler, latest: latest)
            upstream.subscribe(throttleSubscriber)
        }
    }
}

extension Publishers.Throttle {
    
    // MARK: THROTTLE SINK
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        public let interval: Context.PKSchedulerTimeType.Stride
        
        public let scheduler: Context
        
        public let latest: Bool
        
        fileprivate let downstreamLock = RecursiveLock()
        
        private var lastSendTime: Context.PKSchedulerTimeType? = nil
        private var sent = false
        
        private var inputs: [Input] = []
        
        init(downstream: Downstream, interval: Context.PKSchedulerTimeType.Stride, scheduler: Context, latest: Bool) {
            self.interval = interval
            self.scheduler = scheduler
            self.latest = latest
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
        
        override func receive(_ input: Input) -> Subscribers.Demand {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return .none }
            
            inputs.append(input)
            
            handleInput()
                        
            return demand
        }
        
        private func handleInput() {
            let delay: Context.PKSchedulerTimeType.Stride
            
            if let lastSendTime = lastSendTime {
                delay = lastSendTime.distance(to: scheduler.now) > interval ? 0 : interval
            } else {
                delay = 0
            }
                        
            guard !sent else {
                getLock().unlock()
                return
            }
            
            sent = true
            
            getLock().unlock()
            
            scheduler.schedule(after: scheduler.now.advanced(by: delay)) { [weak self] in
                self?.scheduledReceive()
            }
        }
        
        private func scheduledReceive() {
            getLock().lock()
            
            sent = false
            
            lastSendTime = scheduler.now
            
            guard !inputs.isEmpty else {
                getLock().unlock()
                return
            }
            
            let _input: Input?
            
            if latest {
                _input = inputs.removeLast()
               inputs = inputs.suffix(1)
            } else {
                _input = inputs.removeFirst()
                inputs = []
            }
            
            getLock().unlock()
            
            downstreamLock.lock()
            guard let input = _input else { return }
            _ = downstream?.receive(input)
            downstreamLock.unlock()
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
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
            downstreamLock.lock()
            completion()
            downstreamLock.unlock()
            downstream = nil
        }
        
        override var description: String {
            "Throttle"
        }
    }
}
