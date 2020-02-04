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
