//
//  Merge.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the merge function to two upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge<A: PKPublisher, B: PKPublisher>: PKPublisher where A.Output == B.Output, A.Failure == B.Failure {
        
        public typealias Output = A.Output
        
        public typealias Failure = A.Failure
        
        /// A publisher.
        public let a: A
        
        /// A second publisher.
        public let b: B
        
        public init(_ a: A, _ b: B) {
            self.a = a
            self.b = b
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = InternalSink(downstream: subscriber)
            
            mergeSubscriber.receiveSubscription()
            
            subscriber.receive(subscription: mergeSubscriber)
            
            mergeSubscriber.sendRequest()
            
            b.subscribe(mergeSubscriber.bSubscriber)
            a.subscribe(mergeSubscriber.aSubscriber)
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

extension PKPublishers.Merge {
    
    // MARK: MERGE SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.FinalOperatorSink<CombineSink<Downstream>, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func receiveSubscription() {
            receive(subscription: aSubscriber)
            receive(subscription: bSubscriber)
        }
        
        override func sendRequest() {
            request(.unlimited)
            aSubscriber.request(.unlimited)
            bSubscriber.request(.unlimited)
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            switch completion {
            case .finished:
                if aSubscriber.isOver && bSubscriber.isOver {
                    downstream?.receive(completion: .finished)
                }
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
        }
    }
}
