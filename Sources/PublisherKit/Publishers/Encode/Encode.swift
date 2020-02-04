//
//  Encode.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/01/20.
//

import Foundation

public extension Publishers {
    
    /// A publisher that encodes elements received from an upstream publisher using the specified encoder.
    struct Encode<Upstream: Publisher, Encoder: PKEncoder>: Publisher where Upstream.Output: Encodable {
        
        public typealias Output = Encoder.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The encoder that encodes values received from the upstream publisher.
        private let encoder: Encoder
        
        public init(upstream: Upstream, encoder: Encoder) {
            self.upstream = upstream
            self.encoder = encoder
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let encodeSubscriber = InternalSink(downstream: subscriber, encoder: encoder)
            upstream.subscribe(encodeSubscriber)
        }
    }
}

extension Publishers.Encode {
    
    // MARK: ENCODE SINK
    private final class InternalSink<Downstream: Subscriber, Encoder: PKEncoder>: UpstreamOperatorSink<Downstream, Upstream> where Encoder.Output == Downstream.Input, Failure == Downstream.Failure, Upstream.Output: Encodable {
        
        private let encoder: Encoder
        
        init(downstream: Downstream, encoder: Encoder) {
            self.encoder = encoder
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            
            do {
                let output = try encoder.encode(input)
                _ = downstream?.receive(output)
                
            } catch {
                downstream?.receive(completion: .failure(error))
            }
            
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
    }
}
