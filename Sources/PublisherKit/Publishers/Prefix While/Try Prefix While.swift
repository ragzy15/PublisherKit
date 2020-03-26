//
//  Try Prefix While.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Publishers {
    
    /// A publisher that republishes elements while an error-throwing predicate closure indicates publishing should continue.
    public struct TryPrefixWhile<Upstream> : Publisher where Upstream : Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The error-throwing closure that determines whether publishing should continue.
        public let predicate: (Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Output) throws -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryPrefixWhileSubscription = Inner(downstream: subscriber, operation: predicate)
            
//            subscriber.receive(subscription: tryPrefixWhileSubscription)
            upstream.subscribe(tryPrefixWhileSubscription)
        }
    }
}

extension Publishers.TryPrefixWhile {
    
    // MARK: TRY PREFIX WHILE SINK
    private final class Inner<Downstream: Subscriber>: FilterProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Output) throws -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Input) -> CompletionResult<Output, Downstream.Failure>? {
            do {
                return try operation(input) ? .send(input) : .finished
            } catch {
                return .failure(error)
            }
        }
        
        override var description: String {
            "TryPrefixWhile"
        }
    }
}
