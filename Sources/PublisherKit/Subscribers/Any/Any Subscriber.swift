//
//  Any Subscriber.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

@available(*, deprecated, renamed: "AnyPKSubscriber")
public typealias NKAnySubscriber = AnyPKSubscriber

/// A type-erasing subscriber.
///
/// Use `AnyPKSubscriber` to wrap an existing subscriber whose details you don’t want to expose.
/// `AnyPKSubscriber` can also be used to create a custom subscriber by providing closures for `PKSubscriber`’s methods, rather than implementing `PKSubscriber` directly.
public struct AnyPKSubscriber<Input, Failure: Error>: PKSubscriber {
    
    @usableFromInline let receiveSubscription: ((PKSubscription) -> Void)?
    @usableFromInline let receiveValue: ((Input) -> PKSubscribers.Demand)?
    @usableFromInline let receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)?

    /// Creates a type-erasing subscriber to wrap an existing subscriber.
    ///
    /// - Parameter s: The subscriber to type-erase.
    @inlinable public init<S: PKSubscriber>(_ s: S) where Input == S.Input, Failure == S.Failure {
        receiveSubscription = { (subscription) in
            s.receive(subscription: subscription)
        }
        
        receiveValue = { (output) in
            s.receive(output)
        }
        
        receiveCompletion = { (completion) in
            s.receive(completion: completion)
        }
    }

    /// Creates a type-erasing subscriber that executes the provided closures.
    ///
    /// - Parameters:
    ///   - receiveSubscription: A closure to execute when the subscriber receives the initial subscription from the publisher.
    ///   - receiveValue: A closure to execute when the subscriber receives a value from the publisher.
    ///   - receiveCompletion: A closure to execute when the subscriber receives a completion callback from the publisher.
    @inlinable public init(receiveSubscription: ((PKSubscription) -> Void)? = nil, receiveValue: ((Input) -> PKSubscribers.Demand)? = nil, receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)? = nil) {
        self.receiveSubscription = receiveSubscription
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
    }

    @inlinable public func receive(subscription: PKSubscription) {
        receiveSubscription?(subscription)
    }
    
    @inlinable public func receive(_ value: Input) -> PKSubscribers.Demand {
        receiveValue?(value) ?? .none
    }
    
    @inlinable public func receive(completion: PKSubscribers.Completion<Failure>) {
        receiveCompletion?(completion)
    }
}
