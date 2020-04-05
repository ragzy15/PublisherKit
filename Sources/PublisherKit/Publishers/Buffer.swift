//
//  Buffer.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 29/03/20.
//

extension Publisher {
    
    /// Buffers elements received from an upstream publisher.
    /// - Parameter size: The maximum number of elements to store.
    /// - Parameter prefetch: The strategy for initially populating the buffer.
    /// - Parameter whenFull: The action to take when the buffer becomes full.
    public func buffer(size: Int, prefetch: Publishers.PrefetchStrategy, whenFull: Publishers.BufferingStrategy<Failure>) -> Publishers.Buffer<Self> {
        Publishers.Buffer(upstream: self, size: size, prefetch: prefetch, whenFull: whenFull)
    }
}

extension Publishers {
    
    /// A strategy for filling a buffer.
    ///
    /// * keepFull: A strategy to fill the buffer at subscription time, and keep it full thereafter.
    /// * byRequest: A strategy that avoids prefetching and instead performs requests on demand.
    public enum PrefetchStrategy {
        
        /// A strategy to fill the buffer at subscription time, and keep it full thereafter.
        ///
        /// This strategy starts by making a demand equal to the buffer’s size from the upstream when the subscriber first connects. Afterwards, it continues to demand elements from the upstream to try to keep the buffer full.
        case keepFull
        
        /// A strategy that avoids prefetching and instead performs requests on demand.
        ///
        /// This strategy just forwards the downstream’s requests to the upstream publisher.
        case byRequest
    }
    
    /// A strategy for handling exhaustion of a buffer’s capacity.
    ///
    /// * dropNewest: When full, discard the newly-received element without buffering it.
    /// * dropOldest: When full, remove the least recently-received element from the buffer.
    /// * customError: When full, execute the closure to provide a custom error.
    public enum BufferingStrategy<Failure> where Failure: Error {
        
        /// When full, discard the newly-received element without buffering it.
        case dropNewest
        
        /// When full, remove the least recently-received element from the buffer.
        case dropOldest
        
        /// When full, execute the closure to provide a custom error.
        case customError(() -> Failure)
    }
    
    /// A publisher that buffers elements received from an upstream publisher.
    public struct Buffer<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The maximum number of elements to store.
        public let size: Int
        
        /// The strategy for initially populating the buffer.
        public let prefetch: Publishers.PrefetchStrategy
        
        /// The action to take when the buffer becomes full.
        public let whenFull: Publishers.BufferingStrategy<Upstream.Failure>
        
        /// Creates a publisher that buffers elements received from an upstream publisher.
        /// - Parameter upstream: The publisher from which this publisher receives elements.
        /// - Parameter size: The maximum number of elements to store.
        /// - Parameter prefetch: The strategy for initially populating the buffer.
        /// - Parameter whenFull: The action to take when the buffer becomes full.
        public init(upstream: Upstream, size: Int, prefetch: Publishers.PrefetchStrategy, whenFull: Publishers.BufferingStrategy<Failure>) {
            self.upstream = upstream
            self.size = size
            self.prefetch = prefetch
            self.whenFull = whenFull
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, parent: self))
        }
    }
}

extension Publishers.PrefetchStrategy: Equatable { }

extension Publishers.PrefetchStrategy: Hashable { }

extension Publishers.Buffer {
    
    // MARK: BUFFER SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var terminal: Subscribers.Completion<Failure>?
        
        private let lock = Lock()
        
        private var values: [Input] = []
        
        private var downstreamDemand: Subscribers.Demand = .none
        private var isActive = false
        
        fileprivate typealias Buffer = Publishers.Buffer<Upstream>
        
        private enum State {
            case awaiting(Buffer, Downstream)
            case subscribed(Buffer, Downstream, Subscription)
            case terminated
        }
        
        private var state: State
        
        init(downstream: Downstream, parent: Buffer) {
            state = .awaiting(parent, downstream)
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard case .awaiting(let parent, let downstream) = state else {
                lock.unlock()
                subscription.cancel()
                return
            }
            
            state = .subscribed(parent, downstream, subscription)
            lock.unlock()
            
            let demand: Subscribers.Demand
            
            switch parent.prefetch {
            case .keepFull:
                demand = .max(parent.size)
            case .byRequest:
                demand = .unlimited
            }
            
            subscription.request(demand)
            
            downstream.receive(subscription: self)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed(let parent, _, let subscription) = state else { lock.unlock(); return .none }
            
            switch terminal {
            case .none, .finished:
                guard values.count >= parent.size else {
                    values.append(input)
                    lock.unlock()
                    return drain()
                }
                
                switch parent.whenFull {
                case .dropNewest:
                    lock.unlock()
                    return drain()
                    
                case .dropOldest:
                    values.removeFirst()
                    
                    values.append(input)
                    lock.unlock()
                    return drain()
                    
                case .customError(let createError):
                    terminal = .failure(createError())
                    lock.unlock()
                    
                    subscription.cancel()
                    return .none
                }
                
            case .failure:
                lock.unlock()
                return .none
            }
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard case .subscribed = state, terminal == nil else { lock.unlock(); return }
            terminal = completion
            lock.unlock()
            
            _ = drain()
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = state else { lock.unlock(); return }
            downstreamDemand += demand
            
            let isActive = self.isActive
            lock.unlock()
            
            guard !isActive else { return }
            
            subscription.request(drain() + demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = state else { lock.unlock(); return }
            state = .terminated
            values = []
            lock.unlock()
            
            subscription.cancel()
        }
        
        private func drain() -> Subscribers.Demand {
            var demand: Subscribers.Demand = .none
            lock.lock()
            
            while true {
                guard case .subscribed(let parent, let downstream, _) = state else { lock.unlock(); return demand }
                
                guard downstreamDemand > .none else {
                    guard let terminal = terminal, case .failure(let error) = terminal else { lock.unlock(); return demand }
                    state = .terminated
                    lock.unlock()
                    
                    downstream.receive(completion: .failure(error))
                    return demand
                }
                
                if values.isEmpty {
                    guard let terminal = terminal else { lock.unlock(); return demand }
                    state = .terminated
                    lock.unlock()
                    
                    downstream.receive(completion: terminal)
                    return demand
                }
                
                let poppedValues = locked_pop(downstreamDemand)
                downstreamDemand -= poppedValues.count
                
                isActive = true
                lock.unlock()
                
                var additionalDemand: Subscribers.Demand = .none
                var additionalUpstreamDemand = 0
                
                poppedValues.forEach { (value) in
                    additionalDemand += downstream.receive(value)
                    additionalUpstreamDemand += 1
                }
                
                if parent.prefetch == .keepFull {
                    demand += additionalUpstreamDemand
                }
                
                lock.lock()
                isActive = false
                
                downstreamDemand += additionalDemand
                lock.unlock()
            }
        }
        
        private func locked_pop(_ demand: Subscribers.Demand) -> [Input] {
            assert(demand > .none)
            
            guard let max = demand.max else {
                let values = self.values
                self.values = []
                return values
            }
            
            let values = Array(self.values.prefix(max))
            self.values.removeFirst(values.count)
            
            return values
        }
        
        
        var description: String {
            "Buffer"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            
            let children: [Mirror.Child] = [
                ("values", values),
                ("state", state),
                ("downstreamDemand", downstreamDemand),
                ("terminal", terminal as Any)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
