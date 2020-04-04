//
//  Output.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Publishers {
    
    /// A publisher that publishes elements specified by a range in the sequence of published elements.
    public struct Output<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The range of elements to publish.
        public let range: CountableRange<Int>
        
        /// Creates a publisher that publishes elements specified by a range.
        ///
        /// - Parameters:
        ///   - upstream: The publisher that this publisher receives elements from.
        ///   - range: The range of elements to publish.
        public init(upstream: Upstream, range: CountableRange<Int>) {
            self.upstream = upstream
            self.range = range
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, range: range))
        }
    }
}

extension Publishers.Output: Equatable where Upstream: Equatable { }

extension Publishers.Output {
    
    // MARK: OUTPUT SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private let range: CountableRange<Int>
        private var startOffset: Int
        private var remainingCount: Int
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        private let lock = Lock()
        
        init(downstream: Downstream, range: CountableRange<Int>) {
            self.downstream = downstream
            self.range = range
            startOffset = range.lowerBound
            remainingCount = range.count
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
            
            if startOffset > 0 {
                startOffset -= 1
                return .max(1)
            }
            
            if remainingCount > 0 {
                remainingCount -= 1
                return downstream?.receive(input) ?? .none
            } else {
                lock.lock()
                status = .terminated
                lock.unlock()
                
                subscription.cancel()
                downstream?.receive(completion: .finished)
                
                return .none
            }
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            downstream?.receive(completion: completion)
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
            "Output"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
