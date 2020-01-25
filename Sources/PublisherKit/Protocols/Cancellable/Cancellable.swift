//
//  Cancellable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "PKCancellable")
public typealias NKCancellable = PKCancellable
 

public protocol PKCancellable {
    
    /// Cancel the activity.
    func cancel()
}

extension PKCancellable {
    
    /// Stores this Cancellable in the specified set.
    /// Parameters:
    ///    - collection: The set to store this Cancellable.
    public func store(in set: inout Set<PKAnyCancellable>) {
        
        let anyCancellable = PKAnyCancellable(self)
        anyCancellable.store(in: &set)
    }
}
