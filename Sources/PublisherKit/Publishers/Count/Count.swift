//
//  Count.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers {
    
    /// A publisher that publishes the number of elements received from the upstream publisher.
    /// It publishes the value when upstream publisher has finished.
    public struct Count<Upstream: Publisher>: Publisher {
        
        public typealias Output = Int
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let countSubscriber = Inner(downstream: subscriber)
            subscriber.receive(subscription: countSubscriber)
            upstream.subscribe(countSubscriber)
        }
    }
}

extension Publishers.Count: Equatable where Upstream: Equatable {
    
}

extension Publishers.Count {
    
    // MARK: COUNT SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var counter = 0
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            counter += 1
            return nil
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            switch completion {
            case .finished:
                _ = downstream?.receive(counter)
                downstream?.receive(completion: .finished)
                
            case .failure(let error):
                downstream?.receive(completion: .failure(error))
            }
        }
        
        override var description: String {
            "Count"
        }
    }
}
