//
//  Future.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 13/03/20.
//

/// A publisher that eventually produces one value and then finishes or fails.
final public class Future<Output, Failure>: Publisher where Failure : Error {
    
    private var result: Result<Output, Failure>?
    
    private let lock = Lock()
    
    private var subscriptions: [Inner] = []

    public typealias Promise = (Result<Output, Failure>) -> Void

    public init(_ attemptToFulfill: @escaping (@escaping Promise) -> Void) {
        attemptToFulfill { [weak self] result in
            self?.lock.do {
                guard self?.result == nil else { return }
                self?.result = result
                self?.publish()
            }
        }
    }
    
    public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        
        let futureSubscription = Inner(downstream: AnySubscriber(subscriber))
        
        subscriber.receive(subscription: futureSubscription)
        
        subscriptions.append(futureSubscription)
        
        lock.do(publish)
    }
    
    private func publish() {
        switch result {
        case .success(let output):
            publish(output: output)
            
        case .failure(let error):
            publish(failure: error)
            
        case .none:
            return
        }
    }
    
    @inline(__always)
    private func publish(output: Output) {
        subscriptions.removeAll { $0.isTerminated }
        
        for subscription in subscriptions where subscription.demand > 0 {
            subscription.receive(input: output)
            subscription.receive(completion: .finished)
        }
    }
    
    @inline(__always)
    private func publish(failure: Failure) {
        subscriptions.removeAll { $0.isTerminated }
        
        for subscription in subscriptions {
            subscription.receive(completion: .failure(failure))
        }
    }
}

extension Future {
    
    // MARK: FUTURE SINK
    private final class Inner: Subscriptions.Internal<AnySubscriber<Output, Failure>, Output, Failure> {
        
        override func receive(input: Output) {
            guard !isTerminated else { return }
            _ = downstream?.receive(input)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isTerminated else { return }
            
            end {
                onCompletion(completion)
            }
        }
        
        override func end(completion: () -> Void) {
            terminate()
            completion()
            downstream = nil
        }
        
        override var description: String {
            "Future"
        }
    }
}
