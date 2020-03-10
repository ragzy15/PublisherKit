//
//  Ignore Output.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that ignores all upstream elements, but passes along a completion state (finish or failed).
    public struct IgnoreOutput<Upstream: Publisher>: Publisher {
        
        public typealias Output = Never
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let ignoreOutputSubscriber = Inner(downstream: subscriber)
            subscriber.receive(subscription: ignoreOutputSubscriber)
            upstream.subscribe(ignoreOutputSubscriber)
        }
    }
}

extension Publishers.IgnoreOutput: Equatable where Upstream: Equatable {
    
}

extension Publishers.IgnoreOutput {
    
    // MARK: IGNORE OUTPUT SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
       
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "IgnoreOutput"
        }
    }
}
