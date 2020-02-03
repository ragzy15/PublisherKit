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
    
    final private var _completion: PKSubscribers.Completion<Failure>? = nil
    
    private var upstreamSubscriptions: [PKSubscription] = []
    private var downstreamSubscriptions: [InternalSink] = []
    
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
        
        downstreamSubscriptions.forEach { (subscription) in
            subscription.cancel()
        }
    }
    
    final public func send(subscription: PKSubscription) {
        upstreamSubscriptions.append(subscription)
        subscription.request(_completion == nil ? .unlimited : .none)
    }
    
    final public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        
        if let completion = _completion {
            subscriber.receive(subscription: Subscriptions.empty)
            subscriber.receive(completion: completion)
        } else {
            let subscription = InternalSink(downstream: AnyPKSubscriber(subscriber))
            subscription.subject = self
            downstreamSubscriptions.append(subscription)
            
            subscriber.receive(subscription: subscription)
        }
    }
    
    final public func send(_ input: Output) {
        guard _completion == nil else { return }    // if subject has been completed, do not send or save any more inputs.
        
        _value = input
        downstreamSubscriptions.forEach { (subscription) in
            subscription.receive(input)
        }
    }
    
    final public func send(completion: PKSubscribers.Completion<Failure>) {
        guard _completion == nil else { return }    // if subject has been completed, do not send or save future completions.
        
        _completion = completion
        downstreamSubscriptions.forEach { (subscription) in
            subscription.receive(completion: completion)
        }
        
        downstreamSubscriptions = []
    }
}

extension CurrentValueSubject {
    
    // MARK: CURRENT VALUE SUBJECT SINK
    private final class InternalSink: SubjectBaseSubscriber<Output, Failure> {
        
        var subject: CurrentValueSubject?
        
        override func request(_ demand: PKSubscribers.Demand) {
            super.request(demand)
            guard !isOver, demand > .none else { return }
            
            if let value = subject?.value {
                receive(value)
            }
        }
    }
}
