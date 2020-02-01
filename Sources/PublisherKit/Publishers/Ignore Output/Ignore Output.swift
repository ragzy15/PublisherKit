//
//  Ignore Output.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that ignores all upstream elements, but passes along a completion state (finish or failed).
    public struct IgnoreOutput<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Never
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let ignoreOutputSubscriber = InternalSink(downstream: subscriber)
            upstream.subscribe(ignoreOutputSubscriber)
        }
    }
}

extension PKPublishers.IgnoreOutput {
    
    // MARK: IGNORE OUTPUT SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
