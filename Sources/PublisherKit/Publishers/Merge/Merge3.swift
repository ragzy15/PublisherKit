//
//  Merge3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the merge function to three upstream publishers.
    public struct Merge3<A: PKPublisher, B: PKPublisher, C: PKPublisher>: PKPublisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure {

        public typealias Output = A.Output

        public typealias Failure = A.Failure

        public let a: A

        public let b: B

        public let c: C

        public init(_ a: A, _ b: B, _ c: C) {
            self.a = a
            self.b = b
            self.c = c
        }

        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            typealias Subscriber = PKSubscribers.MergeSink<S, A>
            
            let upstreamSubscriber = Subscriber(downstream: subscriber)
            
            var aUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var bUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var cUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            
            aUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            bUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            cUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            subscriber.receive(subscription: upstreamSubscriber)
            a.subscribe(aUpstreamSubscriber)
            b.subscribe(bUpstreamSubscriber)
            c.subscribe(cUpstreamSubscriber)
        }
        
        public func merge<P: PKPublisher>(with other: P) -> PKPublishers.Merge4<A, B, C, P> {
            PKPublishers.Merge4(a, b, c, other)
        }

        public func merge<P: PKPublisher, Q: PKPublisher>(with p: P, _ q: Q) -> PKPublishers.Merge5<A, B, C, P, Q> {
            PKPublishers.Merge5(a, b, c, p, q)
        }

        public func merge<P: PKPublisher, Q: PKPublisher, R: PKPublisher>(with p: P, _ q: Q, _ r: R) -> PKPublishers.Merge6<A, B, C, P, Q, R> {
            PKPublishers.Merge6(a, b, c, p, q, r)
        }

        public func merge<P: PKPublisher, Q: PKPublisher, R: PKPublisher, S: PKPublisher>(with p: P, _ q: Q, _ r: R, _ s: S) -> PKPublishers.Merge7<A, B, C, P, Q, R, S> {
            PKPublishers.Merge7(a, b, c, p, q, r, s)
        }

        public func merge<P: PKPublisher, Q: PKPublisher, R: PKPublisher, S: PKPublisher, T: PKPublisher>(with p: P, _ q: Q, _ r: R, _ s: S, _ t: T) -> PKPublishers.Merge8<A, B, C, P, Q, R, S, T> {
            PKPublishers.Merge8(a, b, c, p, q, r, s, t)
        }
    }
}
