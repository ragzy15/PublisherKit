//
//  Subscriber.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

/// A protocol that declares a type that can receive input from a publisher.
///
/// A Subscriber instance receives a stream of elements from a [Publisher](apple-reference-documentation://hsja-BzNqj), along with life cycle events describing changes to their relationship.
/// A given subscriber’s [Input](apple-reference-documentation://hsrmq8c2MQ) and [Failure](apple-reference-documentation://hsWS513Txq) associated types must match the [Output](apple-reference-documentation://hsnFtAIKuJ) and [Failure](apple-reference-documentation://hsWsJXxFs5) of its corresponding publisher.
///
/// You connect a subscriber to a publisher by calling the publisher’s [subscribe(_:)](apple-reference-documentation://hsPm07iUKW) method. After making this call, the publisher invokes the subscriber’s [receive(subscription:)](apple-reference-documentation://hsnet3EtNw) method.
/// This gives the subscriber a [Subscription](apple-reference-documentation://hsuduLjqdO) instance, which it uses to demand elements from the publisher, and to optionally cancel the subscription.
/// After the subscriber makes an initial demand, the publisher calls [receive(_:)](apple-reference-documentation://hse2ogRhvE), possibly asynchronously, to deliver newly-published elements.
/// If the publisher stops publishing, it calls [receive(completion:)](apple-reference-documentation://hsR1HQfqnT), using a parameter of type [Subscribers.Completion](apple-reference-documentation://hs0a1r610i) to indicate whether publishing completes normally or with an error.
///
/// Combine provides the following subscribers as operators on the [Publisher](apple-reference-documentation://hsja-BzNqj) type:
///
/// * [sink(receiveCompletion:receiveValue:)](https://developer.apple.com/documentation/combine/publisher/3343978-sink) executes arbitrary closures when it receives a completion signal and each time it receives a new element.
///
/// * [assign(to:on:)](apple-reference-documentation://hsCl4f6B8r) writes each newly-received value to a property identified by a key path on a given instance.
public protocol Subscriber: CustomCombineIdentifierConvertible {
    
    /// The kind of values this subscriber receives.
    associatedtype Input
    
    /// The kind of errors this subscriber might receive.
    ///
    /// Use `Never` if this `Subscriber` cannot receive errors.
    associatedtype Failure : Error
    
    /// Tells the subscriber that it has successfully subscribed to the publisher and may request items.
    ///
    /// Use the received [Subscription](apple-reference-documentation://hsuduLjqdO) to request items from the publisher.
    /// - Parameter subscription: A subscription that represents the connection between publisher and subscriber.
    func receive(subscription: Subscription)
    
    /// Tells the subscriber that the publisher has produced an element.
    ///
    /// - Parameter input: The published element.
    /// - Returns: A [Subscribers.Demand](https://developer.apple.com/documentation/combine/subscribers/demand) instance indicating how many more elements the subcriber expects to receive.
    func receive(_ input: Input) -> Subscribers.Demand
    
    /// Tells the subscriber that the publisher has completed publishing, either normally or with an error.
    ///
    /// - Parameter completion: A [Subscribers.Completion](apple-reference-documentation://hs0a1r610i) case indicating whether publishing completed normally or with an error.
    func receive(completion: Subscribers.Completion<Failure>)
}

extension Subscriber where Input == Void {
    
    /// Tells the subscriber that a publisher of void elements is ready to receive further requests.
    ///
    /// Use Void inputs and outputs when you want to signal that an event has occurred, but don’t need to send the event itself.
    /// - Returns: A [Subscribers.Demand](https://developer.apple.com/documentation/combine/subscribers/demand) instance indicating how many more elements the subscriber expects to receive.
    public func receive() -> Subscribers.Demand {
        receive(())
    }
}
