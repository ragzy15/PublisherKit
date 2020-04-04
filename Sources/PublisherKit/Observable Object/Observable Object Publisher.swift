//
//  Observable Object Publisher.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 29/03/20.
//

/// The default publisher of an `ObservableObject`.
final public class ObservableObjectPublisher: Publisher {
    
    public typealias Output = Void
    
    public typealias Failure = Never
    
    private let lock = Lock()

    private var connections = Set<Conduit>()
    
    public init() { }
    
    final public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        let inner = Inner(downstream: subscriber, parent: self)
        
        lock.lock()
        connections.insert(inner)
        lock.unlock()
        
        subscriber.receive(subscription: inner)
    }
    
    final public func send() {
        lock.lock()
        let connections = self.connections
        lock.unlock()
        
        connections.forEach { (connection) in
            connection.send()
        }
    }
    
    private func remove(_ conduit: Conduit) {
        lock.lock()
        connections.remove(conduit)
        lock.unlock()
    }
}

extension ObservableObjectPublisher {
    
    private class Conduit: Hashable {
        
        func send() {
            /* abstract method to be overrided by Inner subclass. */
        }
        
        static func == (lhs: Conduit, rhs: Conduit) -> Bool {
            return lhs === rhs
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }
    }
    
    private final class Inner<Downstream: Subscriber>: Conduit, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let downstream: Downstream
        private var parent: ObservableObjectPublisher?
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        private enum State {
            case awaiting
            case subscribed
            case terminated
        }
        
        private var state: State = .awaiting
        
        init(downstream: Downstream, parent: ObservableObjectPublisher) {
            self.downstream = downstream
            self.parent = parent
        }
        
        override func send() {
            lock.lock()
            let state = self.state
            lock.unlock()
            
            guard state == .subscribed else { return }
            
            downstreamLock.lock()
            _ = downstream.receive()
            downstreamLock.unlock()
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard state == .awaiting else { lock.unlock(); return }
            state = .subscribed
            lock.unlock()
        }

        func cancel() {
            lock.lock()
            state = .terminated
            lock.unlock()
            
            parent?.remove(self)
            parent = nil
        }
        
        var description: String {
            "ObservableObjectPublisher"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("downstream", downstream)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
