//
//  Reduce Producer.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/03/20.
//

class ReduceProducer<Downstream: Subscriber, Output, Input, Failure: Error, Operator>: CustomStringConvertible, CustomReflectable where Downstream.Input == Output {
    
    private var status: SubscriptionStatus = .awaiting
    private let lock = Lock()
    
    private var downstream: Downstream?
    private var requestReceived = false
    var output: Output?
    
    let operation: Operator
    
    init(downstream: Downstream, initial: Output? = nil, operation: Operator) {
        self.downstream = downstream
        output = initial
        self.operation = operation
    }
    
    func receive(input: Input) -> CompletionResult<Void, Downstream.Failure> {
        fatalError("receive(_:) not overrided.")
    }
    
    var description: String {
        "Inner"
    }
    
    var customMirror: Mirror {
        lock.lock()
        defer { lock.unlock() }
        
        let children: [Mirror.Child] = [
            ("downstream", downstream ?? "nil"),
            ("status", status)
        ]
        
        return Mirror(self, children: children)
    }
}

extension ReduceProducer: Subscriber {
    
    func receive(subscription: Subscription) {
        lock.lock()
        guard status == .awaiting else { lock.unlock(); return }
        status = .subscribed(to: subscription)
        lock.unlock()
        
        downstream?.receive(subscription: self)
        subscription.request(.unlimited)
    }
    
    private func sendAndFinish(with output: Output?) {
        if let output = output {
            _ = downstream?.receive(output)
        }
        
        downstream?.receive(completion: .finished)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        lock.lock()
        guard case let .subscribed(subscription) = status else { lock.unlock(); return .none }
        lock.unlock()
        
        switch receive(input: input) {
            
        case .send: break
            
        case .finished:
            lock.lock()
            status = .terminated
            let finalOutput = output
            lock.unlock()
            
            subscription.cancel()
            sendAndFinish(with: finalOutput)
            
        case .failure(let error):
            lock.lock()
            status = .terminated
            lock.unlock()
            
            subscription.cancel()
            
            downstream?.receive(completion: .failure(error))
        }
        
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        lock.lock()
        guard status.isSubscribed else { lock.unlock(); return }
        let finalOutput = output
        lock.unlock()
        
        switch completion {
        case .finished:
            sendAndFinish(with: finalOutput)
            
        case .failure(let error):
            lock.lock()
            status = .terminated
            lock.unlock()
            
            downstream?.receive(completion: .failure(error as! Downstream.Failure))
        }
    }
}

extension ReduceProducer: Subscription {
    
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard status.isTerminated, !requestReceived else { lock.unlock(); return }
        
        requestReceived = true
        let finalOutput = output
        lock.unlock()
        
        sendAndFinish(with: finalOutput)
    }
    
    func cancel() {
        lock.lock()
        guard case let .subscribed(subscription) = status else {
            lock.unlock()
            return
        }
        
        status = .terminated
        lock.unlock()
        subscription.cancel()
        downstream = nil
    }
}
