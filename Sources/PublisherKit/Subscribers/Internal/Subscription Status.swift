//
//  Subscription Status.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 09/02/20.
//

enum SubscriptionStatus: Equatable {
    
    case awaiting
    case subscribed(to: Subscription)
    case multipleSubscription(to: [Subscription])
    case terminated
    
    static func == (lhs: SubscriptionStatus, rhs: SubscriptionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.awaiting, .awaiting):
            return true
            
        case (.terminated, .terminated):
            return true
            
        case (.subscribed(let subscription1), .subscribed(let subscription2)):
            return subscription1.combineIdentifier == subscription2.combineIdentifier
            
        case (.multipleSubscription(let subscriptions1), .multipleSubscription(let subscriptions2)):
            if subscriptions1.count != subscriptions2.count {
                return false
            } else {
                for subscription in subscriptions1 {
                    if !subscriptions2.contains(where: { (sub) -> Bool in
                        sub.combineIdentifier == subscription.combineIdentifier
                    }) {
                        return false
                    }
                }
                
                return true
            }
            
        default:
            return false
        }
    }
    
    var isTerminated: Bool {
        self == .terminated
    }
    
    var isSubscribed: Bool {
        switch self {
        case .subscribed: return true
        case .multipleSubscription(let subscriptions): return !subscriptions.isEmpty
        default: return false
        }
    }
}
