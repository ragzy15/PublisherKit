//
//  Zip.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

extension Publishers {
    
    /// A publisher created by applying the zip function to two upstream publishers.
    public struct Zip<A: Publisher, B: Publisher>: Publisher where A.Failure == B.Failure {
        
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
            let abstractZip = AbstractZip(downstream: subscriber, upstreamCount: 2)
            a.subscribe(AbstractZip.Side(index: 0, abstractZip: abstractZip))
            b.subscribe(AbstractZip.Side(index: 1, abstractZip: abstractZip))
            subscriber.receive(subscription: abstractZip)
        }
    }
    
    /// A publisher created by applying the zip function to three upstream publishers.
    public struct Zip3<A: Publisher, B: Publisher, C: Publisher>: Publisher where A.Failure == B.Failure, B.Failure == C.Failure {
        
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
            let abstractZip = AbstractZip(downstream: subscriber, upstreamCount: 3)
            a.subscribe(AbstractZip.Side(index: 0, abstractZip: abstractZip))
            b.subscribe(AbstractZip.Side(index: 1, abstractZip: abstractZip))
            c.subscribe(AbstractZip.Side(index: 2, abstractZip: abstractZip))
            subscriber.receive(subscription: abstractZip)
        }
    }
    
    /// A publisher created by applying the zip function to four upstream publishers.
    public struct Zip4<A: Publisher, B: Publisher, C: Publisher, D: Publisher>: Publisher where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure {
        
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
            let abstractZip = AbstractZip(downstream: subscriber, upstreamCount: 4)
            a.subscribe(AbstractZip.Side(index: 0, abstractZip: abstractZip))
            b.subscribe(AbstractZip.Side(index: 1, abstractZip: abstractZip))
            c.subscribe(AbstractZip.Side(index: 2, abstractZip: abstractZip))
            d.subscribe(AbstractZip.Side(index: 3, abstractZip: abstractZip))
            subscriber.receive(subscription: abstractZip)
        }
    }
    
    /// A publisher created by applying the zip function to five upstream publishers.
    public struct Zip5<A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher>: Publisher where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure, D.Failure == E.Failure {
        
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
            let abstractZip = AbstractZip(downstream: subscriber, upstreamCount: 5)
            a.subscribe(AbstractZip.Side(index: 0, abstractZip: abstractZip))
            b.subscribe(AbstractZip.Side(index: 1, abstractZip: abstractZip))
            c.subscribe(AbstractZip.Side(index: 2, abstractZip: abstractZip))
            d.subscribe(AbstractZip.Side(index: 3, abstractZip: abstractZip))
            e.subscribe(AbstractZip.Side(index: 4, abstractZip: abstractZip))
            subscriber.receive(subscription: abstractZip)
        }
    }
}

extension Publishers.Zip: Equatable where A: Equatable, B: Equatable { }

extension Publishers.Zip3: Equatable where A: Equatable, B: Equatable, C: Equatable { }

extension Publishers.Zip4: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable { }

extension Publishers.Zip5: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable { }
