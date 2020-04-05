//
//  Comparison.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 29/03/20.
//

extension Publisher where Output: Comparable {
    
    /// Publishes the minimum value received from the upstream publisher, after it finishes.
    ///
    /// After this publisher receives a request for more than 0 items, it requests unlimited items from its upstream publisher.
    /// - Returns: A publisher that publishes the minimum value received from the upstream publisher, after the upstream publisher finishes.
    public func min() -> Publishers.Comparison<Self> {
        Publishers.Comparison(upstream: self, areInIncreasingOrder: { $0 > $1 })
    }
    
    /// Publishes the maximum value received from the upstream publisher, after it finishes.
    ///
    /// After this publisher receives a request for more than 0 items, it requests unlimited items from its upstream publisher.
    /// - Returns: A publisher that publishes the maximum value received from the upstream publisher, after the upstream publisher finishes.
    public func max() -> Publishers.Comparison<Self> {
        Publishers.Comparison(upstream: self, areInIncreasingOrder: { $0 < $1 })
    }
}

extension Publisher {
    
    /// Publishes the minimum value received from the upstream publisher, after it finishes.
    ///
    /// After this publisher receives a request for more than 0 items, it requests unlimited items from its upstream publisher.
    /// - Parameter areInIncreasingOrder: A closure that receives two elements and returns `true` if they are in increasing order.
    /// - Returns: A publisher that publishes the minimum value received from the upstream publisher, after the upstream publisher finishes.
    public func min(by areInIncreasingOrder: @escaping (Output, Output) -> Bool) -> Publishers.Comparison<Self> {
        Publishers.Comparison(upstream: self, areInIncreasingOrder: areInIncreasingOrder)
    }
    
    /// Publishes the minimum value received from the upstream publisher, using the provided error-throwing closure to order the items.
    ///
    /// After this publisher receives a request for more than 0 items, it requests unlimited items from its upstream publisher.
    /// - Parameter areInIncreasingOrder: A throwing closure that receives two elements and returns `true` if they are in increasing order. If this closure throws, the publisher terminates with a `Failure`.
    /// - Returns: A publisher that publishes the minimum value received from the upstream publisher, after the upstream publisher finishes.
    public func tryMin(by areInIncreasingOrder: @escaping (Output, Output) throws -> Bool) -> Publishers.TryComparison<Self> {
        Publishers.TryComparison(upstream: self, areInIncreasingOrder: areInIncreasingOrder)
    }
    
    /// Publishes the maximum value received from the upstream publisher, using the provided ordering closure.
    ///
    /// After this publisher receives a request for more than 0 items, it requests unlimited items from its upstream publisher.
    /// - Parameter areInIncreasingOrder: A closure that receives two elements and returns `true` if they are in increasing order.
    /// - Returns: A publisher that publishes the maximum value received from the upstream publisher, after the upstream publisher finishes.
    public func max(by areInIncreasingOrder: @escaping (Output, Output) -> Bool) -> Publishers.Comparison<Self> {
        Publishers.Comparison(upstream: self, areInIncreasingOrder: areInIncreasingOrder)
    }
    
    /// Publishes the maximum value received from the upstream publisher, using the provided error-throwing closure to order the items.
    ///
    /// After this publisher receives a request for more than 0 items, it requests unlimited items from its upstream publisher.
    /// - Parameter areInIncreasingOrder: A throwing closure that receives two elements and returns `true` if they are in increasing order. If this closure throws, the publisher terminates with a `Failure`.
    /// - Returns: A publisher that publishes the maximum value received from the upstream publisher, after the upstream publisher finishes.
    public func tryMax(by areInIncreasingOrder: @escaping (Output, Output) throws -> Bool) -> Publishers.TryComparison<Self> {
        Publishers.TryComparison(upstream: self, areInIncreasingOrder: areInIncreasingOrder)
    }
}

extension Publishers {
    
    /// A publisher that republishes items from another publisher only if each new item is in increasing order from the previously-published item.
    public struct Comparison<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// A closure that receives two elements and returns `true` if they are in increasing order.
        public let areInIncreasingOrder: (Upstream.Output, Upstream.Output) -> Bool
        
        public init(upstream: Upstream, areInIncreasingOrder: @escaping (Upstream.Output, Upstream.Output) -> Bool) {
            self.upstream = upstream
            self.areInIncreasingOrder = areInIncreasingOrder
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, reduce: areInIncreasingOrder))
        }
    }
    
    /// A publisher that republishes items from another publisher only if each new item is in increasing order from the previously-published item, and fails if the ordering logic throws an error.
    public struct TryComparison<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// A closure that receives two elements and returns `true` if they are in increasing order.
        public let areInIncreasingOrder: (Upstream.Output, Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, areInIncreasingOrder: @escaping (Upstream.Output, Upstream.Output) throws -> Bool) {
            self.upstream = upstream
            self.areInIncreasingOrder = areInIncreasingOrder
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, reduce: areInIncreasingOrder))
        }
    }
}

extension Publishers.Comparison {
    
    // MARK: COMPARISON SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output, Upstream.Output) -> Bool>  where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(newValue: Upstream.Output) -> PartialCompletion<Void, Downstream.Failure> {
            guard let result = result else {
                self.result = newValue
                return .continue
            }
            
            if reduce(result, newValue) {
                self.result = newValue
            }
            
            return .continue
        }
        
        override var description: String {
            "Comparison"
        }
    }
}

extension Publishers.TryComparison {
    
    // MARK: TRY COMPARISON SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output, Upstream.Output) throws -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(newValue: Upstream.Output) -> PartialCompletion<Void, Downstream.Failure> {
            guard let result = result else {
                self.result = newValue
                return .continue
            }
            
            do {
                if try reduce(result, newValue) {
                    self.result = newValue
                }
                
                return .continue
            } catch {
                return .failure(error)
            }
        }
        
        override var description: String {
            "TryComparison"
        }
    }
}
