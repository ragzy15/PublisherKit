//
//  Combine Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

class CombineSink<Downstream: PKSubscriber>: PKSubscribers.Sinkable<Downstream, Downstream.Input, Downstream.Failure> {
    
    private var subscriptions: [PKSubscription] = []
    
    override func receive(subscription: PKSubscription) {
        guard !isCancelled else { return }
        subscriptions.append(subscription)
    }
    
    override func receive(_ input: Input) -> PKSubscribers.Demand {
        guard !isCancelled else { return .none }
        downstream?.receive(input: input)
        return demand
    }
    
    func receiveSubscription() { }
    func sendRequest() { }
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
