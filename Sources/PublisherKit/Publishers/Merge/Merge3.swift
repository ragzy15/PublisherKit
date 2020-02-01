//
//  Merge3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the merge function to three upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge3<A: PKPublisher, B: PKPublisher, C: PKPublisher>: PKPublisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure {
        
        public typealias Output = A.Output
        
        public typealias Failure = A.Failure
        
        /// A publisher.
        public let a: A
        
        /// A second publisher.
        public let b: B
        
        /// A third publisher.
        public let c: C
        
        public init(_ a: A, _ b: B, _ c: C) {
            self.a = a
            self.b = b
            self.c = c
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = InternalSink(downstream: subscriber)
            
            a.subscribe(mergeSubscriber.aSubscriber)
            b.subscribe(mergeSubscriber.bSubscriber)
            c.subscribe(mergeSubscriber.cSubscriber)
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

extension PKPublishers.Merge3 {
    
    // MARK: MERGE3 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            switch completion {
            case .finished:
                if aSubscriber.isOver && bSubscriber.isOver && cSubscriber.isOver {
                    downstream?.receive(completion: .finished)
                }
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
