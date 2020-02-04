//
//  Share.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher implemented as a class, which otherwise behaves like its upstream publisher.
    final public class Share<Upstream: Publisher>: Publisher, Equatable {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        final public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(subscriber)
        }
        
        public static func == (lhs: Publishers.Share<Upstream>, rhs: Publishers.Share<Upstream>) -> Bool {
            lhs === rhs
        }
    }
}
