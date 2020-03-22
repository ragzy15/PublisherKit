//
//  Internal Subscribers.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

extension Subscribers {
    
    // MARK: BASE
    class InternalBase<Downstream: Subscriber, Input, Failure: Error>: Subscriptions.InternalBase<Downstream, Input, Failure>, Subscriber {
        
        final var status: SubscriptionStatus = .awaiting
        var requiredDemand: Subscribers.Demand = .unlimited
        
        private let lock = Lock()
        
        final func getLock() -> Lock {
            lock
        }
        
        final func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            onSubscription(subscription)
        }
        
        override func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            super.request(demand)
            lock.unlock()
        }
        
        func onSubscription(_ subscription: Subscription) {
            status = .subscribed(to: subscription)
            lock.unlock()
            downstream?.receive(subscription: self)
            subscription.request(requiredDemand)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            end {
                onCompletion(completion)
            }
        }
        
        func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            /* abstract method */
            nil
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            lock.unlock()
            switch operate(on: input) {
            case .success(let output):
                _ = downstream?.receive(output)
                
            case .failure(let error):
                lock.lock()
                end {
                    downstream?.receive(completion: .failure(error))
                }
                
            case .none: break
            }
            
            return demand
        }
        
        override var description: String {
            "Inner"
        }
        
        override var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("downstream", downstream as Any),
                ("status", status)
            ]
            
            return Mirror(self, children: children)
        }
        
        override func cancel() {
            lock.lock()
            switch status {
            case .subscribed(let subscription):
                status = .terminated
                lock.unlock()
                subscription.cancel()
                
            case .multipleSubscription(let subscriptions):
                status = .terminated
                lock.unlock()
                subscriptions.forEach { (subscription) in
                    subscription.cancel()
                }
                
            default: lock.unlock()
            }
            
            downstream = nil
        }
        
        override func end(completion: () -> Void) {
            status = .terminated
            lock.unlock()
            completion()
            downstream = nil
        }
    }
    
    // MARK: INNER
    class Inner<Downstream: Subscriber, Input, Failure>: InternalBase<Downstream, Input, Failure> where Downstream.Input == Input, Downstream.Failure == Failure {
        
        override func operate(on input: Input) -> Result<Downstream.Input, Downstream.Failure>? {
            .success(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
        }
    }
}
