//
//  Zip Sink5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

class ZipSink5<Downstream: NKSubscriber, AInput, BInput, CInput, DInput, EInput, Failure>: InternalSink<Downstream, (AInput, BInput, CInput, DInput, EInput), Failure> where Downstream.Input == (AInput, BInput, CInput, DInput, EInput), Downstream.Failure == Failure {
    
    var aOutput: AInput?
    var bOutput: BInput?
    var cOutput: CInput?
    var dOutput: DInput?
    var eOutput: EInput?
    
    var subscriptions: [NKSubscription] = []
    
    override func receive(subscription: NKSubscription) {
        guard !isCancelled else { return }
        subscriptions.append(subscription)
    }
    
    override func receive(_ input: (AInput, BInput, CInput, DInput, EInput)) -> NKSubscribers.Demand {
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
    
    func receive(c input: CInput) {
        cOutput = input
        checkAndSend()
    }
    
    func receive(d input: DInput) {
        dOutput = input
        checkAndSend()
    }
    
    func receive(e input: EInput) {
        eOutput = input
        checkAndSend()
    }
    
    func checkAndSend() {
        if let aValue = aOutput, let bValue = bOutput, let cValue = cOutput, let dValue = dOutput, let eValue = eOutput {
            aOutput = nil
            bOutput = nil
            cOutput = nil
            dOutput = nil
            eOutput = nil
            
            _ = receive((aValue, bValue, cValue, dValue, eValue))
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
