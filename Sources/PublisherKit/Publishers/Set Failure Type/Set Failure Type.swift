//
//  Set Failure Type.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

import Foundation

extension Publishers {
    
    /// A publisher that appears to send a specified failure type.
    ///
    /// The publisher cannot actually fail with the specified type and instead just finishes normally. Use this publisher type when you need to match the error types for two mismatched publishers.
    public struct SetFailureType<Upstream: Publisher, Failure: Error>: Publisher where Upstream.Failure == Never {
        
        public typealias Output = Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// Creates a publisher that appears to send a specified failure type.
        ///
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let failureTypeSubscriber = InternalSink(downstream: subscriber)
            upstream.subscribe(failureTypeSubscriber)
        }
        
        public func setFailureType<E: Error>(to failure: E.Type) -> Publishers.SetFailureType<Upstream, E> {
            Publishers.SetFailureType<Upstream, E>(upstream: upstream)
        }
    }
}

extension Publishers.SetFailureType {
    
    // MARK: SET FAILURE TYPE SINK
    private final class InternalSink<Downstream: Subscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isOver else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Never>) {
            guard !isOver else { return }
            end()
            downstream?.receive(completion: .finished)
        }
    }
}
