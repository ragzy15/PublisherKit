//
//  First Match.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher that publishes a single Boolean value that indicates whether the ouput has passed a given pattern.
    public struct FirstMatch<Upstream: Publisher>: Publisher where Upstream.Output == String {
        
        public typealias Output = Bool
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The regular expression pattern to compile.
        public let pattern: String
        
        /// The regular expression options that are applied to the expression during matching.
        public let options: NSRegularExpression.Options
        
        /// The matching options to use
        public let matchOptions: NSRegularExpression.MatchingOptions
        
        private let result: Result<NSRegularExpression, Error>
        
        public init(upstream: Upstream, pattern: String, options: NSRegularExpression.Options, matchOptions: NSRegularExpression.MatchingOptions) {
            self.upstream = upstream
            self.pattern = pattern
            self.options = options
            self.matchOptions = matchOptions
            
            do {
                let expression = try NSRegularExpression(pattern: pattern, options: options)
                result = .success(expression)
            } catch {
                result = .failure(error)
            }
        }
        
        public init(upstream: Upstream, regularExpression: NSRegularExpression, matchOptions: NSRegularExpression.MatchingOptions) {
            self.upstream = upstream
            self.pattern = regularExpression.pattern
            self.options = regularExpression.options
            self.matchOptions = matchOptions
            result = .success(regularExpression)
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let firstMatchSubscriber = Inner(downstream: subscriber, result: result, matchOptions: matchOptions)
            subscriber.receive(subscription: firstMatchSubscriber)
            upstream.subscribe(firstMatchSubscriber)
        }
    }
}

extension Publishers.FirstMatch {
    
    // MARK: FIRST MATCH SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let result: Result<NSRegularExpression, Error>
        private let matchOptions: NSRegularExpression.MatchingOptions
        
        init(downstream: Downstream, result: Result<NSRegularExpression, Error>, matchOptions: NSRegularExpression.MatchingOptions) {
            self.matchOptions = matchOptions
            self.result = result
            super.init(downstream: downstream)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            result.map { (expression) -> Downstream.Input in
                let match = expression.firstMatch(in: input, options: matchOptions, range: NSRange(location: 0, length: input.count))
                return match != nil
            }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "FirstMatch"
        }
    }
}
