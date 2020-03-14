//
//  Encode.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/01/20.
//

extension Publishers {
    
    /// A publisher that encodes elements received from an upstream publisher using the specified encoder.
    public struct Encode<Upstream: Publisher, Encoder: TopLevelEncoder>: Publisher where Upstream.Output: Encodable {
        
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
            
            let encodeSubscriber = Inner(downstream: subscriber, encoder: encoder)
            upstream.subscribe(encodeSubscriber)
        }
    }
}

extension Publishers.Encode {
    
    // MARK: ENCODE SINK
    private final class Inner<Downstream: Subscriber, Encoder: TopLevelEncoder>: InternalSubscriber<Downstream, Upstream> where Encoder.Output == Downstream.Input, Failure == Downstream.Failure, Upstream.Output: Encodable {
        
        private let encoder: Encoder
        
        init(downstream: Downstream, encoder: Encoder) {
            self.encoder = encoder
            super.init(downstream: downstream)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            return Result { try encoder.encode(input) }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "Encode"
        }
    }
}
