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
    
    final private var _completion: PKSubscribers.Completion<Failure>? = nil
    
    private var upstreamSubscriptions: [PKSubscription] = []
    private var downstreamSubscriptions: [InternalSink] = []
    
    public init() {}
    
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
    
    final public func send(completion: PKSubscribers.Completion<Failure>) {
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
    private final class InternalSink: SubjectBaseSubscriber<Output, Failure> {
    }
}
