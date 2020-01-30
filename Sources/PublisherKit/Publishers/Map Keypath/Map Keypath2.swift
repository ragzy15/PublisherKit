//
//  Map KeyPath2.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that publishes the values of two key paths as a tuple.
    public struct MapKeyPath2<Upstream: PKPublisher, Output0, Output1>: PKPublisher {
        
        public typealias Output = (Output0, Output1)
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        /// The key path of a property to publish.
        public let keyPath0: KeyPath<Upstream.Output, Output0>
        
        /// The key path of a second property to publish.
        public let keyPath1: KeyPath<Upstream.Output, Output1>
        
        public init(upstream: Upstream, keyPath0: KeyPath<Upstream.Output, Output0>, keyPath1: KeyPath<Upstream.Output, Output1>) {
            self.upstream = upstream
            self.keyPath0 = keyPath0
            self.keyPath1 = keyPath1
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mapKeypathSubscriber = InternalSink(downstream: subscriber, keyPath0: keyPath0, keyPath1: keyPath1)
            
            subscriber.receive(subscription: mapKeypathSubscriber)
            mapKeypathSubscriber.request(.unlimited)
            upstream.subscribe(mapKeypathSubscriber)
        }
    }
}

extension PKPublishers.MapKeyPath2 {
    
    // MARK: MAPKEYPATH2 SINK
    private final class InternalSink<Downstream: PKSubscriber>: UpstreamSinkable<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let keyPath0: KeyPath<Upstream.Output, Output0>
        private let keyPath1: KeyPath<Upstream.Output, Output1>
        
        init(downstream: Downstream, keyPath0: KeyPath<Upstream.Output, Output0>, keyPath1: KeyPath<Upstream.Output, Output1>) {
            self.keyPath0 = keyPath0
            self.keyPath1 = keyPath1
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            let output0 = input[keyPath: keyPath0]
            let output1 = input[keyPath: keyPath1]
            
            downstream?.receive(input: (output0, output1))
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
