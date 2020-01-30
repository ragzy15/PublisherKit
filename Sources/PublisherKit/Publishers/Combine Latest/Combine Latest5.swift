//
//  Combine Latest5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher created by applying the zip function to two upstream publishers.
    public struct CombineLatest5<A: PKPublisher, B: PKPublisher, C: PKPublisher, D: PKPublisher, E: PKPublisher>: PKPublisher where A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure, D.Failure == E.Failure {
        
        public typealias Output = (A.Output, B.Output, C.Output, D.Output, E.Output)
        
        public typealias Failure = A.Failure
        
        public let a: A
        
        public let b: B
        
        public let c: C
        
        public let d: D
        
        public let e: E
        
        public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let combineLatestSubscriber = InternalSink(downstream: subscriber)
            
            combineLatestSubscriber.receiveSubscription()
            
            subscriber.receive(subscription: combineLatestSubscriber)
            
            combineLatestSubscriber.sendRequest()
            
            e.subscribe(combineLatestSubscriber.eSubscriber)
            d.subscribe(combineLatestSubscriber.dSubscriber)
            c.subscribe(combineLatestSubscriber.cSubscriber)
            b.subscribe(combineLatestSubscriber.bSubscriber)
            a.subscribe(combineLatestSubscriber.aSubscriber)
        }
    }
}

extension PKPublishers.CombineLatest5: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable, E: Equatable {
    
    public static func == (lhs: PKPublishers.CombineLatest5<A, B, C, D, E>, rhs: PKPublishers.CombineLatest5<A, B, C, D, E>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d && lhs.e == rhs.e
    }
}

extension PKPublishers.CombineLatest5 {
    
    // MARK: COMBINELATEST5 SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var cSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, C.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var dSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, D.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var eSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, E.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutput: A.Output?
        private var bOutput: B.Output?
        private var cOutput: C.Output?
        private var dOutput: D.Output?
        private var eOutput: E.Output?
        
        override func receiveSubscription() {
            receive(subscription: aSubscriber)
            receive(subscription: bSubscriber)
            receive(subscription: cSubscriber)
            receive(subscription: dSubscriber)
            receive(subscription: eSubscriber)
        }
        
        override func sendRequest() {
            request(.unlimited)
            aSubscriber.request(.unlimited)
            bSubscriber.request(.unlimited)
            cSubscriber.request(.unlimited)
            dSubscriber.request(.unlimited)
            eSubscriber.request(.unlimited)
        }
        
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
        
        private func receive(d input: D.Output, downstream: InternalSink?) {
            dOutput = input
            checkAndSend()
        }
        
        private func receive(e input: E.Output, downstream: InternalSink?) {
            eOutput = input
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard let aOutput = aOutput, let bOutput = bOutput, let cOutput = cOutput, let dOutput = dOutput, let eOutput = eOutput else {
                return
            }
            
            receive(input: (aOutput, bOutput, cOutput, dOutput, eOutput))
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            if let error = completion.getError() {
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            if aSubscriber.isOver && bSubscriber.isOver && cSubscriber.isOver && dSubscriber.isOver && eSubscriber.isOver {
                end()
                downstream?.receive(completion: .finished)
            }
        }
    }
}
