//
//  Any Cancellable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/11/19.
//

import Foundation

/// A collection of `AnyCancellable`.
public typealias CancellableBag = Set<AnyCancellable>

@available(*, deprecated, renamed: "AnyCancellable")
public typealias NKAnyCancellable = AnyCancellable

@available(*, deprecated, renamed: "AnyCancellable")
public typealias PKAnyCancellable = AnyCancellable

final public class AnyCancellable: Cancellable, Hashable {
    
    private final let block: () -> Void
    private final let uuid: UUID
    
    var isCancelled = false
    
    //    private var storagePointer: UnsafeMutablePointer<Set<AnyCancellable>>?
    
    /// Initializes the cancellable object with the given cancel-time closure.
    ///
    /// - Parameter cancel: A closure that the `cancel()` method executes.
    public init(cancel: @escaping () -> Void) {
        block = cancel
        uuid = UUID()
    }
    
    public init<C: Cancellable>(_ canceller: C) {
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
    
    public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public final func store(in set: inout CancellableBag) {
        set.insert(self)
    }
}
