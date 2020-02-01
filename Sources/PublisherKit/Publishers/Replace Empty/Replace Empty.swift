//
//  Replace Empty.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that replaces an empty stream with a provided element.
    struct ReplaceEmpty<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The element to deliver when the upstream publisher finishes without delivering any elements.
        public let output: Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream, output: Output) {
            self.upstream = upstream
            self.output = output
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let replaceEmptySubscriber = InternalSink(downstream: subscriber)
            
            replaceEmptySubscriber.onFinish = { (downstream) in
                _ = downstream?.receive(self.output)
            }
            
            upstream.subscribe(replaceEmptySubscriber)
        }
    }
}

extension PKPublishers.ReplaceEmpty {
    
    // MARK: REPLACE EMPTY SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var inputReceived = false
        var onFinish: ((Downstream?) -> Void)?
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            inputReceived = true
            _ = downstream?.receive(input)
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            if let error = completion.getError() {
                downstream?.receive(completion: .failure(error))
                return
            }
            
            if !inputReceived {
                onFinish?(downstream)
            }
            downstream?.receive(completion: .finished)
        }
    }
}
