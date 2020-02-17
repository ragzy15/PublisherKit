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
            
            let zipSubscriber = Inner(downstream: subscriber)
            
            b.subscribe(zipSubscriber.bSubscriber)
            a.subscribe(zipSubscriber.aSubscriber)
        }
    }
}

extension Publishers.Zip: Equatable where A: Equatable, B: Equatable{
    
    public static func == (lhs: Publishers.Zip<A, B>, rhs: Publishers.Zip<A, B>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}

extension Publishers.Zip {
    
    // MARK: ZIP SINK
    final class Inner<Downstream: Subscriber>: Subscribers.InternalCombine<Downstream> where Downstream.Input == Output {
        
        private(set) lazy var aSubscriber = Subscribers.InternalClosure<Inner, A.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private(set) lazy var bSubscriber = Subscribers.InternalClosure<Inner, B.Output, Failure>(downstream: self, receiveCompletion: receive, receiveValue: receive)
        
        private var aOutputs: [A.Output] = []
        private var bOutputs: [B.Output] = []
        
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
        
        override func checkAndSend() {
            guard !aOutputs.isEmpty, !bOutputs.isEmpty else {
                getLock().unlock()
                return
            }
            
            let aOutput = aOutputs.removeFirst()
            let bOutput = bOutputs.removeFirst()
            
            getLock().unlock()
            
            _ = receive((aOutput, bOutput))
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            end {
                downstream?.receive(completion: completion)
            }
        }
        
        override var description: String {
            "Zip"
        }
    }
}
