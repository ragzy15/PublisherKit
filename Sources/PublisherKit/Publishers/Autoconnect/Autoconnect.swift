//
//  Autoconnect.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

extension Publishers {
    
    /// A publisher that automatically connects and disconnects from this connectable publisher.
    public class Autoconnect<Upstream: ConnectablePublisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        final public let upstream: Upstream
        
        private enum ConnectionState {
            case connected(count: Int, connection: Cancellable)
            case disconnected
        }
        
        private var state: ConnectionState = .disconnected
        private let lock = Lock()
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let inner = Inner(downstream: subscriber, parent: self)
            
            lock.lock()
            switch state {
            case .connected(let count, let connection):
                state = .connected(count: count + 1, connection: connection)
                lock.unlock()
                
                upstream.subscribe(inner)
                
            case .disconnected:
                lock.unlock()
                
                upstream.subscribe(inner)
                
                let connection = upstream.connect()
                lock.lock()
                state = .connected(count: 1, connection: connection)
                lock.unlock()
            }
        }
        
        fileprivate func cancel() {
            lock.lock()
            switch state {
            case .connected(let count, let connection):
                if count <= 1 {
                    state = .disconnected
                    lock.unlock()
                    connection.cancel()
                } else {
                    state = .connected(count: count - 1, connection: connection)
                }
                
            case .disconnected:
                lock.unlock()
            }
        }
    }
}

extension Publishers.Autoconnect {
    
    // MARK: AUTOCONNECT SINK
    private struct Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        private let parent: Publishers.Autoconnect<Upstream>
        let combineIdentifier: CombineIdentifier
        
        init(downstream: Downstream, parent: Publishers.Autoconnect<Upstream>) {
            self.downstream = downstream
            self.parent = parent
            combineIdentifier = CombineIdentifier()
        }
        
        func receive(subscription: Subscription) {
            downstream.receive(subscription: SideEffectSubscription(upstreamSubscription: subscription, parent: parent))
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            downstream.receive(input)
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            downstream.receive(completion: completion)
        }
        
        var description: String {
            "Autoconnect"
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
    
    private struct SideEffectSubscription: Subscription, CustomStringConvertible, CustomReflectable {
        
        private let upstreamSubscription: Subscription
        private let parent: Publishers.Autoconnect<Upstream>
        
        init(upstreamSubscription: Subscription, parent: Publishers.Autoconnect<Upstream>) {
            self.upstreamSubscription = upstreamSubscription
            self.parent = parent
        }
        
        var combineIdentifier: CombineIdentifier {
            upstreamSubscription.combineIdentifier
        }
        
        func request(_ demand: Subscribers.Demand) {
            upstreamSubscription.request(demand)
        }
        
        func cancel() {
            parent.cancel()
            upstreamSubscription.cancel()
        }
        
        var description: String { "" }
        var customMirror: Mirror { Mirror(self, children: []) }
    }
}
