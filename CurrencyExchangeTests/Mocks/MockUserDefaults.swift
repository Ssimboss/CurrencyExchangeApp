//
//  MockUserDefaults.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 12/11/2025.
//

import Foundation
@testable import CurrencyExchange

final class MockUserDefaults: UserDefaultsProtocol {
    var _set = _Set()
    var _string = _String()
    
    nonisolated func set(_ value: Any?, forKey defaultName: String) {
        self._set.history.append(.init(value: value, key: defaultName))
    }
    nonisolated func string(forKey defaultName: String) -> String? {
        self._string.history.append(defaultName)
        Task { await self._string.resume() }
        return self._string.result
    }

    struct _Set {
        struct Arguments {
            let value: Any?
            let key: String
        }
        var history: [Arguments] = []
    }
    struct _String {
        var history: [String] = []
        var result: String? = nil
        private let awaiting = MockAwait()
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
