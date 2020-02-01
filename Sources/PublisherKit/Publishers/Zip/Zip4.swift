//
//  Zip4.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the zip function to four upstream publishers.
    public struct Zip4<A: PKPublisher, B: PKPublisher, C: PKPublisher, D: PKPublisher>: PKPublisher where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure {
        
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
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let zipSubscriber = InternalSink(downstream: subscriber)
            
            d.subscribe(zipSubscriber.dSubscriber)
            c.subscribe(zipSubscriber.cSubscriber)
            b.subscribe(zipSubscriber.bSubscriber)
            a.subscribe(zipSubscriber.aSubscriber)
        }
    }
}

extension PKPublishers.Zip4: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable {
    
    public static func == (lhs: PKPublishers.Zip4<A, B, C, D>, rhs: PKPublishers.Zip4<A, B, C, D>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d
    }
}

extension PKPublishers.Zip4 {
    
    // MARK: ZIP4 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, D.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutputs: [A.Output] = []
        private var bOutputs: [B.Output] = []
        private var cOutputs: [C.Output] = []
        private var dOutputs: [D.Output] = []
        
        private func receive(a input: A.Output, downstream: CombineSink<Downstream>?) {
            aOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(b input: B.Output, downstream: CombineSink<Downstream>?) {
            bOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(c input: C.Output, downstream: CombineSink<Downstream>?) {
            cOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(d input: D.Output, downstream: CombineSink<Downstream>?) {
            dOutputs.append(input)
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard !aOutputs.isEmpty, !bOutputs.isEmpty, !cOutputs.isEmpty, !dOutputs.isEmpty else {
                return
            }
            
            let aOutput = aOutputs.removeFirst()
            let bOutput = bOutputs.removeFirst()
            let cOutput = cOutputs.removeFirst()
            let dOutput = dOutputs.removeFirst()
            
            receive(input: (aOutput, bOutput, cOutput, dOutput))
        }
    }
}
