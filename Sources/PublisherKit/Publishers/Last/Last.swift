//
//  Last.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 28/03/20.
//

extension Publishers {
    
    /// A publisher that only publishes the last element of a stream, after the stream finishes.
    public struct Last<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber))
        }
    }
}

extension Publishers {
    
    /// A publisher that only publishes the last element of a stream that satisfies a predicate closure, once the stream finishes.
    public struct LastWhere<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that determines whether to publish an element.
        public let predicate: (Upstream.Output) -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, reduce: predicate))
        }
    }
    
    /// A publisher that only publishes the last element of a stream that satisfies a error-throwing predicate closure, once the stream finishes.
    public struct TryLastWhere<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The error-throwing closure that determines whether to publish an element.
        public let predicate: (Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Output) throws -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, reduce: predicate))
        }
    }
}

extension Publishers.Last: Equatable where Upstream: Equatable { }

extension Publishers.Last {
    
    // MARK: Last SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, Void> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        init(downstream: Downstream) {
            super.init(downstream: downstream, reduce: ())
        }
        
        override func receive(newValue: Input) -> PartialCompletion<Void, Failure> {
            result = newValue
            return .continue
        }
        
        override var description: String {
            "Last"
        }
    }
}

extension Publishers.LastWhere {
    
    // MARK: Last WHERE SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output) -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(newValue: Input) -> PartialCompletion<Void, Failure> {
            if reduce(newValue) {
                result = newValue
            }
            return .continue
        }
        
        override var description: String {
            "LastWhere"
        }
    }
}

extension Publishers.TryLastWhere {
    
    // MARK: TRY Last WHERE SINK
    private final class Inner<Downstream: Subscriber>: ReduceProducer<Downstream, Output, Upstream.Output, Upstream.Failure, (Upstream.Output) throws -> Bool> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override func receive(newValue: Input) -> PartialCompletion<Void, Downstream.Failure> {
            do {
                if try reduce(newValue) {
                    result = newValue
                }
                return .continue
            } catch {
                return .failure(error)
            }
        }
        
        override var description: String {
            "TryLastWhere"
        }
    }
}
