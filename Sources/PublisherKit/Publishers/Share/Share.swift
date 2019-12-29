//
//  Share.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {

    /// A publisher implemented as a class, which otherwise behaves like its upstream publisher.
    final public class Share<Upstream: NKPublisher>: NKPublisher, Equatable {
        
        public typealias Output = Upstream.Output

        public typealias Failure = Upstream.Failure
        
        private let uuidString: String
        
        /// The publisher from which this publisher receives elements.
        final public let upstream: Upstream

        public init(upstream: Upstream) {
            self.upstream = upstream
            uuidString = "\(UUID().uuidString)-\(Date())"
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(subscriber)
        }
        
        public static func == (lhs: NKPublishers.Share<Upstream>, rhs: NKPublishers.Share<Upstream>) -> Bool {
            lhs.uuidString == rhs.uuidString
        }
    }
}
