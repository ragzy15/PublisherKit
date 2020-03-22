//
//  Subject Subscriber.swift
//  
//
//  Created by Raghav Ahuja on 20/03/20.
//

final class SubjectSubscriber<DownstreamSubject: Subject>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
    
    typealias Input = DownstreamSubject.Output
    
    typealias Failure = DownstreamSubject.Failure
    
    private var subject: DownstreamSubject?
    
    private var status: SubscriptionStatus = .awaiting
    
    private let lock = Lock()
    
    init(subject: DownstreamSubject) {
        self.subject = subject
    }
    
    final func receive(subscription: Subscription) {
        lock.lock()
        guard status == .awaiting else { lock.unlock(); return }
        status = .subscribed(to: subscription)
        lock.unlock()
        
        subject?.send(subscription: self)
    }
    
    final func receive(_ input: Input) -> Subscribers.Demand {
        lock.lock()
        guard status.isSubscribed else { lock.unlock(); return .none }
        lock.unlock()
        
        subject?.send(input)
        return .none
    }
    
    final func receive(completion: Subscribers.Completion<Failure>) {
        lock.lock()
        guard status.isSubscribed else { lock.unlock(); return }
        status = .terminated
        lock.unlock()
        
        subject?.send(completion: completion)
        subject = nil
    }
    
    final func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard case let .subscribed(subscription) = status else { lock.unlock(); return }
        lock.unlock()
        subscription.request(demand)
    }
    
    final func cancel() {
        lock.lock()
        guard case let .subscribed(subscription) = status else { lock.unlock(); return }
        status = .terminated
        subject = nil
        lock.unlock()
        
        subscription.cancel()
    }
    
    var description: String {
        "Subject"
    }
    
    var playgroundDescription: Any {
        description
    }
    
    var customMirror: Mirror {
        var subscription: Subscription? = nil
        if case .subscribed(let _subscription) = status {
            subscription = _subscription
        }
        
        let children: [Mirror.Child] = [
            ("downstreamSubject", subject as Any),
            ("upstreamSubscription", subscription as Any)
        ]
        
        return Mirror(self, children: children)
    }
}
