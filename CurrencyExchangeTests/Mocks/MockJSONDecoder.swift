//
//  MockJSONDecoder.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import Foundation
@testable import CurrencyExchange

final class MockJSONDecoder: JSONDecoderProtocol {
    var _dateDecodingStrategy = _DateDecodingStrategy()
    var _decode = _Decode()
    
    nonisolated var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        get {
            return self._dateDecodingStrategy.result
        }
        set {
            self._dateDecodingStrategy.history.append(newValue)
        }
    }
    nonisolated func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        self._decode.history.append(.init(type: type, data: data))
        Task { [weak self] in
            await self?._decode.resume()
        }
        switch self._decode.result {
        case .value(let value):
            return value as! T
        case .throwError(let error):
            throw error
        }
    }
    
    struct _DateDecodingStrategy {
        var history: [JSONDecoder.DateDecodingStrategy] = []
        var result: JSONDecoder.DateDecodingStrategy = .iso8601
    }
    
    struct _Decode {
        struct Arguments {
            let type: Any.Type
            let data: Data?
        }
        enum Result {
            case value(Any)
            case throwError(Error)
        }
        private let awaiting = MockAwait()
        var history: [Arguments] = []
        var result: Result = .value(Data())

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
