//
//  Combine Latest3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
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
            
            let combineLatestSubscriber = InternalSink(downstream: subscriber)
            
            c.subscribe(combineLatestSubscriber.cSubscriber)
            b.subscribe(combineLatestSubscriber.bSubscriber)
            a.subscribe(combineLatestSubscriber.aSubscriber)
        }
    }
}

extension Publishers.CombineLatest3: Equatable where A: Equatable, B: Equatable, C: Equatable {
    
    public static func == (lhs: Publishers.CombineLatest3<A, B, C>, rhs: Publishers.CombineLatest3<A, B, C>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}

extension Publishers.CombineLatest3 {
    
    // MARK: COMBINELATEST3 SINK
    private final class InternalSink<Downstream: Subscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.ClosureOperatorSink<InternalSink, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.ClosureOperatorSink<InternalSink, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = Subscribers.ClosureOperatorSink<InternalSink, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutput: A.Output?
        private var bOutput: B.Output?
        private var cOutput: C.Output?
        
        private func receive(a input: A.Output, downstream: InternalSink?) {
            aOutput = input
            checkAndSend()
        }
        
        private func receive(b input: B.Output, downstream: InternalSink?) {
            bOutput = input
            checkAndSend()
        }
        
        private func receive(c input: C.Output, downstream: InternalSink?) {
            cOutput = input
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard let aOutput = aOutput, let bOutput = bOutput, let cOutput = cOutput else {
                return
            }
            
            receive(input: (aOutput, bOutput, cOutput))
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            if let error = completion.getError() {
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            if aSubscriber.isOver && bSubscriber.isOver && cSubscriber.isOver {
                end()
                downstream?.receive(completion: .finished)
            }
        }
    }
}
