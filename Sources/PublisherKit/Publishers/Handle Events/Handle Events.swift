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
            
            
            let handleEventsSubscriber = HandleEventsSink<S, Upstream>(downstream: subscriber,
                                                                   receiveSubscription: receiveSubscription,
                                                                   receiveOutput: receiveOutput,
                                                                   receiveCompletion: receiveCompletion,
                                                                   receiveCancel: receiveCancel,
                                                                   receiveRequest: receiveRequest)
            upstream.subscribe(handleEventsSubscriber)
        }
    }
}
