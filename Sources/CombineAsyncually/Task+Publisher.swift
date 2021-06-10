//
//  Task+Publisher.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Combine

public extension Task {

    final class Publisher<Output> {

        typealias Closure = () async -> Output

        private let closure: Closure

        init(_ closure: @escaping Closure) {
            self.closure = closure
        }

    }

}

// MARK: - Publisher Implementation

extension Task.Publisher: Publisher {

    public typealias Output = Output
    public typealias Failure = Never

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(closure, downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }

}

// MARK: - Subscription

extension Task.Publisher {

    final class Subscription {

        private let closure: Closure

        private var handle: Task.Handle<Void, Never>?
        private var downstream: AnySubscriber<Output, Never>?

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

extension Task.Publisher.Subscription: Subscription {

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
                let value = await closure()
                self?.receive(value)
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

extension Task.Publisher.Subscription {

    func receive(_ input: Output) {
        downstreamLock.synchronized {
            _ = downstream?.receive(input)
            downstream?.receive(completion: .finished)
        }
        cleanup()
    }

}
