//
//  Map KeyPath3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

extension Publishers {
    
    /// A publisher that publishes the values of three key paths as a tuple.
    public struct MapKeyPath3<Upstream: Publisher, Output0, Output1, Output2>: Publisher {
        
        public typealias Output = (Output0, Output1, Output2)
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The key path of a property to publish.
        public let keyPath0: KeyPath<Upstream.Output, Output0>
        
        /// The key path of a second property to publish.
        public let keyPath1: KeyPath<Upstream.Output, Output1>
        
        /// The key path of a third property to publish.
        public let keyPath2: KeyPath<Upstream.Output, Output2>
        
        public init(upstream: Upstream, keyPath0: KeyPath<Upstream.Output, Output0>, keyPath1: KeyPath<Upstream.Output, Output1>, keyPath2: KeyPath<Upstream.Output, Output2>) {
            self.upstream = upstream
            self.keyPath0 = keyPath0
            self.keyPath1 = keyPath1
            self.keyPath2 = keyPath2
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mapKeypathSubscriber = Inner(downstream: subscriber, keyPath0: keyPath0, keyPath1: keyPath1, keyPath2: keyPath2)
            subscriber.receive(subscription: mapKeypathSubscriber)
            upstream.subscribe(mapKeypathSubscriber)
        }
    }
}

extension Publishers.MapKeyPath3 {
    
    // MARK: MAPKEYPATH3 SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let keyPath0: KeyPath<Upstream.Output, Output0>
        private let keyPath1: KeyPath<Upstream.Output, Output1>
        private let keyPath2: KeyPath<Upstream.Output, Output2>
        
        init(downstream: Downstream, keyPath0: KeyPath<Upstream.Output, Output0>, keyPath1: KeyPath<Upstream.Output, Output1>, keyPath2: KeyPath<Upstream.Output, Output2>) {
            self.keyPath0 = keyPath0
            self.keyPath1 = keyPath1
            self.keyPath2 = keyPath2
            super.init(downstream: downstream)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            let output0 = input[keyPath: keyPath0]
            let output1 = input[keyPath: keyPath1]
            let output2 = input[keyPath: keyPath2]
                
            return .success((output0, output1, output2))
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            switch status {
            case .subscribed(let subscription):
                return "\(subscription)"
                
            default:
                return "MapKeyPath3"
            }
        }
    }
}
