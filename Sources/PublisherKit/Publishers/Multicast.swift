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
            subject.subscribe(Inner(downstream: subscriber, upstream: upstream))
        }
        
        final public func connect() -> Cancellable {
            upstream.subscribe(subject)
        }
    }
}

extension Publishers.Multicast {
    
    // MARK: MULTICAST SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private enum SubscriptionStatus {
            case awaiting(upstream: Upstream, downstream: Downstream)
            case subscribed(upstream: Upstream, downstream: Downstream, subscription: Subscription)
            case terminated
        }
        
        private var status: SubscriptionStatus
        
        private let lock = Lock()
        
        init(downstream: Downstream, upstream: Upstream) {
            status = .awaiting(upstream: upstream, downstream: downstream)
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard case .awaiting(let upstream, let downstream) = status else { lock.unlock(); return }
            status = .subscribed(upstream: upstream, downstream: downstream, subscription: subscription)
            lock.unlock()
            
            downstream.receive(subscription: self)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed(_, let downstream, let subscription) = status else { lock.unlock(); return .none }
            lock.unlock()
            
            let newDemand = downstream.receive(input)
            if newDemand > 0 {
                subscription.request(newDemand)
            }
            
            return newDemand
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard case .subscribed(_, let downstream, _) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            downstream.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "Multicast"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
