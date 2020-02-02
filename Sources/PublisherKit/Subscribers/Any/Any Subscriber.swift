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
    
    @usableFromInline var sink: AnySubscriberBaseSink<Input, Failure>
    
    /// Creates a type-erasing subscriber to wrap an existing subscriber.
    ///
    /// - Parameter subscriber: The subscriber to type-erase.
    @inlinable public init<S: PKSubscriber>(_ subscriber: S) where Input == S.Input, Failure == S.Failure {
        sink = AnySubscriberSink(subscriber: subscriber)
    }
    
    public init<S: Subject>(_ subject: S) where Input == S.Output, Failure == S.Failure {
        self.init(SubjectSubscriber(subject: subject))
    }
    
    /// Creates a type-erasing subscriber that executes the provided closures.
    ///
    /// - Parameters:
    ///   - receiveSubscription: A closure to execute when the subscriber receives the initial subscription from the publisher.
    ///   - receiveValue: A closure to execute when the subscriber receives a value from the publisher.
    ///   - receiveCompletion: A closure to execute when the subscriber receives a completion callback from the publisher.
    @inlinable public init(receiveSubscription: ((PKSubscription) -> Void)? = nil,
                           receiveValue: ((Input) -> PKSubscribers.Demand)? = nil,
                           receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)? = nil) {
        
        sink = ClosureAnySubscriberSink(receiveSubscription: receiveSubscription,
                                        receiveValue: receiveValue,
                                        receiveCompletion: receiveCompletion)
    }
    
    @inlinable public func receive(subscription: PKSubscription) {
        sink.receive(subscription: subscription)
    }
    
    @inlinable public func receive(_ input: Input) -> PKSubscribers.Demand {
        sink.receive(input)
    }
    
    @inlinable public func receive(completion: PKSubscribers.Completion<Failure>) {
        sink.receive(completion: completion)
    }
}

@usableFromInline class AnySubscriberBaseSink<Input, Failure: Error>: PKSubscriber {
    
    @usableFromInline func receive(subscription: PKSubscription) { }
    
    @usableFromInline func receive(_ input: Input) -> PKSubscribers.Demand { .none }
    
    @usableFromInline func receive(completion: PKSubscribers.Completion<Failure>) { }
}

@usableFromInline final class AnySubscriberSink<Subscriber: PKSubscriber>: AnySubscriberBaseSink<Subscriber.Input, Subscriber.Failure> {
    
    @usableFromInline var subscriber: Subscriber?
    
    @usableFromInline init(subscriber: Subscriber) {
        self.subscriber = subscriber
    }
    
    @usableFromInline override func receive(subscription: PKSubscription) {
        subscriber?.receive(subscription: subscription)
    }
    
    @usableFromInline override func receive(_ input: Input) -> PKSubscribers.Demand {
        subscriber?.receive(input) ?? .none
    }
    
    @usableFromInline override func receive(completion: PKSubscribers.Completion<Failure>) {
        subscriber?.receive(completion: completion)
    }
}

@usableFromInline final class ClosureAnySubscriberSink<Input, Failure: Error>: AnySubscriberBaseSink<Input, Failure> {
    
    
    @usableFromInline var receiveSubscription: ((PKSubscription) -> Void)?
    @usableFromInline var receiveValue: ((Input) -> PKSubscribers.Demand)?
    @usableFromInline var receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)?
    
    @usableFromInline init(receiveSubscription: ((PKSubscription) -> Void)?,
                    receiveValue: ((Input) -> PKSubscribers.Demand)?,
                    receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)?) {
        
        self.receiveSubscription = receiveSubscription
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
    }
    
    @usableFromInline override func receive(subscription: PKSubscription) {
        receiveSubscription?(subscription)
    }
    
    @usableFromInline override func receive(_ input: Input) -> PKSubscribers.Demand {
        receiveValue?(input) ?? .none
    }
    
    @usableFromInline override func receive(completion: PKSubscribers.Completion<Failure>) {
        receiveCompletion?(completion)
    }
}
