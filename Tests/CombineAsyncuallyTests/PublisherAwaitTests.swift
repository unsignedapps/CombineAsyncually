//
//  PublisherAwaitTests.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Combine
import CombineAsyncually
import XCTest

final class PublisherAwaitTests: XCTestCase {

    // MARK: - Happy Paths

    func testEmitsValue() throws {

        // GIVEN a Publisher that emits a fixed value
        let publisher = Just(0)

        // WHEN we map that through an async function
        let received = expectation(description: "received value")
        var result: Int?
        let cancellable = publisher
            .await {
                await plusplus(value: $0)
            }
            .sink {
                result = $0
                received.fulfill()
            }

        // THEN we expect that to have emitted a plusplused value
        wait(for: [ received ], timeout: 0.1)
        XCTAssertEqual(result, 1)
        XCTAssertNotNil(cancellable)

    }

    func testHandlesThrownErrors() throws {

        // GIVEN a Publisher that emits a fixed value
        let publisher = Just(0)

        // WHEN we map that through an async function that throws
        let completed = expectation(description: "received completion")
        var completion: Subscribers.Completion<Error>?
        let cancellable = publisher
            .tryAwait {
                try await ohno(value: $0)
            }
            .sink(
                receiveCompletion: {
                    completion = $0
                    completed.fulfill()
                },
                receiveValue: { _ in }
            )

        // THEN we expect that to have emitted the failure
        wait(for: [ completed ], timeout: 0.1)
        if case .failure(let error) = completion {
            if let failure = error as? MockError {
                XCTAssertEqual(failure, MockError.failed)
            } else {
                XCTFail("Completion returned by Task.ThrowingPublisher was not the correct error")
            }
        } else {
            XCTFail("Completion returned by Task.ThrowingPublisher was not an error")
        }
        XCTAssertNotNil(cancellable)

    }

}

// MARK: - Fixtures

private func plusplus(value: Int) async -> Int {
    value + 1
}

private func ohno(value: Int) async throws -> Int {
    throw MockError.failed
}

private enum MockError: Error, Equatable {
    case failed
}


public extension Future where Failure == Error {

    typealias Closure = () async throws -> Output
    convenience init(async closure: @escaping Closure) {
        self.init { promise in
            async {
                do {
                    promise(.success(try await closure()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }

}
