//
//  Current Value Subject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 02/02/20.
//

import Foundation

/// A subject that wraps a single value and publishes a new element whenever the value changes.
///
/// Unlike PassthroughSubject, CurrentValueSubject maintains a buffer of the most recently published element.
final public class CurrentValueSubject<Output, Failure: Error>: Subject {
    
    final private var _completion: Subscribers.Completion<Failure>? = nil
    
    private var upstreamSubscriptions: [Subscription] = []
    private var downstreamSubscriptions: [Inner] = []
    
    private let _lock = RecursiveLock()
    
    private var _value: Output
    
    /// The value wrapped by this subject, published as a new element whenever it changes.
    final public var value: Output {
        get {
            _value
        } set {
            send(newValue)
        }
    }
    
    /// Creates a current value subject with the given initial value.
    ///
    /// - Parameter value: The initial value to publish.
    public init(_ value: Output) {
        self._value = value
    }
    
    deinit {
        upstreamSubscriptions.forEach { (subscription) in
            subscription.cancel()
        }
        
        upstreamSubscriptions = []
        
        downstreamSubscriptions.forEach { (subscription) in
            subscription.cancel()
        }
        
        downstreamSubscriptions = []
    }
    
    final public func send(subscription: Subscription) {
        _lock.do {
            upstreamSubscriptions.append(subscription)
            subscription.request(_completion == nil ? .unlimited : .none)
        }
    }
    
    final public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        _lock.do {
            if let completion = _completion {
                subscriber.receive(subscription: Subscriptions.empty)
                subscriber.receive(completion: completion)
            } else {
                let subscription = Inner(downstream: AnySubscriber(subscriber))
                subscription.subject = self
                subscription.lock = _lock
                downstreamSubscriptions.append(subscription)
                
                subscriber.receive(subscription: subscription)
            }
        }
    }
    
    final public func send(_ input: Output) {
        _lock.do {
            guard _completion == nil else { return }    // if subject has been completed, do not send or save any more inputs.
            
            _value = input
            downstreamSubscriptions.forEach { (subscription) in
                subscription.receive(input)
            }
        }
    }
    
    final public func send(completion: Subscribers.Completion<Failure>) {
        _lock.do {
            guard _completion == nil else { return }    // if subject has been completed, do not send or save future completions.
            
            _completion = completion
            downstreamSubscriptions.forEach { (subscription) in
                subscription.receive(completion: completion)
            }
            
            downstreamSubscriptions = []
        }
    }
}

extension CurrentValueSubject {
    
    // MARK: CURRENT VALUE SUBJECT SINK
    private final class Inner: Subscriptions.InternalSubject<Output, Failure> {
        
        var subject: CurrentValueSubject?
        var lock: RecursiveLock?
        
        private var hasDeliveredOnRequest = false
        
        override func request(_ demand: Subscribers.Demand) {
            guard !isTerminated, !hasDeliveredOnRequest, _demand >= .none else { return }
            _demand += demand
            
            if let value = subject?.value {
                receive(value)
            }
            
            hasDeliveredOnRequest = true
        }
        
        @inlinable override func finish() {
            super.finish()
            subject = nil
            lock = nil
        }
        
        override var description: String {
            "CurrentValueSubject"
        }
    }
}
