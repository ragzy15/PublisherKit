//
//  Cancellable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public protocol NKCancellable {
    
    /// Cancel the activity.
    func cancel()
}

extension NKCancellable {
    
    /// Stores this Cancellable in the specified set.
    /// Parameters:
    ///    - collection: The set to store this Cancellable.
    public func store(in set: inout Set<NKAnyCancellable>) {
        
        let anyCancellable = NKAnyCancellable(self)
        anyCancellable.store(in: &set)
    }
}
