//
//  Current Value Subject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 02/02/20.
//

/// A subject that wraps a single value and publishes a new element whenever the value changes.
///
/// Unlike PassthroughSubject, CurrentValueSubject maintains a buffer of the most recently published element.
final public class CurrentValueSubject<Output, Failure: Error>: Subject {
    
    final private var _completion: Subscribers.Completion<Failure>? = nil
    
    private var upstreamSubscriptions: [Subscription] = []
    private var downstreamSubscriptions: [Conduit] = []
    
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
        downstreamSubscriptions.forEach { (subscription) in
            subscription._downstream = nil
        }
    }
    
    final public func send(subscription: Subscription) {
        _lock.do {
            upstreamSubscriptions.append(subscription)
            subscription.request(.unlimited)
        }
    }
    
    final public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        _lock.do {
            if let completion = _completion {
                subscriber.receive(subscription: Subscriptions.empty)
                subscriber.receive(completion: completion)
            } else {
                let subscription = Conduit(parent: self, downstream: AnySubscriber(subscriber))
                downstreamSubscriptions.append(subscription)
                
                subscriber.receive(subscription: subscription)
            }
        }
    }
    
    final public func send(_ input: Output) {
        _lock.do {
            guard _completion == nil else { return }    // if subject has been completed, do not send or save any more inputs.
            
            for subscription in downstreamSubscriptions where !subscription.isCompleted {
                if subscription._demand > 0 {
                    subscription.offer(input)
                    subscription._demand -= 1
                } else {
                    subscription._delivered = false
                }
            }
        }
    }
    
    final public func send(completion: Subscribers.Completion<Failure>) {
        _lock.do {
            guard _completion == nil else { return }    // if subject has been completed, do not send or save future completions.
            
            _completion = completion
            
            downstreamSubscriptions.forEach { (subscription) in
                subscription.finish(completion: completion)
            }
            
            downstreamSubscriptions = []
        }
    }
}

extension CurrentValueSubject {
    
    // MARK: CURRENT VALUE SUBJECT SINK
    private class Conduit: Subscription, CustomStringConvertible {

        private var _parent: CurrentValueSubject?

        fileprivate var _downstream: AnySubscriber<Output, Failure>?

        fileprivate var _demand: Subscribers.Demand = .none

        /// Whethere we satisfied the demand
        fileprivate var _delivered = false

        var isCompleted: Bool {
            return _parent == nil
        }

        func offer(_ value: Output) {
            let newDemand = _downstream?.receive(value) ?? .none
            _demand += newDemand
            _delivered = true
        }

        init(parent: CurrentValueSubject, downstream: AnySubscriber<Output, Failure>) {
            _parent = parent
            _downstream = downstream
        }

        func finish(completion: Subscribers.Completion<Failure>) {
            if !isCompleted {
                _parent = nil
                _downstream?.receive(completion: completion)
            }
        }

        func request(_ demand: Subscribers.Demand) {
            precondition(demand > 0)
            
            _parent?._lock.do {
                if !_delivered, let value = _parent?.value {
                    let newDemand = _downstream?.receive(value) ?? .none
                    _demand += newDemand
                    _delivered = true
                    
                    _demand += demand
                    _demand -= 1
                } else {
                    _demand = demand
                }
            }
        }

        func cancel() {
            _parent = nil
        }
        
        var description: String {
            "CurrentValueSubject"
        }
    }
}
