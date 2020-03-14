//
//  Try Filter.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that republishes all elements that match a provided error-throwing closure.
    public struct TryFilter<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// An error-throwing closure that indicates whether to republish an element.
        public let isIncluded: (Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, isIncluded: @escaping (Upstream.Output) throws -> Bool) {
            self.upstream = upstream
            self.isIncluded = isIncluded
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let tryFilterSubscriber = Inner(downstream: subscriber, operation: isIncluded)
            upstream.receive(subscriber: tryFilterSubscriber)
        }
    }
}

extension Publishers.TryFilter {
    
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> Publishers.TryFilter<Upstream> {
        Publishers.TryFilter(upstream: upstream, isIncluded: { try self.isIncluded($0) && isIncluded($0) })
    }
    
    public func tryFilter(_ isIncluded: @escaping (Output) throws -> Bool) -> Publishers.TryFilter<Upstream> {
        Publishers.TryFilter(upstream: upstream, isIncluded: { try self.isIncluded($0) && isIncluded($0) })
    }
}

extension Publishers.TryFilter {
    
    // MARK: TRY FILTER SINK
    private final class Inner<Downstream: Subscriber>: OperatorSubscriber<Downstream, Upstream, (Upstream.Output) throws -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
         override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {            
            do {
                let isIncluded = try operation(input)
                return isIncluded ? .success(input) : nil
            } catch {
                return .failure(error)
            }
        }
        
         override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "TryFilter"
        }
    }
}
