//
//  Any Subscriber.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

@available(*, deprecated, renamed: "AnySubscriber")
public typealias NKAnySubscriber = AnySubscriber

@available(*, deprecated, renamed: "AnySubscriber")
public typealias AnyPKSubscriber = AnySubscriber

/// A type-erasing subscriber.
///
/// Use `AnySubscriber` to wrap an existing subscriber whose details you don’t want to expose.
/// `AnySubscriber` can also be used to create a custom subscriber by providing closures for `Subscriber`’s methods, rather than implementing `Subscriber` directly.
public struct AnySubscriber<Input, Failure: Error>: Subscriber {
    
    public let combineIdentifier: CombineIdentifier
    
    @usableFromInline var sink: AnySubscriberBaseSink<Input, Failure>
    
    /// Creates a type-erasing subscriber to wrap an existing subscriber.
    ///
    /// - Parameter subscriber: The subscriber to type-erase.
    @inlinable public init<S: Subscriber>(_ subscriber: S) where Input == S.Input, Failure == S.Failure {
        sink = AnySubscriberSink(subscriber: subscriber)
        combineIdentifier = subscriber.combineIdentifier
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
    @inlinable public init(receiveSubscription: ((Subscription) -> Void)? = nil,
                           receiveValue: ((Input) -> Subscribers.Demand)? = nil,
                           receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)? = nil) {
        combineIdentifier = CombineIdentifier()
        sink = ClosureAnySubscriberSink(receiveSubscription: receiveSubscription,
                                        receiveValue: receiveValue,
                                        receiveCompletion: receiveCompletion)
    }
    
    @inlinable public func receive(subscription: Subscription) {
        sink.receive(subscription: subscription)
    }
    
    @inlinable public func receive(_ input: Input) -> Subscribers.Demand {
        sink.receive(input)
    }
    
    @inlinable public func receive(completion: Subscribers.Completion<Failure>) {
        sink.receive(completion: completion)
    }
}

@usableFromInline class AnySubscriberBaseSink<Input, Failure: Error>: Subscriber {
    
    @usableFromInline func receive(subscription: Subscription) { }
    
    @usableFromInline func receive(_ input: Input) -> Subscribers.Demand { .none }
    
    @usableFromInline func receive(completion: Subscribers.Completion<Failure>) { }
}

@usableFromInline final class AnySubscriberSink<SomeSubscriber: Subscriber>: AnySubscriberBaseSink<SomeSubscriber.Input, SomeSubscriber.Failure> {
    
    @usableFromInline var subscriber: SomeSubscriber?
    
    @usableFromInline init(subscriber: SomeSubscriber) {
        self.subscriber = subscriber
    }
    
    @usableFromInline override func receive(subscription: Subscription) {
        subscriber?.receive(subscription: subscription)
        subscription.request(.unlimited)
    }
    
    @usableFromInline override func receive(_ input: Input) -> Subscribers.Demand {
        subscriber?.receive(input) ?? .none
    }
    
    @usableFromInline override func receive(completion: Subscribers.Completion<Failure>) {
        subscriber?.receive(completion: completion)
    }
}

@usableFromInline final class ClosureAnySubscriberSink<Input, Failure: Error>: AnySubscriberBaseSink<Input, Failure> {
    
    
    @usableFromInline var receiveSubscription: ((Subscription) -> Void)?
    @usableFromInline var receiveValue: ((Input) -> Subscribers.Demand)?
    @usableFromInline var receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)?
    
    @usableFromInline init(receiveSubscription: ((Subscription) -> Void)?,
                    receiveValue: ((Input) -> Subscribers.Demand)?,
                    receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)?) {
        
        self.receiveSubscription = receiveSubscription
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
    }
    
    @usableFromInline override func receive(subscription: Subscription) {
        receiveSubscription?(subscription)
    }
    
    @usableFromInline override func receive(_ input: Input) -> Subscribers.Demand {
        receiveValue?(input) ?? .none
    }
    
    @usableFromInline override func receive(completion: Subscribers.Completion<Failure>) {
        receiveCompletion?(completion)
    }
}
