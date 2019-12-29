//
//  Any Cancellable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

final public class NKAnyCancellable: NKCancellable, Hashable {
    
    private final let block: () -> Void
    private final let uuid: UUID
    
    var isCancelled = false
    
    private var storagePointer: UnsafeMutablePointer<Set<NKAnyCancellable>>?
    
    /// Initializes the cancellable object with the given cancel-time closure.
    ///
    /// - Parameter cancel: A closure that the `cancel()` method executes.
    public init(cancel: @escaping () -> Void) {
        block = cancel
        uuid = UUID()
    }
    
    public init<C: NKCancellable>(_ canceller: C) {
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
        storagePointer?.pointee.remove(self)
        storagePointer = nil
    }
    
    public final func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public static func == (lhs: NKAnyCancellable, rhs: NKAnyCancellable) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public final func store(in set: inout Set<NKAnyCancellable>) {
        storagePointer = withUnsafeMutablePointer(to: &set) { (ptr) in
            return ptr
        }
        
        set.insert(self)
    }
}
