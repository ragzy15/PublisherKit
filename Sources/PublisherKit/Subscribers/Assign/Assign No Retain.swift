//
//  Assign No Retain.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/04/20.
//

extension Subscribers {
    
    /// A simple subscriber that assigns received elements to a property indicated by a key path.
    /// - Note: It is created as there is a flaw in `Assign` subscriber that it strongly holds the reference to object which can leak memory.
    final public class AssignNoRetain<Root: AnyObject, Input>: Subscriber, Cancellable {
        
        public typealias Failure = Never
        
        /// The object that contains the property to assign.
        final public var object: Root? { _object }
        
        private weak var _object: Root?
        
        private var subscription: Subscription?
        
        /// The key path that indicates the property to assign.
        final public var keyPath: ReferenceWritableKeyPath<Root, Input>
        
        /// Creates a subscriber to assign the value of a property indicated by a key path.
        /// - Parameters:
        ///   - object: The object that contains the property. The subscriber assigns the object’s property every time it receives a new value.
        ///   - keyPath: A key path that indicates the property to assign. See [Key-Path Expression](https://docs.swift.org/swift-book/ReferenceManual/Expressions.html#//apple_ref/doc/uid/TP40014097-CH32-ID563) in *The Swift Programming Language* to learn how to use key paths to specify a property of an object.
        public init(object: Root, keyPath: ReferenceWritableKeyPath<Root, Input>) {
            self._object = object
            self.keyPath = keyPath
        }
        
        final public func receive(subscription: Subscription) {
            guard self.subscription == nil else { return }
            self.subscription = subscription
            subscription.request(.unlimited)
        }
        
        final public func receive(_ value: Input) -> Subscribers.Demand {
            guard subscription != nil else { return .none }
            _object?[keyPath: keyPath] = value
            return .none
        }
        
        final public func receive(completion: Subscribers.Completion<Never>) {
            guard subscription != nil else { return }
            subscription = nil
            _object = nil
        }
        
        final public func cancel() {
            _object = nil
            subscription?.cancel()
            subscription = nil
        }
    }
}
