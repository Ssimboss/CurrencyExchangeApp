//
//  URLSessionProtocol.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import Foundation

protocol URLSessionProtocol {
    nonisolated func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
