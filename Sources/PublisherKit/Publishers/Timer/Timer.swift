//
//  Timer.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

import Foundation

extension Timer {
    
    /// Returns a publisher that repeatedly emits the current date on the given interval.
    ///
    /// - Parameters:
    ///   - interval: The time interval on which to publish events. For example, a value of `0.5` publishes an event approximately every half-second.
    ///   - tolerance: The allowed timing variance when emitting events. Defaults to `nil`, which allows any variance.
    ///   - runLoop: The run loop on which the timer runs.
    ///   - mode: The run loop mode in which to run the timer.
    ///   - options: Scheduler options passed to the timer. Defaults to `nil`.
    /// - Returns: A publisher that repeatedly emits the current date on the given interval.
    public static func pkPublish(every interval: TimeInterval, tolerance: TimeInterval? = nil, on runLoop: RunLoop, in mode: RunLoop.Mode, options: RunLoop.PKSchedulerOptions? = nil) -> TimerPKPublisher {
        TimerPKPublisher(interval: interval, tolerance: tolerance, runLoop: runLoop, mode: mode, options: options)
    }
    
    /// A publisher that repeatedly emits the current date on a given interval.
    final public class TimerPKPublisher: ConnectablePublisher {
        
        public typealias Output = Date
        
        public typealias Failure = Never
        
        final public let interval: TimeInterval
        
        final public let tolerance: TimeInterval?
        
        final public let runLoop: RunLoop
        
        final public let mode: RunLoop.Mode
        
        final public let options: RunLoop.PKSchedulerOptions?
        
        private let inner: Inner
        
        /// Creates a publisher that repeatedly emits the current date on the given interval.
        ///
        /// - Parameters:
        ///   - interval: The interval on which to publish events.
        ///   - tolerance: The allowed timing variance when emitting events. Defaults to `nil`, which allows any variance.
        ///   - runLoop: The run loop on which the timer runs.
        ///   - mode: The run loop mode in which to run the timer.
        ///   - options: Scheduler options passed to the timer. Defaults to `nil`.
        public init(interval: TimeInterval, tolerance: TimeInterval? = nil, runLoop: RunLoop, mode: RunLoop.Mode, options: RunLoop.PKSchedulerOptions? = nil)  {
            self.interval = interval
            self.tolerance = tolerance
            self.runLoop = runLoop
            self.mode = mode
            self.options = options
            
            inner = Inner(interval: interval, tolerance: tolerance, runLoop: runLoop, mode: mode, options: options)
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let routingSubscription = RoutingSubscription(downstream: AnySubscriber(subscriber), inner: inner)
            subscriber.receive(subscription: routingSubscription)
            
            inner.lock.lock()
            inner.subscriptions.append(routingSubscription)
            inner.lock.unlock()
        }
        
        final public func connect() -> Cancellable {
            inner.connect()
        }
    }
}

extension Timer.TimerPKPublisher {
    
    // MARK: TIMER SINK
    private final class Inner: CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
        
        fileprivate var subscriptions: [RoutingSubscription] = []
        
        fileprivate let lock = Lock()
        
        private var demand: Subscribers.Demand = .none
        
        private var isTerminated = false
        
        private var connection: Cancellable?
        
        private let interval: TimeInterval
        
        private let tolerance: TimeInterval?
        
        private let runLoop: RunLoop
        
        private let mode: RunLoop.Mode
        
        private let options: RunLoop.PKSchedulerOptions?
        
        init(interval: TimeInterval, tolerance: TimeInterval? = nil, runLoop: RunLoop, mode: RunLoop.Mode, options: RunLoop.PKSchedulerOptions? = nil) {
            self.interval = interval
            self.tolerance = tolerance
            self.runLoop = runLoop
            self.mode = mode
            self.options = options
        }
        
        func connect() -> Cancellable {
            lock.lock()
            if let connection = connection {
                lock.unlock()
                return connection
            }
            
            guard !isTerminated else { lock.unlock(); return Subscriptions.empty }
            
            let timer = Timer(fireAt: Date().addingTimeInterval(interval), interval: interval, target: self, selector: #selector(timerFired(args:)), userInfo: nil, repeats: true)
            
            if let tolerance = tolerance {
                timer.tolerance = tolerance
            }
            
            let connection = AnyCancellable { timer.invalidate() }
            self.connection = connection
            runLoop.add(timer, forMode: mode)
            lock.unlock()
            
            return connection
        }
        
        @objc private func timerFired(args: Timer) {
            lock.lock()
            guard demand > .none, !isTerminated else { lock.unlock(); return }
            demand -= 1
            lock.unlock()
            
            let date = Date()
            
            var additionalDemand: Subscribers.Demand = .none
            
            subscriptions.forEach { (subscription) in
                additionalDemand += subscription.receive(date)
            }
            
            lock.lock()
            demand += additionalDemand
            lock.unlock()
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard demand > .none else { lock.unlock(); return }
            self.demand += demand
            lock.unlock()
        }
        
        func cancel() {
            lock.lock()
            guard !isTerminated else { lock.unlock(); return }
            isTerminated = true
            connection?.cancel()
            subscriptions = []
            lock.unlock()
        }
        
        var description: String {
            "Timer"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
    
    private struct RoutingSubscription: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
        
        private let downstream: AnySubscriber<Output, Failure>
        private let inner: Inner
        let combineIdentifier: CombineIdentifier
        
        init(downstream: AnySubscriber<Output, Failure>, inner: Inner) {
            self.downstream = downstream
            self.inner = inner
            combineIdentifier = CombineIdentifier()
        }
        
        func receive(_ input: Output) -> Subscribers.Demand {
            downstream.receive(input)
        }
        
        func request(_ demand: Subscribers.Demand) {
            inner.request(demand)
        }
        
        func cancel() {
            inner.cancel()
        }
        
        var description: String {
            inner.description
        }
        
        var playgroundDescription: Any {
            inner.playgroundDescription
        }
        
        var customMirror: Mirror {
            inner.customMirror
        }
    }
}
