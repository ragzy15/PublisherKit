//
//  Map KeyPath.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public extension Publishers {
    
    /// A publisher that publishes the value of a key path.
    struct MapKeyPath<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The key path of a property to publish.
        public let keyPath: KeyPath<Upstream.Output, Output>
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, keyPath: keyPath))
        }
    }
}

extension Publishers.MapKeyPath {
    
    // MARK: MAPKEYPATH SINK
    private struct Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        let combineIdentifier: CombineIdentifier
        
        private var downstream: Downstream?
        
        private let keyPath: KeyPath<Upstream.Output, Output>
        
        init(downstream: Downstream, keyPath: KeyPath<Upstream.Output, Output>) {
            self.downstream = downstream
            self.keyPath = keyPath
            combineIdentifier = CombineIdentifier()
        }
        
        func receive(subscription: Subscription) {
            downstream?.receive(subscription: subscription)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            downstream?.receive(input[keyPath: keyPath]) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
        }
        
        var description: String {
            "MapKeyPath"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
