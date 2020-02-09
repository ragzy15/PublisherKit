//
//  Passthrough Subject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 02/02/20.
//

import Foundation

/// A subject that broadcasts elements to downstream subscribers.
///
/// As a concrete implementation of Subject, the PassthroughSubject provides a convenient way to adapt existing imperative code to the Combine model.
///
/// Unlike CurrentValueSubject, a PassthroughSubject doesn’t have an initial value or a buffer of the most recently-published element.
final public class PassthroughSubject<Output, Failure: Error>: Subject {
    
    final private var _completion: Subscribers.Completion<Failure>? = nil
    
    private var upstreamSubscriptions: [Subscription] = []
    private var downstreamSubscriptions: [Inner] = []
    
    public init() {}
    
    deinit {
        upstreamSubscriptions.forEach { (subscription) in
            subscription.cancel()
        }
        
        downstreamSubscriptions.forEach { (subscription) in
            subscription.cancel()
        }
    }
    
    final public func send(subscription: Subscription) {
        upstreamSubscriptions.append(subscription)
        subscription.request(_completion == nil ? .unlimited : .none)
    }
    
    final public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        
        if let completion = _completion {
            subscriber.receive(subscription: Subscriptions.empty)
            subscriber.receive(completion: completion)
        } else {
            let subscription = Inner(downstream: AnySubscriber(subscriber))
            downstreamSubscriptions.append(subscription)
            
            subscriber.receive(subscription: subscription)
        }
    }
    
    final public func send(_ input: Output) {
        guard _completion == nil else { return }    // if subject has been completed, do not send any more inputs.
        
        downstreamSubscriptions.forEach { (subscription) in
            subscription.receive(input)
        }
    }
    
    final public func send(completion: Subscribers.Completion<Failure>) {
        guard _completion == nil else { return }    // if subject has been completed, do not send or save future completions.
        
        _completion = completion
        downstreamSubscriptions.forEach { (subscription) in
            subscription.receive(completion: completion)
        }
        
        downstreamSubscriptions = []
    }
}

extension PassthroughSubject {
    
    // MARK: PASSTHROUGH SUBJECT SINK
    private final class Inner: Subscriptions.InternalSubject<Output, Failure> {
    }
}
