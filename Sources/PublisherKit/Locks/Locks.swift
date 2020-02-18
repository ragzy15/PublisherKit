//
//  Locks.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 13/02/20.
//

import Darwin

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

class Lock: Locking {
    
    private var _lock: Locking?
    
    convenience init() {
        if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
            self.init(lock: OSUnfaireLock())
        } else {
            self.init(lock: MutexLock())
        }
    }
    
    init(lock: Locking) {
        _lock = lock
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

final class RecursiveLock: Lock {
    
    convenience init() {
        self.init(lock: RecursiveMutexLock())
    }
}

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
fileprivate final class OSUnfaireLock: Locking {
    private var unfairLock = os_unfair_lock_s()
    
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
    
    fileprivate var mutex: pthread_mutex_t
    
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
