//
//  WebSocketTests.swift
//  Alamofire
//
//  Created by Jon Shier on 1/17/21.
//  Copyright © 2021 Alamofire. All rights reserved.
//

import Alamofire
import Foundation
import XCTest

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
final class WebSocketTests: BaseTestCase {
    private let closeDelay: Int64 = 50

    func testThatWebSocketsCanReceiveAMessage() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let taskDidComplete = expectation(description: "taskDidComplete")
        let queue = DispatchQueue(label: #function)
        let monitor = ClosureEventMonitor(queue: queue)
        monitor.taskDidComplete = { _, _, _ in
            taskDidComplete.fulfill()
        }
        let session = Session(rootQueue: queue, eventMonitors: [ /* NSLoggingEventMonitor(), */ monitor])

        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocket(closeDelay: closeDelay)).responseMessage { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, taskDidComplete, didComplete],
             timeout: timeout,
             enforceOrder: false)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(message)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketsCanReceiveAMessageWithAProtocol() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let taskDidComplete = expectation(description: "taskDidComplete")
        let queue = DispatchQueue(label: #function)
        let monitor = ClosureEventMonitor(queue: queue)
        monitor.taskDidComplete = { _, _, _ in
            taskDidComplete.fulfill()
        }
        let session = Session(rootQueue: queue, eventMonitors: [ /* NSLoggingEventMonitor(), */ monitor])

        let `protocol` = "protocol"
        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocket(closeDelay: closeDelay), protocol: `protocol`).responseMessage { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, taskDidComplete, didComplete],
             timeout: timeout,
             enforceOrder: true)

        // Then
        XCTAssertEqual(connectedProtocol, `protocol`)
        XCTAssertNotNil(message)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketsCanReceiveMultipleMessages() {
        // Given
        let count = 5
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        didReceiveMessage.expectedFulfillmentCount = count
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let taskDidComplete = expectation(description: "taskDidComplete")
        let queue = DispatchQueue(label: #function)
        let monitor = ClosureEventMonitor(queue: queue)
        monitor.taskDidComplete = { _, _, _ in
            taskDidComplete.fulfill()
        }
        let session = Session(rootQueue: queue, eventMonitors: [ /* NSLoggingEventMonitor(), */ monitor])

        var connectedProtocol: String?
        var messages: [URLSessionWebSocketTask.Message] = []
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocketCount(count, closeDelay: 500)).responseMessage { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                messages.append(receivedMessage)
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, taskDidComplete, didComplete],
             timeout: timeout,
             enforceOrder: true)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertEqual(messages.count, count)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }
    
    func testMany() {
        for _ in 0..<100 {
            testThatWebSocketsCanReceiveMultipleMessages()
        }
    }

    func testThatWebSocketsCanSendAndReceiveMessages() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didSend = expectation(description: "didSend")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let taskDidComplete = expectation(description: "taskDidComplete")
        let queue = DispatchQueue(label: #function)
        let monitor = ClosureEventMonitor(queue: queue)
        monitor.taskDidComplete = { _, _, _ in
            taskDidComplete.fulfill()
        }
        let session = Session(rootQueue: queue, eventMonitors: [ /* NSLoggingEventMonitor(), */ monitor])
        let sentMessage = URLSessionWebSocketTask.Message.string("Echo")

        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        let request = session.websocketRequest(.websocketEcho).responseMessage { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                event.cancel(with: .normalClosure, reason: nil)
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }
        request.send(sentMessage) { _ in didSend.fulfill() }

        wait(for: [didConnect, didSend, didReceiveMessage, didDisconnect, taskDidComplete, didComplete],
             timeout: timeout,
             enforceOrder: true)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(message)
        XCTAssertEqual(sentMessage, message)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketFailsWithTooSmallMaximumMessageSize() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didComplete = expectation(description: "didComplete")
        let taskDidComplete = expectation(description: "taskDidComplete")
        let queue = DispatchQueue(label: "com.alamofire.webSocketTests")
        let monitor = ClosureEventMonitor(queue: queue)
        monitor.taskDidComplete = { _, _, _ in
            taskDidComplete.fulfill()
        }
        let session = Session(rootQueue: queue, eventMonitors: [ /* NSLoggingEventMonitor(), */ monitor])

        var connectedProtocol: String?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocket(closeDelay: closeDelay), maximumMessageSize: 1).responseMessage { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case .receivedMessage, .disconnected:
                break
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, taskDidComplete, didComplete], timeout: timeout, enforceOrder: false)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(receivedCompletion?.error)
    }

    func testThatWebSocketsFinishAfterNonNormalResponseCode() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let taskDidComplete = expectation(description: "taskDidComplete")
        let queue = DispatchQueue(label: #function)
        let monitor = ClosureEventMonitor(queue: queue)
        monitor.taskDidComplete = { _, _, _ in
            taskDidComplete.fulfill()
        }
        let session = Session(rootQueue: queue, eventMonitors: [ /* NSLoggingEventMonitor(), */ monitor])

        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocket(closeCode: .goingAway, closeDelay: closeDelay)).responseMessage { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, taskDidComplete, didComplete],
             timeout: timeout,
             enforceOrder: false)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(message)
        XCTAssertEqual(closeCode, .goingAway)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension URLSessionWebSocketTask.Message: Equatable {
    public static func ==(lhs: URLSessionWebSocketTask.Message, rhs: URLSessionWebSocketTask.Message) -> Bool {
        switch (lhs, rhs) {
        case let (.string(left), .string(right)):
            return left == right
        case let (.data(left), .data(right)):
            return left == right
        default:
            return false
        }
    }
}
