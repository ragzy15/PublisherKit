//
//  Try Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public extension Publishers {
    
    /// A publisher that transforms all elements received from an upstream publisher with a specified error-throwing closure.
    struct TryMap<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) throws -> Output
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) throws -> Output) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.receive(subscriber: Inner(downstream: subscriber, transform: transform))
        }
    }
}

extension Publishers.TryMap {
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> Publishers.TryMap<Upstream, T> {
        Publishers.TryMap(upstream: upstream, transform: { try transform(self.transform($0)) })
    }
    
    public func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> Publishers.TryMap<Upstream, T> {
        Publishers.TryMap(upstream: upstream, transform: { try transform(self.transform($0)) })
    }
}

extension Publishers.TryMap {
    
    // MARK: TRY MAP SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Error == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var downstream: Downstream?
        private let transform: (Input) throws -> Output
        
        private var status: SubscriptionStatus = .awaiting
        private let lock = Lock()
        
        init(downstream: Downstream, transform: @escaping (Input) throws -> Output) {
            self.downstream = downstream
            self.transform = transform
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
            lock.unlock()
            
            do {
                return downstream?.receive(try transform(input)) ?? .none
            } catch {
                lock.lock()
                status = .terminated
                lock.unlock()
                
                subscription.cancel()
                
                downstream?.receive(completion: .failure(error))
                downstream = nil
                
                return .none
            }
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            downstream?.receive(completion: completion.mapError { $0 as Downstream.Failure })
            downstream = nil
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            downstream = nil
            subscription.cancel()
        }
        
        var description: String {
            "TryMap"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(reflecting: self)
        }
    }
}
