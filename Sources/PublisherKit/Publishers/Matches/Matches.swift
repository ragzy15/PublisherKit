//
//  Matches.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that publishes an array containing all the matches of the given regular pattern from the output.
    public struct Matches<Upstream: PKPublisher>: PKPublisher where Upstream.Output == String {
        
        public typealias Output = [NSTextCheckingResult]
        
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
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let matchesSubscriber = InternalSink(downstream: subscriber, result: result, matchOptions: matchOptions)
            upstream.subscribe(matchesSubscriber)
        }
    }
}

extension PKPublishers.Matches {
    
    // MARK: MATCHES SINK
    private final class InternalSink<Downstream: PKSubscriber>: PKSubscribers.OperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let result: Result<NSRegularExpression, Error>
        private let matchOptions: NSRegularExpression.MatchingOptions
        
        init(downstream: Downstream, result: Result<NSRegularExpression, Error>, matchOptions: NSRegularExpression.MatchingOptions) {
            self.matchOptions = matchOptions
            self.result = result
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            switch result {
            case .success(let expression):
                let matches = expression.matches(in: input, options: matchOptions, range: NSRange(location: 0, length: input.utf8.count))
                _ = downstream?.receive(matches)
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            end()
            
            let completion = completion.mapError { $0 as Downstream.Failure }
            downstream?.receive(completion: completion)
        }
    }
}
