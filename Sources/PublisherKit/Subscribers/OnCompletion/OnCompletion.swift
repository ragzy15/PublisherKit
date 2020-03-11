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
        
        private var subscription: Subscription?
        
        private var isCancelled = false
        
        private var demand: Subscribers.Demand = .unlimited

        /// Initializes a sink with the provided closures.
        ///
        /// - Parameters:
        ///   - receiveCompletion: The closure to execute on completion.
        ///   - receiveValue: The closure to execute on receipt of a value.
        public init(receiveCompletion: @escaping ((Result<Input, Failure>) -> Void)) {
            self.receiveCompletion = receiveCompletion
        }
        
        final public func receive(subscription: Subscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
            subscription.request(.unlimited)
        }

        final public func receive(_ value: Input) -> Subscribers.Demand  {
            guard !isCancelled else { return .none }
            receiveCompletion(.success(value))
            return demand
        }
        
        final public func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            
            if let error = completion.getError() {
                #if DEBUG
                Logger.default.log(error: error)
                #endif
                receiveCompletion(.failure(error))
            }
            end()
        }
        
        final func end() {
            subscription = nil
        }

        /// Cancel the activity.
        final public func cancel() {
            isCancelled = true
            subscription?.cancel()
            subscription = nil
        }
    }
}
