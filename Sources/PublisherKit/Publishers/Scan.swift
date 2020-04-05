//
//  Scan.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 28/03/20.
//

extension Publishers {
    
    public struct Scan<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Upstream.Failure
        
        public let upstream: Upstream
        
        public let initialResult: Output
        
        public let nextPartialResult: (Output, Upstream.Output) -> Output
        
        public init(upstream: Upstream, initialResult: Output, nextPartialResult: @escaping (Output, Upstream.Output) -> Output) {
            self.upstream = upstream
            self.initialResult = initialResult
            self.nextPartialResult = nextPartialResult
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, initialResult: initialResult, nextPartialResult: nextPartialResult))
        }
    }
    
    public struct TryScan<Upstream: Publisher, Output>: Publisher {
        
        public typealias Failure = Error
        
        public let upstream: Upstream
        
        public let initialResult: Output
        
        public let nextPartialResult: (Output, Upstream.Output) throws -> Output
        
        public init(upstream: Upstream, initialResult: Output, nextPartialResult: @escaping (Output, Upstream.Output) throws -> Output) {
            self.upstream = upstream
            self.initialResult = initialResult
            self.nextPartialResult = nextPartialResult
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, initialResult: initialResult, nextPartialResult: nextPartialResult))
        }
    }
}

extension Publishers.Scan {
    
    // MARK: SCAN SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let downstream: Downstream
        
        private let nextPartialResult: (Downstream.Input, Input) -> Downstream.Input
        
        private var result: Downstream.Input
        
        fileprivate init(downstream: Downstream, initialResult: Output, nextPartialResult: @escaping (Output, Input) -> Output) {
            self.downstream = downstream
            self.result = initialResult
            self.nextPartialResult = nextPartialResult
        }
        
        func receive(subscription: Subscription) {
            downstream.receive(subscription: subscription)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            result = nextPartialResult(result, input)
            return downstream.receive(result)
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            downstream.receive(completion: completion)
        }
        
        var description: String {
            "Scan"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}

extension Publishers.TryScan {
    
    // MARK: TRY SCAN SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let lock = Lock()
        
        private let downstream: Downstream
        private var status: SubscriptionStatus = .awaiting
        
        private let nextPartialResult: (Downstream.Input, Input) throws -> Downstream.Input
        
        private var result: Downstream.Input
        
        fileprivate init(downstream: Downstream, initialResult: Output, nextPartialResult: @escaping (Output, Input) throws -> Output) {
            self.downstream = downstream
            self.result = initialResult
            self.nextPartialResult = nextPartialResult
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            
            downstream.receive(subscription: self)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            do {
                result = try nextPartialResult(result, input)
                return downstream.receive(result)
            } catch {
                lock.lock()
                guard case .subscribed(let subscription) = status else { lock.unlock(); return .none }
                status = .terminated
                lock.unlock()
                
                subscription.cancel()
                downstream.receive(completion: .failure(error))
                return .none
            }
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            guard status.isSubscribed else { return }
            downstream.receive(completion: completion.eraseError())
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
            
            subscription.cancel()
        }
        
        var description: String {
            "TryScan"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }
            
            let children: [Mirror.Child] = [
                ("downstream", downstream),
                ("status", status),
                ("result", result)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
