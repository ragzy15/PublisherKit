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
    private var downstreamSubscriptions = Set<InternalSink>()
    
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
        subscription.request(.unlimited)
    }
    
    final public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        
        if let completion = _completion {
            subscriber.receive(subscription: Subscriptions.empty)
            subscriber.receive(completion: completion)
        } else {
            let subscription = InternalSink(downstream: AnyPKSubscriber(subscriber))
            downstreamSubscriptions.insert(subscription)
            subscriber.receive(subscription: subscription)
            
            subscription.remove = { [weak self] (subscription) in
                self?.downstreamSubscriptions.remove(subscription)
            }
        }
    }
    
    final public func send(_ input: Output) {
        guard _completion == nil else { return }
        downstreamSubscriptions.forEach { (subscription) in
            subscription.receive(input)
        }
    }
    
    final public func send(completion: PKSubscribers.Completion<Failure>) {
        _completion = completion
        downstreamSubscriptions.forEach { (subscription) in
            subscription.receive(completion: completion)
        }
    }
}

extension PassthroughSubject {
    
    private final class InternalSink: PKSubscription, Hashable {
        
        static func == (lhs: InternalSink, rhs: InternalSink) -> Bool {
            lhs.identitfier == rhs.identitfier
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(identitfier)
        }
        
        var remove: ((InternalSink) -> Void)?
        
        private var identitfier: ObjectIdentifier!
        
        private var downstream: AnyPKSubscriber<Output, Failure>?
        
        private var isOver = false
        
        private var _demand: PKSubscribers.Demand = .none
        
        init(downstream: AnyPKSubscriber<Output, Failure>) {
            self.downstream = downstream
            identitfier = ObjectIdentifier(self)
        }
        
        func request(_ demand: PKSubscribers.Demand) {
            _demand += demand
        }
        
        func receive(_ input: Output)  {
            guard !isOver else { return }
            let newDemand = downstream?.receive(input)
            _demand = newDemand ?? .none
        }
        
        func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isOver else { return }
            finish()
            downstream?.receive(completion: completion)
        }
        
        func cancel() {
            finish()
        }
        
        @inlinable func finish() {
            isOver = true
            downstream = nil
            remove?(self)
        }
    }
}
