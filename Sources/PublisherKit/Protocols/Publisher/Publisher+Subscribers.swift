//
//  Publisher+Subscribers.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

// MARK: SUBSCRIBER
extension Publisher {
    
    /// Attaches the specified subscriber to this publisher.
    ///
    /// Always call this function instead of `receive(subscriber:)`.
    /// Adopters of `Publisher` must implement `receive(subscriber:)`. The implementation of `subscribe(_:)` in this extension calls through to `receive(subscriber:)`.
    /// - SeeAlso: `receive(subscriber:)`
    /// - Parameters:
    ///     - subscriber: The subscriber to attach to this `Publisher`. After attaching, the subscriber can start to receive values.
    public func subscribe<S: Subscriber>(_ subscriber: S) where Output == S.Input, Failure == S.Failure {
        receive(subscriber: subscriber)
    }
}

// MARK: SUBJECT
extension Publisher {
    
    /// Attaches the specified subject to this publisher.
    /// - Parameter subject: The subject to attach to this publisher.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func subscribe<S: Subject>(_ subject: S) -> AnyCancellable where Output == S.Output, Failure == S.Failure {
        let subscriber = SubjectSubscriber(subject: subject)
        subscribe(subscriber)
        return AnyCancellable(subscriber)
    }
}

// MARK: COMPLETION
extension Publisher {
    
    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// - parameter block: The closure to execute on completion.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func completion(_ block: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
        
        let subscriber = Subscribers.OnCompletion(receiveCompletion: block)
        subscribe(subscriber)
        return AnyCancellable(subscriber)
    }
}

// MARK: SINK
extension Publisher {

    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// - parameter receiveComplete: The closure to execute on completion.
    /// - parameter receiveValue: The closure to execute on receipt of a value.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func sink(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void), receiveValue: @escaping ((Output) -> Void)) -> AnyCancellable {
        
        let sink = Subscribers.Sink<Output, Failure>(receiveCompletion: { (completion) in
            receiveCompletion(completion)
        }) { (output) in
            receiveValue(output)
        }
        
        subscribe(sink)
        return AnyCancellable(sink)
    }
}

extension Publisher where Failure == Never {

    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// - parameter receiveValue: The closure to execute on receipt of a value.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func sink(receiveValue: @escaping ((Output) -> Void)) -> AnyCancellable {
        
        let sink = Subscribers.Sink<Output, Failure>(receiveCompletion: { (_) in
            
        }) { (output) in
            receiveValue(output)
        }
        
        subscribe(sink)
        return AnyCancellable(sink)
    }
    
    // MARK: ASSIGN
    
    /// Assigns each element from a Publisher to a property on an object.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property to assign.
    ///   - object: The object on which to assign the value.
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> AnyCancellable {
        
        let subscriber = Subscribers.Assign(object: object, keyPath: keyPath)
        subscribe(subscriber)
        return AnyCancellable(subscriber)
    }
}
