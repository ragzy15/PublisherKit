//
//  Subject Subscriber.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 02/02/20.
//

import Foundation

final class SubjectSubscriber<DownstreamSubject: Subject>: Subscriber, Subscription {
    
    typealias Input = DownstreamSubject.Output
    
    typealias Failure = DownstreamSubject.Failure
    
    private var isCancelled = false
    
    private var isEnded = false
    
    private var isOver: Bool {
        isEnded || isCancelled
    }
    
    private var subject: DownstreamSubject?
    
    private var subscription: Subscription?
    
    init(subject: DownstreamSubject) {
        self.subject = subject
    }
    
    func request(_ demand: Subscribers.Demand) {
        guard !isOver else { return }
        subscription?.request(demand)
    }
    
    func receive(subscription: Subscription) {
        guard !isOver else { return }
        self.subscription = subscription
        subject?.send(subscription: self)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        guard !isOver else { return .none }
        subject?.send(input)
        return .unlimited
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        guard !isOver else { return }
        end()
        subject?.send(completion: completion)
    }
    
    func end() {
        isEnded = true
        subscription = nil
        subject = nil
    }
    
    func cancel() {
        isCancelled = true
        subscription?.cancel()
        subscription = nil
        subject = nil
    }
}
