//
//  Try Catch.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

extension Publishers {
    
    /// A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher or producing a new error.
    public struct TryCatch<Upstream: Publisher, NewPublisher: Publisher>: Publisher where Upstream.Output == NewPublisher.Output {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public let handler: (Upstream.Failure) throws -> NewPublisher
        
        /// Creates a publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.
        ///
        /// - Parameters:
        ///   - upstream: The publisher that this publisher receives elements from.
        ///   - handler: A closure that accepts the upstream failure as input and returns a publisher to replace the upstream publisher.
        public init(upstream: Upstream, handler: @escaping (Upstream.Failure) throws -> NewPublisher) {
            self.upstream = upstream
            self.handler = handler
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            let inner = Inner(downstream: subscriber, handler: handler)
            upstream.subscribe(Inner.UncaughtS<Upstream.Failure>(inner: inner, state: .pre))
        }
    }
}

extension Publishers.TryCatch {
    
    // MARK: TRY CATCH SINK
    private final class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomReflectable where Downstream.Input == Output, Downstream.Failure == Failure {
        
        private var downstream: Downstream?
        private let handler: (Upstream.Failure) throws -> NewPublisher
        
        var status: SubscriptionStatus = .awaiting
        
        private(set) var isCancelled = false
        private var demand: Subscribers.Demand = .unlimited
        
        let lock = Lock()
        
        init(downstream: Downstream,  handler: @escaping (Upstream.Failure) throws -> NewPublisher) {
            self.downstream = downstream
            self.handler = handler
        }
        
        func receivePre(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting, !isCancelled else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            
            downstream?.receive(subscription: self)
        }
        
        func receive(_ input: Output) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed, !isCancelled else { lock.unlock(); return .none }
            lock.unlock()
            
            return downstream?.receive(input) ?? .none
        }
        
        func receivePre(completion: Subscribers.Completion<Upstream.Failure>) {
            switch completion {
            case .finished:
                downstream?.receive(completion: .finished)
                
            case .failure(let error):
                do {
                    let newPublisher = try handler(error)
                    let subscriber = UncaughtS<NewPublisher.Failure>(inner: self, state: .post)
                    
                    lock.lock()
                    status = .awaiting
                    lock.unlock()
                    
                    newPublisher.subscribe(subscriber)
                } catch {
                    downstream?.receive(completion: .failure(error))
                }
            }
        }
        
        func receivePost(subscription: Subscription) {
            subscription.request(.unlimited)
        }
        
        func receivePost(completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
            downstream = nil
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(let subscription) = status else {
                lock.unlock()
                return
            }
            lock.unlock()
            
            self.demand = demand
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            isCancelled = true
            lock.unlock()
            
            downstream = nil
            subscription.cancel()
        }
        
        var description: String {
            "Catch"
        }
        
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }
            
            let children: [Mirror.Child] = [
                ("downstream", downstream as Any),
                ("demand", demand)
            ]
            
            return Mirror(self, children: children)
        }
        
        fileprivate final class UncaughtS<Failure: Error>: Subscriber, CustomStringConvertible, CustomReflectable {
            
            typealias Input = Output
            
            private let inner: Inner
            
            enum State {
                case pre
                case post
            }
            
            private let state: State
            
            init(inner: Inner, state: State) {
                self.inner = inner
                self.state = state
            }
            
            func receive(subscription: Subscription) {
                switch state {
                case .pre: inner.receivePre(subscription: subscription)
                case .post: inner.receivePost(subscription: subscription)
                }
            }
            
            func receive(_ input: Upstream.Output) -> Subscribers.Demand {
                inner.receive(input)
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {
                inner.lock.lock()
                guard inner.status.isSubscribed, !inner.isCancelled else { inner.lock.unlock(); return }
                inner.status = .terminated
                inner.lock.unlock()
                
                switch state {
                case .pre:
                    let completion = completion.mapError { $0 as! Upstream.Failure }
                    inner.receivePre(completion: completion)
                    
                case .post:
                    let completion = completion.mapError { $0 as Error }
                    inner.receivePost(completion: completion)
                }
            }
            
            var description: String {
                inner.description
            }
            
            var customMirror: Mirror {
                inner.customMirror
            }
        }
    }
}
