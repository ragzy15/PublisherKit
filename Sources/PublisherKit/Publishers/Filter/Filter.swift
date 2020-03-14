//
//  Filter.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that republishes all elements that match a provided closure.
    public struct Filter<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure that indicates whether to republish an element.
        public let isIncluded: (Upstream.Output) -> Bool
        
        public init(upstream: Upstream, isIncluded: @escaping (Upstream.Output) -> Bool) {
            self.upstream = upstream
            self.isIncluded = isIncluded
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let filterSubscriber = Inner(downstream: subscriber, operation: isIncluded)
            upstream.subscribe(filterSubscriber)
        }
    }
}

extension Publishers.Filter {
    
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> Publishers.Filter<Upstream> {
        Publishers.Filter(upstream: upstream, isIncluded: { self.isIncluded($0) && isIncluded($0) })
    }
    
    public func tryFilter(_ isIncluded: @escaping (Output) throws -> Bool) -> Publishers.TryFilter<Upstream> {
        Publishers.TryFilter(upstream: upstream, isIncluded: { try self.isIncluded($0) && isIncluded($0) })
    }
}

extension Publishers.Filter {

    // MARK: FILTER SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Upstream.Output) -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            operation(input) ? .success(input) : nil
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "Filter"
        }
    }
}
