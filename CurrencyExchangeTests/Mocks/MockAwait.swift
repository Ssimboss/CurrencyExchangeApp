//
//  MockAwaitError.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 12/11/2025.
//

import Foundation

enum MockAwaitError: Error {
    case timeout
}

actor MockAwait {
    private var continuations: [Int : [UUID : CheckedContinuation<Void, Error>]] = [:]
    
    func await(callsCount: Int) async throws {
        try await withCheckedThrowingContinuation { continuation in
            var countContinuations = self.continuations[callsCount] ?? [:]
            let identifier = UUID()
            countContinuations[identifier] = continuation
            self.continuations[callsCount] = countContinuations
            Task {
                try await Task.sleep(for: .milliseconds(100))
                guard var countContinuations = self.continuations[callsCount],
                      let continuation = countContinuations[identifier] else {
                    return
                }
                countContinuations[identifier] = nil
                self.continuations[callsCount] = countContinuations
                continuation.resume(throwing: MockAwaitError.timeout)
            }
        }
    }
    
    func resume(callsCount: Int) {
        self.continuations[callsCount]?.forEach { _, continuation in
            continuation.resume(returning: ())
        }
        self.continuations[callsCount] = nil
    }
}
