//
//  Passthrough Subject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 02/02/20.
//

/// A subject that broadcasts elements to downstream subscribers.
///
/// As a concrete implementation of Subject, the PassthroughSubject provides a convenient way to adapt existing imperative code to the Combine model.
///
/// Unlike CurrentValueSubject, a PassthroughSubject doesn’t have an initial value or a buffer of the most recently-published element.
final public class PassthroughSubject<Output, Failure: Error>: Subject {
    
    final private var _completion: Subscribers.Completion<Failure>? = nil
    
    private var upstreamSubscriptions: [Subscription] = []
    private var downstreamSubscriptions: [Conduit] = []
    
    private let _lock = RecursiveLock()
    private var hasAnyDownstreamDemand = false
    
    public init() {}
    
    deinit {
        downstreamSubscriptions.forEach { (subscription) in
            subscription._downstream = nil
        }
    }
    
    final public func send(subscription: Subscription) {
        _lock.lock()
        defer { _lock.unlock() }
        
        upstreamSubscriptions.append(subscription)
        subscription.request(.unlimited)
    }
    
    final public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        _lock.lock()
        defer { _lock.unlock() }
        
        if let completion = _completion {
            subscriber.receive(subscription: Subscriptions.empty)
            subscriber.receive(completion: completion)
        } else {
            let subscription = Conduit(parent: self, downstream: AnySubscriber(subscriber))
            downstreamSubscriptions.append(subscription)
            
            subscriber.receive(subscription: subscription)
        }
    }
    
    final public func send(_ input: Output) {
        _lock.lock()
        defer { _lock.unlock() }
        
        guard _completion == nil else { return }    // if subject has been completed, do not send any more inputs.
        
        downstreamSubscriptions.forEach { (subscription) in
            subscription.offer(input)
        }
    }
    
    final public func send(completion: Subscribers.Completion<Failure>) {
        _lock.lock()
        defer { _lock.unlock() }
        
        guard _completion == nil else { return }    // if subject has been completed, do not send or save future completions.
        
        _completion = completion
        downstreamSubscriptions.forEach { (subscription) in
            subscription.finish(completion: completion)
        }
        
        downstreamSubscriptions = []
    }
    
    fileprivate func acknowledgeDownstreamDemand() {
        _lock.lock()
        defer { _lock.unlock() }
        
        guard !hasAnyDownstreamDemand else { return }
        hasAnyDownstreamDemand = true
        for subscription in upstreamSubscriptions {
            subscription.request(.unlimited)
        }
    }
}

extension PassthroughSubject {
    
    // MARK: PASSTHROUGH SUBJECT SINK
    // MARK: CURRENT VALUE SUBJECT SINK
    private class Conduit: Subscription, CustomStringConvertible {
        
        private var _parent: PassthroughSubject?
        
        fileprivate var _downstream: AnySubscriber<Output, Failure>?
        
        fileprivate var _demand: Subscribers.Demand = .none
        
        var isCompleted: Bool {
            return _parent == nil
        }
        
        func offer(_ value: Output) {
            let newDemand = _downstream?.receive(value) ?? .none
            _demand += newDemand
        }
        
        init(parent: PassthroughSubject, downstream: AnySubscriber<Output, Failure>) {
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
                _demand += demand
            }
            _parent?.acknowledgeDownstreamDemand()
        }
        
        func cancel() {
            _parent = nil
        }
        
        var description: String {
            "PassthroughSubject"
        }
    }
}
