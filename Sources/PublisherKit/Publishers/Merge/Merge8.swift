//
//  Merge8.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {
    
    /// A publisher created by applying the merge function to eight upstream publishers.
    public struct Merge8<A: NKPublisher, B: NKPublisher, C: NKPublisher, D: NKPublisher, E: NKPublisher, F: NKPublisher, G: NKPublisher, H: NKPublisher>: NKPublisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure, E.Output == F.Output, E.Failure == F.Failure, F.Output == G.Output, F.Failure == G.Failure, G.Output == H.Output, G.Failure == H.Failure {

        public typealias Output = A.Output

        public typealias Failure = A.Failure

        public let a: A

        public let b: B

        public let c: C

        public let d: D

        public let e: E

        public let f: F

        public let g: G

        public let h: H

        public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
            self.g = g
            self.h = h
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            typealias Subscriber = NKSubscribers.MergeSink<S, A>
            
            let upstreamSubscriber = Subscriber(downstream: subscriber)
            
            var aUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var bUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var cUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var dUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var eUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var fUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var gUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            var hUpstreamSubscriber: SameUpstreamOutputOperatorSink<Subscriber, A>!
            
            aUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver, fUpstreamSubscriber.isOver, gUpstreamSubscriber.isOver, hUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    fUpstreamSubscriber?.cancel()
                    gUpstreamSubscriber?.cancel()
                    hUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            bUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver, fUpstreamSubscriber.isOver, gUpstreamSubscriber.isOver, hUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    fUpstreamSubscriber?.cancel()
                    gUpstreamSubscriber?.cancel()
                    hUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            cUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver, fUpstreamSubscriber.isOver, gUpstreamSubscriber.isOver, hUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    fUpstreamSubscriber?.cancel()
                    gUpstreamSubscriber?.cancel()
                    hUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            dUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver, fUpstreamSubscriber.isOver, gUpstreamSubscriber.isOver, hUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    fUpstreamSubscriber?.cancel()
                    gUpstreamSubscriber?.cancel()
                    hUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            eUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, fUpstreamSubscriber.isOver, gUpstreamSubscriber.isOver, hUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    fUpstreamSubscriber?.cancel()
                    gUpstreamSubscriber?.cancel()
                    hUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            fUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver, gUpstreamSubscriber.isOver, hUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    gUpstreamSubscriber?.cancel()
                    hUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            gUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver, fUpstreamSubscriber.isOver, hUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    fUpstreamSubscriber?.cancel()
                    hUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            hUpstreamSubscriber = .init(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    if aUpstreamSubscriber.isOver, bUpstreamSubscriber.isOver, cUpstreamSubscriber.isOver, dUpstreamSubscriber.isOver, eUpstreamSubscriber.isOver, fUpstreamSubscriber.isOver, gUpstreamSubscriber.isOver {
                        upstreamSubscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    aUpstreamSubscriber?.cancel()
                    bUpstreamSubscriber?.cancel()
                    cUpstreamSubscriber?.cancel()
                    dUpstreamSubscriber?.cancel()
                    eUpstreamSubscriber?.cancel()
                    fUpstreamSubscriber?.cancel()
                    gUpstreamSubscriber?.cancel()
                    
                    upstreamSubscriber.receive(completion: .failure(error))
                }
            })
            
            subscriber.receive(subscription: upstreamSubscriber)
            
            a.subscribe(aUpstreamSubscriber)
            b.subscribe(bUpstreamSubscriber)
            c.subscribe(cUpstreamSubscriber)
            d.subscribe(dUpstreamSubscriber)
            e.subscribe(eUpstreamSubscriber)
            f.subscribe(fUpstreamSubscriber)
            g.subscribe(gUpstreamSubscriber)
            h.subscribe(hUpstreamSubscriber)
        }
    }
}
