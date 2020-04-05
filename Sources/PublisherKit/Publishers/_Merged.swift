//
//  _Merged.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 22/03/20.
//

extension Publishers {
    
    final class _Merged<Downstream: Subscriber> {
        
        typealias Input = Downstream.Input
        
        typealias Failure = Downstream.Failure
        
        private var downstream: Downstream?
        
        private var upstreamSubscriptions: [Subscription?]
        
        private let upstreamCount: Int
        private var finishedSubscriptions: Int = 0
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        private var demand: Subscribers.Demand = .max(1)
        
        private var isTerminated = false
        private var isActive = false
        
        init(downstream: Downstream, upstreamCount: Int) {
            self.downstream = downstream
            self.upstreamCount = upstreamCount
            self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
        }
        
        fileprivate final func receive(subscription: Subscription, _ index: Int) {
            lock.lock()
            guard !isTerminated && upstreamSubscriptions[index] == nil else {
                lock.unlock()
                subscription.cancel()
                return
            }
            
            upstreamSubscriptions[index] = subscription
            lock.unlock()
            subscription.request(demand == .unlimited ? .unlimited : .max(1))
        }
        
        fileprivate final func receive(_ input: Input, _ index: Int) -> Subscribers.Demand {
            lock.lock()
            guard !isTerminated else { lock.unlock(); return .none }
            
            guard !isActive, demand > 0 else { lock.unlock(); return .none }
            
            demand -= 1
            isActive = true
            lock.unlock()
            
            downstreamLock.lock()
            let additionalDemand = downstream?.receive(input) ?? .none
            downstreamLock.unlock()
            
            lock.lock()
            isActive = false
            demand += additionalDemand
            lock.unlock()
            
            return demand
        }
        
        fileprivate final func receive(completion: Subscribers.Completion<Failure>, _ index: Int) {
            lock.lock()
            guard !isTerminated else { lock.unlock(); return }
            
            switch completion {
            case .finished:
                finishedSubscriptions += 1
                upstreamSubscriptions[index] = nil
                
                guard finishedSubscriptions == upstreamCount else { lock.unlock(); return }
                
                isTerminated = true
                lock.unlock()
                
                downstreamLock.lock()
                downstream?.receive(completion: .finished)
                downstreamLock.unlock()
                
            case .failure(let error):
                isTerminated = true
                
                let upstreamSubscriptions = self.upstreamSubscriptions
                self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
                
                lock.unlock()
                
                for (i, subscription) in upstreamSubscriptions.enumerated() where i != index {
                    subscription?.cancel()
                }
                
                downstreamLock.lock()
                downstream?.receive(completion: .failure(error))
                downstreamLock.unlock()
            }
        }
        
        struct Side: Subscriber, CustomStringConvertible {
            
            private let index: Int
            private let merged: _Merged
            
            let combineIdentifier = CombineIdentifier()
            
            init(index: Int, merged: _Merged) {
                self.index = index
                self.merged = merged
            }
            
            func receive(subscription: Subscription) {
                merged.receive(subscription: subscription, index)
            }
            
            func receive(_ input: Input) -> Subscribers.Demand {
                merged.receive(input, index)
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {
                merged.receive(completion: completion, index)
            }
            
            var description: String {
                "Merge"
            }
        }
    }
}

extension Publishers._Merged: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
    
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return }
        self.demand += demand
        lock.unlock()
        
        for subscription in upstreamSubscriptions {
            subscription?.request(demand)
        }
    }
    
    func cancel() {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return }
        isTerminated = true
        
        let upstreamSubscriptions = self.upstreamSubscriptions
        self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
        lock.unlock()
        
        for subscription in upstreamSubscriptions {
            subscription?.cancel()
        }
    }
    
    var description: String {
        "Merge"
    }
    
    var playgroundDescription: Any {
        description
    }
    
    var customMirror: Mirror {
        Mirror(self, children: [])
    }
}
