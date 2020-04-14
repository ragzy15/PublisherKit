//
//  Matches.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import PublisherKit
import Foundation

extension Publisher where Output == String {
    
    public func matches(pattern: String, options: NSRegularExpression.Options = [], matchOptions: NSRegularExpression.MatchingOptions = []) -> Publishers.Matches<Self> {
        Publishers.Matches(upstream: self, pattern: pattern, options: options, matchOptions: matchOptions)
    }
}

extension Publishers {
    
    /// A publisher that publishes an array containing all the matches of the given regular pattern from the output.
    public struct Matches<Upstream: Publisher>: Publisher where Upstream.Output == String {
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, result: result, matchOptions: matchOptions))
        }
    }
}

extension Publishers.Matches {
    
    // MARK: MATCHES SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let lock = Lock()
        private var status: SubscriptionStatus = .awaiting
        private var downstream: Downstream?
        
        private let result: Result<NSRegularExpression, Error>
        private let matchOptions: NSRegularExpression.MatchingOptions
        
        init(downstream: Downstream, result: Result<NSRegularExpression, Error>, matchOptions: NSRegularExpression.MatchingOptions) {
            self.matchOptions = matchOptions
            self.result = result
            self.downstream = downstream
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
        }
        
        func receive(_ input: String) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return .none }
            lock.unlock()
            
            switch result {
            case .success(let regularExpression):
                let matches = regularExpression.matches(in: input, options: matchOptions, range: NSRange(location: 0, length: input.count))
                return downstream?.receive(matches) ?? .none
                
            case .failure(let error):
                lock.lock()
                status = .terminated
                lock.unlock()
                
                subscription.cancel()
                downstream?.receive(completion: .failure(error))
                
                return .none
            }
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            downstream?.receive(completion: completion.eraseError())
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "Matches"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
