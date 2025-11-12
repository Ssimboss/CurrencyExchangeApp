//
//  MockJSONEncoder.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 12/11/2025.
//

import Foundation
@testable import CurrencyExchange

final class MockJSONEncoder: JSONEncoderProtocol {
    var _dateEncodingStrategy = _DateEncodingStrategy()
    var _encode = _Encode()
    
    nonisolated var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
        get {
            return self._dateEncodingStrategy.result
        }
        set {
            self._dateEncodingStrategy.history.append(newValue)
        }
    }
    nonisolated func encode<T>(_ value: T) throws -> Data where T : Encodable {
        self._encode.history.append(value)
        switch self._encode.result {
        case .value(let value):
            return value
        case .throwError(let error):
            throw error
        }
    }

    struct _DateEncodingStrategy {
        var history: [JSONEncoder.DateEncodingStrategy] = []
        var result: JSONEncoder.DateEncodingStrategy = .iso8601
    }
    
    struct _Encode {
        enum Result {
            case value(Data)
            case throwError(Error)
        }
        var history: [Encodable] = []
        var result: Result = .value(Data())
    }
}
