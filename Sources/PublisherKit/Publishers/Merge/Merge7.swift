//
//  Merge7.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher created by applying the merge function to seven upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge7<A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher, F: Publisher, G: Publisher>: Publisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure, E.Output == F.Output, E.Failure == F.Failure, F.Output == G.Output, F.Failure == G.Failure {
        
        public typealias Output = A.Output
        
        public typealias Failure = A.Failure
        
        /// A publisher.
        public let a: A
        
        /// A second publisher.
        public let b: B
        
        /// A third publisher.
        public let c: C
        
        /// A fourth publisher.
        public let d: D
        
        /// A fifth publisher.
        public let e: E
        
        /// A sixth publisher.
        public let f: F
        
        /// A seventh publisher.
        public let g: G
        
        public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
            self.g = g
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = InternalSink(downstream: subscriber)
            
            mergeSubscriber.receiveSubscription()
            
            subscriber.receive(subscription: mergeSubscriber)
            
            mergeSubscriber.sendRequest()
            
            a.subscribe(mergeSubscriber.aSubscriber)
            b.subscribe(mergeSubscriber.bSubscriber)
            c.subscribe(mergeSubscriber.cSubscriber)
            d.subscribe(mergeSubscriber.dSubscriber)
            e.subscribe(mergeSubscriber.eSubscriber)
            f.subscribe(mergeSubscriber.fSubscriber)
            g.subscribe(mergeSubscriber.gSubscriber)
        }
        
        public func merge<P: Publisher>(with other: P) -> Publishers.Merge8<A, B, C, D, E, F, G, P> {
            Publishers.Merge8(a, b, c, d, e, f, g, other)
        }
    }
}

extension Publishers.Merge7 {
    
    // MARK: MERGE7 SINK
    private final class InternalSink<Downstream: Subscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var fSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var gSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func receiveSubscription() {
            receive(subscription: aSubscriber)
            receive(subscription: bSubscriber)
            receive(subscription: cSubscriber)
            receive(subscription: dSubscriber)
            receive(subscription: eSubscriber)
            receive(subscription: fSubscriber)
            receive(subscription: gSubscriber)
        }
        
        override func sendRequest() {
            request(.unlimited)
            aSubscriber.request(.unlimited)
            bSubscriber.request(.unlimited)
            cSubscriber.request(.unlimited)
            dSubscriber.request(.unlimited)
            eSubscriber.request(.unlimited)
            fSubscriber.request(.unlimited)
            gSubscriber.request(.unlimited)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            switch completion {
            case .finished:
                if aSubscriber.isOver && bSubscriber.isOver &&
                    cSubscriber.isOver && dSubscriber.isOver &&
                    eSubscriber.isOver && fSubscriber.isOver &&
                    gSubscriber.isOver {
                    
                    downstream?.receive(completion: .finished)
                }
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
