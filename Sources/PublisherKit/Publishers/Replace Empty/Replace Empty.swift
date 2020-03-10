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
            
            let replaceEmptySubscriber = Inner(downstream: subscriber)
            subscriber.receive(subscription: replaceEmptySubscriber)
            
            replaceEmptySubscriber.onFinish = { (downstream) in
                _ = downstream?.receive(self.output)
            }
            
            upstream.subscribe(replaceEmptySubscriber)
        }
    }
}

extension Publishers.ReplaceEmpty: Equatable where Upstream : Equatable, Upstream.Output: Equatable {
    
}

extension Publishers.ReplaceEmpty {
    
    // MARK: REPLACE EMPTY SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var inputReceived = false
        var onFinish: ((Downstream?) -> Void)?
        
        override func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            inputReceived = true
            return .success(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            if let error = completion.getError() {
                downstream?.receive(completion: .failure(error))
                return
            }
            
            if !inputReceived {
                onFinish?(downstream)
            }
            
            downstream?.receive(completion: .finished)
        }
        
        override func cancel() {
            super.cancel()
            onFinish = nil
        }
        
        override func end(completion: () -> Void) {
            super.end(completion: completion)
            onFinish = nil
        }
        
        override var description: String {
            "ReplaceEmpty"
        }
    }
}
