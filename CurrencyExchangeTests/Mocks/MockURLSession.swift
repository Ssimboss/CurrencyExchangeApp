//
//  MockURLSession.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import Foundation
@testable import CurrencyExchange

final class MockURLSession: URLSessionProtocol {
    var _data = _Data()
    
    nonisolated func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        self._data.history.append(.init(url: url, delegate: delegate))
        await self._data.resume()
        switch self._data.result {
            case .value(let data, let response):
            return (data, response)
        case .throwError(let error):
            throw error
        }
    }

    struct _Data {
        struct Arguments {
            let url: URL
            let delegate: URLSessionTaskDelegate?
        }
        enum Result {
            case value(Data, URLResponse)
            case throwError(Error)
        }
        
        private let awaiting = MockAwait()
        var history: [Arguments] = []
        var result: Result = .value(Data(), URLResponse())
        
        func await(callsCount: Int) async throws {
            guard self.history.count < callsCount else {
                return
            }
            return try await self.awaiting.await(callsCount: callsCount)
        }
        func resume() async {
            await self.awaiting.resume(callsCount: self.history.count)
        }
    }
}
