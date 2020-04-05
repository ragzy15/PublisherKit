//
//  Empty.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 02/02/20.
//

extension Subscriptions {
    
    /// Returns the 'empty' subscription.
    ///
    /// Use the empty subscription when you need a `Subscription` that ignores requests and cancellation.
    public static var empty: Subscription { _EmptySubscription() }
}

extension Subscriptions {
    
    private class _EmptySubscription: Subscription {
        
        init() {}
        
        func request(_ demand: Subscribers.Demand) {}
        
        func cancel() {}
    }
}
