//
//  Drop.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Publishers {
    
    /// A publisher that omits a specified number of elements before republishing later elements.
    public struct Drop<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The number of elements to drop.
        public let count: Int
        
        public init(upstream: Upstream, count: Int) {
            self.upstream = upstream
            self.count = count
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dropSubscription = Inner(downstream: subscriber, count: count)
            
            subscriber.receive(subscription: dropSubscription)
            upstream.subscribe(dropSubscription)
        }
    }
}

extension Publishers.Drop: Equatable where Upstream: Equatable {
}

extension Publishers.Drop {
    
    // MARK: DROP SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var count: Int
        
        init(downstream: Downstream, count: Int) {
            self.count = count
            super.init(downstream: downstream)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Output, Failure>? {
            if count > 0 { count -= 1 }
            if count == 0 {
                return .success(input)
            } else {
                return nil
            }
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override var description: String {
            "Drop"
        }
    }
}
