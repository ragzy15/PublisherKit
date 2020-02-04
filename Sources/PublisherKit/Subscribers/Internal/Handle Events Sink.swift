//
//  Handle Events Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers.HandleEvents {
    
    final class HandleEventsSink<Downstream: Subscriber, Upstream: Publisher>: Subscribers.OperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
        
        final let receiveOutput: ((Input) -> Void)?
        
        final let receiveCancel: (() -> Void)?
        
        final let receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)?
        
        final let receiveSubscription: ((Subscription) -> Void)?
        final let receiveRequest: ((Subscribers.Demand) -> Void)?
        
        init(downstream: Downstream,
             receiveSubscription: ((Subscription) -> Void)? = nil,
             receiveOutput: ((Input) -> Void)? = nil,
             receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)? = nil,
             receiveCancel: (() -> Void)? = nil,
             receiveRequest: ((Subscribers.Demand) -> Void)?) {
            
            self.receiveSubscription = receiveSubscription
            self.receiveOutput = receiveOutput
            self.receiveCompletion = receiveCompletion
            self.receiveCancel = receiveCancel
            self.receiveRequest = receiveRequest
            
            super.init(downstream: downstream)
        }
        
        override func request(_ demand: Subscribers.Demand) {
            super.request(demand)
            receiveRequest?(demand)
        }
        
        override func receive(subscription: Subscription) {
            super.receive(subscription: subscription)
            receiveSubscription?(subscription)
            downstream?.receive(subscription: self)
            subscription.request(.unlimited)
        }
        
        override func receive(_ input: Input) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            receiveOutput?(input)
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            receiveCompletion?(completion)
            downstream?.receive(completion: completion)
        }
        
        override func cancel() {
            receiveCancel?()
            super.cancel()
        }
    }

}
