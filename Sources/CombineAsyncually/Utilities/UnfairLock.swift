//
//  UnfairLock.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Foundation

/// A type of lock or mutex that can be used to synchronise access
/// or execution of code by wrapping `os_unfair_lock`.
///
/// This lock must be unlocked from the same thread that locked it, attempts to
/// unlock from a different thread will cause an assertion aborting the process.
///
/// This lock must not be accessed from multiple processes or threads via shared
/// or multiply-mapped memory, the lock implementation relies on the address of
/// the lock value and owning process.
///
public class UnfairLock {

    public var mutex = os_unfair_lock()

    public init() {
        // Intentionally left blank
    }

}

// MARK: - Lock Implementation

public extension UnfairLock {

    func lock() {
        os_unfair_lock_lock(&mutex)
    }

    func unlock() {
        os_unfair_lock_unlock(&mutex)
    }

    func tryLock() -> Bool {
        os_unfair_lock_trylock(&mutex)
    }

    func synchronized<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try closure()
    }

    func trySynchronized<T>(_ closure: () throws -> T) rethrows -> T? {
        guard tryLock() else {
            return nil
        }
        defer {
            unlock()
        }
        return try closure()
    }

}
