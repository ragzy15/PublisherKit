//
//  OnCompletion.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

public extension Subscribers {
    
    /// A simple subscriber that requests an unlimited number of values upon subscription.
    final class OnCompletion<Input, Failure: Error>: Subscriber, Cancellable {
        
        /// The closure to execute on completion.
        final public let receiveCompletion: (Result<Input, Failure>) -> Void
        
        private var status: SubscriptionStatus = .awaiting
        
        let logError: Bool
        
        
        /// Initializes a sink with the provided closures.
        ///
        /// - Parameters:
        ///   - logError: If an error if received in completion, it allows to print on console
        ///   - receiveCompletion: The closure to execute on completion.
        public init(logError: Bool = true, receiveCompletion: @escaping ((Result<Input, Failure>) -> Void)) {
            self.receiveCompletion = receiveCompletion
            self.logError = logError
        }
        
        final public func receive(subscription: Subscription) {
            guard case .awaiting = status else {
                subscription.cancel()
                return
            }
            
            status = .subscribed(to: subscription)
            subscription.request(.unlimited)
        }
        
        final public func receive(_ value: Input) -> Subscribers.Demand  {
            guard case .subscribed = status else { return .none }
            receiveCompletion(.success(value))
            return .none
        }
        
        final public func receive(completion: Subscribers.Completion<Failure>) {
            guard case .subscribed = status else { return }
            status = .terminated
            
            if let error = completion.getError() {
                #if DEBUG
                if logError {
                    Swift.print("⚠️ [PublisherKit: Error]\n  ↪︎ \(error)\n")
                }
                #endif
                receiveCompletion(.failure(error))
            }
        }
        
        final public func cancel() {
            guard case .subscribed(let subscription) = status else { return }
            status = .terminated
            subscription.cancel()
        }
    }
}
