//
//  Merge5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    /// A publisher created by applying the merge function to five upstream publishers.
    public struct Merge5<A: NKPublisher, B: NKPublisher, C: NKPublisher, D: NKPublisher, E: NKPublisher> : NKPublisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure {
        
        public typealias Output = A.Output
        
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
            typealias Subscriber = NKSubscribers.MergeSink<S, A>
            
            let upstreamSubscriber = Subscriber(downstream: subscriber)
            
            var aUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var bUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var cUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var dUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var eUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            
            aUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            bUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            cUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            dUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            eUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            subscriber.receive(subscription: upstreamSubscriber)
            
            a.subscribe(aUpstreamSubscriber)
            b.subscribe(bUpstreamSubscriber)
            c.subscribe(cUpstreamSubscriber)
            d.subscribe(dUpstreamSubscriber)
            e.subscribe(eUpstreamSubscriber)
        }
        
        public func merge<P: NKPublisher>(with other: P) -> NKPublishers.Merge6<A, B, C, D, E, P> {
            NKPublishers.Merge6(a, b, c, d, e, other)
        }

        public func merge<P: NKPublisher, Q: NKPublisher>(with p: P, _ q: Q) -> NKPublishers.Merge7<A, B, C, D, E, P, Q> {
            NKPublishers.Merge7(a, b, c, d, e, p, q)
        }

        public func merge<P: NKPublisher, Q: NKPublisher, R: NKPublisher>(with p: P, _ q: Q, _ r: R) -> NKPublishers.Merge8<A, B, C, D, E, P, Q, R> {
            NKPublishers.Merge8(a, b, c, d, e, p, q, r)
        }
    }
}
