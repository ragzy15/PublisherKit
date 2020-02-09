//
//  Any Cancellable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/11/19.
//

import Foundation

/// A set of `AnyCancellable`s.
public typealias CancellableBag = Set<AnyCancellable>

@available(*, deprecated, renamed: "AnyCancellable")
public typealias NKAnyCancellable = AnyCancellable

@available(*, deprecated, renamed: "AnyCancellable")
public typealias PKAnyCancellable = AnyCancellable

final public class AnyCancellable: Cancellable, Hashable {
    
    private final var _cancel: (() -> Void)?
    
    var isCancelled = false
    
    /// Initializes the cancellable object with the given cancel-time closure.
    ///
    /// - Parameter cancel: A closure that the `cancel()` method executes.
    public init(cancel: @escaping () -> Void) {
        _cancel = cancel
    }
    
    public init<C: Cancellable>(_ canceller: C) {
        _cancel = canceller.cancel
    }
    
    deinit {
        cancel()
    }
    
    public final func cancel() {
        isCancelled = true
        _cancel?()
        _cancel = nil
    }
    
    public final func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public func store<C: RangeReplaceableCollection>(in collection: inout C) where C.Element == AnyCancellable {
        collection.append(self)
    }
    
    public final func store(in set: inout CancellableBag) {
        set.insert(self)
    }
}
