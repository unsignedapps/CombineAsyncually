//
//  Publisher+Await.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Combine

public extension Publisher {

    /// Transforms an output value into a new Publisher the provided `async` closure.
    ///
    /// This is more or less the same as Combine's `.map` operator but it accepts an `async`
    /// closure instead.
    ///
    /// - Returns:  A publisher that uses the provided closure to map elements from the upstream publisher to new
    ///             elements that it then publishes.
    ///
    func `await`<T>(_ transform: @escaping (Output) async -> T) -> AnyPublisher<T, Failure> {
        self
            .flatMap { value -> Task.Publisher<T> in
                Task.Publisher {
                    await transform(value)
                }
            }
            .eraseToAnyPublisher()
    }

}

public extension Publisher where Failure == Error {

    /// Transforms an output value into a new Publisher the provided `async` closure.
    ///
    /// This is more or less the same as Combine's `.tryMap` operator but it accepts an `async`
    /// closure instead.
    ///
    /// - Returns:  A publisher that uses the provided closure to map elements from the upstream publisher to new
    ///             elements that it then publishes.
    ///
    func tryAwait<T>(_ transform: @escaping (Output) async throws -> T) -> AnyPublisher<T, Error> {
        self
            .flatMap { value -> Task.ThrowingPublisher<T> in
                Task.ThrowingPublisher {
                    try await transform(value)
                }
            }
            .eraseToAnyPublisher()
    }

}

public extension Publisher where Failure == Never {

    /// Transforms an output value into a new Publisher the provided `async` closure.
    ///
    /// This is more or less the same as Combine's `.tryMap` operator but it accepts an `async`
    /// closure instead.
    ///
    /// - Returns:  A publisher that uses the provided closure to map elements from the upstream publisher to new
    ///             elements that it then publishes.
    ///
    func tryAwait<T>(_ transform: @escaping (Output) async throws -> T) -> AnyPublisher<T, Error> {
        self
            .setFailureType(to: Error.self)
            .flatMap { value -> Task.ThrowingPublisher<T> in
                Task.ThrowingPublisher {
                    try await transform(value)
                }
            }
            .eraseToAnyPublisher()
    }

}
