//
//  Drop While.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Publishers {
    
    /// A publisher that omits elements from an upstream publisher until a given closure returns false.
    public struct DropWhile<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that indicates whether to drop the element.
        public let predicate: (Output) -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dropWhileSubscription = Inner(downstream: subscriber, operation: predicate)
            
            subscriber.receive(subscription: dropWhileSubscription)
            upstream.subscribe(dropWhileSubscription)
        }
    }
}

extension Publishers.DropWhile {
    
    // MARK: DROP WHILE SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Output) -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func operate(on input: Upstream.Output) -> Result<Output, Failure>? {
            
            if operation(input) {
                return nil
            } else {
                return .success(input)
            }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "DropWhile"
        }
    }
}
