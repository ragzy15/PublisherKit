//
//  Replace Error.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public extension Publishers {
    
    /// A publisher that replaces any errors in the stream with a provided element.
    struct ReplaceError<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Never
        
        /// The element with which to replace errors from the upstream publisher.
        public let output: Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream, output: Output) {
            self.upstream = upstream
            self.output = output
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, output: output))
        }
    }
}

extension Publishers.ReplaceError: Equatable where Upstream: Equatable, Upstream.Output: Equatable { }

extension Publishers.ReplaceError {
    
    // MARK: REPLACE ERROR SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        private let lock = Lock()
        private var pendingDemand: Subscribers.Demand = .none
        private var terminated = false
        
        private let output: Output
        
        init(downstream: Downstream, output: Output) {
            self.downstream = downstream
            self.output = output
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            
            downstream?.receive(subscription: self)
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            lock.unlock()
            
            return downstream?.receive(input) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            
            switch completion {
            case .finished:
                lock.unlock()
                downstream?.receive(completion: .finished)
                
            case .failure:
                guard pendingDemand > .none else {
                    terminated = true
                    lock.unlock()
                    return
                }
                lock.unlock()
                
                _ = downstream?.receive(output)
                downstream?.receive(completion: .finished)
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            
            if terminated {
                terminated = false
                lock.unlock()
                
                _ = downstream?.receive(output)
                downstream?.receive(completion: .finished)
                return
            }
            
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            pendingDemand += demand
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "ReplaceError"
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
