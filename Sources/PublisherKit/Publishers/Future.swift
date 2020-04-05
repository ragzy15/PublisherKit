//
//  Future.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 13/03/20.
//

/// A publisher that eventually produces one value and then finishes or fails.
final public class Future<Output, Failure>: Publisher where Failure : Error {

    private var result: Result<Output, Failure>?
    
    private let lock = Lock()
    private let downstreamLock = RecursiveLock()

    private var subscriptions: [Conduit] = []

    public typealias Promise = (Result<Output, Failure>) -> Void

    public init(_ attemptToFulfill: @escaping (@escaping Promise) -> Void) {
        attemptToFulfill { [weak self] result in
            self?.promise(result)
        }
    }
    
    public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        lock.lock()
        let conduit = Conduit(parent: self, downstream: AnySubscriber(subscriber))
        subscriptions.append(conduit)
        conduit.index = subscriptions.count - 1
        lock.unlock()
        
        subscriber.receive(subscription: conduit)
    }
    
    private func promise(_ newResult: Result<Output, Failure>) {
        lock.lock()
        guard result == nil else { lock.unlock(); return }
        result = newResult
        let subscriptions = self.subscriptions
        lock.unlock()
        
        subscriptions.forEach { (subscription) in
            subscription.fullfill(newResult)
        }
    }
    
    fileprivate func disassociate(_ index: Int) {
        subscriptions.remove(at: index)
    }
}

extension Future {

    // MARK: FUTURE SINK
    private final class Conduit: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
        
        private let parent: Future<Output, Failure>
        private let downstream: AnySubscriber<Output, Failure>
        
        fileprivate var index: Int = 0
        
        fileprivate var hasAnyDemand = false
        
        init(parent: Future<Output, Failure>, downstream: AnySubscriber<Output, Failure>) {
            self.parent = parent
            self.downstream = downstream
        }
        
        func fullfill(_ result: Result<Output, Failure>) {
            parent.downstreamLock.lock()
            guard hasAnyDemand else { parent.downstreamLock.unlock(); return }
            
            switch result {
            case .success(let output):
                _ = downstream.receive(output)
                downstream.receive(completion: .finished)
                
            case .failure(let error):
                downstream.receive(completion: .failure(error))
            }
            
            parent.disassociate(index)
            parent.downstreamLock.unlock()
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "demand must not be negative.")
            hasAnyDemand = true
            parent.lock.lock()
            guard let result = parent.result else { parent.lock.unlock(); return }
            parent.lock.unlock()
            
            parent.downstreamLock.lock()
            switch result {
            case .success(let output):
                _ = downstream.receive(output)
                downstream.receive(completion: .finished)
                
            case .failure(let error):
                downstream.receive(completion: .failure(error))
            }
            
            parent.disassociate(index)
            parent.downstreamLock.unlock()
        }
        
        func cancel() {
            parent.lock.lock()
            parent.disassociate(index)
            parent.lock.unlock()
        }

        var description: String {
            "Future"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("parent", parent),
                ("downstream", downstream.box),
                ("hasAnyDemand", hasAnyDemand)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
