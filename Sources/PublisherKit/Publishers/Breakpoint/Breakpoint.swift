//
//  Breakpoint.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

import Darwin

extension Publishers {
    
    /// A publisher that raises a debugger signal when a provided closure needs to stop the process in the debugger.
    ///
    /// When any of the provided closures returns `true`, this publisher raises the `SIGTRAP` signal to stop the process in the debugger.
    /// Otherwise, this publisher passes through values and completions as-is.
    public struct Breakpoint<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A closure that executes when the publisher receives a subscription, and can raise a debugger signal by returning a true Boolean value.
        public let receiveSubscription: ((Subscription) -> Bool)?
        
        /// A closure that executes when the publisher receives output from the upstream publisher, and can raise a debugger signal by returning a true Boolean value.
        public let receiveOutput: ((Upstream.Output) -> Bool)?
        
        /// A closure that executes when the publisher receives completion, and can raise a debugger signal by returning a true Boolean value.
        public let receiveCompletion: ((Subscribers.Completion<Upstream.Failure>) -> Bool)?
        
        /// Creates a breakpoint publisher with the provided upstream publisher and breakpoint-raising closures.
        ///
        /// - Parameters:
        ///   - upstream: The publisher from which this publisher receives elements.
        ///   - receiveSubscription: A closure that executes when the publisher receives a subscription, and can raise a debugger signal by returning a true Boolean value.
        ///   - receiveOutput: A closure that executes when the publisher receives output from the upstream publisher, and can raise a debugger signal by returning a true Boolean value.
        ///   - receiveCompletion: A closure that executes when the publisher receives completion, and can raise a debugger signal by returning a true Boolean value.
        public init(upstream: Upstream,
                    receiveSubscription: ((Subscription) -> Bool)? = nil,
                    receiveOutput: ((Upstream.Output) -> Bool)? = nil,
                    receiveCompletion: ((Subscribers.Completion<Failure>) -> Bool)? = nil) {
            
            self.upstream = upstream
            self.receiveSubscription = receiveSubscription
            self.receiveOutput = receiveOutput
            self.receiveCompletion = receiveCompletion
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let breakpointSubscriber = Inner(downstream: subscriber,
                                             receiveSubscription: receiveSubscription,
                                             receiveOutput: receiveOutput,
                                             receiveCompletion: receiveCompletion)
            upstream.subscribe(breakpointSubscriber)
        }
    }
}


extension Publishers.Breakpoint {
    
    // MARK: BREAKPOINT SINK
    private struct Inner<Downstream: Subscriber>: Subscriber, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
        
        typealias Input = Downstream.Input
        
        typealias Failure = Downstream.Failure
        
        let combineIdentifier: CombineIdentifier
        
        private let receiveSubscription: ((Subscription) -> Bool)?
        
        private let receiveOutput: ((Input) -> Bool)?
        
        private let receiveCompletion: ((Subscribers.Completion<Failure>) -> Bool)?
        
        private let signal = Int32(SIGTRAP)
        
        private var downstream: Downstream?
        
        init(downstream: Downstream,
             receiveSubscription: ((Subscription) -> Bool)? = nil,
             receiveOutput: ((Input) -> Bool)? = nil,
             receiveCompletion: ((Subscribers.Completion<Failure>) -> Bool)? = nil) {
            
            self.receiveSubscription = receiveSubscription
            self.receiveOutput = receiveOutput
            self.receiveCompletion = receiveCompletion
            self.downstream = downstream
            combineIdentifier = CombineIdentifier()
        }
        
        func receive(subscription: Subscription) {
            if receiveSubscription?(subscription) ?? false {
                Darwin.raise(signal)
            }
            
            downstream?.receive(subscription: subscription)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            if receiveOutput?(input) ?? false {
                Darwin.raise(signal)
            }
            
            return downstream?.receive(input) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            if receiveCompletion?(completion) ?? false {
                Darwin.raise(signal)
            }
            
            downstream?.receive(completion: completion)
        }
        
        var description: String {
            "Breakpoint"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
