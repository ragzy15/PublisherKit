//
//  Subject Base Subscriber.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 03/02/20.
//

import Foundation

class SubjectBaseSubscriber<Output, Failure: Error>: Subscription, Hashable {
    
    static func == (lhs: SubjectBaseSubscriber, rhs: SubjectBaseSubscriber) -> Bool {
        lhs.identitfier == rhs.identitfier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identitfier)
    }
    
    private var identitfier: ObjectIdentifier!
    
    private var downstream: AnySubscriber<Output, Failure>?
    
    var isOver = false
    
    private(set) var _demand: Subscribers.Demand = .none
    
    init(downstream: AnySubscriber<Output, Failure>) {
        self.downstream = downstream
        identitfier = ObjectIdentifier(self)
    }
    
    func request(_ demand: Subscribers.Demand) {
        _demand += demand
    }
    
    final func receive(_ input: Output) {
        guard !isOver, _demand > .none else { return }
        let newDemand = downstream?.receive(input)
        _demand = newDemand ?? .none
    }
    
    final func receive(completion: Subscribers.Completion<Failure>) {
        guard !isOver else { return }
        downstream?.receive(completion: completion)
        finish()
    }
    
    final func cancel() {
        finish()
    }
    
    @inlinable func finish() {
        isOver = true
        downstream = nil
    }
}
