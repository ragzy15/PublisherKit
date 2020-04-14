//
//  Locks.swift
//  PublisherKitFoundation
//
//  Created by Raghav Ahuja on 09/04/20.
//

import Darwin

typealias Lock = __PKUnfairLock
typealias RecursiveLock = __PKUnfairRecursiveLock

protocol Locking {
    /// Attempts to acquire a lock, blocking a thread’s execution until the lock can be acquired.
    ///
    /// An application protects a critical section of code by requiring a thread to acquire a lock before executing the code. Once the critical section is completed, the thread relinquishes the lock by invoking [unlock()](apple-reference-documentation://hsNRwYT2vz).
    func lock()
    
    /// Relinquishes a previously acquired lock.
    func unlock()
    
    // Asserts if the owner of the lock still exists.
    func assertOwner()
}

class __PKUnfairLock: Locking {
    
    private var _lock: Locking?
    
    init() {
        if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
            _lock = OSUnfairLock()
        } else {
            _lock = MutexLock()
        }
    }
    
    final func lock() {
        _lock?.lock()
    }
    
    final func unlock() {
        _lock?.unlock()
    }
    
    final func assertOwner() {
        _lock?.assertOwner()
    }
    
    @inlinable func `do`<Result>(_ body: () throws -> Result) rethrows -> Result {
        lock()
        defer { unlock() }
        return try body()
    }
}

final class __PKUnfairRecursiveLock: Locking {
    
    private var _lock: RecursiveMutexLock?
    
    init() {
        _lock = RecursiveMutexLock()
    }
    
    final func lock() {
        _lock?.lock()
    }
    
    final func unlock() {
        _lock?.unlock()
    }
    
    final func assertOwner() {
        _lock?.assertOwner()
    }
    
    @inlinable func `do`<Result>(_ body: () throws -> Result) rethrows -> Result {
        lock()
        defer { unlock() }
        return try body()
    }
}

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
fileprivate final class OSUnfairLock: Locking {
    private var unfairLock = os_unfair_lock()
    
    func lock() {
        os_unfair_lock_lock(&unfairLock)
    }
    
    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }
    
    func assertOwner() {
        os_unfair_lock_assert_owner(&unfairLock)
    }
}

fileprivate class MutexLock: Locking {
    
    private var mutex: pthread_mutex_t
    
    convenience init() {
        let attributes = MutexAttributes()
        attributes.setErrorCheck()
        self.init(attributes: attributes)
    }
    
    func assertOwner() {
    }
    
    func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    final class MutexAttributes {
        
        fileprivate var attributes: pthread_mutexattr_t = {
            var attributes = pthread_mutexattr_t()
            return attributes
        }()
        
        func setRecursive() {
            setType(PTHREAD_MUTEX_RECURSIVE)
        }
        
        func setErrorCheck() {
            setType(PTHREAD_MUTEX_ERRORCHECK)
        }
        
        private func setType(_ type: Int32) {
            pthread_mutexattr_settype(&attributes, type)
        }
    }
    
    init(attributes: MutexAttributes) {
        mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, &attributes.attributes)
    }
}

fileprivate final class RecursiveMutexLock: MutexLock {
    
    convenience init() {
        let attributes = MutexAttributes()
        attributes.setRecursive()
        self.init(attributes: attributes)
    }
}

