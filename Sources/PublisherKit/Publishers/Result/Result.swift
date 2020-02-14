//
//  Result.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Result {
    
    public var pkPublisher: PKPublisher {
        PKPublisher(self)
    }
}

extension Result {
    
    /// A publisher that publishes an output to each subscriber exactly once then finishes, or fails immediately without producing any elements.
    ///
    /// If `result` is `.success`, then `Once` waits until it receives a request for at least 1 value before sending the output. If `result` is `.failure`, then `Once` sends the failure immediately upon subscription.
    ///
    /// In contrast with `Just`, a `Once` publisher can terminate with an error instead of sending a value.
    /// In contrast with `Optional`, a `Once` publisher always sends one value (unless it terminates with an error).
    public struct PKPublisher: PublisherKit.Publisher {
        
        public typealias Output = Success
        
        /// The result to deliver to each subscriber.
        public let result: Result<Success, Failure>
        
        /// Creates a publisher that delivers the specified result.
        ///
        /// If the result is `.success`, the `Once` publisher sends the specified output to all subscribers and finishes normally. If the result is `.failure`, then the publisher fails immediately with the specified error.
        /// - Parameter result: The result to deliver to each subscriber.
        public init(_ result: Result<Output, Failure>) {
            self.result = result
        }
        
        /// Creates a publisher that sends the specified output to all subscribers and finishes normally.
        ///
        /// - Parameter output: The output to deliver to each subscriber.
        public init(_ output: Output) {
            result = .success(output)
        }
        
        /// Creates a publisher that immediately terminates upon subscription with the given failure.
        ///
        /// - Parameter failure: The failure to send when terminating.
        public init(_ failure: Failure) {
            result = .failure(failure)
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let resultSubscriber = Inner(downstream: subscriber)
            
            subscriber.receive(subscription: resultSubscriber)
            resultSubscriber.request(.max(1))
            
            switch result {
            case .success(let output):
                resultSubscriber.receive(input: output)
                resultSubscriber.receive(completion: .finished)
                
            case .failure(let error):
                resultSubscriber.receive(completion: .failure(error))
            }
        }
    }
}

extension Result.PKPublisher {
    
    // MARK: RESULT SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.Internal<Downstream, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override var description: String {
            "Result"
        }
    }
}
