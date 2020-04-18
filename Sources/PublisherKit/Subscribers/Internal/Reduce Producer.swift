//
//  Reduce Producer.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/03/20.
//

class ReduceProducer<Downstream: Subscriber, Output, Input, Failure: Error, Reducer>: CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Downstream.Input == Output {
    
    private var status: SubscriptionStatus = .awaiting
    private let lock = Lock()
    
    private let downstream: Downstream
    private var downstreamRequested = false
    
    var result: Output?
    private let initial: Output?

    private var cancelled = false

    private var completed = false

    private var upstreamCompleted = false

    private var empty = true
    
    let reduce: Reducer
    
    init(downstream: Downstream, initial: Output? = nil, reduce: Reducer) {
        self.downstream = downstream
        self.initial = initial
        result = initial
        self.reduce = reduce
    }
    
    func receive(newValue: Input) -> PartialCompletion<Void, Downstream.Failure> {
        fatalError("receive(_:) not overrided.")
    }
    
    var description: String {
        "Inner"
    }
    
    var playgroundDescription: Any {
        description
    }
    
    var customMirror: Mirror {
        lock.lock()
        defer { lock.unlock() }
        
        let children: [Mirror.Child] = [
            ("downstream", downstream as Any),
            ("status", status)
        ]
        
        return Mirror(self, children: children)
    }
    
    private func sendResultAndFinish(_ result: Output?) {
        assert(completed && upstreamCompleted)
        
        if let result = result {
            _ = downstream.receive(result)
        }
        
        downstream.receive(completion: .finished)
    }
}

extension ReduceProducer: Subscriber {
    
    func receive(subscription: Subscription) {
        lock.lock()
        guard status == .awaiting else {
            lock.unlock()
            subscription.cancel()
            return
        }
        
        status = .subscribed(to: subscription)
        lock.unlock()
        
        downstream.receive(subscription: self)
        subscription.request(.unlimited)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        lock.lock()
        guard case .subscribed(let subscription) = status else { lock.unlock(); return .none }
        empty = true
        lock.unlock()
        
        switch receive(newValue: input) {
            
        case .continue: break
            
        case .finished:
            lock.lock()
            status = .terminated
            upstreamCompleted = true
            
            let downstreamRequested = self.downstreamRequested
            if downstreamRequested { completed = true }
            
            let result = self.result
            lock.unlock()
            
            subscription.cancel()
            
            guard downstreamRequested else { break }
            
            sendResultAndFinish(result)
            
        case .failure(let error):
            lock.lock()
            status = .terminated
            upstreamCompleted = true
            completed = true
            lock.unlock()
            
            subscription.cancel()
            
            downstream.receive(completion: .failure(error))
        }
        
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        lock.lock()
        guard status.isSubscribed else { lock.unlock(); return }
        status = .terminated
        
        switch completion {
        case .finished:
            receiveFinished()
            
        case .failure(let error):
            receiveFailure(error)
        }
    }
    
    private func receiveFinished() {
        guard !cancelled, !completed, !upstreamCompleted else {
            // this should never get called
            lock.unlock()
            return
        }
        
        upstreamCompleted = true
        completed = downstreamRequested || empty
        let completed = self.completed
        let result = self.result
        lock.unlock()

        if completed {
            sendResultAndFinish(result)
        }
    }
    
    private func receiveFailure(_ error: Failure) {
        guard !cancelled, !completed, !upstreamCompleted else {
            // this should never get called
            lock.unlock()
            return
        }
        
        upstreamCompleted = true
        completed = true
        lock.unlock()
        
        downstream.receive(completion: .failure(error as! Downstream.Failure))
    }
}

extension ReduceProducer: Subscription {
    
    func request(_ demand: Subscribers.Demand) {
        precondition(demand > .none, "demand must be greater than zero.")
        lock.lock()
        guard !downstreamRequested, !cancelled, !completed, !status.isTerminated else { lock.unlock(); return }
        
        downstreamRequested = true
        
        guard upstreamCompleted else { lock.unlock(); return }
        completed = true
        
        let result = self.result
        lock.unlock()
        
        sendResultAndFinish(result)
    }
    
    func cancel() {
        lock.lock()
        guard case .subscribed(let subscription) = status else { lock.unlock(); return }
        status = .terminated
        cancelled = true
        lock.unlock()
        
        subscription.cancel()
    }
}
