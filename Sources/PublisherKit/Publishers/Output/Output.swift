//
//  Output.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Publishers {
    
    /// A publisher that publishes elements specified by a range in the sequence of published elements.
    public struct Output<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The range of elements to publish.
        public let range: CountableRange<Int>
        
        /// Creates a publisher that publishes elements specified by a range.
        ///
        /// - Parameters:
        ///   - upstream: The publisher that this publisher receives elements from.
        ///   - range: The range of elements to publish.
        public init(upstream: Upstream, range: CountableRange<Int>) {
            self.upstream = upstream
            self.range = range
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let outputSubscription = Inner(downstream: subscriber, range: range)
            
            subscriber.receive(subscription: outputSubscription)
            upstream.subscribe(outputSubscription)
        }
    }
}

extension Publishers.Output: Equatable where Upstream: Equatable {
}

extension Publishers.Output {
    
    // MARK: OUTPUT SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let range: CountableRange<Int>
        private var start: Int
        private var counter: Int
        
        init(downstream: Downstream, range: CountableRange<Int>) {
            self.range = range
            start = range.lowerBound
            counter = range.count
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> Subscribers.Demand {
            getLock().lock()
            guard status.isSubscribed else { getLock().unlock(); return .none }
            getLock().unlock()
            
            if start > 0 {
                start -= 1
                demand = .max(1)
            }
            
            if counter > 0 {
                counter -= 1                
                demand = downstream?.receive(input) ?? .none
            } else {
                demand = .none
            }
            
            return demand
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "Output"
        }
    }
}
