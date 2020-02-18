//
//  Merge8.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher created by applying the merge function to eight upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge8<A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher, F: Publisher, G: Publisher, H: Publisher>: Publisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure, E.Output == F.Output, E.Failure == F.Failure, F.Output == G.Output, F.Failure == G.Failure, G.Output == H.Output, G.Failure == H.Failure {
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = Inner(downstream: subscriber)
            
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

extension Publishers.Merge8 {
    
    // MARK: MERGE8 SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.InternalCombine<Downstream> where Output == Downstream.Input {
        
        private(set) lazy var aSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var fSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var gSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var hSubscriber = Subscribers.InternalClosure<Inner, Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        override var allSubscriptionsHaveTerminated: Bool {
            aSubscriber.status.isTerminated && bSubscriber.status.isTerminated &&
            cSubscriber.status.isTerminated && dSubscriber.status.isTerminated &&
            eSubscriber.status.isTerminated && fSubscriber.status.isTerminated &&
            gSubscriber.status.isTerminated && hSubscriber.status.isTerminated
        }
        
        override var description: String {
            "Merge8"
        }
    }
}
