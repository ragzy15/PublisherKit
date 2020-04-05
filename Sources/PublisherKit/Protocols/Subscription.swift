//
//  Subscription.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

public protocol Subscription: Cancellable, CustomCombineIdentifierConvertible {
    
    /// Tells a publisher that it may send more values to the subscriber.
    func request(_ demand: Subscribers.Demand)
}
