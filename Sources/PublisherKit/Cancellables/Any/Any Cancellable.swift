//
//  Any Cancellable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/11/19.
//

import Foundation

public typealias PKCancellables = Set<PKAnyCancellable>

@available(*, deprecated, renamed: "PKAnyCancellable")
public typealias NKAnyCancellable = PKAnyCancellable

final public class PKAnyCancellable: PKCancellable, Hashable {
    
    private final let block: () -> Void
    private final let uuid: UUID
    
    var isCancelled = false
    
    //    private var storagePointer: UnsafeMutablePointer<Set<PKAnyCancellable>>?
    
    /// Initializes the cancellable object with the given cancel-time closure.
    ///
    /// - Parameter cancel: A closure that the `cancel()` method executes.
    public init(cancel: @escaping () -> Void) {
        block = cancel
        uuid = UUID()
    }
    
    public init<C: PKCancellable>(_ canceller: C) {
        block = canceller.cancel
        uuid = UUID()
    }
    
    deinit {
        if !isCancelled {
            cancel()
        }
    }
    
    public final func cancel() {
        isCancelled = true
        block()
    }
    
    public final func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public static func == (lhs: PKAnyCancellable, rhs: PKAnyCancellable) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public final func store(in set: inout Set<PKAnyCancellable>) {
        set.insert(self)
    }
}
