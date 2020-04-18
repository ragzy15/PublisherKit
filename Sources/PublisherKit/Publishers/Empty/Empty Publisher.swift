//
//  Empty Publisher.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

public struct Empty<Output, Failure: Error>: Publisher, Equatable {
    
    /// A Boolean value that indicates whether the publisher immediately sends a completion.
    ///
    /// If `true`, the publisher finishes immediately after sending a subscription to the subscriber. If `false`, it never completes.
    public let completeImmediately: Bool
    
    /// Creates an empty publisher.
    ///
    /// - Parameter completeImmediately: A Boolean value that indicates whether the publisher should immediately finish.
    public init(completeImmediately: Bool = true) {
        self.completeImmediately = completeImmediately
    }
    
    /// Creates an empty publisher with the given completion behavior and output and failure types.
    ///
    /// Use this initializer to connect the empty publisher to subscribers or other publishers that have specific output and failure types.
    /// - Parameters:
    ///   - completeImmediately: A Boolean value that indicates whether the publisher should immediately finish.
    ///   - outputType: The output type exposed by this publisher.
    ///   - failureType: The failure type exposed by this publisher.
    public init(completeImmediately: Bool = true, outputType: Output.Type, failureType: Failure.Type) {
        self.completeImmediately = completeImmediately
    }
    
    public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        subscriber.receive(subscription: Subscriptions.empty)
        
        if completeImmediately {
            subscriber.receive(completion: .finished)
        }
    }
}
