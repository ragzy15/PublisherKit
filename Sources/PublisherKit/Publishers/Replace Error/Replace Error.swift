//
//  Replace Error.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    /// A publisher that replaces any errors in the stream with a provided element.
    struct ReplaceError<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Never
        
        /// The element with which to replace errors from the upstream publisher.
        public let output: Upstream.Output
        
        public let upstream: Upstream
        
        public init(upstream: Upstream, output: Output) {
            self.upstream = upstream
            self.output = output
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let replaceErrorSubscriber = InternalSink(downstream: subscriber)
            
            replaceErrorSubscriber.onError = { (downstream) in
                downstream?.receive(input: self.output)
            }
            
            subscriber.receive(subscription: replaceErrorSubscriber)
            replaceErrorSubscriber.request(.unlimited)
            upstream.subscribe(replaceErrorSubscriber)
        }
    }
}

extension PKPublishers.ReplaceError {
    
    // MARK: REPLACE ERROR SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        var onError: ((Downstream?) -> Void)?
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            downstream?.receive(input: input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            if let error = completion.getError() {
                Logger.default.log(error: error)
                onError?(downstream)
            }
            
            downstream?.receive(completion: .finished)
        }
    }
}
