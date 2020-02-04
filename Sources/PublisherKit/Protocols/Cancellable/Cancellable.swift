//
//  Cancellable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

@available(*, deprecated, renamed: "Cancellable")
public typealias NKCancellable = Cancellable

@available(*, deprecated, renamed: "Cancellable")
public typealias PKCancellable = Cancellable
 
public protocol Cancellable {
    
    /// Cancel the activity.
    func cancel()
}

extension Cancellable {
    
    /// Stores this Cancellable in the specified set.
    /// Parameters:
    ///    - collection: The set to store this Cancellable.
    public func store(in set: inout CancellableBag) {
        
        let anyCancellable = AnyCancellable(self)
        anyCancellable.store(in: &set)
    }
}
