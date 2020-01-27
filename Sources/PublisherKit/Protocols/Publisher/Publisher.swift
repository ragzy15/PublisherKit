//
//  Publisher.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "PKPublisher")
public typealias NKPublisher = PKPublisher

public protocol PKPublisher {

    /// The kind of values published by this publisher.
    associatedtype Output
    
    /// The kind of errors this publisher might publish.
    ///
    /// Use `Never` if this `PKPublisher` does not publish errors.
    associatedtype Failure: Error
    
    /// This function is called to attach the specified `PKSubscriber` to this `PKPublisher` by `subscribe(_:)`
    ///
    /// - SeeAlso: `subscribe(_:)`
    /// - Parameters:
    ///     - subscriber: The subscriber to attach to this `PKPublisher`.
    ///                   Once attached it can begin to receive values.
    func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure
}
