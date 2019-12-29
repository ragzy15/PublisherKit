//
//  First Match.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {

    /// A publisher that publishes a single Boolean value that indicates whether the ouput has passed a given pattern.
    public struct FirstMatch<Upstream: NKPublisher>: NKPublisher where Upstream.Output == String {

        public typealias Output = Bool

        public typealias Failure = Error

        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public let pattern: String
        
        public let options: NSRegularExpression.Options
        
        public let matchOptions: NSRegularExpression.MatchingOptions

        public init(upstream: Upstream, pattern: String, options: NSRegularExpression.Options, matchOptions: NSRegularExpression.MatchingOptions) {
            self.upstream = upstream
            self.pattern = pattern
            self.options = options
            self.matchOptions = matchOptions
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            var expression: NSRegularExpression?
            var error: Error?
            
            do {
                expression = try NSRegularExpression(pattern: pattern, options: options)
            } catch let creationError {
                error = creationError
            }
            
            typealias Sub = NKSubscribers.OperatorSink<S, Upstream.Output, Failure>
            
            let upstreamSubscriber = Sub(downstream: subscriber, receiveCompletion: { (completion) in
                
                subscriber.receive(completion: completion)
                
            }) { (output) in
                
                if let error = error {
                    subscriber.receive(completion: .failure(error))
                } else if let expression = expression {
                    let match = expression.firstMatch(in: output, options: self.matchOptions, range: NSRange(location: 0, length: output.utf8.count))
                    _ = subscriber.receive(match != nil)
                }
            }
            
            let superSubscriber = NKSubscribers.OperatorSink<Sub, Upstream.Output, Upstream.Failure>(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                
                let newCompletion = completion.mapError { $0 as Failure }
                upstreamSubscriber.receive(completion: newCompletion)
                
            }) { (output) in
                _ = upstreamSubscriber.receive(output)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(superSubscriber)
        }
    }
}
