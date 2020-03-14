//
//  Merge4.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

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
            
            let mergeSubscriber = Inner(downstream: subscriber)
            
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

extension Publishers.Merge4: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable {
    
}

extension Publishers.Merge4 {
    
    // MARK: MERGE4 SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.InternalCombine<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override var allSubscriptionsHaveTerminated: Bool {
            aSubscriber.status.isTerminated && bSubscriber.status.isTerminated &&
            cSubscriber.status.isTerminated && dSubscriber.status.isTerminated
        }
        
        override var description: String {
            "Merge4"
        }
    }
}
