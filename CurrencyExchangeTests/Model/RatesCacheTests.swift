//
//  RatesCacheTests.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 12/11/2025.
//

import Foundation
import Testing
@testable import CurrencyExchange

final class RatesCacheTests {
    enum TestError: Error {
        case invalidURL
        case invalidJsonData
    }
    
    private var cache: RatesCache?
    private var mockCacheDirectoryURL: URL {
        get throws {
            if let result = URL(string: "file:///cacheDirectory/") {
                return result
            } else {
                throw TestError.invalidURL
            }
        }
    }

    private var mockJsonData: Data {
        get throws {
            if let result = "{}".data(using: .utf8) {
                return result
            } else {
                throw TestError.invalidJsonData
            }
        }
    }

    @Test
    func whenCacheConstructed_ThenDateCodingStrategiesSet() {
        // Given
        let fileManager = MockFileManager()
        let jsonDecoder = MockJSONDecoder()
        let jsonEncoder = MockJSONEncoder()
        let userDefaults = MockUserDefaults()
        // When
        self.cache = RatesCache(
            fileManager: fileManager,
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            userDefaults: userDefaults
        )
        // Then
        #expect(jsonDecoder._dateDecodingStrategy.history.count == 1)
        guard case .formatted(let decodeFormatter) = jsonDecoder._dateDecodingStrategy.history[0] else {
            Issue.record("unexpected dateDecodingStrategy: \(jsonDecoder._dateDecodingStrategy.history[0])")
            return
        }
        #expect(jsonEncoder._dateEncodingStrategy.history.count == 1)
        guard case .formatted(let encodeFormatter) = jsonEncoder._dateEncodingStrategy.history[0] else {
            Issue.record("unexpected dateEncodingStrategy: \(jsonEncoder._dateEncodingStrategy.history[0])")
            return
        }
        #expect(decodeFormatter.dateFormat == encodeFormatter.dateFormat)
        #expect(decodeFormatter.dateFormat == Rate.dateFormat)
    }
    
    @Test
    func whenCacheConstructed_ThenFileManagerContentLoaded() async throws {
        // Given
        let fileManager = MockFileManager()
        fileManager._urls.result = [try self.mockCacheDirectoryURL]
        let jsonDecoder = MockJSONDecoder()
        let jsonEncoder = MockJSONEncoder()
        let userDefaults = MockUserDefaults()
        // When
        self.cache = RatesCache(
            fileManager: fileManager,
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            userDefaults: userDefaults
        )
        // Then
        try await fileManager._contents.await(callsCount: 1)
        #expect(fileManager._contents.history.count == 1)
        #expect(fileManager._contents.history[0] == "/cacheDirectory/rates.json")
    }

    @Test
    func whenCacheConstructed_ThenJSONDecodeLoadedContent() async throws {
        // Given
        let loadedContentData = try self.mockJsonData
        let fileManager = MockFileManager()
        fileManager._urls.result = [try self.mockCacheDirectoryURL]
        fileManager._contents.result = loadedContentData
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value([String : Rate]())
        let jsonEncoder = MockJSONEncoder()
        let userDefaults = MockUserDefaults()
        // When
        self.cache = RatesCache(
            fileManager: fileManager,
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            userDefaults: userDefaults
        )
        // Then
        try await jsonDecoder._decode.await(callsCount: 1)
        #expect(jsonDecoder._decode.history.count == 1)
        #expect(jsonDecoder._decode.history[0].data == loadedContentData)
        #expect(jsonDecoder._decode.history[0].type == [String : Rate]?.self)
    }
    
    @Test
    func whenGetCachedRates_ThenJSONDecodedRateReturned() async throws {
        // Given
        let cachedRate = Rate.init(ask: 1.5, bid: 1.5, currencyID: "CUR", date: .now)
        let loadedContentData = try self.mockJsonData
        let fileManager = MockFileManager()
        fileManager._urls.result = [try self.mockCacheDirectoryURL]
        fileManager._contents.result = loadedContentData
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value(["CUR" : cachedRate])
        let jsonEncoder = MockJSONEncoder()
        let userDefaults = MockUserDefaults()
        let cache = RatesCache(
            fileManager: fileManager,
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            userDefaults: userDefaults
        )
        // When
        let result = await cache.getCachedRates()
        // Then
        #expect(result == [cachedRate])
    }
    
    @Test
    func whenCacheConstructed_ThenUserDefautsLoadValidString() async throws {
        // Given
        let loadedContentData = try self.mockJsonData
        let fileManager = MockFileManager()
        fileManager._urls.result = [try self.mockCacheDirectoryURL]
        fileManager._contents.result = loadedContentData
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value([String : Rate]())
        let jsonEncoder = MockJSONEncoder()
        let userDefaults = MockUserDefaults()
        // When
        self.cache = RatesCache(
            fileManager: fileManager,
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            userDefaults: userDefaults
        )
        // Then
        try await userDefaults._string.await(callsCount: 1)
        #expect(userDefaults._string.history.count == 1)
        #expect(userDefaults._string.history[0] == "selectedCurrencyID")
    }
    
    @Test
    func whenGetCachedSelectedCurrencyID_ThenUserDefautsValueReturned() async throws {
        // Given
        let testCurrencyID = "TEST ID"
        let loadedContentData = try self.mockJsonData
        let fileManager = MockFileManager()
        fileManager._urls.result = [try self.mockCacheDirectoryURL]
        fileManager._contents.result = loadedContentData
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value([String : Rate]())
        let jsonEncoder = MockJSONEncoder()
        let userDefaults = MockUserDefaults()
        userDefaults._string.result = testCurrencyID
        let cache = RatesCache(
            fileManager: fileManager,
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            userDefaults: userDefaults
        )
        // When
        let result = await cache.getCachedSelectedCurrencyID()
        // Then
        #expect(result == testCurrencyID)
    }
    
    @Test
    func whenCacheSelectedCurrencyID_ThenUserDefautsSetCalled() async throws {
        // Given
        let testID = "Some ID"
        let fileManager = MockFileManager()
        let jsonDecoder = MockJSONDecoder()
        let jsonEncoder = MockJSONEncoder()
        let userDefaults = MockUserDefaults()
        let cache = RatesCache(
            fileManager: fileManager,
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            userDefaults: userDefaults
        )
        // When
        await cache.cache(selectedCurrencyID: testID)
        // Then
        #expect(userDefaults._set.history.count == 1)
        #expect(userDefaults._set.history[0].key == "selectedCurrencyID")
        #expect(userDefaults._set.history[0].value as? String == testID)
        let currentSelectedCurrencyID = await cache.getCachedSelectedCurrencyID()
        #expect(currentSelectedCurrencyID == testID)
    }

    @Test
    func whenCacheRates_ThenJSONEncodeExecuted_AndFileManagerRecreatesFile() async throws {
        // Given
        let encodedData = Data()
        let rate = Rate.init(ask: 1.5, bid: 1.5, currencyID: "CUR", date: .now)
        let fileManager = MockFileManager()
        fileManager._urls.result = [try self.mockCacheDirectoryURL]
        let jsonDecoder = MockJSONDecoder()
        let jsonEncoder = MockJSONEncoder()
        jsonEncoder._encode.result = .value(encodedData)
        let userDefaults = MockUserDefaults()
        let cache = RatesCache(
            fileManager: fileManager,
            jsonDecoder: jsonDecoder,
            jsonEncoder: jsonEncoder,
            userDefaults: userDefaults
        )
        // When
        try await cache.cache(rates: [rate])
        // Then
        try await fileManager._createFile.await(callsCount: 1)
        #expect(jsonEncoder._encode.history.count == 1)
        #expect(jsonEncoder._encode.history[0] as? [String : Rate] == [rate.currencyID : rate])
        #expect(fileManager._removeItem.history.count == 1)
        #expect(fileManager._removeItem.history[0].path() == "/cacheDirectory/rates.json")
        #expect(fileManager._createFile.history.count == 1)
        #expect(fileManager._createFile.history[0].path == "/cacheDirectory/rates.json")
        #expect(fileManager._createFile.history[0].data == encodedData)
        #expect(fileManager._createFile.history[0].attributes == nil)
        let currentCachedRates = await cache.getCachedRates()
        #expect(currentCachedRates == [rate])
    }
}
