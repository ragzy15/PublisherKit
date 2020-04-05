//
//  Deferred.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 13/03/20.
//

/// A publisher that awaits subscription before running the supplied closure to create a publisher for the new subscriber.
public struct Deferred<DeferredPublisher: Publisher>: Publisher {
    
    public typealias Output = DeferredPublisher.Output
    
    public typealias Failure = DeferredPublisher.Failure
    
    /// The closure to execute when it receives a subscription.
    ///
    /// The publisher returned by this closure immediately receives the incoming subscription.
    public let createPublisher: () -> DeferredPublisher
    
    /// Creates a deferred publisher.
    ///
    /// - Parameter createPublisher: The closure to execute when calling `subscribe(_:)`.
    public init(createPublisher: @escaping () -> DeferredPublisher) {
        self.createPublisher = createPublisher
    }
    
    public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        
        let deferredPublisher = createPublisher()
        deferredPublisher.subscribe(subscriber)
    }
}
