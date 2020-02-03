//
//  Assign.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

extension PKSubscribers {
    
    final public class Assign<Root, Input>: PKSubscriber, PKCancellable {
        
        public typealias Failure = Never
        
        /// The object that contains the property to assign.
        final public var object: Root? { _object }
        
        private var _object: Root?
        
        private var subscription: PKSubscription?
        
        private var isCancelled = false
        
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
        
        final public func receive(subscription: PKSubscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
            subscription.request(.unlimited)
        }
        
        final public func receive(_ value: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _object?[keyPath: keyPath] = value
            return .unlimited
        }
        
        final public func receive(completion: PKSubscribers.Completion<Never>) {
            guard !isCancelled else { return }
            end()
        }
        
        final func end() {
            subscription?.cancel()
            subscription = nil
        }
        
        final public func cancel() {
            isCancelled = true
            _object = nil
            subscription?.cancel()
            subscription = nil
        }
    }
}
