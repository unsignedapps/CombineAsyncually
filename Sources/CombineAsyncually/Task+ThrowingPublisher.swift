//
//  Task+ThrowingPublisher.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Combine

public extension Task {

    final class ThrowingPublisher<Output> {

        typealias Closure = () async throws -> Output

        private let closure: Closure

        init(_ closure: @escaping Closure) {
            self.closure = closure
        }

    }

}

// MARK: - Publisher Implementation

extension Task.ThrowingPublisher: Publisher {

    public typealias Output = Output
    public typealias Failure = Error

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(closure, downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }

}

// MARK: - Subscription

extension Task.ThrowingPublisher {

    final class Subscription {

        private let closure: Closure

        private var handle: Task.Handle<Void, Error>? = nil
        private var downstream: AnySubscriber<Output, Error>? = nil

        private let handleLock = UnfairLock()
        private let downstreamLock = UnfairLock()

        init<Downstream>(_ closure: @escaping Closure, downstream: Downstream) where Downstream: Subscriber, Output == Downstream.Input, Failure == Downstream.Failure {
            self.closure = closure
            self.downstream = AnySubscriber(downstream)
        }

        private func cleanup() {
            handle = nil
            downstream = nil
        }

    }

}

// MARK: - Downstream -> Task Messaging

extension Task.ThrowingPublisher.Subscription: Subscription {

    func request(_ demand: Subscribers.Demand) {
        guard demand > 0 else {
            return
        }

        handleLock.synchronized {
            guard handle == nil else {
                return
            }

            // run the async closure in a detached context
            handle = detach { [closure, weak self] in
                do {
                    let value = try await closure()
                    self?.receive(value)
                } catch {
                    self?.receive(error: error)
                }
            }
        }
    }

    func cancel() {
        handleLock.synchronized {
            handle?.cancel()
        }
        cleanup()
    }

}

// MARK: - Task -> Downstream Messaging

extension Task.ThrowingPublisher.Subscription {

    func receive(_ input: Output) {
        downstreamLock.synchronized {
            _ = downstream?.receive(input)
            downstream?.receive(completion: .finished)
        }
        cleanup()
    }

    func receive(error: Error) {
        downstreamLock.synchronized {
            downstream?.receive(completion: .failure(error))
        }
        cleanup()
    }

}
