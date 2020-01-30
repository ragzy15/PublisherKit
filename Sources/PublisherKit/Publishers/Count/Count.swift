//
//  Count.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that publishes the number of elements received from the upstream publisher.
    public struct Count<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Int
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let countSubscriber = InternalSink(downstream: subscriber)
            
            subscriber.receive(subscription: countSubscriber)
            countSubscriber.request(.unlimited)
            upstream.subscribe(countSubscriber)
        }
    }
}

extension PKPublishers.Count {
    
    // MARK: COUNT SINK
    private final class InternalSink<Downstream: PKSubscriber>: PKSubscribers.Sinkable<Downstream, Upstream.Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var counter = 0
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            counter += 1
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            switch completion {
            case .finished:
                downstream?.receive(input: counter)
                downstream?.receive(completion: .finished)
                
            case .failure(let error):
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
