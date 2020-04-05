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
        
        
        /// Initializes a sink with the provided closures.
        ///
        /// - Parameters:
        ///   - receiveCompletion: The closure to execute on completion.
        ///   - receiveValue: The closure to execute on receipt of a value.
        public init(receiveCompletion: @escaping ((Result<Input, Failure>) -> Void)) {
            self.receiveCompletion = receiveCompletion
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
                Logger.default.log(error: error)
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
