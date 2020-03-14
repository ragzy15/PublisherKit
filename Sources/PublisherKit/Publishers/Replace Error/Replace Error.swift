//
//  Replace Error.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public extension Publishers {
    
    /// A publisher that replaces any errors in the stream with a provided element.
    struct ReplaceError<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Never
        
        /// The element with which to replace errors from the upstream publisher.
        public let output: Upstream.Output
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public init(upstream: Upstream, output: Output) {
            self.upstream = upstream
            self.output = output
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let replaceErrorSubscriber = Inner(downstream: subscriber)
            
            replaceErrorSubscriber.onError = { (downstream) in
                _ = downstream?.receive(self.output)
            }
            
            upstream.subscribe(replaceErrorSubscriber)
        }
    }
}

extension Publishers.ReplaceError: Equatable where Upstream: Equatable, Upstream.Output: Equatable { }

extension Publishers.ReplaceError {
    
    // MARK: REPLACE ERROR SINK
    private final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        var onError: ((Downstream?) -> Void)?
        
        override func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            .success(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            if let error = completion.getError() {
                Logger.default.log(error: error)
                onError?(downstream)
            }
            
            downstream?.receive(completion: .finished)
        }
        
        override func cancel() {
            super.cancel()
            onError = nil
        }
        
        override func end(completion: () -> Void) {
            super.end(completion: completion)
            onError = nil
        }
        
        override var description: String {
            "ReplaceError"
        }
    }
}
