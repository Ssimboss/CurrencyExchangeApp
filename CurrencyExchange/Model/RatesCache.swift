//
//  RatesCache.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 10/11/2025.
//

import Foundation

enum RatesCacheError: Error {
    case cacheDirectoryNotFound
    case fileContentNotFound
    case dataEncodingFailed(jsonEncoderError: Error)
    case dataDecodingFailed(jsonDecoderError: Error)
}

private enum RatesCacheConstants {
    nonisolated static let selectedCurrencyIDKey: String = "selectedCurrencyID"
    nonisolated static let ratesFileName = "rates.json"
}

protocol RatesCacheProtocol: Actor {
    func cache(selectedCurrencyID: String)
    func cache(rates: [Rate]) throws(RatesCacheError)
    func getCachedSelectedCurrencyID() async -> String?
    func getCachedRates() async -> [Rate]?
}

actor RatesCache: RatesCacheProtocol {
    private typealias Constants = RatesCacheConstants
    
    private let fileManager: FileManagerProtocol
    private var jsonDecoder: JSONDecoderProtocol
    private var jsonEncoder: JSONEncoderProtocol
    private let userDefaults: UserDefaultsProtocol
    
    private var cachedSelectedCurrencyID: Loadable<String?> = .loading
    private var loadingSelectedCurrencyIDContinuations: [CheckedContinuation<String?, Never>] = []
    private var cachedRates: Loadable<[String : Rate]?> = .loading
    private var loadingRatesContinuations: [CheckedContinuation<[String : Rate]?, Never>] = []
    
    init(
        fileManager: FileManagerProtocol,
        jsonDecoder: JSONDecoderProtocol,
        jsonEncoder: JSONEncoderProtocol,
        userDefaults: UserDefaultsProtocol
    ) {
        self.fileManager = fileManager
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        self.userDefaults = userDefaults
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Rate.dateFormat
        self.jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)
        self.jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        Task { [weak self] in
            await self?.restoreCache()
        }
    }

    func getCachedSelectedCurrencyID() async -> String? {
        switch self.cachedSelectedCurrencyID {
        case .loaded(let value):
            return value
        case .loading:
            return await withCheckedContinuation{ continuation in
                self.loadingSelectedCurrencyIDContinuations.append(continuation)
            }
        }
    }
    
    func getCachedRates() async -> [Rate]? {
        let rates: [String : Rate]?
        switch self.cachedRates {
        case .loaded(let loadedRates):
            rates = loadedRates
        case .loading:
            rates = await withCheckedContinuation{ continuation in
                self.loadingRatesContinuations.append(continuation)
            }
        }
        return rates.map { Array($0.values) }
    }
    
    private let uuid = UUID().uuidString

    func cache(selectedCurrencyID: String) {
        let cancelLoading = self.cachedSelectedCurrencyID == .loading
        self.cachedSelectedCurrencyID = .loaded(selectedCurrencyID)
        self.userDefaults.set(selectedCurrencyID, forKey: Constants.selectedCurrencyIDKey)
        if cancelLoading {
            self.loadingSelectedCurrencyIDContinuations.forEach { $0.resume(returning: selectedCurrencyID) }
            self.loadingSelectedCurrencyIDContinuations.removeAll()
        }
    }
    
    func cache(rates: [Rate]) throws(RatesCacheError) {
        let cancelLoading = self.cachedRates == .loading
        var currentCachedRates: [String : Rate]
        if case .loaded(let currentRates) = self.cachedRates,
           let currentRates {
            currentCachedRates = currentRates
        } else {
            currentCachedRates = [:]
        }
        rates.forEach { rate in
            currentCachedRates[rate.currencyID] = rate
        }
        self.cachedRates = .loaded(currentCachedRates)
        try self.cache(currentCachedRates, fileName: Constants.ratesFileName)
        if cancelLoading {
            self.loadingRatesContinuations.forEach { $0.resume(returning: currentCachedRates) }
            self.loadingRatesContinuations.removeAll()
        }
    }

    private func restoreCache() async {
        let cachedRates: [String : Rate]?
        do {
            cachedRates = try self.restore(fileName: Constants.ratesFileName)
        } catch {
            cachedRates = nil
        }
        if case .loading = self.cachedRates {
            self.cachedRates = .loaded(cachedRates)
            self.loadingRatesContinuations.forEach { $0.resume(returning: cachedRates) }
            self.loadingRatesContinuations.removeAll()
        }

        let cachedSelectedCurrencyID = self.userDefaults.string(forKey: Constants.selectedCurrencyIDKey)
        if case .loading = self.cachedSelectedCurrencyID {
            self.cachedSelectedCurrencyID = .loaded(cachedSelectedCurrencyID)
            self.loadingSelectedCurrencyIDContinuations.forEach { $0.resume(returning: cachedSelectedCurrencyID) }
            self.loadingSelectedCurrencyIDContinuations.removeAll()
        }
    }

    private func cache<T: Encodable>(_ value: T, fileName: String) throws(RatesCacheError) {
        let data: Data
        do {
            data = try self.jsonEncoder.encode(value)
        } catch {
            throw .dataEncodingFailed(jsonEncoderError: error)
        }
        let fileURL = try self.cacheDirectoryFileURL(fileName: fileName)
        try? self.fileManager.removeItem(at: fileURL)
        _ = self.fileManager.createFile(
            atPath: fileURL.path(),
            contents: data,
            attributes: nil
        )
    }
    
    private func restore<T: Decodable>(fileName: String) throws(RatesCacheError) -> T {
        let fileURL = try self.cacheDirectoryFileURL(fileName: Constants.ratesFileName)
        guard let fileData = self.fileManager.contents(atPath: fileURL.path()) else {
            throw RatesCacheError.fileContentNotFound
        }
        do {
            return try self.jsonDecoder.decode(T.self, from: fileData)
        } catch {
            throw .dataDecodingFailed(jsonDecoderError: error)
        }
    }

    private func cacheDirectoryFileURL(fileName: String) throws(RatesCacheError) -> URL {
        guard let folderURL = self.fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first else {
            throw .cacheDirectoryNotFound
        }
        return folderURL.appendingPathComponent(fileName)
    }
}
