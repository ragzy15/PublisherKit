//
//  Merge.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the merge function to two upstream publishers.
    public struct Merge<A: PKPublisher, B: PKPublisher>: PKPublisher where A.Output == B.Output, A.Failure == B.Failure {
        
        public typealias Output = A.Output
        
        public typealias Failure = A.Failure
        
        public let a: A
        
        public let b: B
        
        public init(_ a: A, _ b: B) {
            self.a = a
            self.b = b
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            typealias Subscriber = PKSubscribers.MergeSink<S, A>
            
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
        
        public func merge<P: PKPublisher>(with other: P) -> PKPublishers.Merge3<A, B, P> {
            PKPublishers.Merge3(a, b, other)
        }
        
        public func merge<P: PKPublisher, Q: PKPublisher>(with p: P, _ q: Q) -> PKPublishers.Merge4<A, B, P, Q> {
            PKPublishers.Merge4(a, b, p, q)
        }
        
        public func merge<P: PKPublisher, Q: PKPublisher, R: PKPublisher>(with p: P, _ q: Q, _ r: R) -> PKPublishers.Merge5<A, B, P, Q, R> {
            PKPublishers.Merge5(a, b, p, q, r)
        }
        
        public func merge<P: PKPublisher, Q: PKPublisher, R: PKPublisher, S: PKPublisher>(with p: P, _ q: Q, _ r: R, _ s: S) -> PKPublishers.Merge6<A, B, P, Q, R, S> {
            PKPublishers.Merge6(a, b, p, q, r, s)
        }
        
        public func merge<P: PKPublisher, Q: PKPublisher, R: PKPublisher, S: PKPublisher, T: PKPublisher>(with p: P, _ q: Q, _ r: R, _ s: S, _ t: T) -> PKPublishers.Merge7<A, B, P, Q, R, S, T> {
            PKPublishers.Merge7(a, b, p, q, r, s, t)
        }
        
        public func merge<P: PKPublisher, Q: PKPublisher, R: PKPublisher, S: PKPublisher, T: PKPublisher, U: PKPublisher>(with p: P, _ q: Q, _ r: R, _ s: S, _ t: T, _ u: U) -> PKPublishers.Merge8<A, B, P, Q, R, S, T, U> {
            PKPublishers.Merge8(a, b, p, q, r, s, t, u)
        }
    } 
}
