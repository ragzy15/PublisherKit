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
            upstream.subscribe(Inner(downstream: subscriber, encoder: encoder))
        }
    }
}

extension Publishers.Encode {
    
    // MARK: ENCODE SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var downstream: Downstream?
        private var subscription: Subscription?
        private var finished = false
        
        private let encoder: Encoder
        
        init(downstream: Downstream, encoder: Encoder) {
            self.encoder = encoder
            self.downstream = downstream
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            guard !finished else { return .none }
            
            do {
                let output = try encoder.encode(input)
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
        
        var playgroundDescription: Any {
            description
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
