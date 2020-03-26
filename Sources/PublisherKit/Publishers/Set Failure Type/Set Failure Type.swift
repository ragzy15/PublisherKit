//
//  Set Failure Type.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

extension Publishers {
    
    /// A publisher that appears to send a specified failure type.
    ///
    /// The publisher cannot actually fail with the specified type and instead just finishes normally. Use this publisher type when you need to match the error types for two mismatched publishers.
    public struct SetFailureType<Upstream: Publisher, Failure: Error>: Publisher where Upstream.Failure == Never {
        
        public typealias Output = Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// Creates a publisher that appears to send a specified failure type.
        ///
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber))
        }
        
        public func setFailureType<E: Error>(to failure: E.Type) -> Publishers.SetFailureType<Upstream, E> {
            Publishers.SetFailureType<Upstream, E>(upstream: upstream)
        }
    }
}

extension Publishers.SetFailureType: Equatable where Upstream: Equatable { }

extension Publishers.SetFailureType {
    
    // MARK: SET FAILURE TYPE SINK
    private struct Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let downstream: Downstream
        let combineIdentifier: CombineIdentifier
        
        init(downstream: Downstream) {
            self.downstream = downstream
            combineIdentifier = CombineIdentifier()
        }
        
        func receive(subscription: Subscription) {
            downstream.receive(subscription: subscription)
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            downstream.receive(input)
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            downstream.receive(completion: .finished)
        }
        
        var description: String {
            "SetFailureType"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
