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
    public static func pkPublish(every interval: TimeInterval, tolerance: TimeInterval? = nil, on runLoop: RunLoop, in mode: RunLoop.Mode, options: RunLoop.PKSchedulerOptions? = nil) -> Timer.TimerPKPublisher {
        Timer.TimerPKPublisher(interval: interval, tolerance: tolerance, runLoop: runLoop, mode: mode, options: options)
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
            inner.subscriptions.append(routingSubscription)
        }
        
        final public func connect() -> Cancellable {
            inner.connect()
        }
    }
}

extension Timer.TimerPKPublisher {

    // MARK: TIMER SINK
    private final class Inner {
        
        private let lock = Lock()
        
        final public let interval: TimeInterval
        
        final public let tolerance: TimeInterval?
        
        final public let runLoop: RunLoop
        
        final public let mode: RunLoop.Mode
        
        final public let options: RunLoop.PKSchedulerOptions?
        
        public init(interval: TimeInterval, tolerance: TimeInterval? = nil, runLoop: RunLoop, mode: RunLoop.Mode, options: RunLoop.PKSchedulerOptions? = nil)  {
            self.interval = interval
            self.tolerance = tolerance
            self.runLoop = runLoop
            self.mode = mode
            self.options = options
        }
        
        fileprivate var subscriptions: [RoutingSubscription] = []
        var connection: Cancellable?
        
        func connect() -> Cancellable {
            lock.lock()
            if let connection = connection {
                lock.unlock()
                return connection
            }
            
            let timer = Timer(fireAt: Date().addingTimeInterval(interval), interval: interval, target: self, selector: #selector(timerFired(args:)), userInfo: nil, repeats: true)
            
            if let tolerance = tolerance {
                timer.tolerance = tolerance
            }
            
            connection = AnyCancellable { timer.invalidate() }
            lock.unlock()
            runLoop.add(timer, forMode: mode)
            
            return connection!
        }
        
        @objc private func timerFired(args: Timer) {
            let date = Date()
            subscriptions.forEach { (subscription) in
                _ = subscription.receive(date)
            }
        }
        
        func cancel() {
            lock.lock()
            connection?.cancel()
            lock.unlock()
        }
    }
    
    private final class RoutingSubscription: Subscription, CustomStringConvertible, CustomReflectable {
        
        let downstream: AnySubscriber<Output, Failure>
        let inner: Inner
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        var demand: Subscribers.Demand = .none
        
        init(downstream: AnySubscriber<Output, Failure>, inner: Inner) {
            self.downstream = downstream
            self.inner = inner
        }
        
        func receive(_ input: Output) -> Subscribers.Demand {
            lock.lock()
            guard demand > 0 else { lock.unlock(); return .none }
            demand -= 1
            lock.unlock()
            
            downstreamLock.lock()
            let newDemand = downstream.receive(input)
            downstreamLock.unlock()
            
            lock.lock()
            demand += newDemand
            lock.unlock()
            
            return demand
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            self.demand += demand
            lock.unlock()
        }
        
        func cancel() {
            lock.lock()
            inner.cancel()
            lock.unlock()
        }
        
        var description: String { "" }
        var customMirror: Mirror { Mirror(self, children: [])}
    }
}
