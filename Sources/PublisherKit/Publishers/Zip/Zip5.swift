//
//  Zip5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
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
            
            let zipSubscriber = Inner(downstream: subscriber)
            
            e.subscribe(zipSubscriber.eSubscriber)
            d.subscribe(zipSubscriber.dSubscriber)
            c.subscribe(zipSubscriber.cSubscriber)
            b.subscribe(zipSubscriber.bSubscriber)
            a.subscribe(zipSubscriber.aSubscriber)
        }
    }
}

extension Publishers.Zip5: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable {
    
    public static func == (lhs: Publishers.Zip5<A, B, C, D, E>, rhs: Publishers.Zip5<A, B, C, D, E>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d && lhs.e == rhs.e
    }
}

extension Publishers.Zip5 {
    
    // MARK: ZIP5 SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.InternalCombine<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.InternalClosure<Inner, A.Output, Downstream.Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.InternalClosure<Inner, B.Output, Downstream.Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.InternalClosure<Inner, C.Output, Downstream.Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = Subscribers.InternalClosure<Inner, D.Output, Downstream.Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = Subscribers.InternalClosure<Inner, E.Output, Downstream.Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutputs: [A.Output] = []
        private var bOutputs: [B.Output] = []
        private var cOutputs: [C.Output] = []
        private var dOutputs: [D.Output] = []
        private var eOutputs: [E.Output] = []
        
        private func receive(a input: A.Output, downstream: Inner?) {
            getLock().lock()
            aOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(b input: B.Output, downstream: Inner?) {
            getLock().lock()
            bOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(c input: C.Output, downstream: Inner?) {
            getLock().lock()
            cOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(d input: D.Output, downstream: Inner?) {
            getLock().lock()
            dOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(e input: E.Output, downstream: Inner?) {
            getLock().lock()
            eOutputs.append(input)
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard !aOutputs.isEmpty, !bOutputs.isEmpty, !cOutputs.isEmpty, !dOutputs.isEmpty, !eOutputs.isEmpty else {
                getLock().unlock()
                return
            }
            
            let aOutput = aOutputs.removeFirst()
            let bOutput = bOutputs.removeFirst()
            let cOutput = cOutputs.removeFirst()
            let dOutput = dOutputs.removeFirst()
            let eOutput = eOutputs.removeFirst()
            
            getLock().unlock()
            
            _ = receive((aOutput, bOutput, cOutput, dOutput, eOutput))
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            end {
                downstream?.receive(completion: completion)
            }
        }
        
        override var description: String {
            "Zip5"
        }
    }
}
