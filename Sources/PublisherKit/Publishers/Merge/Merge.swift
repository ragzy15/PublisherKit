//
//  Merge.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    /// A publisher created by applying the merge function to two upstream publishers.
    public struct Merge<A: NKPublisher, B: NKPublisher>: NKPublisher where A.Output == B.Output, A.Failure == B.Failure {
        
        public typealias Output = A.Output
        
        public typealias Failure = A.Failure
        
        public let a: A
        
        public let b: B
        
        public init(_ a: A, _ b: B) {
            self.a = a
            self.b = b
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            typealias Subscriber = NKSubscribers.MergeSink<S, A>
            
            let upstreamSubscriber = Subscriber(downstream: subscriber)
            
            var aUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var bUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            
            aUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if bUpstreamSubscriber.isOver  {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    bUpstreamSubscriber?.cancel()
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            bUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            subscriber.receive(subscription: upstreamSubscriber)
            a.subscribe(aUpstreamSubscriber)
            b.subscribe(bUpstreamSubscriber)
        }
        
        public func merge<P: NKPublisher>(with other: P) -> NKPublishers.Merge3<A, B, P> {
            NKPublishers.Merge3(a, b, other)
        }
        
        public func merge<P: NKPublisher, Q: NKPublisher>(with p: P, _ q: Q) -> NKPublishers.Merge4<A, B, P, Q> {
            NKPublishers.Merge4(a, b, p, q)
        }
        
        public func merge<P: NKPublisher, Q: NKPublisher, R: NKPublisher>(with p: P, _ q: Q, _ r: R) -> NKPublishers.Merge5<A, B, P, Q, R> {
            NKPublishers.Merge5(a, b, p, q, r)
        }
        
        public func merge<P: NKPublisher, Q: NKPublisher, R: NKPublisher, S: NKPublisher>(with p: P, _ q: Q, _ r: R, _ s: S) -> NKPublishers.Merge6<A, B, P, Q, R, S> {
            NKPublishers.Merge6(a, b, p, q, r, s)
        }
        
        public func merge<P: NKPublisher, Q: NKPublisher, R: NKPublisher, S: NKPublisher, T: NKPublisher>(with p: P, _ q: Q, _ r: R, _ s: S, _ t: T) -> NKPublishers.Merge7<A, B, P, Q, R, S, T> {
            NKPublishers.Merge7(a, b, p, q, r, s, t)
        }
        
        public func merge<P: NKPublisher, Q: NKPublisher, R: NKPublisher, S: NKPublisher, T: NKPublisher, U: NKPublisher>(with p: P, _ q: Q, _ r: R, _ s: S, _ t: T, _ u: U) -> NKPublishers.Merge8<A, B, P, Q, R, S, T, U> {
            NKPublishers.Merge8(a, b, p, q, r, s, t, u)
        }
    } 
}
