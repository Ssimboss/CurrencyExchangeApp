//
//  RateAPI.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 07/11/2025.
//

import Foundation

enum RateAPIError: Error {
    case invalidURL
    case dataFetchingFailed(sessionError: Error)
    case rateDecodingFailed(jsonDecoderError: Error)
    case mockLoadingFailed
}

protocol RateAPIProtocol: Actor {
    func fetchRates(currencyIDs: [String]) async throws(RateAPIError) -> [Rate]
    func fetchCurrencies() async throws(RateAPIError) -> [String]
}

private enum RateAPIConstants {
    nonisolated static let scheme = "https"
    nonisolated static let host = "api.dolarapp.dev"
    nonisolated static let version = "v1"
}

actor RateAPI: RateAPIProtocol {
    enum CurrencyLoadMock {
        case emulate(milliseconds: any BinaryInteger)
        case disabled
        
        static var enabled: Self { return .emulate(milliseconds: 3000) }
    }
    
    private typealias Constants = RateAPIConstants
    
    private let currencyLoadMock: CurrencyLoadMock
    private var jsonDecoder: JSONDecoderProtocol
    private let urlSession: URLSessionProtocol

    init(
        currencyLoadMock: CurrencyLoadMock,
        jsonDecoder: JSONDecoderProtocol,
        urlSession: URLSessionProtocol
    ) {
        self.currencyLoadMock = currencyLoadMock
        self.jsonDecoder = jsonDecoder
        self.urlSession = urlSession
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Rate.dateFormat
        self.jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    }

    func fetchRates(currencyIDs: [String]) async throws(RateAPIError) -> [Rate] {
        return try await self.fetch(
            path: "/tickers",
            queryItems: [
                URLQueryItem(
                    name: "currencies",
                    value: currencyIDs.joined(separator: ",")
                )
            ],
            retryCount: 3
        )
    }

    func fetchCurrencies() async throws(RateAPIError) -> [String] {
        switch self.currencyLoadMock {
        case .emulate(let milliseconds):
            do {
                try await Task.sleep(for: .milliseconds(milliseconds))
            } catch {
                throw .mockLoadingFailed
            }
            return ["MXN", "ARS", "BRL", "COP"]
        case .disabled:
            return try await self.fetch(
                path: "/tickers-currencies",
                retryCount: 0
            )
        }
    }
    
    private func fetch<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        retryCount: Int
    ) async throws(RateAPIError) -> T {
        var urlComponents = URLComponents()
        urlComponents.scheme = Constants.scheme
        urlComponents.host = Constants.host
        urlComponents.path = "/\(Constants.version)" + path
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw .invalidURL
        }
        let data: Data = try await self.fetchData(
            url: url,
            attempt: 0,
            retryCount: retryCount
        )
        do {
            let result = try self.jsonDecoder.decode(T.self, from: data)
            return result
        } catch let error {
            throw .rateDecodingFailed(jsonDecoderError: error)
        }
    }
    
    private func fetchData(
        url: URL,
        attempt: Int,
        retryCount: Int,
    ) async throws(RateAPIError) -> Data {
        do {
            let data = try await self.urlSession.data(from: url, delegate: nil).0
            return data
        } catch let error {
            if attempt + 1 < retryCount {
                return try await self.fetchData(
                    url: url,
                    attempt: attempt + 1,
                    retryCount: retryCount
                )
            } else {
                throw .dataFetchingFailed(sessionError: error)
            }
        }
    }
}
