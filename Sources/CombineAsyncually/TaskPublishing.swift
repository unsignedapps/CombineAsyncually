//
//  TaskPublishing.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Combine


/// Creates a cold Publisher that emits the result returned from the given async closure
///
/// ```swift
/// // emits the result of someFunc
/// Single {
///     await someFunc()
/// }
/// ```
///
public func withPublisher<Output>(_ closure: @escaping () async -> Output) -> Task.Publisher<Output> {
    Task.Publisher(closure)
}

/// Creates a cold Publisher that emits the result returned from the given throwing async closure,
/// or fails if the closure throws an error.
///
/// ```swift
/// // emits the result of someFunc
/// Single {
///     try await someFunc()
/// }
/// ```
///
public func withThrowingPublisher<Output>(_ closure: @escaping () async throws -> Output) -> Task.ThrowingPublisher<Output> {
    Task.ThrowingPublisher(closure)
}
