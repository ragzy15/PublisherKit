//
//  Combine Latest5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    /// A publisher created by applying the zip function to two upstream publishers.
    public struct CombineLatest5<A: NKPublisher, B: NKPublisher, C: NKPublisher, D: NKPublisher, E: NKPublisher>: NKPublisher where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure, D.Failure == E.Failure {

        public typealias Output = (A.Output, B.Output, C.Output, D.Output, E.Output)

        public typealias Failure = A.Failure

        public let a: A

        public let b: B

        public let c: C
        
        public let d: D
        
        public let e: E

        public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Sub = CombineLatestSink5<S, A.Output, B.Output, C.Output, D.Output, E.Output, Failure>
            
            let upstreamSubscriber = Sub(downstream: subscriber)

            let aUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, A>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(a: output)
            }

            let bUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, B>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(b: output)
            }
            
            let cUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, C>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(c: output)
            }
            
            let dUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, D>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(d: output)
            }
            
            let eUpstreamSubscriber = SameUpstreamFailureOperatorSink<Sub, E>(downstream: upstreamSubscriber) { (output) in
                upstreamSubscriber.receive(e: output)
            }
            
            upstreamSubscriber.receive(subscription: aUpstreamSubscriber)
            upstreamSubscriber.receive(subscription: bUpstreamSubscriber)
            upstreamSubscriber.receive(subscription: cUpstreamSubscriber)
            upstreamSubscriber.receive(subscription: dUpstreamSubscriber)
            upstreamSubscriber.receive(subscription: eUpstreamSubscriber)
            
            subscriber.receive(subscription: upstreamSubscriber)
            
            upstreamSubscriber.request(.unlimited)
            aUpstreamSubscriber.request(.unlimited)
            bUpstreamSubscriber.request(.unlimited)
            cUpstreamSubscriber.request(.unlimited)
            dUpstreamSubscriber.request(.unlimited)
            eUpstreamSubscriber.request(.unlimited)
            
            e.subscribe(eUpstreamSubscriber)
            d.subscribe(dUpstreamSubscriber)
            c.subscribe(cUpstreamSubscriber)
            b.subscribe(bUpstreamSubscriber)
            a.subscribe(aUpstreamSubscriber)
        }
    }
}

extension NKPublishers.CombineLatest5: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable {
    
    public static func == (lhs: NKPublishers.CombineLatest5<A, B, C, D, E>, rhs: NKPublishers.CombineLatest5<A, B, C, D, E>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d && lhs.e == rhs.e
    }
}
