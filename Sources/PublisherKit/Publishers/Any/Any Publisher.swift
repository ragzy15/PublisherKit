//
//  Any Publisher.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

@available(*, deprecated, renamed: "AnyPublisher")
public typealias NKAnyPublisher = AnyPublisher

@available(*, deprecated, renamed: "AnyPublisher")
public typealias PKAnyPublisher = AnyPublisher

@available(*, deprecated, renamed: "AnyPublisher")
public typealias AnyPKPublisher = AnyPublisher

/// A type-erasing publisher.
///
/// Use `AnyPublisher` to wrap a publisher whose type has details you don’t want to expose to subscribers or other publishers.
public struct AnyPublisher<Output, Failure: Error>: Publisher {
    
    @usableFromInline let subscriberBlock: ((AnySubscriber<Output, Failure>) -> Void)?
    
    /// Creates a type-erasing publisher to wrap the provided publisher.
    ///
    /// - Parameters:
    ///   - publisher: A publisher to wrap with a type-eraser.
    @inlinable public init<P: Publisher>(_ publisher: P) where Output == P.Output, Failure == P.Failure {
        subscriberBlock = { (subscriber) in
            publisher.subscribe(subscriber)
        }
    }
    
    @inlinable public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        let anySubscriber = AnySubscriber<Output, Failure>(subscriber)
        subscriberBlock?(anySubscriber)
    }
}
