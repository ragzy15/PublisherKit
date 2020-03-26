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
            upstream.subscribe(Inner.UncaughtS(inner: inner))
        }
    }
}

extension Publishers.TryCatch {
    
    // MARK: TRY CATCH SINK
    private final class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Downstream.Input == Output, Downstream.Failure == Failure {
        
        private var downstream: Downstream?
        private let handler: (Upstream.Failure) throws -> NewPublisher
        
        fileprivate enum SubscriptionStatus: Equatable {
            
            case awaitingPre
            case pre(Subscription)
            case awaitingPost
            case post(Subscription)
            case terminated
            
            static func == (lhs: SubscriptionStatus, rhs: SubscriptionStatus) -> Bool {
                switch (lhs, rhs) {
                case (.awaitingPre, .awaitingPre): return true
                case (.awaitingPost, .awaitingPost): return true
                case (.terminated, .terminated): return true
                case (.pre(let subscriptionLhs), .pre(let subscriptionRhs)):
                    return subscriptionLhs.combineIdentifier == subscriptionRhs.combineIdentifier
                case (.post(let subscriptionLhs), .post(let subscriptionRhs)):
                    return subscriptionLhs.combineIdentifier == subscriptionRhs.combineIdentifier
                default: return false
                }
            }
            
            var preSubscribed: Bool {
                switch self {
                case .pre: return true
                default: return false
                }
            }
            
            var postSubscribed: Bool {
                switch self {
                case .post: return true
                default: return false
                }
            }
        }
        
        fileprivate var status: SubscriptionStatus = .awaitingPre
        
        private var demand: Subscribers.Demand = .unlimited
        
        fileprivate let lock = Lock()
        
        init(downstream: Downstream,  handler: @escaping (Upstream.Failure) throws -> NewPublisher) {
            self.downstream = downstream
            self.handler = handler
        }
        
        func receivePre(subscription: Subscription) {
            lock.lock()
            guard status == .awaitingPre else { lock.unlock(); return }
            status = .pre(subscription)
            lock.unlock()
            
            downstream?.receive(subscription: self)
        }
        
        func receive(_ input: Output) -> Subscribers.Demand {
            lock.lock()
            guard status.preSubscribed else { lock.unlock(); return .none }
            lock.unlock()
            
            return downstream?.receive(input) ?? .none
        }
        
        func receivePre(completion: Subscribers.Completion<Upstream.Failure>) {
            switch completion {
            case .finished:
                lock.lock()
                guard status.preSubscribed else { lock.unlock(); return }
                status = .terminated
                lock.unlock()
                downstream?.receive(completion: .finished)
                
            case .failure(let error):
                lock.lock()
                guard status.preSubscribed else { lock.unlock(); return }
                status = .awaitingPost
                lock.unlock()
                
                do {
                    try handler(error).subscribe(CaughtS(inner: self))
                } catch {
                    lock.lock()
                    status = .terminated
                    lock.unlock()
                    
                    downstream?.receive(completion: .failure(error))
                }
            }
        }
        
        func receivePost(subscription: Subscription) {
            lock.lock()
            guard status == .awaitingPost else { lock.unlock(); return }
            status = .post(subscription)
            lock.unlock()
            
            downstream?.receive(subscription: self)
        }
        
        func receivePost(completion: Subscribers.Completion<Error>) {
            lock.lock()
            guard status.postSubscribed else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            downstream?.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            
            switch status {
            case .pre(let subscription):
                guard status.preSubscribed else { lock.unlock(); return }
                lock.unlock()
                subscription.request(demand)
                
            case .post(let subscription):
                guard status.postSubscribed else { lock.unlock(); return }
                lock.unlock()
                subscription.request(demand)
                
            default:
                lock.unlock()
            }
        }
        
        func cancel() {
            lock.lock()
            
            switch status {
            case .pre(let subscription), .post(let subscription):
                status = .terminated
                lock.unlock()
                subscription.cancel()
                
            default:
                status = .terminated
                lock.unlock()
            }
        }
        
        var description: String {
            "TryCatch"
        }
        
        var playgroundDescription: Any {
            description
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
        
        fileprivate struct UncaughtS: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
            
            typealias Input = Output
            
            typealias Failure = Upstream.Failure
            
            private let inner: Inner
            
            let combineIdentifier: CombineIdentifier
            
            init(inner: Inner) {
                self.inner = inner
                combineIdentifier = CombineIdentifier()
            }
            
            func receive(subscription: Subscription) {
                inner.receivePre(subscription: subscription)
            }
            
            func receive(_ input: Upstream.Output) -> Subscribers.Demand {
                inner.receive(input)
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {
                inner.receivePre(completion: completion)
            }
            
            var description: String {
                inner.description
            }
            
            var playgroundDescription: Any {
                inner.playgroundDescription
            }
            
            var customMirror: Mirror {
                inner.customMirror
            }
        }
                
        fileprivate struct CaughtS: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
            
            typealias Input = Output
            
            typealias Failure = NewPublisher.Failure
            
            private let inner: Inner
            
            let combineIdentifier: CombineIdentifier
            
            init(inner: Inner) {
                self.inner = inner
                combineIdentifier = CombineIdentifier()
            }
            
            func receive(subscription: Subscription) {
                inner.receivePost(subscription: subscription)
            }
            
            func receive(_ input: Upstream.Output) -> Subscribers.Demand {
                inner.lock.lock()
                guard inner.status.postSubscribed else { inner.lock.unlock(); return .none }
                inner.lock.unlock()
                
                return inner.downstream?.receive(input) ?? .none
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {
                inner.receivePost(completion: completion.mapError { $0 as Error })
            }
            
            var description: String {
                inner.description
            }
            
            var playgroundDescription: Any {
                inner.playgroundDescription
            }
            
            var customMirror: Mirror {
                inner.customMirror
            }
        }
    }
}
