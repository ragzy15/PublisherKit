//
//  Assign.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

extension Subscribers {
    
    final public class Assign<Root, Input>: Subscriber, Cancellable {
        
        public typealias Failure = Never
        
        /// The object that contains the property to assign.
        final public var object: Root? { _object }
        
        private var _object: Root?
        
        private var status: SubscriptionStatus = .awaiting
        
        /// The key path that indicates the property to assign.
        final public let keyPath: ReferenceWritableKeyPath<Root, Input>
        
        /// Creates a subscriber to assign the value of a property indicated by a key path.
        /// - Parameters:
        ///   - object: The object that contains the property. The subscriber assigns the object’s property every time it receives a new value.
        ///   - keyPath: A key path that indicates the property to assign. See [Key-Path Expression](https://docs.swift.org/swift-book/ReferenceManual/Expressions.html#//apple_ref/doc/uid/TP40014097-CH32-ID563) in *The Swift Programming Language* to learn how to use key paths to specify a property of an object.
        public init(object: Root, keyPath: ReferenceWritableKeyPath<Root, Input>) {
            self._object = object
            self.keyPath = keyPath
        }
        
        final public func receive(subscription: Subscription) {
            guard case .awaiting = status else {
                subscription.cancel()
                return
            }
            
            status = .subscribed(to: subscription)
            subscription.request(.unlimited)
        }
        
        final public func receive(_ value: Input) -> Subscribers.Demand {
            guard case .subscribed = status else { return .none }
            _object?[keyPath: keyPath] = value
            return .none
        }
        
        final public func receive(completion: Subscribers.Completion<Failure>) {
            cancel()
        }
        
        final public func cancel() {
            guard case .subscribed(let subscription) = status else { return }
            status = .terminated
            _object = nil
            subscription.cancel()
        }
        
        final public var description: String {
            "Assign \(Root.self)."
        }
        
        final public var playgroundDescription: Any {
            description
        }
        
        final public var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("object", object as Any),
                ("keyPath", keyPath),
                ("status", status as Any)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
