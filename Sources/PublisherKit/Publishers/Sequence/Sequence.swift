//
//  Sequence.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Sequence {
    
    public var pkPublisher: Publishers.Sequence<Self, Never> {
        Publishers.Sequence(sequence: self)
    }
}

extension Publishers {
    
    /// A publisher that publishes a given sequence of elements.
    ///
    /// When the publisher exhausts the elements in the sequence, the next request causes the publisher to finish.
    public struct Sequence<Elements: Swift.Sequence, Failure: Error>: Publisher {
        
        public typealias Output = Elements.Element
        
        /// The sequence of elements to publish.
        public let sequence: Elements
        
        /// Creates a publisher for a sequence of elements.
        ///
        /// - Parameter sequence: The sequence of elements to publish.
        public init(sequence: Elements) {
            self.sequence = sequence
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            var iterator = sequence.makeIterator()
            
            if iterator.next() == nil {
                subscriber.receive(subscription: Subscriptions.empty)
                subscriber.receive(completion: .finished)
            } else {
                subscriber.receive(subscription: Inner(downstream: subscriber, sequence: sequence))
            }
        }
    }
}

extension Publishers.Sequence {
    
    // MARK: SEQUENCE SINK
    private final class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var sequence: Elements?
        private var iterator: Elements.Iterator
        private var nextElement: Elements.Element?
        
        private var downstream: Downstream?
        private let lock = Lock()
        private var downstreamDemand: Subscribers.Demand = .none
        
        private var isActive = false
        
        init(downstream: Downstream, sequence: Elements) {
            self.downstream = downstream
            self.sequence = sequence
            self.iterator = sequence.makeIterator()
            nextElement = iterator.next()
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard downstream != nil else { lock.unlock(); return }
            downstreamDemand += demand
            
            if isActive { lock.unlock(); return }
            
            while let downstream = downstream, downstreamDemand > .none {
                if let element = nextElement {
                    downstreamDemand -= 1
                    isActive = true
                    lock.unlock()
                    
                    let additionalDemand = downstream.receive(element)
                    
                    lock.lock()
                    downstreamDemand += additionalDemand
                    isActive = false
                    nextElement = iterator.next()
                } else if nextElement == nil {
                    self.downstream = nil
                    sequence = nil
                    lock.unlock()
                    
                    downstream.receive(completion: .finished)
                    return
                }
            }
            
            lock.unlock()
        }
        
        func cancel() {
            lock.lock()
            downstream = nil
            sequence = nil
            lock.unlock()
        }
        
        var description: String {
            sequence.map { "\($0)" } ?? "Sequence"
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [("sequence", sequence?.map { $0 } ?? [] )])
        }
    }
}
