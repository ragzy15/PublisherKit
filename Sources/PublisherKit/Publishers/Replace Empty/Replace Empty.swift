//
//  Replace Empty.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/11/19.
//

public extension Publishers {
    
    /// A publisher that replaces an empty stream with a provided element.
    struct ReplaceEmpty<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The element to deliver when the upstream publisher finishes without delivering any elements.
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

extension Publishers.ReplaceEmpty: Equatable where Upstream : Equatable, Upstream.Output: Equatable {
    
}

extension Publishers.ReplaceEmpty {
    
    // MARK: REPLACE EMPTY SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        private let lock = Lock()
        private var inputReceived = false
        private var terminated = false
        private var downstreamDemandReceived = false
        
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
            inputReceived = true
            lock.unlock()
            
            return downstream?.receive(input) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            
            if inputReceived {
                lock.unlock()
                downstream?.receive(completion: completion)
                return
            }
            
            switch completion {
            case .finished:
                if downstreamDemandReceived {
                    lock.unlock()
                    _ = downstream?.receive(output)
                    downstream?.receive(completion: .finished)
                } else {
                    terminated = true
                    lock.unlock()
                }
                
            case .failure(let error):
                lock.unlock()
                downstream?.receive(completion: .failure(error))
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
            downstreamDemandReceived = true
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
            "ReplaceEmpty"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
