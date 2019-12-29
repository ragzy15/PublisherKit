//
//  Zip Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

class ZipSink<Downstream: NKSubscriber, AInput, BInput, Failure>: InternalSink<Downstream, (AInput, BInput), Failure> where Downstream.Input == (AInput, BInput), Downstream.Failure == Failure {
    
    var aOutput: AInput?
    var bOutput: BInput?
    
    var subscriptions: [NKSubscription] = []
    
    override func receive(subscription: NKSubscription) {
        guard !isCancelled else { return }
        subscriptions.append(subscription)
    }
    
    override func receive(_ input: (AInput, BInput)) -> NKSubscribers.Demand {
        guard !isCancelled else { return .none }
        _ = downstream?.receive(input)
        return demand
    }
    
    func receive(a input: AInput) {
        aOutput = input
        checkAndSend()
    }
    
    func receive(b input: BInput) {
        bOutput = input
        checkAndSend()
    }
    
    func checkAndSend() {
        if let aValue = aOutput, let bValue = bOutput {
            aOutput = nil
            bOutput = nil
            
            _ = receive((aValue, bValue))
        }
    }
    
    override func receive(completion: NKSubscribers.Completion<Failure>) {
        guard !isCancelled else { return }
        downstream?.receive(completion: completion)
        end()
    }
    
    override func end() {
        super.end()
        subscriptions.removeAll()
    }
}
