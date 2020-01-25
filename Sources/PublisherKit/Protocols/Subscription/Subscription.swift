//
//  Subscription.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "PKSubscription")
public typealias NKSubscription = PKSubscription

public protocol PKSubscription: PKCancellable {

    /// Tells a publisher that it may send more values to the subscriber.
    func request(_ demand: PKSubscribers.Demand)
}
