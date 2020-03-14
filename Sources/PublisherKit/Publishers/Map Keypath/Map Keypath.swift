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
        
        public init(upstream: Upstream, keyPath: KeyPath<Upstream.Output, Output>) {
            self.upstream = upstream
            self.keyPath = keyPath
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mapKeypathSubscriber = Inner(downstream: subscriber, keyPath: keyPath)
            upstream.subscribe(mapKeypathSubscriber)
        }
    }
}

extension Publishers.MapKeyPath {
    
    // MARK: MAPKEYPATH SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let keyPath: KeyPath<Upstream.Output, Output>
        
        init(downstream: Downstream, keyPath: KeyPath<Upstream.Output, Output>) {
            self.keyPath = keyPath
            super.init(downstream: downstream)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            .success(input[keyPath: keyPath])
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            switch status {
            case .subscribed(let subscription):
                return "\(subscription)"
                
            default:
                return "MapKeyPath"
            }
        }
    }
}
