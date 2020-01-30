//
//  Combine Latest.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers {
    
    /// A publisher that receives and combines the latest elements from two publishers.
    public struct CombineLatest<A: PKPublisher, B: PKPublisher>: PKPublisher where A.Failure == B.Failure {
        
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
            
            let combineLatestSubscriber = InternalSink(downstream: subscriber)
            
            combineLatestSubscriber.receiveSubscription()
            
            subscriber.receive(subscription: combineLatestSubscriber)
            
            combineLatestSubscriber.sendRequest()
            
            b.subscribe(combineLatestSubscriber.bSubscriber)
            a.subscribe(combineLatestSubscriber.aSubscriber)
        }
    }
}

extension PKPublishers.CombineLatest: Equatable where A: Equatable, B: Equatable{
    
    public static func == (lhs: PKPublishers.CombineLatest<A, B>, rhs: PKPublishers.CombineLatest<A, B>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}

extension PKPublishers.CombineLatest {
    
    // MARK: COMBINELATEST SINK
    private final class InternalSink<Downstream: PKSubscriber>: CombineSink<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = PKSubscribers.FinalOperatorSink<InternalSink, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutput: A.Output?
        private var bOutput: B.Output?
        
        override func receiveSubscription() {
            receive(subscription: aSubscriber)
            receive(subscription: bSubscriber)
        }
        
        override func sendRequest() {
            request(.unlimited)
            aSubscriber.request(.unlimited)
            bSubscriber.request(.unlimited)
        }
        
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
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
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
