//
//  Subject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 02/02/20.
//

import Foundation

/// A publisher that exposes a method for outside callers to publish elements.
///
/// A subject is a publisher that you can use to ”inject” values into a stream, by calling its [send()](apple-reference-documentation://hsyr-564TS) method. This can be useful for adapting existing imperative code to the Combine model.
public protocol Subject: class, Publisher {
    
    /// Sends a value to the subscriber.
    ///
    /// - Parameter value: The value to send.
    func send(_ value: Output)
    
    /// Sends a completion signal to the subscriber.
    ///
    /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
    func send(completion: Subscribers.Completion<Failure>)
    
    /// Sends a subscription to the subscriber.
    ///
    /// Provides this Subject an opportunity to establish demand for any new upstream subscriptions (say via, `Publisher.subscribe<S: Subject>(_: Subject)`
    ///
    /// This call provides the Subject an opportunity to establish demand for any new upstream subscriptions.
    /// - Parameter subscription: The subscription instance through which the subscriber can request elements.
    func send(subscription: Subscription)
}

extension Subject where Output == Void {
    
    /// Sends a void value to the subscriber.
    ///
    /// Use Void inputs and outputs when you want to signal that an event has occurred, but don’t need to send the event itself.
    public func send() {
        send(())
    }
}
