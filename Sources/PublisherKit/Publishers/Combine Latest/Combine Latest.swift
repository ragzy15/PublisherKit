//
//  Combine Latest.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that receives and combines the latest elements from two publishers.
    public struct CombineLatest<A: Publisher, B: Publisher>: Publisher where A.Failure == B.Failure {
        
        public typealias Output = (A.Output, B.Output)
        
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
            let abstractCombineLatest = AbstractCombineLatest(downstream: subscriber, upstreamCount: 2)
            a.subscribe(AbstractCombineLatest.Side(index: 0, abstractCombineLatest: abstractCombineLatest))
            b.subscribe(AbstractCombineLatest.Side(index: 1, abstractCombineLatest: abstractCombineLatest))
            subscriber.receive(subscription: abstractCombineLatest)
        }
    }
    
    /// A publisher that receives and combines the latest elements from three publishers.
    public struct CombineLatest3<A: Publisher, B: Publisher, C: Publisher>: Publisher where A.Failure == B.Failure, B.Failure == C.Failure {
        
        public typealias Output = (A.Output, B.Output, C.Output)
        
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
            let abstractCombineLatest = AbstractCombineLatest(downstream: subscriber, upstreamCount: 3)
            a.subscribe(AbstractCombineLatest.Side(index: 0, abstractCombineLatest: abstractCombineLatest))
            b.subscribe(AbstractCombineLatest.Side(index: 1, abstractCombineLatest: abstractCombineLatest))
            c.subscribe(AbstractCombineLatest.Side(index: 2, abstractCombineLatest: abstractCombineLatest))
            subscriber.receive(subscription: abstractCombineLatest)
        }
    }
    /// A publisher that receives and combines the latest elements from four publishers.
    public struct CombineLatest4<A: Publisher, B: Publisher, C: Publisher, D: Publisher>: Publisher where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure {
        
        public typealias Output = (A.Output, B.Output, C.Output, D.Output)
        
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
            let abstractCombineLatest = AbstractCombineLatest(downstream: subscriber, upstreamCount: 4)
            a.subscribe(AbstractCombineLatest.Side(index: 0, abstractCombineLatest: abstractCombineLatest))
            b.subscribe(AbstractCombineLatest.Side(index: 1, abstractCombineLatest: abstractCombineLatest))
            c.subscribe(AbstractCombineLatest.Side(index: 2, abstractCombineLatest: abstractCombineLatest))
            d.subscribe(AbstractCombineLatest.Side(index: 3, abstractCombineLatest: abstractCombineLatest))
            subscriber.receive(subscription: abstractCombineLatest)
        }
    }
    /// A publisher that receives and combines the latest elements from five publishers.
    public struct CombineLatest5<A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher>: Publisher where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure, D.Failure == E.Failure {
        
        public typealias Output = (A.Output, B.Output, C.Output, D.Output, E.Output)
        
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
            let abstractCombineLatest = AbstractCombineLatest(downstream: subscriber, upstreamCount: 5)
            a.subscribe(AbstractCombineLatest.Side(index: 0, abstractCombineLatest: abstractCombineLatest))
            b.subscribe(AbstractCombineLatest.Side(index: 1, abstractCombineLatest: abstractCombineLatest))
            c.subscribe(AbstractCombineLatest.Side(index: 2, abstractCombineLatest: abstractCombineLatest))
            d.subscribe(AbstractCombineLatest.Side(index: 3, abstractCombineLatest: abstractCombineLatest))
            e.subscribe(AbstractCombineLatest.Side(index: 4, abstractCombineLatest: abstractCombineLatest))
            subscriber.receive(subscription: abstractCombineLatest)
        }
    }
}

extension Publishers.CombineLatest: Equatable where A: Equatable, B: Equatable { }

extension Publishers.CombineLatest3: Equatable where A: Equatable, B: Equatable, C: Equatable { }

extension Publishers.CombineLatest4: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable { }

extension Publishers.CombineLatest5: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable { }
