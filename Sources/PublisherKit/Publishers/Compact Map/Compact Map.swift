//
//  Compact Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

extension Publishers {
    
    /// A publisher that republishes all non-`nil` results of calling a closure with each received element.
    public struct CompactMap<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) -> Output?
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output?) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, operation: transform))
        }
    }
    
    /// A publisher that republishes all non-`nil` results of calling an error-throwing closure with each received element.
    public struct TryCompactMap<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) throws -> Output?
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) throws -> Output?) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.receive(subscriber: Inner(downstream: subscriber, operation: transform))
        }
    }
}

extension Publishers.CompactMap {
    
    public func compactMap<T>(_ transform: @escaping (Output) -> T?) -> Publishers.CompactMap<Upstream, T> {
        Publishers.CompactMap(upstream: upstream, transform: { self.transform($0).flatMap(transform) })
    }
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> Publishers.CompactMap<Upstream, T> {
        Publishers.CompactMap(upstream: upstream, transform: { self.transform($0).map(transform) })
    }
}

extension Publishers.TryCompactMap {
    
    public func compactMap<T>(_ transform: @escaping (Output) throws -> T?) -> Publishers.TryCompactMap<Upstream, T> {
        Publishers.TryCompactMap(upstream: upstream, transform: { try self.transform($0).flatMap(transform) })
    }
}

extension Publishers.CompactMap {
    
    // MARK: COMPACTMAP SINK
    private final class Inner<Downstream: Subscriber>: FilterProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output) -> Output?> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Input) -> PartialCompletion<Output, Failure>? {
            if let value = operation(input) {
                return .continue(value)
            } else {
                return nil
            }
        }
        
        override var description: String {
            "CompactMap"
        }
    }
}

extension Publishers.TryCompactMap {
    
    // MARK: TRY COMPACTMAP SINK
    private final class Inner<Downstream: Subscriber>: FilterProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output) throws -> Output?> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(input: Input) -> PartialCompletion<Output, Downstream.Failure>? {
            do {
                if let output = try operation(input) {
                    return .continue(output)
                } else {
                    return nil
                }
            } catch {
                return .failure(error)
            }
        }
        
        override var description: String {
            "TryCompactMap"
        }
    }
}
