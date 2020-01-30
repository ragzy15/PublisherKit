//
//  Merge5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the merge function to five upstream publishers.
    public struct Merge5<A: PKPublisher, B: PKPublisher, C: PKPublisher, D: PKPublisher, E: PKPublisher> : PKPublisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure {
        
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
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = InternalSink(downstream: subscriber)
            
            mergeSubscriber.receiveSubscription()
            
            subscriber.receive(subscription: mergeSubscriber)
            
            mergeSubscriber.sendRequest()
            
            a.subscribe(mergeSubscriber.aSubscriber)
            b.subscribe(mergeSubscriber.bSubscriber)
            c.subscribe(mergeSubscriber.cSubscriber)
            d.subscribe(mergeSubscriber.dSubscriber)
            e.subscribe(mergeSubscriber.eSubscriber)
        }
        
        public func merge<P: PKPublisher>(with other: P) -> PKPublishers.Merge6<A, B, C, D, E, P> {
            PKPublishers.Merge6(a, b, c, d, e, other)
        }
        
        public func merge<P: PKPublisher, Q: PKPublisher>(with p: P, _ q: Q) -> PKPublishers.Merge7<A, B, C, D, E, P, Q> {
            PKPublishers.Merge7(a, b, c, d, e, p, q)
        }
        
        public func merge<P: PKPublisher, Q: PKPublisher, R: PKPublisher>(with p: P, _ q: Q, _ r: R) -> PKPublishers.Merge8<A, B, C, D, E, P, Q, R> {
            PKPublishers.Merge8(a, b, c, d, e, p, q, r)
        }
    }
}

extension PKPublishers.Merge5 {
    
    // MARK: MERGE5 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func receiveSubscription() {
            receive(subscription: aSubscriber)
            receive(subscription: bSubscriber)
            receive(subscription: cSubscriber)
            receive(subscription: dSubscriber)
            receive(subscription: eSubscriber)
        }
        
        override func sendRequest() {
            request(.unlimited)
            aSubscriber.request(.unlimited)
            bSubscriber.request(.unlimited)
            cSubscriber.request(.unlimited)
            dSubscriber.request(.unlimited)
            eSubscriber.request(.unlimited)
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            switch completion {
            case .finished:
                if aSubscriber.isOver && bSubscriber.isOver && cSubscriber.isOver && dSubscriber.isOver && eSubscriber.isOver {
                    downstream?.receive(completion: .finished)
                }
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
