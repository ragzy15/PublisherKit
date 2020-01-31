//
//  Try Catch.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher or producing a new error.
    public struct TryCatch<Upstream: PKPublisher, NewPublisher: PKPublisher>: PKPublisher where Upstream.Output == NewPublisher.Output {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public let handler: (Upstream.Failure) throws -> NewPublisher
        
        /// Creates a publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
        ///
        /// - Parameters:
        ///   - upstream: The publisher that this publisher receives elements from.
        ///   - handler: A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public init(upstream: Upstream, handler: @escaping (Upstream.Failure) throws -> NewPublisher) {
            self.upstream = upstream
            self.handler = handler
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryCatchSubscriber = InternalSink(downstream: subscriber, handler: handler)
            
            subscriber.receive(subscription: tryCatchSubscriber)
            tryCatchSubscriber.request(.unlimited)
            upstream.receive(subscriber: tryCatchSubscriber)
        }
    }
}

extension PKPublishers.TryCatch {
    
    // MARK: TRY CATCH SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let handler: (Upstream.Failure) throws -> NewPublisher
        
        private lazy var subscriber = PKSubscribers.FinalOperatorSink<Downstream, Upstream.Output, NewPublisher.Failure>(downstream: downstream!, receiveCompletion: { (completion, downstream) in
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
            
        }) { (input, downstream) in
            downstream?.receive(input: input)
        }
        
        init(downstream: Downstream, handler: @escaping (Upstream.Failure) throws -> NewPublisher) {
            self.handler = handler
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            downstream?.receive(input: input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            guard let error = completion.getError() else {
                downstream?.receive(completion: .finished)
                return
            }
            
            do {
                let newPublisher = try handler(error)
                
                downstream?.receive(subscription: subscriber)
                subscriber.request(demand)
                newPublisher.subscribe(subscriber)
                
            } catch let catchError {
                downstream?.receive(completion: .failure(catchError as Downstream.Failure))
            }
        }
    }
}
