//
//  Combine Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

class CombineSink<Downstream: Subscriber>: Subscribers.OperatorSink<Downstream, Downstream.Input, Downstream.Failure> {
    
    private var subscriptions: [Subscription] = []
    
    override func receive(subscription: Subscription) {
        guard !isCancelled else { return }
        subscriptions.append(subscription)
    }
    
    override func receive(_ input: Input) -> Subscribers.Demand {
        guard !isCancelled else { return .none }
        _ = downstream?.receive(input)
        return demand
    }
    
    func receive(input: Input) {
        guard !isCancelled else { return }
        _ = downstream?.receive(input)
    }
    
    func receiveSubscription() { }
    func sendRequest() { }
    func checkAndSend() { }
    
    func receive(completion: Subscribers.Completion<Failure>, downstream: CombineSink?) {
        receive(completion: completion)
    }
    
    override func receive(completion: Subscribers.Completion<Failure>) {
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
