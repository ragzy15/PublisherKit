//
//  Merge.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher created by applying the merge function to two upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge<A: Publisher, B: Publisher>: Publisher where A.Output == B.Output, A.Failure == B.Failure {
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = Inner(downstream: subscriber)
            
            b.subscribe(mergeSubscriber.bSubscriber)
            a.subscribe(mergeSubscriber.aSubscriber)
        }
        
        public func merge<P: Publisher>(with other: P) -> Publishers.Merge3<A, B, P> {
            Publishers.Merge3(a, b, other)
        }
        
        public func merge<P: Publisher, Q: Publisher>(with p: P, _ q: Q) -> Publishers.Merge4<A, B, P, Q> {
            Publishers.Merge4(a, b, p, q)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher>(with p: P, _ q: Q, _ r: R) -> Publishers.Merge5<A, B, P, Q, R> {
            Publishers.Merge5(a, b, p, q, r)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher, S: Publisher>(with p: P, _ q: Q, _ r: R, _ s: S) -> Publishers.Merge6<A, B, P, Q, R, S> {
            Publishers.Merge6(a, b, p, q, r, s)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher, S: Publisher, T: Publisher>(with p: P, _ q: Q, _ r: R, _ s: S, _ t: T) -> Publishers.Merge7<A, B, P, Q, R, S, T> {
            Publishers.Merge7(a, b, p, q, r, s, t)
        }
        
        public func merge<P: Publisher, Q: Publisher, R: Publisher, S: Publisher, T: Publisher, U: Publisher>(with p: P, _ q: Q, _ r: R, _ s: S, _ t: T, _ u: U) -> Publishers.Merge8<A, B, P, Q, R, S, T, U> {
            Publishers.Merge8(a, b, p, q, r, s, t, u)
        }
    }
}

extension Publishers.Merge {
    
    // MARK: MERGE SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.InternalCombine<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.InternalClosure<Inner, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.InternalClosure<Inner, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            
            switch completion {
            case .finished:
                if aSubscriber.status.isTerminated && bSubscriber.status.isTerminated {
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
            "Merge"
        }
    }
}
