//
//  Decode.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    struct Decode<Upstream: PKPublisher, Output: Decodable, Decoder: PKDecoder>: PKPublisher where Upstream.Output == Decoder.Input {
        
        public typealias Failure = Error
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        private let decoder: Decoder
        
        public init(upstream: Upstream, decoder: Decoder) {
            self.upstream = upstream
            self.decoder = decoder
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let decodeSubscriber = InternalSink(downstream: subscriber, decoder: decoder)
            upstream.subscribe(decodeSubscriber)
        }
    }
}

extension PKPublishers.Decode {
    
    // MARK: DECODE SINK
    private final class InternalSink<Downstream: PKSubscriber, Output: Decodable, Decoder: PKDecoder>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure, Upstream.Output == Decoder.Input {
        
        private let decoder: Decoder
        
        init(downstream: Downstream, decoder: Decoder) {
            self.decoder = decoder
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            do {
                let output = try decoder.decode(Output.self, from: input)
                _ = downstream?.receive(output)
                
            } catch {
                downstream?.receive(completion: .failure(error))
            }
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
    }
}
