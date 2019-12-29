//
//  Any Publisher.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

/// A type-erasing publisher.
///
/// Use `AnyPublisher` to wrap a publisher whose type has details you don’t want to expose to subscribers or other publishers.
public struct NKAnyPublisher<Output, Failure: Error>: NKPublisher {
    
    @usableFromInline let subscriberBlock: ((NKAnySubscriber<Output, Failure>) -> Void)?
    
    /// Creates a type-erasing publisher to wrap the provided publisher.
    ///
    /// - Parameters:
    ///   - publisher: A publisher to wrap with a type-eraser.
    @inlinable public init<P: NKPublisher>(_ publisher: P) where Output == P.Output, Failure == P.Failure {
        
        subscriberBlock = { (subscriber) in
            publisher.subscribe(subscriber)
        }
    }
    
    @inlinable public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        let anySubscriber = NKAnySubscriber<Output, Failure>(subscriber)
        subscriberBlock?(anySubscriber)
    }
}
