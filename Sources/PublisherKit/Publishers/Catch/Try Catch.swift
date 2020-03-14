//
//  Try Catch.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

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
            subscriber.receive(subscription: tryCatchSubscriber)
            upstream.receive(subscriber: tryCatchSubscriber)
        }
    }
}

extension Publishers.TryCatch {
    
    // MARK: TRY CATCH SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Upstream.Failure) throws -> NewPublisher> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func operate(on input: Upstream.Output) -> Result<Output, Downstream.Failure>? {
            .success(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            
            guard let error = completion.getError() else {
                downstream?.receive(completion: .finished)
                return
            }
            
            do {
                let newPublisher = try operation(error)
                
                let subscriber = CatchInner(downstream: downstream)
                newPublisher.subscribe(subscriber)
                
            } catch let catchError {
                downstream?.receive(completion: .failure(catchError as Downstream.Failure))
            }
        }
        
        override var description: String {
            "TryCatch"
        }
        
        private final class CatchInner: Subscriber {
            
            private var subscription: Subscription?
            
            private var downstream: Downstream?
            
            init(downstream: Downstream?) {
                self.downstream = downstream
            }
            
            final func receive(subscription: Subscription) {
                self.subscription = subscription
                subscription.request(.unlimited)
            }
            
            final func receive(_ input: Upstream.Output) -> Subscribers.Demand {
                downstream?.receive(input) ?? .none
            }
            
            final func receive(completion: Subscribers.Completion<NewPublisher.Failure>) {
                let newCompletion = completion.mapError { $0 as Downstream.Failure }
                downstream?.receive(completion: newCompletion)
                
                subscription = nil
                downstream = nil
            }
        }
    }
}
