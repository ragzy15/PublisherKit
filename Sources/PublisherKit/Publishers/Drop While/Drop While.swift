//
//  Drop While.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Publishers {
    
    /// A publisher that omits elements from an upstream publisher until a given closure returns false.
    public struct DropWhile<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that indicates whether to drop the element.
        public let predicate: (Output) -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Output) -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, predicate: predicate))
        }
    }
    
    /// A publisher that omits elements from an upstream publisher until a given error-throwing closure returns false.
    public struct TryDropWhile<Upstream> : Publisher where Upstream : Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The error-throwing closure that indicates whether to drop the element.
        public let predicate: (Upstream.Output) throws -> Bool
        
        public init(upstream: Upstream, predicate: @escaping (Output) throws -> Bool) {
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, predicate: predicate))
        }
    }
}

extension Publishers.DropWhile {
    
    // MARK: DROP WHILE SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        
        private var predicate: ((Output) -> Bool)?
        
        private let lock = Lock()
        
        private var isDropping = true
        
        init(downstream: Downstream, predicate: @escaping (Output) -> Bool) {
            self.downstream = downstream
            self.predicate = predicate
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            
            downstream?.receive(subscription: self)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            let predicate = self.predicate
            lock.unlock()
            
            if isDropping {
                if predicate?(input) ?? true {
                    return .max(1)
                }
                
                lock.lock()
                isDropping = false
                lock.unlock()
            }
            
            return downstream?.receive(input) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            predicate = nil
            lock.unlock()
            
            downstream?.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "demand must not be negative.")
            
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            predicate = nil
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "DropWhile"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}

extension Publishers.TryDropWhile {
    
    // MARK: TRY DROP WHILE SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        
        private var predicate: ((Output) throws -> Bool)?
        
        private let lock = Lock()
        
        private var isDropping = true
        
        init(downstream: Downstream, predicate: @escaping (Output) throws -> Bool) {
            self.downstream = downstream
            self.predicate = predicate
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            
            downstream?.receive(subscription: self)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return .none }
            let predicate = self.predicate
            lock.unlock()
            
            if isDropping {
                do {
                    if try predicate?(input) ?? true {
                        return .max(1)
                    }
                } catch {
                    lock.lock()
                    status = .terminated
                    self.predicate = nil
                    lock.unlock()
                    
                    subscription.cancel()
                    downstream?.receive(completion: .failure(error))
                    return .none
                }
                
                lock.lock()
                isDropping = false
                lock.unlock()
            }
            
            return downstream?.receive(input) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            predicate = nil
            lock.unlock()
            
            downstream?.receive(completion: completion.eraseError())
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "demand must not be negative.")
            
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            predicate = nil
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "TryDropWhile"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
