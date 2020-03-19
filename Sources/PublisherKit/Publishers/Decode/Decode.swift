//
//  Decode.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

extension Publishers {
    
    /// A publisher that decodes elements received from an upstream publisher into the specified type.
    public struct Decode<Upstream: Publisher, Output: Decodable, Decoder: TopLevelDecoder>: Publisher where Upstream.Output == Decoder.Input {
        
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
            upstream.subscribe(Inner(downstream: subscriber, decoder: decoder, logOutput: logOutput))
        }
    }
}

extension Publishers.Decode {
    
    // MARK: DECODE SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var downstream: Downstream?
        private var subscription: Subscription?
        private var finished = false
        
        private let decoder: Decoder
        
        let logOutput: Bool
        
        init(downstream: Downstream, decoder: Decoder, logOutput: Bool) {
            self.decoder = decoder
            self.logOutput = logOutput
            self.downstream = downstream
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            guard !finished else { return .none }
            
            if logOutput { decoder.log(from: input) }
            
            do {
                let output = try decoder.decode(Output.self, from: input)
                return downstream?.receive(output) ?? .none
            } catch {
                finished = true
                subscription?.cancel()
                subscription = nil
                downstream?.receive(completion: .failure(error))
                return .none
            }
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard !finished else { return }
            finished = true
            subscription = nil
            downstream?.receive(completion: completion.mapError { $0 as Error })
        }
        
        func receive(subscription: Subscription) {
            guard self.subscription == nil, !finished else { return }
            self.subscription = subscription
            downstream?.receive(subscription: self)
        }
        
        func request(_ demand: Subscribers.Demand) {
            subscription?.request(demand)
        }
        
        func cancel() {
            guard !finished else { return }
            finished = true
            subscription?.cancel()
            subscription = nil
        }
        
        var description: String {
            "Encode"
        }
        
        var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("downstream", downstream as Any),
                ("finished", finished),
                ("upstreamSubscription", subscription as Any)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
