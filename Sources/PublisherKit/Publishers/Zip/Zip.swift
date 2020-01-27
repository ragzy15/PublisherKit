//
//  Zip.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the zip function to two upstream publishers.
    public struct Zip<A: PKPublisher, B: PKPublisher>: PKPublisher where A.Failure == B.Failure {

        public typealias Output = (A.Output, B.Output)

        public typealias Failure = A.Failure

        public let a: A

        public let b: B

        public init(_ a: A, _ b: B) {
            self.a = a
            self.b = b
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Sub = ZipSink<S, A.Output, B.Output, Failure>
            
            let upstreamSubscriber = Sub(downstream: subscriber)

            let aUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, A>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(a: output)
            }

            let bUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, B>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(b: output)
            }
            
            upstreamSubscriber.receive(subscription: aUpstreamSubscriber)
            upstreamSubscriber.receive(subscription: bUpstreamSubscriber)
            
            subscriber.receive(subscription: upstreamSubscriber)
            
            upstreamSubscriber.request(.unlimited)
            aUpstreamSubscriber.request(.unlimited)
            bUpstreamSubscriber.request(.unlimited)
            
            b.subscribe(bUpstreamSubscriber)
            a.subscribe(aUpstreamSubscriber)
        }
    }
}

extension PKPublishers.Zip: Equatable where A: Equatable, B: Equatable{
    
    public static func == (lhs: PKPublishers.Zip<A, B>, rhs: PKPublishers.Zip<A, B>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}
