//
//  Merge.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    // MARK: MERGE
    
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
            let merged = _Merged(downstream: subscriber, upstreamCount: 2)
            a.subscribe(_Merged.Side(index: 0, merged: merged))
            b.subscribe(_Merged.Side(index: 1, merged: merged))
            subscriber.receive(subscription: merged)
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
    
    // MARK: MERGE3
    
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
            let merged = _Merged(downstream: subscriber, upstreamCount: 3)
            a.subscribe(_Merged.Side(index: 0, merged: merged))
            b.subscribe(_Merged.Side(index: 1, merged: merged))
            c.subscribe(_Merged.Side(index: 2, merged: merged))
            subscriber.receive(subscription: merged)
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
    
    // MARK: MERGE4
    
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
            let merged = _Merged(downstream: subscriber, upstreamCount: 4)
            a.subscribe(_Merged.Side(index: 0, merged: merged))
            b.subscribe(_Merged.Side(index: 1, merged: merged))
            c.subscribe(_Merged.Side(index: 2, merged: merged))
            d.subscribe(_Merged.Side(index: 3, merged: merged))
            subscriber.receive(subscription: merged)
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
    
    // MARK: MERGE5
    
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
            let merged = _Merged(downstream: subscriber, upstreamCount: 5)
            a.subscribe(_Merged.Side(index: 0, merged: merged))
            b.subscribe(_Merged.Side(index: 1, merged: merged))
            c.subscribe(_Merged.Side(index: 2, merged: merged))
            d.subscribe(_Merged.Side(index: 3, merged: merged))
            e.subscribe(_Merged.Side(index: 4, merged: merged))
            subscriber.receive(subscription: merged)
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
    
    // MARK: MERGE6
    
    /// A publisher created by applying the merge function to six upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge6<A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher, F: Publisher>: Publisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure, E.Output == F.Output, E.Failure == F.Failure {
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let merged = _Merged(downstream: subscriber, upstreamCount: 6)
            a.subscribe(_Merged.Side(index: 0, merged: merged))
            b.subscribe(_Merged.Side(index: 1, merged: merged))
            c.subscribe(_Merged.Side(index: 2, merged: merged))
            d.subscribe(_Merged.Side(index: 3, merged: merged))
            e.subscribe(_Merged.Side(index: 4, merged: merged))
            f.subscribe(_Merged.Side(index: 5, merged: merged))
            subscriber.receive(subscription: merged)
        }
        
        public func merge<P: Publisher>(with other: P) -> Publishers.Merge7<A, B, C, D, E, F, P> {
            Publishers.Merge7(a, b, c, d, e, f, other)
        }
        
        public func merge<P: Publisher, Q: Publisher>(with p: P, _ q: Q) -> Publishers.Merge8<A, B, C, D, E, F, P, Q> {
            Publishers.Merge8(a, b, c, d, e, f, p, q)
        }
    }
    
    // MARK: MERGE7
    
    /// A publisher created by applying the merge function to seven upstream publishers. Combines elements from all upstream publisher delivering an interleaved sequence of elements.
    public struct Merge7<A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher, F: Publisher, G: Publisher>: Publisher where A.Output == B.Output, A.Failure == B.Failure, B.Output == C.Output, B.Failure == C.Failure, C.Output == D.Output, C.Failure == D.Failure, D.Output == E.Output, D.Failure == E.Failure, E.Output == F.Output, E.Failure == F.Failure, F.Output == G.Output, F.Failure == G.Failure {
        
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
        
        public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
            self.g = g
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let merged = _Merged(downstream: subscriber, upstreamCount: 7)
            a.subscribe(_Merged.Side(index: 0, merged: merged))
            b.subscribe(_Merged.Side(index: 1, merged: merged))
            c.subscribe(_Merged.Side(index: 2, merged: merged))
            d.subscribe(_Merged.Side(index: 3, merged: merged))
            e.subscribe(_Merged.Side(index: 4, merged: merged))
            f.subscribe(_Merged.Side(index: 5, merged: merged))
            g.subscribe(_Merged.Side(index: 6, merged: merged))
            subscriber.receive(subscription: merged)
        }
        
        public func merge<P: Publisher>(with other: P) -> Publishers.Merge8<A, B, C, D, E, F, G, P> {
            Publishers.Merge8(a, b, c, d, e, f, g, other)
        }
    }
    
    // MARK: MERGE8
    
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
            let merged = _Merged(downstream: subscriber, upstreamCount: 8)
            a.subscribe(_Merged.Side(index: 0, merged: merged))
            b.subscribe(_Merged.Side(index: 1, merged: merged))
            c.subscribe(_Merged.Side(index: 2, merged: merged))
            d.subscribe(_Merged.Side(index: 3, merged: merged))
            e.subscribe(_Merged.Side(index: 4, merged: merged))
            f.subscribe(_Merged.Side(index: 5, merged: merged))
            g.subscribe(_Merged.Side(index: 6, merged: merged))
            h.subscribe(_Merged.Side(index: 7, merged: merged))
            subscriber.receive(subscription: merged)
        }
    }
    
    // MARK: MERGE MANY
    
    public struct MergeMany<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        public let publishers: [Upstream]
        
        private let publisherCount: Int
        
        public init(_ upstream: Upstream...) {
            publishers = upstream
            publisherCount = publishers.count
        }
        
        public init<S: Swift.Sequence>(_ upstream: S) where Upstream == S.Element {
            publishers = upstream.map { $0 }
            publisherCount = publishers.count
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let merged = _Merged(downstream: subscriber, upstreamCount: publishers.count)
            
            for (index, publisher) in publishers.enumerated() {
                publisher.subscribe(_Merged.Side(index: index, merged: merged))
            }
            
            subscriber.receive(subscription: merged)
        }
        
        public func merge(with other: Upstream) -> Publishers.MergeMany<Upstream> {
            Publishers.MergeMany(publishers + [other])
        }
    }
}


extension Publishers.Merge: Equatable where A: Equatable, B: Equatable { }

extension Publishers.Merge3: Equatable where A: Equatable, B: Equatable, C: Equatable { }

extension Publishers.Merge4: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable { }

extension Publishers.Merge5: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable { }

extension Publishers.Merge6: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable, F: Equatable { }

extension Publishers.Merge7: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable, F: Equatable, G: Equatable { }

extension Publishers.Merge8: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable, F: Equatable, G: Equatable, H: Equatable { }

extension Publishers.MergeMany: Equatable where Upstream: Equatable { }
