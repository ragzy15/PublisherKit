//
//  Merge3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher created by applying the merge function to three upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge3<A: Publisher, B: Publisher, C: Publisher>: Publisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure {
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = Inner(downstream: subscriber)
            subscriber.receive(subscription: mergeSubscriber)
            
            a.subscribe(mergeSubscriber.aSubscriber)
            b.subscribe(mergeSubscriber.bSubscriber)
            c.subscribe(mergeSubscriber.cSubscriber)
        }
        
        public func merge<P: Publisher>(with other: P) -> Publishers.Merge4<A, B, C, P> {
            Publishers.Merge4(a, b, c, other)
        }
        
        public func merge<P: Publisher, Q: Publisher>(with p: P, _ q: Q) -> Publishers.Merge5<A, B, C, P, Q> {
            Publishers.Merge5(a, b, c, p, q)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher>(with p: P, _ q: Q, _ r: R) -> Publishers.Merge6<A, B, C, P, Q, R> {
            Publishers.Merge6(a, b, c, p, q, r)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher, S: Publisher>(with p: P, _ q: Q, _ r: R, _ s: S) -> Publishers.Merge7<A, B, C, P, Q, R, S> {
            Publishers.Merge7(a, b, c, p, q, r, s)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher, S: Publisher, T: Publisher>(with p: P, _ q: Q, _ r: R, _ s: S, _ t: T) -> Publishers.Merge8<A, B, C, P, Q, R, S, T> {
            Publishers.Merge8(a, b, c, p, q, r, s, t)
        }
    }
}

extension Publishers.Merge3 {
    
    // MARK: MERGE3 SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.InternalCombine<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.InternalClosure<Inner, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.InternalClosure<Inner, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.InternalClosure<Inner, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override var allSubscriptionsHaveTerminated: Bool {
            aSubscriber.status.isTerminated && bSubscriber.status.isTerminated &&
            cSubscriber.status.isTerminated
        }
        
        override var description: String {
            "Merge3"
        }
    }
}
