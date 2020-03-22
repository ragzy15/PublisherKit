//
//  Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public extension Publishers {
    
    /// A publisher that transforms all elements received from an upstream publisher with a specified closure.
    struct Map<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) -> Output
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, transform: transform))
        }
    }
}

extension Publishers.Map {
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> Publishers.Map<Upstream, T> {
        Publishers.Map(upstream: upstream, transform: { transform(self.transform($0)) })
    }
    
    public func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> Publishers.TryMap<Upstream, T> {
        Publishers.TryMap(upstream: upstream, transform: { try transform(self.transform($0)) })
    }
}

extension Publishers.Map {
    
    // MARK: MAP SINK
    private struct Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Upstream.Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output

        typealias Failure = Upstream.Failure

        private var downstream: Downstream?

        private let transform: (Input) -> Output

        let combineIdentifier: CombineIdentifier

        fileprivate init(downstream: Downstream, transform: @escaping (Input) -> Output) {
            self.downstream = downstream
            self.transform = transform
            combineIdentifier = CombineIdentifier()
        }

        func receive(subscription: Subscription) {
            downstream?.receive(subscription: subscription)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            downstream?.receive(transform(input)) ?? .none
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
        }

        var description: String {
            "Map"
        }
        
        var playgroundDescription: Any {
            description
        }

        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
