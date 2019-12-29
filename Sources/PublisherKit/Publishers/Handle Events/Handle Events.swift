//
//  Handle Events.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers {

    /// A publisher that performs the specified closures when publisher events occur.
    public struct HandleEvents<Upstream: NKPublisher>: NKPublisher  {

        public typealias Output = Upstream.Output

        public typealias Failure = Upstream.Failure

        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream

        /// A closure that executes when the publisher receives the subscription from the upstream publisher.
        public var receiveSubscription: ((NKSubscription) -> Void)?

        ///  A closure that executes when the publisher receives a value from the upstream publisher.
        public var receiveOutput: ((Upstream.Output) -> Void)?

        /// A closure that executes when the publisher receives the completion from the upstream publisher.
        public var receiveCompletion: ((NKSubscribers.Completion<Upstream.Failure>) -> Void)?

        ///  A closure that executes when the downstream receiver cancels publishing.
        public var receiveCancel: (() -> Void)?

        /// A closure that executes when the publisher receives a request for more elements.
        public var receiveRequest: ((NKSubscribers.Demand) -> Void)?

        public init(upstream: Upstream,
                    receiveSubscription: ((NKSubscription) -> Void)? = nil,
                    receiveOutput: ((NKPublishers.HandleEvents<Upstream>.Output) -> Void)? = nil,
                    receiveCompletion: ((NKSubscribers.Completion<NKPublishers.HandleEvents<Upstream>.Failure>) -> Void)? = nil,
                    receiveCancel: (() -> Void)? = nil,
                    receiveRequest: ((NKSubscribers.Demand) -> Void)?) {
            
            
            self.upstream = upstream
            self.receiveSubscription = receiveSubscription
            self.receiveOutput = receiveOutput
            self.receiveCompletion = receiveCompletion
            self.receiveCancel = receiveCancel
            self.receiveRequest = receiveRequest
        }

        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            
            let upstreamSubscriber = UpstreamHandleEventsSink<S, Upstream>(downstream: subscriber,
                                                                           receiveSubscription: receiveSubscription,
                                                                           receiveOutput: receiveOutput,
                                                                           receiveCompletion: receiveCompletion,
                                                                           receiveCancel: receiveCancel,
                                                                           receiveRequest: receiveRequest)
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
