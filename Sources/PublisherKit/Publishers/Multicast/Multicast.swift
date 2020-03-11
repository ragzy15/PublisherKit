//
//  Multicast.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

extension Publishers {
    
    /// A publisher that uses a subject to deliver elements to multiple subscribers.
    final public class Multicast<Upstream: Publisher, SubjectType: Subject>: ConnectablePublisher where Upstream.Output == SubjectType.Output, Upstream.Failure == SubjectType.Failure {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        final public let upstream: Upstream
        
        /// A closure to create a new Subject each time a subscriber attaches to the multicast publisher.
        final public let createSubject: () -> SubjectType
        
        private var _subject: SubjectType?
        
        private var subject: SubjectType {
            lock.lock()
            if let subject = _subject {
                return subject
            }
            
            let subject = createSubject()
            _subject = subject
            lock.unlock()
            
            return subject
        }
        
        private let lock = Lock()
        
        /// Creates a multicast publisher that applies a closure to create a subject that delivers elements to subscribers.
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        /// - Parameter createSubject: A closure to create a new Subject each time a subscriber attaches to the multicast publisher.
        public init(upstream: Upstream, createSubject: @escaping () -> SubjectType) {
            self.upstream = upstream
            self.createSubject = createSubject
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            subject.subscribe(Inner(downstream: subscriber))
        }
        
        final public func connect() -> Cancellable {
            upstream.subscribe(subject)
        }
    }
}

extension Publishers.Multicast {
    
    // MARK: MULTICAST SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.Inner<Downstream, Upstream.Output, Upstream.Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        override var description: String {
            "Multicast"
        }
    }
}
