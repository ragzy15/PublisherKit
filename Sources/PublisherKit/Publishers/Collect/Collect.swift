//
//  Collect.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 27/03/20.
//

extension Publishers {
    
    /// A strategy for collecting received elements.
    ///
    /// - byTime: Collect and periodically publish items.
    /// - byTimeOrCount: Collect and publish items, either periodically or when a buffer reaches its maximum size.
    public enum TimeGroupingStrategy<Context: Scheduler> {
        
        /// A grouping that collects and periodically publishes items.
        case byTime(Context, Context.PKSchedulerTimeType.Stride)
        
        /// A grouping that collects and publishes items periodically or when a buffer reaches a maximum size.
        case byTimeOrCount(Context, Context.PKSchedulerTimeType.Stride, Int)
    }
    
    /// A publisher that buffers and periodically publishes its items.
    public struct CollectByTime<Upstream, Context> : Publisher where Upstream : Publisher, Context : Scheduler {
        
        public typealias Output = [Upstream.Output]
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The strategy with which to collect and publish elements.
        public let strategy: Publishers.TimeGroupingStrategy<Context>
        
        /// `Scheduler` options to use for the strategy.
        public let options: Context.PKSchedulerOptions?
        
        public init(upstream: Upstream, strategy: Publishers.TimeGroupingStrategy<Context>, options: Context.PKSchedulerOptions?) {
            self.upstream = upstream
            self.strategy = strategy
            self.options = options
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, strategy: strategy, options: options))
        }
    }
    
    /// A publisher that buffers items.
    public struct Collect<Upstream: Publisher>: Publisher {
        
        public typealias Output = [Upstream.Output]
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber))
        }
    }
    
    /// A publisher that buffers a maximum number of items.
    public struct CollectByCount<Upstream: Publisher>: Publisher {
        
        public typealias Output = [Upstream.Output]
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        ///  The maximum number of received elements to buffer before publishing.
        public let count: Int
        
        public init(upstream: Upstream, count: Int) {
            self.upstream = upstream
            self.count = count
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, count: count))
        }
    }
}

extension Publishers.CollectByTime {
    
    // MARK: COLLECT BY TIME SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        private var demand: Subscribers.Demand = .none
        
        private var scheduled: Cancellable?
        
        private let lock = Lock()
        
        private var buffer: [Input] = []
        private var status: SubscriptionStatus = .awaiting
        
        private let strategy: Publishers.TimeGroupingStrategy<Context>
        private let options: Context.PKSchedulerOptions?
        
        init(downstream: Downstream, strategy: Publishers.TimeGroupingStrategy<Context>, options: Context.PKSchedulerOptions?) {
            self.downstream = downstream
            self.strategy = strategy
            self.options = options
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            
            switch strategy {
            case .byTime(let scheduler, let interval):
                scheduled = scheduler.schedule(after: scheduler.now.advanced(by: interval), interval: interval) { [weak self] in
                    self?.schedulerTimerFired()
                }
                
            case .byTimeOrCount(let scheduler, let interval, _):
                scheduled = scheduler.schedule(after: scheduler.now.advanced(by: interval), interval: interval) { [weak self] in
                    self?.schedulerTimerFired()
                }
            }
            
            downstream.receive(subscription: self)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            
            switch strategy {
            case .byTime:
                buffer.append(input)
                lock.unlock()
                return .max(1)
                
            case .byTimeOrCount(let scheduler, _, let count):
                buffer.append(input)
                guard buffer.count == count else { lock.unlock(); return .none }
                
                let buffer = self.buffer
                self.buffer = []
                demand -= 1
                guard demand > .none else { lock.unlock(); return .none }
                lock.unlock()
                
                scheduler.schedule(options: options) { [weak self] in
                    guard let `self` = self else { return }
                    
                    let additionalDemand = self.downstream.receive(buffer)
                    
                    self.lock.lock()
                    self.demand += additionalDemand
                    self.lock.unlock()
                }
                
                return .none
            }
        }
        
        private func schedulerTimerFired() {
            lock.lock()
            guard !buffer.isEmpty else { lock.unlock(); return }
            demand -= 1
            guard demand > .none else { lock.unlock(); return }
            
            let buffer = self.buffer
            self.buffer = []
            lock.unlock()
            
            let additionalDemand = self.downstream.receive(buffer)
            
            lock.lock()
            self.demand += additionalDemand
            lock.unlock()
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            
            switch completion {
            case .finished:
                if buffer.isEmpty {
                    lock.unlock()
                } else {
                    let buffer = self.buffer
                    self.buffer = []
                    lock.unlock()
                    
                    _ = downstream.receive(buffer)
                }
                
            case .failure:
                buffer = []
                lock.unlock()
            }
            
            downstream.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "demand must be greater than zero.")
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            self.demand = demand
            lock.unlock()
            
            subscription.request(.unlimited)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            buffer = []
            lock.unlock()
            
            scheduled?.cancel()
            scheduled = nil
            
            subscription.cancel()
        }
        
        var description: String {
            "CollectByTime"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }

            let children: [Mirror.Child] = [
                ("downstream", downstream),
                ("strategy", strategy),
                ("options", options as Any),
                ("status", status),
                ("scheduled", scheduled as Any),
                ("demand", demand)
            ]

            return Mirror(self, children: children)
        }
    }
}


extension Publishers.Collect {
    
    // MARK: COLLECT SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, Void> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        fileprivate init(downstream: Downstream) {
            super.init(downstream: downstream, initial: [], reduce: ())
        }

        override func receive(newValue: Input) -> PartialCompletion<Void, Failure> {
            result?.append(newValue)
            return .continue
        }

        override var description: String {
            "Collect"
        }
        
        override var customMirror: Mirror {
            Mirror(reflecting: self)
        }
    }
}

extension Publishers.CollectByCount {
    
    // MARK: COLLECT BY COUNT SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        private let count: Int
        
        private let lock = Lock()
        
        private var buffer: [Input] = []
        private var subscription: Subscription?
        
        init(downstream: Downstream, count: Int) {
            self.downstream = downstream
            self.count = count
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard self.subscription == nil else { lock.unlock(); return }
            self.subscription = subscription
            lock.unlock()
            
            downstream.receive(subscription: self)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard subscription == nil else { lock.unlock(); return .none }
            
            buffer.append(input)
            guard buffer.count == count else { lock.unlock(); return .none }
            
            let buffer = self.buffer
            self.buffer = []
            lock.unlock()
                
            return downstream.receive(buffer)
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard self.subscription == nil else { lock.unlock(); return }
            subscription = nil
            
            switch completion {
            case .finished:
                if buffer.isEmpty {
                    lock.unlock()
                } else {
                    let buffer = self.buffer
                    self.buffer = []
                    lock.unlock()
                    
                    _ = downstream.receive(buffer)
                }
                
            case .failure:
                buffer = []
                lock.unlock()
            }
            
            downstream.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "demand must be greater than zero.")
            lock.lock()
            guard let subscription = subscription else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand * count)
        }
        
        func cancel() {
            lock.lock()
            guard let subscription = subscription else { lock.unlock(); return }
            self.subscription = nil
            buffer = []
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "CollectByCount"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }
            
            let children: [Mirror.Child] = [
                ("downstream", downstream),
                ("upstreamSubscription", subscription as Any),
                ("buffer", buffer),
                ("count", count)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
