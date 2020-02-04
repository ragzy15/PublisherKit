//
//  Count.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher that publishes the number of elements received from the upstream publisher.
    /// It publishes the value when upstream publisher has finished.
    public struct Count<Upstream: Publisher>: Publisher {
        
        public typealias Output = Int
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let countSubscriber = InternalSink(downstream: subscriber)
            upstream.subscribe(countSubscriber)
        }
    }
}

extension Publishers.Count {
    
    // MARK: COUNT SINK
    private final class InternalSink<Downstream: Subscriber>: Subscribers.OperatorSink<Downstream, Upstream.Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var counter = 0
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            counter += 1
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            switch completion {
            case .finished:
                _ = downstream?.receive(counter)
                downstream?.receive(completion: .finished)
                
            case .failure(let error):
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
