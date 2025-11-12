//
//  FileManagerProtocol.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 10/11/2025.
//

import Foundation

protocol FileManagerProtocol {
    nonisolated func removeItem(at URL: URL) throws
    nonisolated func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]?) -> Bool
    nonisolated func contents(atPath path: String) -> Data?
    nonisolated func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
}

extension FileManager: FileManagerProtocol {}
