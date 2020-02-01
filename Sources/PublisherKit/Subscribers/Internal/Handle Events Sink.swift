//
//  Handle Events Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers.HandleEvents {
    
    final class HandleEventsSink<Downstream: PKSubscriber, Upstream: PKPublisher>: PKSubscribers.OperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
        
        final let receiveOutput: ((Input) -> Void)?
        
        final let receiveCancel: (() -> Void)?
        
        final let receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)?
        
        final let receiveSubscription: ((PKSubscription) -> Void)?
        final let receiveRequest: ((PKSubscribers.Demand) -> Void)?
        
        init(downstream: Downstream,
             receiveSubscription: ((PKSubscription) -> Void)? = nil,
             receiveOutput: ((Input) -> Void)? = nil,
             receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)? = nil,
             receiveCancel: (() -> Void)? = nil,
             receiveRequest: ((PKSubscribers.Demand) -> Void)?) {
            
            self.receiveSubscription = receiveSubscription
            self.receiveOutput = receiveOutput
            self.receiveCompletion = receiveCompletion
            self.receiveCancel = receiveCancel
            self.receiveRequest = receiveRequest
            
            super.init(downstream: downstream)
        }
        
        override func request(_ demand: PKSubscribers.Demand) {
            super.request(demand)
            receiveRequest?(demand)
        }
        
        override func receive(subscription: PKSubscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
            receiveSubscription?(subscription)
        }
        
        override func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            receiveOutput?(input)
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
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
