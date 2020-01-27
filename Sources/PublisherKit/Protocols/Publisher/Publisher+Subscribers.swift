//
//  Publisher+Subscribers.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

// MARK: SUBSCRIBE
extension PKPublisher {
    
    /// Attaches the specified subscriber to this publisher.
    ///
    /// Always call this function instead of `receive(subscriber:)`.
    /// Adopters of `PKPublisher` must implement `receive(subscriber:)`. The implementation of `subscribe(_:)` in this extension calls through to `receive(subscriber:)`.
    /// - SeeAlso: `receive(subscriber:)`
    /// - Parameters:
    ///     - subscriber: The subscriber to attach to this `PKPublisher`. After attaching, the subscriber can start to receive values.
    public func subscribe<S: PKSubscriber>(_ subscriber: S) where Failure == S.Failure, Output == S.Input {
        receive(subscriber: subscriber)
    }
}

// MARK: COMPLETION
extension PKPublisher {
    
    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// - parameter block: The closure to execute on completion.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func completion(_ block: @escaping (Result<Output, Failure>) -> Void) -> PKAnyCancellable {
        
        let subscriber = PKSubscribers.OnCompletion(receiveCompletion: block)
        subscribe(subscriber)
        return PKAnyCancellable(subscriber)
    }
}

// MARK: SINK
extension PKPublisher {

    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// - parameter receiveComplete: The closure to execute on completion.
    /// - parameter receiveValue: The closure to execute on receipt of a value.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func sink(receiveCompletion: @escaping ((PKSubscribers.Completion<Failure>) -> Void), receiveValue: @escaping ((Output) -> Void)) -> PKAnyCancellable {
        
        let sink = PKSubscribers.Sink<Output, Failure>(receiveCompletion: { (completion) in
            receiveCompletion(completion)
        }) { (output) in
            receiveValue(output)
        }
        
        subscribe(sink)
        return PKAnyCancellable(sink)
    }
}

extension PKPublisher where Failure == Never {

    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// - parameter receiveValue: The closure to execute on receipt of a value.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func sink(receiveValue: @escaping ((Output) -> Void)) -> PKAnyCancellable {
        
        let sink = PKSubscribers.Sink<Output, Failure>(receiveCompletion: { (_) in
            
        }) { (output) in
            receiveValue(output)
        }
        
        subscribe(sink)
        return PKAnyCancellable(sink)
    }
    
    // MARK: ASSIGN
    
    /// Assigns each element from a Publisher to a property on an object.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property to assign.
    ///   - object: The object on which to assign the value.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> PKAnyCancellable {
        
        let subscriber = PKSubscribers.Assign(object: object, keyPath: keyPath)
        subscribe(subscriber)
        return PKAnyCancellable(subscriber)
    }
}
