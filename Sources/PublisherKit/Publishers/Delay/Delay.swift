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
            upstream.subscribe(Inner(downstream: subscriber, interval: interval,
                                     tolerance: tolerance, scheduler: scheduler,
                                     options: options))
        }
    }
}

extension Publishers.Delay {
    
    // MARK: DELAY SINK
    private final class Inner<Downstream: Subscriber, Context: Scheduler>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        let interval: Context.PKSchedulerTimeType.Stride
        
        let tolerance: Context.PKSchedulerTimeType.Stride
        
        let scheduler: Context
        
        let options: Context.PKSchedulerOptions?
        
        private let downstreamLock = RecursiveLock()
        private let lock = Lock()
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        
        init(downstream: Downstream, interval: Context.PKSchedulerTimeType.Stride,
             tolerance: Context.PKSchedulerTimeType.Stride, scheduler: Context,
             options: Context.PKSchedulerOptions?) {
            
            self.interval = interval
            self.tolerance = tolerance
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
            
            scheduler.schedule(after: scheduler.now.advanced(by: interval), tolerance: tolerance, options: options) { [weak self] in
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
            
            scheduler.schedule(after: scheduler.now.advanced(by: interval), tolerance: tolerance, options: options) { [weak self] in
                
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
            "Delay"
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
