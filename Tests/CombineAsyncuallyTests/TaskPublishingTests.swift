//
//  TaskPublishingTests.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Combine
import CombineAsyncually
import XCTest

final class TaskPublishingTests: XCTestCase {

    // MARK: - Async Closure Support

    @MainActor
    func testEmitsAsyncResultSuccess() throws {

        // GIVEN an async function
        func doThing() async -> String {
            "alpha"
        }

        // AND a Publisher that calls it
        let publisher = withPublisher {
            await doThing()
        }

        // WHEN we subscribe to that
        let received = expectation(description: "received result")
        var result: String?
        let cancellable = publisher
            .sink {
                result = $0
                received.fulfill()
            }

        // THEN we expect it to have emitted a single value and completed
        wait(for: [ received ], timeout: 0.1)
        XCTAssertEqual(result, "alpha")
        XCTAssertNotNil(cancellable)

    }

    func testEmitsThrowingAsyncResultSuccess() throws {

        // GIVEN an async function
        func doThing() async throws -> String {
            "beta"
        }

        // AND a Single that calls it
        let publisher = withThrowingPublisher {
            try await doThing()
        }

        // WHEN we subscribe to that
        let received = expectation(description: "received result")
        var result: String?
        let cancellable = publisher
            .assertNoFailure()
            .sink {
                result = $0
                received.fulfill()
            }

        // THEN we expect it to have emitted a single value and completed
        wait(for: [ received ], timeout: 0.1)
        XCTAssertEqual(result, "beta")
        XCTAssertNotNil(cancellable)

    }

    func testEmitsThrowingAsyncResultFailure() throws {

        // GIVEN an async function and a mock error
        func doThing() async throws -> String {
            throw MockError.failed
        }
        enum MockError: Error, Equatable {
            case failed
        }

        // AND a Single that calls it
        let publisher = withThrowingPublisher {
            try await doThing()
        }

        // WHEN we subscribe to that
        let completed = expectation(description: "received result")
        var completion: Subscribers.Completion<Error>?
        let cancellable = publisher
            .sink(
                receiveCompletion: {
                    completion = $0
                    completed.fulfill()
                },
                receiveValue: { _ in }
            )

        // THEN we expect it to have emitted a single value and completed
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

