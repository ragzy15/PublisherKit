//
//  Decode.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public extension Publishers {
    
    /// A publisher that decodes elements received from an upstream publisher into the specified type.
    struct Decode<Upstream: Publisher, Output: Decodable, Decoder: TopLevelDecoder>: Publisher where Upstream.Output == Decoder.Input {
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The decoder used for decoding the elements received from the upstream publisher.
        private let decoder: Decoder
        
        /// Log output to console using serializer.
        public var logOutput = false
        
        public init(upstream: Upstream, decoder: Decoder) {
            self.upstream = upstream
            self.decoder = decoder
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let decodeSubscriber = Inner(downstream: subscriber, decoder: decoder)
            decodeSubscriber.logOutput = logOutput
            subscriber.receive(subscription: decodeSubscriber)
            upstream.subscribe(decodeSubscriber)
        }
    }
}

extension Publishers.Decode {
    
    // MARK: DECODE SINK
    private final class Inner<Downstream: Subscriber, Output: Decodable, Decoder: TopLevelDecoder>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure, Upstream.Output == Decoder.Input {
        
        private let decoder: Decoder
        
        var logOutput = false
        
        init(downstream: Downstream, decoder: Decoder) {
            self.decoder = decoder
            super.init(downstream: downstream)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Output, Downstream.Failure>? {
            if logOutput {
                decoder.log(from: input)
            }
            
            return Result { try decoder.decode(Output.self, from: input) }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "Decode"
        }
    }
}
