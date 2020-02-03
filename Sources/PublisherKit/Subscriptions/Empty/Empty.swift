//
//  Empty.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 02/02/20.
//

import Foundation

extension Subscriptions {
    
    /// Returns the 'empty' subscription.
    ///
    /// Use the empty subscription when you need a `Subscription` that ignores requests and cancellation.
    public static var empty: PKSubscription { EmptySubscription() }
}

private extension Subscriptions {
    
    class EmptySubscription: PKSubscription {
        
        init() {}
        
        func request(_ demand: PKSubscribers.Demand) {}
        
        func cancel() {}
    }
}
