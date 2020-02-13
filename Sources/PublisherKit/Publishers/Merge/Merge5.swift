//
//  Merge5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher created by applying the merge function to five upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge5<A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher> : Publisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure {
        
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
        
        public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = Inner(downstream: subscriber)
            
            a.subscribe(mergeSubscriber.aSubscriber)
            b.subscribe(mergeSubscriber.bSubscriber)
            c.subscribe(mergeSubscriber.cSubscriber)
            d.subscribe(mergeSubscriber.dSubscriber)
            e.subscribe(mergeSubscriber.eSubscriber)
        }
        
        public func merge<P: Publisher>(with other: P) -> Publishers.Merge6<A, B, C, D, E, P> {
            Publishers.Merge6(a, b, c, d, e, other)
        }
        
        public func merge<P: Publisher, Q: Publisher>(with p: P, _ q: Q) -> Publishers.Merge7<A, B, C, D, E, P, Q> {
            Publishers.Merge7(a, b, c, d, e, p, q)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher>(with p: P, _ q: Q, _ r: R) -> Publishers.Merge8<A, B, C, D, E, P, Q, R> {
            Publishers.Merge8(a, b, c, d, e, p, q, r)
        }
    }
}

extension Publishers.Merge5 {
    
    // MARK: MERGE5 SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.InternalCombine<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            
            switch completion {
            case .finished:
                if aSubscriber.status.isTerminated && bSubscriber.status.isTerminated &&
                    cSubscriber.status.isTerminated && dSubscriber.status.isTerminated &&
                    eSubscriber.status.isTerminated {
                    
                    end {
                        downstream?.receive(completion: .finished)
                    }
                }
                
            case .failure(let error):
                end {
                    downstream?.receive(completion: .failure(error))
                }
            }
        }
        
        override var description: String {
            "Merge5"
        }
    }
}
