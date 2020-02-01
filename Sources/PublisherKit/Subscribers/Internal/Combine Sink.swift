//
//  Combine Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

class CombineSink<Downstream: PKSubscriber>: PKSubscribers.OperatorSink<Downstream, Downstream.Input, Downstream.Failure> {
    
    private var subscriptions: [PKSubscription] = []
    
    override func receive(subscription: PKSubscription) {
        guard !isCancelled else { return }
        subscriptions.append(subscription)
    }
    
    override func receive(_ input: Input) -> PKSubscribers.Demand {
        guard !isCancelled else { return .none }
        _ = downstream?.receive(input)
        return demand
    }
    
    override func receive(input: Input) {
        guard !isCancelled else { return }
        _ = downstream?.receive(input)
    }
    
    func checkAndSend() { }
    
    func receive(completion: PKSubscribers.Completion<Failure>, downstream: CombineSink?) {
        receive(completion: completion)
    }
    
    override func receive(completion: PKSubscribers.Completion<Failure>) {
        guard !isCancelled else { return }
        end()
        downstream?.receive(completion: completion)
    }
    
    func receive(_ input: Input, downstream: CombineSink<Downstream>?) {
        receive(input: input)
        checkAndSend()
    }
    
    override func end() {
        super.end()
        subscriptions = []
    }
    
    override func cancel() {
        super.cancel()
        subscriptions.forEach { (subscription) in
            subscription.cancel()
        }
        subscriptions = []
    }
}
