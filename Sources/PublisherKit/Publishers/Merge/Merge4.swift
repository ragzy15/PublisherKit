//
//  Merge4.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher created by applying the merge function to four upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge4<A: Publisher, B: Publisher, C: Publisher, D: Publisher>: Publisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure {
        
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
        
        public init(_ a: A, _ b: B, _ c: C, _ d: D) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
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
        }
        
        public func merge<P: Publisher>(with other: P) -> Publishers.Merge5<A, B, C, D, P> {
            Publishers.Merge5(a, b, c, d, other)
        }
        
        public func merge<P: Publisher, Q: Publisher>(with p: P, _ q: Q) -> Publishers.Merge6<A, B, C, D, P, Q> {
            Publishers.Merge6(a, b, c, d, p, q)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher>(with p: P, _ q: Q, _ r: R) -> Publishers.Merge7<A, B, C, D, P, Q, R> {
            Publishers.Merge7(a, b, c, d, p, q, r)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher, S: Publisher>(with p: P, _ q: Q, _ r: R, _ s: S) -> Publishers.Merge8<A, B, C, D, P, Q, R, S> {
            Publishers.Merge8(a, b, c, d, p, q, r, s)
        }
    }
}

extension Publishers.Merge4 {
    
    // MARK: MERGE4 SINK
    private final class InternalSink<Downstream: Subscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = Subscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func receiveSubscription() {
            receive(subscription: aSubscriber)
            receive(subscription: bSubscriber)
            receive(subscription: cSubscriber)
            receive(subscription: dSubscriber)
        }
        
        override func sendRequest() {
            request(.unlimited)
            aSubscriber.request(.unlimited)
            bSubscriber.request(.unlimited)
            cSubscriber.request(.unlimited)
            dSubscriber.request(.unlimited)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            switch completion {
            case .finished:
                if aSubscriber.isOver && bSubscriber.isOver && cSubscriber.isOver && dSubscriber.isOver {
                    downstream?.receive(completion: .finished)
                }
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
