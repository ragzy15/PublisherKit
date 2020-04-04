//
//  Timeout.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 29/03/20.
//

extension Publisher {
    
    /// Terminates publishing if the upstream publisher exceeds the specified time interval without producing an element.
    ///
    /// - Parameters:
    ///   - interval: The maximum time interval the publisher can go without emitting an element, expressed in the time system of the scheduler.
    ///   - scheduler: The scheduler to deliver events on.
    ///   - options: Scheduler options that customize the delivery of elements.
    ///   - customError: A closure that executes if the publisher times out. The publisher sends the failure returned by this closure to the subscriber as the reason for termination.
    /// - Returns: A publisher that terminates if the specified interval elapses with no events received from the upstream publisher.
    public func timeout<S: Scheduler>(_ interval: S.PKSchedulerTimeType.Stride, scheduler: S, options: S.PKSchedulerOptions? = nil, customError: (() -> Failure)? = nil) -> Publishers.Timeout<Self, S> {
        Publishers.Timeout(upstream: self, interval: interval, scheduler: scheduler, options: options, customError: customError)
    }
}

extension Publishers {
    
    public struct Timeout<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        public let interval: Context.PKSchedulerTimeType.Stride
        
        public let scheduler: Context
        
        public let options: Context.PKSchedulerOptions?
        
        public let customError: (() -> Upstream.Failure)?
        
        public init(upstream: Upstream, interval: Context.PKSchedulerTimeType.Stride, scheduler: Context, options: Context.PKSchedulerOptions?, customError: (() -> Failure)?) {
            self.upstream = upstream
            self.interval = interval
            self.scheduler = scheduler
            self.options = options
            self.customError = customError
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, interval: interval, scheduler: scheduler, options: options, customError: customError))
        }
    }
}

extension Publishers.Timeout {
    
    class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        private let interval: Context.PKSchedulerTimeType.Stride
        private let scheduler: Context
        private let options: Context.PKSchedulerOptions?
        private var customError: (() -> Upstream.Failure)?
        
        private var status: SubscriptionStatus = .awaiting
        private var demand: Subscribers.Demand = .none
        private var lastSendTime: Context.PKSchedulerTimeType?
        
        private var cancellable: AnyCancellable?
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        init(downstream: Downstream, interval: Context.PKSchedulerTimeType.Stride, scheduler: Context, options: Context.PKSchedulerOptions?, customError: (() -> Failure)?) {
            self.downstream = downstream
            self.interval = interval
            self.scheduler = scheduler
            self.options = options
            self.customError = customError
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            
            cancellable = timeoutClock()
            lastSendTime = scheduler.now
            lock.unlock()
            
            downstreamLock.lock()
            downstream.receive(subscription: self)
            downstreamLock.unlock()
            
            lock.lock()
            let demand = self.demand
            lock.unlock()
            
            if demand > .none {
                subscription.request(demand)
            }
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            lastSendTime = scheduler.now
            lock.unlock()
            
            scheduler.schedule(options: options, { [weak self] in
                guard let `self` = self else { return }
                
                self.downstreamLock.lock()
                _ = self.downstream.receive(input)
                self.downstreamLock.unlock()
            })
            
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            let cancellable = self.cancellable
            self.cancellable = nil
            lock.unlock()
            
            cancellable?.cancel()
            
            scheduler.schedule(options: options) { [weak self] in
                guard let `self` = self else { return }
                
                self.downstreamLock.lock()
                self.downstream.receive(completion: completion)
                self.downstreamLock.unlock()
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            self.demand += demand
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            
            let cancellable = self.cancellable
            self.cancellable = nil
            
            customError = nil
            lock.unlock()
            
            cancellable?.cancel()
            subscription.cancel()
        }
        
        private func timeoutClock() -> AnyCancellable {
            let cancellable = scheduler.schedule(after: scheduler.now.advanced(by: interval), interval: interval, tolerance: 0) { [weak self] in
                self?.timedOut()
            }
            
            return AnyCancellable(cancellable.cancel)
        }
        
        private func timedOut() {
            lock.lock()
            guard case .subscribed(let subscription) = status,
                let lastSendTime = lastSendTime, scheduler.now.distance(to: lastSendTime) >= interval else { lock.unlock(); return }
            
            status = .terminated
            
            let cancellable = self.cancellable
            self.cancellable = nil
            
            let customError = self.customError
            self.customError = nil
            lock.unlock()
            
            cancellable?.cancel()
            
            scheduler.schedule(options: options) { [weak self] in
                guard let `self` = self else { return }
                
                let _error = customError?()
                subscription.cancel()
                
                self.downstreamLock.lock()
                if let error = _error {
                    self.downstream.receive(completion: .failure(error))
                } else {
                    self.downstream.receive(completion: .finished)
                }
                self.downstreamLock.unlock()
            }
        }
        
        var description: String {
            "Timeout"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
