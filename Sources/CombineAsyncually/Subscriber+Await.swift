//
//  Subscriber+Await.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Combine

extension Subscribers {

    final class Await<Input> {

        // MARK: - Properties

        private let upstream: AnyPublisher<Input, Failure>

        private var upstreamSubscription: Combine.Subscription? = nil
        private var didEmitValue = false

        private let upstreamLock = UnfairLock()
        private let emitLock = UnfairLock()

        typealias Continuation = (Result<Input, Failure>) -> Void

        private var continuation: Continuation?

        // MARK: - Initialisation

        init(upstream: AnyPublisher<Input, Failure>) {
            self.upstream = upstream
        }

        // MARK: - Continuing

        func `continue`(with continuation: @escaping Continuation) {
            self.continuation = continuation
            upstream.subscribe(self)
        }

        func cancel() {
            upstreamLock.synchronized {
                upstreamSubscription?.cancel()
            }
            cleanup()
        }

        private func cleanup() {
            upstreamSubscription = nil
            continuation = nil
        }

        // MARK: - Errors

        enum AwaitError: Error {
            case upstreamDidNotEmitValue
        }

    }
}

// MARK: - Upstream -> Downstream Messaging

extension Subscribers.Await: Subscriber {

    typealias Input = Input
    typealias Failure = Error

    // Receive a subscription and request a single element back
    func receive(subscription: Subscription) {
        upstreamLock.synchronized {
            upstreamSubscription = subscription
            subscription.request(.max(1))
        }
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        emitLock.synchronized {
            guard didEmitValue == false else {
                return .none
            }

            didEmitValue = true
            continuation?(.success(input))
            cleanup()
            return .none
        }
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        emitLock.synchronized {
            guard didEmitValue == false else {
                return
            }

            switch completion {
            case .finished:
                continuation?(.failure(AwaitError.upstreamDidNotEmitValue))
            case .failure(let error):
                continuation?(.failure(error))
            }
        }
        cleanup()
    }

}
