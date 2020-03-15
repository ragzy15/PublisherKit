//
//  Map KeyPath2.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

extension Publishers {
    
    /// A publisher that publishes the values of two key paths as a tuple.
    public struct MapKeyPath2<Upstream: Publisher, Output0, Output1>: Publisher {
        
        public typealias Output = (Output0, Output1)
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The key path of a property to publish.
        public let keyPath0: KeyPath<Upstream.Output, Output0>
        
        /// The key path of a second property to publish.
        public let keyPath1: KeyPath<Upstream.Output, Output1>
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, keyPath0: keyPath0, keyPath1: keyPath1))
        }
    }
}

extension Publishers.MapKeyPath2 {
    
    // MARK: MAPKEYPATH2 SINK
    private struct Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        let combineIdentifier: CombineIdentifier
        
        private var downstream: Downstream?
        
        private let keyPath0: KeyPath<Upstream.Output, Output0>
        private let keyPath1: KeyPath<Upstream.Output, Output1>
        
        init(downstream: Downstream, keyPath0: KeyPath<Upstream.Output, Output0>, keyPath1: KeyPath<Upstream.Output, Output1>) {
            self.downstream = downstream
            self.keyPath0 = keyPath0
            self.keyPath1 = keyPath1
            combineIdentifier = CombineIdentifier()
        }
        
        func receive(subscription: Subscription) {
            downstream?.receive(subscription: subscription)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            let output0 = input[keyPath: keyPath0]
            let output1 = input[keyPath: keyPath1]
            
            return downstream?.receive((output0, output1)) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
        }
        
        var description: String {
            "MapKeyPath2"
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
