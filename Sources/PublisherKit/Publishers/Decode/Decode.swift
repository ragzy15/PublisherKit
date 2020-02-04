//
//  Decode.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension Publishers {
    
    /// A publisher that decodes elements received from an upstream publisher into the specified type.
    struct Decode<Upstream: Publisher, Output: Decodable, Decoder: PKDecoder>: Publisher where Upstream.Output == Decoder.Input {
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The decoder used for decoding the elements received from the upstream publisher.
        private let decoder: Decoder
        
        public init(upstream: Upstream, decoder: Decoder) {
            self.upstream = upstream
            self.decoder = decoder
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let decodeSubscriber = InternalSink(downstream: subscriber, decoder: decoder)
            upstream.subscribe(decodeSubscriber)
        }
    }
}

extension Publishers.Decode {
    
    // MARK: DECODE SINK
    private final class InternalSink<Downstream: Subscriber, Output: Decodable, Decoder: PKDecoder>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure, Upstream.Output == Decoder.Input {
        
        private let decoder: Decoder
        
        init(downstream: Downstream, decoder: Decoder) {
            self.decoder = decoder
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            
            do {
                let output = try decoder.decode(Output.self, from: input)
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
