//
//  PublisherAwaitingTests.swift
//  CombineAsyncually
//
//  Created by Rob Amos on 10/6/21.
//

import Combine
import CombineAsyncually
import XCTest

final class PublisherAwaitingTests: XCTestCase {

    func testAbleToGetValueAsynchronouslyEasyWay() async throws {

        // GIVEN a single that emits a fixed value
        let publisher = Just(true)

        // WHEN we attempt to await for that value
        let result = try await publisher.get()

        // THEN it should be true
        XCTAssertTrue(result)

    }

    func testAbleToGetValueAsynchronouslyDelayWay() async throws {

        // GIVEN a single that emits a fixed value
        let publisher = Deferred {
            Future<Bool, Never> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                    promise(.success(true))
                }
            }
        }

        // WHEN we attempt to await for that value
        let result = try await publisher.get()

        // THEN it should be true
        XCTAssertTrue(result)

    }

    func testBackAndForth() async throws {

        // Capturing an async function into a Publisher (Single/Future)
        func emitValue() async -> String {
            "Hello 👋"
        }

        let asyncPublisher = withPublisher {
            await emitValue()
        }

        // Awaiting for the completion of a Publisher
        let result = try await asyncPublisher.get()

        XCTAssertEqual(result, "Hello 👋")

    }

}
