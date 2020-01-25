//
//  Data Task Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension URLSession {
    
    final class DataTaskSink<Downstream: PKSubscriber, Input, Failure>: PKSubscribers.DataTaskSubscriptionSinkable, PKSubscriber where Downstream.Input == Input, Downstream.Failure == Failure {
        
        typealias Input = Downstream.Input
        
        typealias Failure = Downstream.Failure
        
        var downstream: Downstream?
        
        private(set) var isCompleted: Bool = false
        
        init(downstream: Downstream) {
            self.downstream = downstream
            super.init()
        }
        
        func receive(subscription: PKSubscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
        }
        
        func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            downstream?.receive(completion: completion)
            end()
        }
        
        func receive(input: Input) {
            guard !isCancelled else { return }
            
            if demand != .none {
                _ = downstream?.receive(input)
            }
            
            demand = getDemand()
            
            if demand == .none, !isCompleted {
                isCompleted.toggle()
                receive(completion: .finished)
            }
        }
    }
}
