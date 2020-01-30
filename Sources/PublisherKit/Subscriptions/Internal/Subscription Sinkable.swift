//
//  Subscription Sinkable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

class SubscriptionSinkable: PKSubscription {
    
    private(set) var isCancelled = false
    
    private(set) var isEnded = false
    
    var isOver: Bool {
        isEnded || isCancelled
    }
    
    var subscription: PKSubscription?
    
    private(set) var demand: PKSubscribers.Demand = .unlimited
    
    func request(_ demand: PKSubscribers.Demand) {
        self.demand = demand
    }
    
    func cancel() {
        isCancelled = true
        subscription?.cancel()
        subscription = nil
    }
    
    func end() {
        isEnded = true
        subscription = nil
    }
    
    final func updateDemand() {
        demand -= 1
    }
}
