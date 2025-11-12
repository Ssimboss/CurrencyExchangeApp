//
//  MockFileManager.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 12/11/2025.
//

import Foundation
@testable import CurrencyExchange

final class MockFileManager: FileManagerProtocol {
    var _removeItem = _RemoveItem()
    var _createFile = _CreateFile()
    var _contents = _Contents()
    var _urls = _URLs()
    
    nonisolated func removeItem(at URL: URL) throws {
        self._removeItem.history.append(URL)
        switch self._removeItem.result {
        case .passed:
            break
        case .throwError(let error):
            throw error
        }
    }
    nonisolated func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]?) -> Bool {
        self._createFile.history.append(.init(path: path, data: data, attributes: attr))
        Task { await self._createFile.resume() }
        return self._createFile.result
    }
    nonisolated func contents(atPath path: String) -> Data? {
        self._contents.history.append(path)
        Task { await self._contents.resume() }
        return self._contents.result
    }
    nonisolated func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        self._urls.history.append(.init(directory: directory, domainMask: domainMask))
        return self._urls.result
    }

    struct _RemoveItem {
        enum Result {
            case passed
            case throwError(Error)
        }
        var history: [URL] = []
        var result: Result = .passed
    }
    struct _CreateFile {
        struct Arguments {
            let path: String
            let data: Data?
            let attributes: [FileAttributeKey : Any]?
        }
        var history: [Arguments] = []
        var result: Bool = true
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
    struct _Contents {
        var history: [String] = []
        var result: Data?
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
    struct _URLs {
        struct Arguments {
            let directory: FileManager.SearchPathDirectory
            let domainMask: FileManager.SearchPathDomainMask
        }
        var history: [Arguments] = []
        var result: [URL] = []
    }
}
