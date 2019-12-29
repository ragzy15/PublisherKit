//
//  Data Task Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKSubscribers {
    
    final class DataTaskSink<Downstream: NKSubscriber>: NKSubscribers.DataTaskSinkable, NKSubscriber where Downstream.Input == (data: Data, response: HTTPURLResponse), Downstream.Failure == NSError {
        
        typealias Input = Downstream.Input
        
        typealias Failure = Downstream.Failure
        
        var downstream: Downstream?
        
        var cancelBlock: (() -> Void)?
        
        private(set) var isCompleted: Bool = false
        
        init(downstream: Downstream) {
            self.downstream = downstream
            super.init()
        }
        
        deinit {
            print("Deiniting DataTaskSink")
        }
        
        func receive(subscription: NKSubscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
        }
        
        func receive(_ input: Input) -> NKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        func receive(completion: NKSubscribers.Completion<Failure>) {
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
        
        override func cancel() {
            super.cancel()
            cancelBlock?()
            cancelBlock = nil
        }
    }
}
