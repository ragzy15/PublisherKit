//
//  Handle Events.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    /// A publisher that performs the specified closures when publisher events occur.
    public struct HandleEvents<Upstream: Publisher>: Publisher  {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure that executes when the publisher receives the subscription from the upstream publisher.
        public var receiveSubscription: ((Subscription) -> Void)?
        
        ///  A closure that executes when the publisher receives a value from the upstream publisher.
        public var receiveOutput: ((Upstream.Output) -> Void)?
        
        /// A closure that executes when the publisher receives the completion from the upstream publisher.
        public var receiveCompletion: ((Subscribers.Completion<Upstream.Failure>) -> Void)?
        
        ///  A closure that executes when the downstream receiver cancels publishing.
        public var receiveCancel: (() -> Void)?
        
        /// A closure that executes when the publisher receives a request for more elements.
        public var receiveRequest: ((Subscribers.Demand) -> Void)?
        
        public init(upstream: Upstream,
                    receiveSubscription: ((Subscription) -> Void)? = nil,
                    receiveOutput: ((Publishers.HandleEvents<Upstream>.Output) -> Void)? = nil,
                    receiveCompletion: ((Subscribers.Completion<Publishers.HandleEvents<Upstream>.Failure>) -> Void)? = nil,
                    receiveCancel: (() -> Void)? = nil,
                    receiveRequest: ((Subscribers.Demand) -> Void)?) {
            
            
            self.upstream = upstream
            self.receiveSubscription = receiveSubscription
            self.receiveOutput = receiveOutput
            self.receiveCompletion = receiveCompletion
            self.receiveCancel = receiveCancel
            self.receiveRequest = receiveRequest
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            
            let handleEventsSubscriber = HandleEvents<S, Upstream>(downstream: subscriber,
                                                                   receiveSubscription: receiveSubscription,
                                                                   receiveOutput: receiveOutput,
                                                                   receiveCompletion: receiveCompletion,
                                                                   receiveCancel: receiveCancel,
                                                                   receiveRequest: receiveRequest)
            upstream.subscribe(handleEventsSubscriber)
        }
    }
}

extension Publishers.HandleEvents {
    
    // MARK: HANDLE EVENTS SINK
    final class HandleEvents<Downstream: Subscriber, Upstream: Publisher>: InternalSubscriber<Downstream, Upstream> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
        
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
            receiveRequest?(demand)
            super.request(demand)
        }
        
        override func receive(subscription: Subscription) {
            guard status == .awaiting else { return }
            super.receive(subscription: subscription)
            receiveSubscription?(subscription)
        }
        
        override func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            receiveOutput?(input)
            return .success(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            receiveCompletion?(completion)
            downstream?.receive(completion: completion)
        }
        
        override func cancel() {
            receiveCancel?()
            super.cancel()
        }
    }
}
