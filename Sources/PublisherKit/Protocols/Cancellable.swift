//
//  Cancellable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public protocol Cancellable {
    
    /// Cancel the activity.
    func cancel()
}

extension Cancellable {
    
    /// Stores this Cancellable in the specified collection.
    /// - Parameter collection: The collection to store this Cancellable.
    public func store<C: RangeReplaceableCollection>(in collection: inout C) where C.Element == AnyCancellable {
        AnyCancellable(self).store(in: &collection)
    }
    
    /// Stores this Cancellable in the specified set.
    /// - Parameter set: The set to store this Cancellable.
    public func store(in set: inout CancellableBag) {
        AnyCancellable(self).store(in: &set)
    }
}
