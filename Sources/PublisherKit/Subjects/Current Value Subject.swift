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
    private var downstreamSubscriptions = Set<InternalSink>()
    
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
            
            subscription.receive(value)
        }
    }
    
    final public func send(_ input: Output) {
        guard _completion == nil else { return }
        _value = input
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

extension CurrentValueSubject {
    
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
