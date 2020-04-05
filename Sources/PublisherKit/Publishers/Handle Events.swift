//
//  Handle Events.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

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
                    receiveOutput: ((Output) -> Void)? = nil,
                    receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)? = nil,
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
            
            let handleEventsSubscriber = Inner<S, Upstream>(downstream: subscriber,
                                                            receiveSubscription: receiveSubscription,
                                                            receiveOutput: receiveOutput,
                                                            receiveCompletion: receiveCompletion,
                                                            receiveCancel: receiveCancel,
                                                            receiveRequest: receiveRequest)
            
            subscriber.receive(subscription: handleEventsSubscriber)
            upstream.subscribe(handleEventsSubscriber)
        }
    }
}

extension Publishers.HandleEvents {
    
    // MARK: HANDLE EVENTS SINK
    private final class Inner<Downstream: Subscriber, Upstream: Publisher>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        private var pendingDemand: Subscribers.Demand = .none
        private let lock = Lock()
        
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
            
            self.downstream = downstream
        }
        
        func receive(subscription: Subscription) {
            receiveSubscription?(subscription)
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            
            let pendingDemand = self.pendingDemand
            self.pendingDemand = .none
            lock.unlock()
            
            if pendingDemand > 0 {
                subscription.request(pendingDemand)
            }
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            receiveOutput?(input)
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            lock.unlock()
            
            let newDemand = downstream?.receive(input) ?? .none
            if newDemand > .none {
                receiveRequest?(newDemand)
            }
            
            return newDemand
        }
        
        func receive(completion: Subscribers.Completion<Downstream.Failure>) {
            receiveCompletion?(completion)
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            downstream?.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            receiveRequest?(demand)
            lock.lock()
            if case .subscribed(let subscription) = status {
                lock.unlock()
                subscription.request(demand)
                return
            }
            pendingDemand += demand
            lock.unlock()
        }
        
        func cancel() {
            receiveCancel?()
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            subscription.cancel()
        }
        
        var description: String {
            "HandleEvents"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
