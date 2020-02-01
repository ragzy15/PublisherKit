//
//  Merge6.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the merge function to six upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge6<A: PKPublisher, B: PKPublisher, C: PKPublisher, D: PKPublisher, E: PKPublisher, F: PKPublisher>: PKPublisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure, E.Output == F.Output, E.Failure == F.Failure {
        
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
        
        public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = InternalSink(downstream: subscriber)
            
            a.subscribe(mergeSubscriber.aSubscriber)
            b.subscribe(mergeSubscriber.bSubscriber)
            c.subscribe(mergeSubscriber.cSubscriber)
            d.subscribe(mergeSubscriber.dSubscriber)
            e.subscribe(mergeSubscriber.eSubscriber)
            f.subscribe(mergeSubscriber.fSubscriber)
        }
        
        public func merge<P: PKPublisher>(with other: P) -> PKPublishers.Merge7<A, B, C, D, E, F, P> {
            PKPublishers.Merge7(a, b, c, d, e, f, other)
        }
        
        public func merge<P: PKPublisher, Q: PKPublisher>(with p: P, _ q: Q) -> PKPublishers.Merge8<A, B, C, D, E, F, P, Q> {
            PKPublishers.Merge8(a, b, c, d, e, f, p, q)
        }
    }
}

extension PKPublishers.Merge6 {
    
    // MARK: MERGE6 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var fSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            switch completion {
            case .finished:
                if aSubscriber.isOver && bSubscriber.isOver && cSubscriber.isOver && dSubscriber.isOver && eSubscriber.isOver && fSubscriber.isOver {
                    downstream?.receive(completion: .finished)
                }
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
