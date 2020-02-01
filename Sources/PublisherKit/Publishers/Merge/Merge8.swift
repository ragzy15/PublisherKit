//
//  Merge8.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the merge function to eight upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge8<A: PKPublisher, B: PKPublisher, C: PKPublisher, D: PKPublisher, E: PKPublisher, F: PKPublisher, G: PKPublisher, H: PKPublisher>: PKPublisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure, E.Output == F.Output, E.Failure == F.Failure, F.Output == G.Output, F.Failure == G.Failure, G.Output == H.Output, G.Failure == H.Failure {
        
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
        
        /// An eighth publisher.
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
            f.subscribe(mergeSubscriber.fSubscriber)
            g.subscribe(mergeSubscriber.gSubscriber)
            h.subscribe(mergeSubscriber.gSubscriber)
        }
    }
}

extension PKPublishers.Merge8 {
    
    // MARK: MERGE8 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var fSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var gSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var hSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func receiveSubscription() {
            receive(subscription: aSubscriber)
            receive(subscription: bSubscriber)
            receive(subscription: cSubscriber)
            receive(subscription: dSubscriber)
            receive(subscription: eSubscriber)
            receive(subscription: fSubscriber)
            receive(subscription: gSubscriber)
            receive(subscription: hSubscriber)
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
            hSubscriber.request(.unlimited)
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            switch completion {
            case .finished:
                if aSubscriber.isOver && bSubscriber.isOver &&
                    cSubscriber.isOver && dSubscriber.isOver &&
                    eSubscriber.isOver && fSubscriber.isOver &&
                    gSubscriber.isOver && hSubscriber.isOver {
                    
                    downstream?.receive(completion: .finished)
                }
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
