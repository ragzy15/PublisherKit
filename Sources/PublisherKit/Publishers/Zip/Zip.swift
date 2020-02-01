//
//  Zip.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the zip function to two upstream publishers.
    public struct Zip<A: PKPublisher, B: PKPublisher>: PKPublisher where A.Failure == B.Failure {
        
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
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let zipSubscriber = InternalSink(downstream: subscriber)
            
            b.subscribe(zipSubscriber.bSubscriber)
            a.subscribe(zipSubscriber.aSubscriber)
        }
    }
}

extension PKPublishers.Zip: Equatable where A: Equatable, B: Equatable{
    
    public static func == (lhs: PKPublishers.Zip<A, B>, rhs: PKPublishers.Zip<A, B>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}

extension PKPublishers.Zip {
    
    // MARK: ZIP SINK
    final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.ClosureOperatorSink<CombineSink<Downstream>, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutputs: [A.Output] = []
        private var bOutputs: [B.Output] = []
        
        private func receive(a input: A.Output, downstream: CombineSink<Downstream>?) {
            aOutputs.append(input)
            checkAndSend()
        }
        
        private func receive(b input: B.Output, downstream: CombineSink<Downstream>?) {
            bOutputs.append(input)
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard !aOutputs.isEmpty, !bOutputs.isEmpty else {
                return
            }
            
            let aOutput = aOutputs.removeFirst()
            let bOutput = bOutputs.removeFirst()
            
            receive(input: (aOutput, bOutput))
        }
    }
}
