//
//  Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension PKSubscribers {

    /// A simple subscriber that requests an unlimited number of values upon subscription.
    final class Sink<Input, Failure: Error>: PKSubscriber, PKCancellable {

        /// The closure to execute on receipt of a value.
        final public let receiveValue: (Input) -> Void

        /// The closure to execute on completion.
        final public let receiveCompletion: (PKSubscribers.Completion<Failure>) -> Void
        
        private var subscription: PKSubscription?
        
        var isCancelled = false

        public init(receiveCompletion: @escaping ((PKSubscribers.Completion<Failure>) -> Void), receiveValue: @escaping ((Input) -> Void)) {
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
        }

        final public func receive(subscription: PKSubscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
        }

        final public func receive(_ value: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(value)
            return .unlimited
        }

        final public func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            receiveCompletion(completion)
            end()
        }

        final public func cancel() {
            isCancelled = true
            subscription?.cancel()
            subscription = nil
        }
        
        final func end() {
            subscription?.cancel()
            subscription = nil
        }
    }
}
