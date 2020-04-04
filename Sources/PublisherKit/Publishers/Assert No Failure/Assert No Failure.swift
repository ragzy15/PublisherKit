//
//  Assert No Failure.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 29/03/20.
//

extension Publisher {

    /// Raises a fatal error when its upstream publisher fails, and otherwise republishes all received input.
    ///
    /// Use this function for internal sanity checks that are active during testing but do not impact performance of shipping code.
    ///
    /// - Parameters:
    ///   - prefix: A string used at the beginning of the fatal error message.
    ///   - file: A filename used in the error message. This defaults to `#file`.
    ///   - line: A line number used in the error message. This defaults to `#line`.
    /// - Returns: A publisher that raises a fatal error when its upstream publisher fails.
    public func assertNoFailure(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> Publishers.AssertNoFailure<Self> {
        Publishers.AssertNoFailure(upstream: self, prefix: prefix, file: file, line: line)
    }
}

extension Publishers {
    
    /// A publisher that raises a fatal error upon receiving any failure, and otherwise republishes all received input.
    ///
    /// Use this function for internal sanity checks that are active during testing but do not impact performance of shipping code.
    public struct AssertNoFailure<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Never
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The string used at the beginning of the fatal error message.
        public let prefix: String
        
        /// The filename used in the error message.
        public let file: StaticString
        
        /// The line number used in the error message.
        public let line: UInt
        
        public init(upstream: Upstream, prefix: String, file: StaticString, line: UInt) {
            self.upstream = upstream
            self.prefix = prefix
            self.file = file
            self.line = line
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, prefix: prefix, file: file, line: line))
        }
    }
}

extension Publishers.AssertNoFailure {
    
    // MARK: ASSERT NO FAILURE SINK
    private struct Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        
        private let prefix: String
        private let file: StaticString
        private let line: UInt
        
        let combineIdentifier = CombineIdentifier()
        
        init(downstream: Downstream, prefix: String, file: StaticString, line: UInt) {
            self.downstream = downstream
            self.prefix = prefix
            self.file = file
            self.line = line
        }
        
        func receive(subscription: Subscription) {
            downstream.receive(subscription: subscription)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            downstream.receive(input)
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            switch completion {
            case .finished:
                downstream.receive(completion: .finished)
                
            case .failure(let error):
                let message = prefix.isEmpty ? error.localizedDescription : "\(prefix) \(error.localizedDescription)"
                Swift.assertionFailure(message, file: file, line: line)
            }
        }
        
        var description: String {
            "AssertNoFailure"
        }
    }
}
