//
//  Map Error.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public extension Publishers {
    
    /// A publisher that converts the failure from the upstream publisher into a new failure.
    struct MapError<Upstream: Publisher, Failure: Error>: Publisher {
        
        public typealias Output = Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Failure) -> Failure
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Failure) -> Failure) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, transform: transform))
        }
    }
}

extension Publishers.MapError {
    
    // MARK: MAPERROR SINK
    private struct Inner<Downstream: Subscriber, NewFailure>: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, NewFailure == Downstream.Failure {
        
        typealias Input = Upstream.Output

        typealias Failure = Upstream.Failure

        private var downstream: Downstream?
        
        private let transform: (Failure) -> NewFailure

        let combineIdentifier: CombineIdentifier

        fileprivate init(downstream: Downstream, transform: @escaping (Failure) -> NewFailure) {
            self.downstream = downstream
            self.transform = transform
            combineIdentifier = CombineIdentifier()
        }

        func receive(subscription: Subscription) {
            downstream?.receive(subscription: subscription)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            downstream?.receive(input) ?? .none
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion.mapError(transform))
        }

        var description: String {
            "MapError"
        }
        
        var playgroundDescription: Any {
            description
        }

        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
