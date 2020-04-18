//
//  Fail.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 13/03/20.
//

/// A publisher that immediately terminates with the specified error.
public struct Fail<Output, Failure: Error>: Publisher {
    
    /// The failure to send when terminating the publisher.
    public let error: Failure
    
    /// Creates a publisher that immediately terminates with the specified failure.
    ///
    /// - Parameter error: The failure to send when terminating the publisher.
    public init(error: Failure) {
        self.error = error
    }
    
    /// Creates publisher with the given output type, that immediately terminates with the specified failure.
    ///
    /// Use this initializer to create a `Fail` publisher that can work with subscribers or publishers that expect a given output type.
    /// - Parameters:
    ///   - outputType: The output type exposed by this publisher.
    ///   - failure: The failure to send when terminating the publisher.
    public init(outputType: Output.Type, failure: Failure) {
        self.error = failure
    }
    
    public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        subscriber.receive(subscription: Subscriptions.empty)
        subscriber.receive(completion: .failure(error))
    }
}

extension Fail: Equatable where Failure: Equatable { }
