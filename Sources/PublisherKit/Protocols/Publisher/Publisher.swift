//
//  Publisher.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

@available(*, deprecated, renamed: "Publisher")
public typealias NKPublisher = Publisher

@available(*, deprecated, renamed: "Publisher")
public typealias PKPublisher = Publisher

/// Declares that a type can transmit a sequence of values over time.
///
/// There are four kinds of messages:
///     subscription - A connection between `Publisher` and `Subscriber`.
///     value - An element in the sequence.
///     error - The sequence ended with an error (`.failure(e)`).
///     complete - The sequence ended successfully (`.finished`).
///
/// Both `.failure` and `.finished` are terminal messages.
///
/// You can summarize these possibilities with a regular expression:
///   value*(error|finished)?
///
/// Every `Publisher` must adhere to this contract.

//

/// Declares that a type can transmit a sequence of values over time.
///
/// A publisher delivers elements to one or more [Subscriber](apple-reference-documentation://hsDfN2YE-m) instances.
/// The subscriber’s [Input](apple-reference-documentation://hsrmq8c2MQ) and [Failure](apple-reference-documentation://hsWS513Txq) associated types must match the [Output](apple-reference-documentation://hsnFtAIKuJ) and [Failure](apple-reference-documentation://hsWsJXxFs5) types declared by the publisher.
/// The publisher implements the [receive(subscriber:)](apple-reference-documentation://hsEcNjsJr5) method to accept a subscriber. After this, the publisher can call the following methods on the subscriber:
///
/// * [receive(subscription:)](apple-reference-documentation://hsnet3EtNw): Acknowledges the subscribe request and returns a [Subscription](apple-reference-documentation://hsuduLjqdO) instance. The subscriber uses the subscription to demand elements from the publisher and can use it to cancel publishing.
///
/// * [receive(_:)](apple-reference-documentation://hse2ogRhvE): Delivers one element from the publisher to the subscriber.
///
/// * [receive(completion:)](apple-reference-documentation://hsR1HQfqnT): Informs the subscriber that publishing has ended, either normally or with an error.
///
/// Every Publisher must adhere to this contract for downstream subscribers to function correctly.
///
/// Extensions on Publisher define a wide variety of operators that you compose to create sophisticated event-processing chains. Each operator returns a type that implements the Publisher protocol. Most of these types exist as extensions on the [Publishers](apple-reference-documentation://hsJaV7Ifc4) enumeration.
/// For example, the [map(_:)](apple-reference-documentation://hs5_y6Rfxo) operator returns an instance of [Publishers.Map](apple-reference-documentation://hsUrOVmShL).
///
/// Rather than implementing Publisher on your own, you can use one of several types provided by the Combine framework. For example, you can use an AnySubject instance and publish new elements imperatively with its send(_:) method.
/// You can also add the @Published annotation to any property to give it a publisher that returns an instance of Published, which emits an event every time the property’s value changes.
public protocol Publisher {

    /// The kind of values published by this publisher.
    associatedtype Output
    
    /// The kind of errors this publisher might publish.
    ///
    /// Use `Never` if this `Publisher` does not publish errors.
    associatedtype Failure: Error
    
    /// This function is called to attach the specified `Subscriber` to this `Publisher` by `subscribe(_:)`
    ///
    /// - SeeAlso: `subscribe(_:)`
    /// - Parameters:
    ///     - subscriber: The subscriber to attach to this `Publisher`.
    ///                   Once attached it can begin to receive values.
    func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure
}
