//
//  RateAPITest.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import Foundation
import Testing
@testable import CurrencyExchange

struct RateAPITests {
    enum TestError: Error {
        case invalidJsonData
        case networkError
        case decodingError
    }
    
    private let rate = Rate(
        ask: 1.601,
        bid: 1.401,
        currencyID: "TestCurrency",
        date: Date(timeIntervalSince1970: 0)
    )
    
    private var mockJsonData: Data {
        get throws {
            if let result = "{}".data(using: .utf8) {
                return result
            } else {
                throw TestError.invalidJsonData
            }
        }
    }
    
    // MARK: - testing: fetchRates
    @Test
    func whenFetchRates_ThenValidURLSessionDataExecuted() async throws {
        // Given
        let currencyIDs = ["CUR_1", "CUR_2"]
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value([self.rate])
        let urlSession = MockURLSession()
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        _ = try await api.fetchRates(currencyIDs: currencyIDs)
        // Then
        #expect(urlSession._data.history.count == 1)
        #expect(urlSession._data.history[0].url.absoluteString == "https://api.dolarapp.dev/v1/tickers?currencies=CUR_1,CUR_2")
    }
    
    @Test
    func givenURLSessionDataFails_WhenFetchRates_ThenURLSessionDataExecutedThreeTimes_AndValidErrorThrown() async throws {
        var thrownError: RateAPIError?
        let jsonDecoder = MockJSONDecoder()
        let urlSession = MockURLSession()
        urlSession._data.result = .throwError(TestError.networkError)
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        do throws(RateAPIError) {
            _ = try await api.fetchRates(currencyIDs: ["CUR_1", "CUR_2"])
        } catch {
            thrownError = error
        }
        // Then
        #expect(urlSession._data.history.count == 3)
        guard case .dataFetchingFailed(let error) = thrownError,
              let sessionError = error as? TestError else {
            Issue.record("unexpected error type: \(thrownError)")
            return
        }
        #expect(sessionError == .networkError)
    }
    
    @Test
    func whenFetchRates_ThenJSONDecodeArrayOfRatesExecuted() async throws {
        // Given
        let loadedData = try self.mockJsonData
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value([self.rate])
        let urlSession = MockURLSession()
        urlSession._data.result = .value(loadedData, URLResponse())
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        _ = try await api.fetchRates(currencyIDs: ["CUR_1", "CUR_2"])
        // Then
        #expect(jsonDecoder._decode.history.count == 1)
        #expect(jsonDecoder._decode.history[0].data == loadedData)
        #expect(jsonDecoder._decode.history[0].type == [Rate].self)
    }
    
    @Test
    func givenJSONDecodingFails_WhenFetchRates_ThenValidErrorThrown() async throws {
        // Given
        var thrownError: RateAPIError?
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .throwError(TestError.decodingError)
        let urlSession = MockURLSession()
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        do throws(RateAPIError) {
            _ = try await api.fetchRates(currencyIDs: ["CUR_1", "CUR_2"])
        } catch {
            thrownError = error
        }
        // Then
        guard case .rateDecodingFailed(let error) = thrownError,
              let jsonError = error as? TestError else {
            Issue.record("unexpected error type: \(thrownError)")
            return
        }
        #expect(jsonError == .decodingError)
    }
    
    @Test
    func givenJSONDecodesSingleRate_WhenFetchRates_ThenResultIsSingleRate() async throws {
        // Given
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value([self.rate])
        let urlSession = MockURLSession()
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        let result = try await api.fetchRates(currencyIDs: ["CUR_1", "CUR_2"])
        // Then
        #expect(result == [self.rate])
    }
    // MARK: - testing: fetchCurrencies
    @Test
    func whenFetchCurrencies_ThenValidURLSessionDataExecuted() async throws {
        // Given
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value(["CUR"])
        let urlSession = MockURLSession()
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        _ = try await api.fetchCurrencies()
        // Then
        #expect(urlSession._data.history.count == 1)
        #expect(urlSession._data.history[0].url.absoluteString == "https://api.dolarapp.dev/v1/tickers-currencies")
    }

    @Test
    func givenURLSessionDataFails_WhenFetchCurrencies_ThenURLSessionDataExecutedOnce_AndValidErrorThrown() async throws {
        var thrownError: RateAPIError?
        let jsonDecoder = MockJSONDecoder()
        let urlSession = MockURLSession()
        urlSession._data.result = .throwError(TestError.networkError)
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        do throws(RateAPIError) {
            _ = try await api.fetchCurrencies()
        } catch {
            thrownError = error
        }
        // Then
        #expect(urlSession._data.history.count == 1)
        guard case .dataFetchingFailed(let error) = thrownError,
              let sessionError = error as? TestError else {
            Issue.record("unexpected error type: \(thrownError)")
            return
        }
        #expect(sessionError == .networkError)
    }

    @Test
    func whenFetchCurrencies_ThenJSONDecodeArrayOfStringExecuted() async throws {
        // Given
        let loadedData = try self.mockJsonData
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value(["CUR"])
        let urlSession = MockURLSession()
        urlSession._data.result = .value(loadedData, URLResponse())
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        _ = try await api.fetchCurrencies()
        // Then
        #expect(jsonDecoder._decode.history.count == 1)
        #expect(jsonDecoder._decode.history[0].data == loadedData)
        #expect(jsonDecoder._decode.history[0].type == [String].self)
    }

    @Test
    func givenJSONDecodingFails_WhenFetchCurrencies_ThenValidErrorThrown() async throws {
        // Given
        var thrownError: RateAPIError?
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .throwError(TestError.decodingError)
        let urlSession = MockURLSession()
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        do throws(RateAPIError) {
            _ = try await api.fetchCurrencies()
        } catch {
            thrownError = error
        }
        // Then
        guard case .rateDecodingFailed(let error) = thrownError,
              let jsonError = error as? TestError else {
            Issue.record("unexpected error type: \(thrownError)")
            return
        }
        #expect(jsonError == .decodingError)
    }
    
    @Test
    func givenJSONDecodesSingleRate_WhenFetchCurrencies_ThenResultIsSingleRate() async throws {
        // Given
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value(["CUR"])
        let urlSession = MockURLSession()
        let api = RateAPI(
            currencyLoadMock: .disabled,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        let result = try await api.fetchCurrencies()
        // Then
        #expect(result == ["CUR"])
    }
}
