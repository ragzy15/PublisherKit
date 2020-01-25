//
//  Any Publisher.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "AnyPKPublisher")
public typealias NKAnyPublisher = AnyPKPublisher

/// A type-erasing publisher.
///
/// Use `AnyPKPublisher` to wrap a publisher whose type has details you don’t want to expose to subscribers or other publishers.
public struct AnyPKPublisher<Output, Failure: Error>: PKPublisher {
    
    @usableFromInline let subscriberBlock: ((AnyPKSubscriber<Output, Failure>) -> Void)?
    
    /// Creates a type-erasing publisher to wrap the provided publisher.
    ///
    /// - Parameters:
    ///   - publisher: A publisher to wrap with a type-eraser.
    @inlinable public init<P: PKPublisher>(_ publisher: P) where Output == P.Output, Failure == P.Failure {
        
        subscriberBlock = { (subscriber) in
            publisher.subscribe(subscriber)
        }
    }
    
    @inlinable public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        let anySubscriber = AnyPKSubscriber<Output, Failure>(subscriber)
        subscriberBlock?(anySubscriber)
    }
}
