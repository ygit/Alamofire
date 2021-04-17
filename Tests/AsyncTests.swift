//
//  AsyncTests.swift
//  Alamofire
//
//  Created by Jon Shier on 1/26/21.
//  Copyright © 2021 Alamofire. All rights reserved.
//

import Alamofire
import XCTest

final class AsyncTests: BaseTestCase {
    final class Capture<T> {
        var captured: T?
    }
    
    func testAsyncHandle() {
        // Given
        let didComplete = expectation(description: "request did complete")
        let response = Capture<AFDataResponse<TestResponse>>()
        
        // When
        detach {
//        runAsyncAndBlock {
            let asyncResponse = AF.request(.get).responseHandle(decoding: TestResponse.self)
            NSLog("\(response)")
            response.captured = await asyncResponse.handle.get()
            didComplete.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
        
        // Then
        XCTAssertNotNil(response.captured)
    }
    
    func testAsyncResponse() {
        runAsyncAndBlock {
            let response = await AF.request(.get).response(decoding: TestResponse.self)
            XCTAssertTrue(response.result.isSuccess)
        }
    }
    
    func testAsyncValue() {
        runAsyncAndBlock {
            do {
                let value = try await AF.request(.get).responseValue(decoding: TestResponse.self)
                XCTAssertTrue(!value.headers.isEmpty)
            } catch {
                XCTFail("Request should succeed but failed with error: \(error)")
            }
        }
    }
}
