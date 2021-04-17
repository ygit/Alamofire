//
//  Async.swift
//  Alamofire
//
//  Created by Jon Shier on 1/26/21.
//  Copyright © 2021 Alamofire. All rights reserved.
//

import Foundation

public struct AsyncDataResponse<Value> {
    public let request: DataRequest
    public let handle: Task.Handle<AFDataResponse<Value>, Never>
    
    fileprivate init(request: DataRequest, handle: Task.Handle<AFDataResponse<Value>, Never>) {
        self.request = request
        self.handle = handle
    }
}

extension DispatchQueue {
    fileprivate static let asyncCompletionQueue = DispatchQueue(label: "org.alamofire.asyncCompletionQueue")
}

extension DataRequest {
    public func responseHandle<Value: Decodable>(decoding: Value.Type = Value.self) -> AsyncDataResponse<Value> {
        let handle = detach { () -> AFDataResponse<Value> in
            await withCheckedContinuation { continuation in
                self.responseDecodable(of: Value.self, queue: .asyncCompletionQueue) { continuation.resume(returning: $0) }
            }
        }

        return AsyncDataResponse<Value>(request: self, handle: handle)
    }

    public func response<Value: Decodable>(decoding: Value.Type = Value.self) async -> AFDataResponse<Value> {
        await responseHandle(decoding: Value.self).handle.get()
    }

    public func responseValue<Value: Decodable>(decoding: Value.Type = Value.self) async throws -> Value {
        let response = await response(decoding: Value.self)
        switch response.result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}
