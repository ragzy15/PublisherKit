//
//  Handle Events Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

typealias UpstreamHandleEventsSink<Downstream: NKSubscriber, Upstream: NKPublisher> = HandleEventsSink<Downstream, Upstream.Output, Upstream.Failure>

class HandleEventsSink<Downstream: NKSubscriber, Input, Failure: Error>: InternalSink<Downstream, Input, Failure> {
    
    final let receiveOutput: ((Input) -> Void)?
    
    final let receiveCancel: (() -> Void)?
    
    final let receiveCompletion: ((NKSubscribers.Completion<Failure>) -> Void)?
    
    final let receiveSubscription: ((NKSubscription) -> Void)?
    final let receiveRequest: ((NKSubscribers.Demand) -> Void)?
    
    init(downstream: Downstream,
         receiveSubscription: ((NKSubscription) -> Void)? = nil,
         receiveOutput: ((Input) -> Void)? = nil,
         receiveCompletion: ((NKSubscribers.Completion<Failure>) -> Void)? = nil,
         receiveCancel: (() -> Void)? = nil,
         receiveRequest: ((NKSubscribers.Demand) -> Void)?) {
        
        self.receiveSubscription = receiveSubscription
        self.receiveOutput = receiveOutput
        self.receiveCompletion = receiveCompletion
        self.receiveCancel = receiveCancel
        self.receiveRequest = receiveRequest
        
        super.init(downstream: downstream)
    }
    
    override func request(_ demand: NKSubscribers.Demand) {
        super.request(demand)
        receiveRequest?(demand)
    }
    
    override func receive(subscription: NKSubscription) {
        super.receive(subscription: subscription)
        receiveSubscription?(subscription)
    }
    
    override func receive(_ input: Input) -> NKSubscribers.Demand {
        guard !isCancelled else { return .none }
        receiveOutput?(input)
        return demand
    }
    
    override func receive(completion: NKSubscribers.Completion<Failure>) {
        guard !isCancelled else { return }
        receiveCompletion?(completion)
        end()
    }
    
    override func cancel() {
        super.cancel()
        receiveCancel?()
    }
}
