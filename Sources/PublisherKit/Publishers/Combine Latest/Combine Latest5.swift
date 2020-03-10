//
//  Combine Latest5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
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
            
            let combineLatestSubscriber = Inner(downstream: subscriber)
            subscriber.receive(subscription: combineLatestSubscriber)
            
            e.subscribe(combineLatestSubscriber.eSubscriber)
            d.subscribe(combineLatestSubscriber.dSubscriber)
            c.subscribe(combineLatestSubscriber.cSubscriber)
            b.subscribe(combineLatestSubscriber.bSubscriber)
            a.subscribe(combineLatestSubscriber.aSubscriber)
        }
    }
}

extension Publishers.CombineLatest5: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable {
    
}

extension Publishers.CombineLatest5 {
    
    // MARK: COMBINELATEST5 SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.InternalCombine<Downstream> where Output == Downstream.Input {
        
        private(set) lazy var aSubscriber = Subscribers.InternalClosure<Inner, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.InternalClosure<Inner, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.InternalClosure<Inner, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = Subscribers.InternalClosure<Inner, D.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = Subscribers.InternalClosure<Inner, E.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutput: A.Output?
        private var bOutput: B.Output?
        private var cOutput: C.Output?
        private var dOutput: D.Output?
        private var eOutput: E.Output?
        
        private func receive(a input: A.Output, downstream: Inner?) {
            getLock().lock()
            aOutput = input
            checkAndSend()
        }
        
        private func receive(b input: B.Output, downstream: Inner?) {
            getLock().lock()
            bOutput = input
            checkAndSend()
        }
        
        private func receive(c input: C.Output, downstream: Inner?) {
            getLock().lock()
            cOutput = input
            checkAndSend()
        }
        
        private func receive(d input: D.Output, downstream: Inner?) {
            getLock().lock()
            dOutput = input
            checkAndSend()
        }
        
        private func receive(e input: E.Output, downstream: Inner?) {
            getLock().lock()
            eOutput = input
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard let aOutput = aOutput, let bOutput = bOutput, let cOutput = cOutput, let dOutput = dOutput, let eOutput = eOutput else {
                getLock().unlock()
                return
            }
            
            getLock().unlock()
            
            _ = receive((aOutput, bOutput, cOutput, dOutput, eOutput))
        }
        
        override var allSubscriptionsHaveTerminated: Bool {
            aSubscriber.status.isTerminated && bSubscriber.status.isTerminated &&
            cSubscriber.status.isTerminated && dSubscriber.status.isTerminated &&
            eSubscriber.status.isTerminated
        }
        
        override var description: String {
            "CombineLatest5"
        }
    }
}
