//
//  Try Catch.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

extension Publishers {
    
    /// A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher or producing a new error.
    public struct TryCatch<Upstream: Publisher, NewPublisher: Publisher>: Publisher where Upstream.Output == NewPublisher.Output {
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryCatchSubscriber = Inner(downstream: subscriber, operation: handler)
            upstream.receive(subscriber: tryCatchSubscriber)
        }
    }
}

extension Publishers.TryCatch {
    
    // MARK: TRY CATCH SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Upstream.Failure) throws -> NewPublisher> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private lazy var subscriber = Subscribers.InternalClosure<Downstream, Upstream.Output, NewPublisher.Failure>(downstream: downstream!, receiveCompletion: { (completion, downstream) in
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
            
        }) { (input, downstream) in
            _ = downstream?.receive(input)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            .success(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            
            guard let error = completion.getError() else {
                downstream?.receive(completion: .finished)
                return
            }
            
            do {
                let newPublisher = try operation(error)
                
                downstream?.receive(subscription: subscriber)
                newPublisher.subscribe(subscriber)
                
            } catch let catchError {
                downstream?.receive(completion: .failure(catchError as Downstream.Failure))
            }
        }
        
        override var description: String {
            "TryCatch"
        }
    }
}
