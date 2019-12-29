//
//  Any Subscriber.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public struct NKAnySubscriber<Input, Failure: Error>: NKSubscriber {
    
    @usableFromInline let receiveSubscription: ((NKSubscription) -> Void)?
    @usableFromInline let receiveValue: ((Input) -> NKSubscribers.Demand)?
    @usableFromInline let receiveCompletion: ((NKSubscribers.Completion<Failure>) -> Void)?

    /// Creates a type-erasing subscriber to wrap an existing subscriber.
    ///
    /// - Parameter s: The subscriber to type-erase.
    @inlinable public init<S: NKSubscriber>(_ s: S) where Input == S.Input, Failure == S.Failure {
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
    @inlinable public init(receiveSubscription: ((NKSubscription) -> Void)? = nil, receiveValue: ((Input) -> NKSubscribers.Demand)? = nil, receiveCompletion: ((NKSubscribers.Completion<Failure>) -> Void)? = nil) {
        self.receiveSubscription = receiveSubscription
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
    }

    @inlinable public func receive(subscription: NKSubscription) {
        receiveSubscription?(subscription)
    }
    
    @inlinable public func receive(_ value: Input) -> NKSubscribers.Demand {
        receiveValue?(value) ?? .none
    }
    
    @inlinable public func receive(completion: NKSubscribers.Completion<Failure>) {
        receiveCompletion?(completion)
    }
}
