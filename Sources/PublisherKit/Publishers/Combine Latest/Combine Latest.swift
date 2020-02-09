//
//  Combine Latest.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

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
            
            let combineLatestSubscriber = InternalSink(downstream: subscriber)
            
            b.subscribe(combineLatestSubscriber.bSubscriber)
            a.subscribe(combineLatestSubscriber.aSubscriber)
        }
    }
}

extension Publishers.CombineLatest: Equatable where A: Equatable, B: Equatable{
    
    public static func == (lhs: Publishers.CombineLatest<A, B>, rhs: Publishers.CombineLatest<A, B>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}

extension Publishers.CombineLatest {
    
    // MARK: COMBINELATEST SINK
    private final class InternalSink<Downstream: Subscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.ClosureOperatorSink<InternalSink, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.ClosureOperatorSink<InternalSink, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutput: A.Output?
        private var bOutput: B.Output?
        
        private func receive(a input: A.Output, downstream: InternalSink?) {
            aOutput = input
            checkAndSend()
        }
        
        private func receive(b input: B.Output, downstream: InternalSink?) {
            bOutput = input
            checkAndSend()
        }
        
        override func checkAndSend() {
            guard let aOutput = aOutput, let bOutput = bOutput else {
                return
            }
            
            receive(input: (aOutput, bOutput))
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            if let error = completion.getError() {
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            if aSubscriber.isOver && bSubscriber.isOver {
                end()
                downstream?.receive(completion: .finished)
            }
        }
    }
}
