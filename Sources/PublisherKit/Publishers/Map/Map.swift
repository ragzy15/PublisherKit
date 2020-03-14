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
        
        let newTransform: (Upstream.Output) -> T = { output in
            let newOutput = self.transform(output)
            return transform(newOutput)
        }
        
        return Publishers.Map<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> Publishers.TryMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T = { output in
            let newOutput = self.transform(output)
            return try transform(newOutput)
        }
        
        return Publishers.TryMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}

extension Publishers.Map {
    
    // MARK: MAP SINK
    private struct Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomReflectable where Downstream.Input == Output, Downstream.Failure == Upstream.Failure {
        
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

        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
