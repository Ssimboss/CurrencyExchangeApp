//
//  RemoteFlagsServiceTests.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 12/11/2025.
//

import UIKit
import Testing
@testable import CurrencyExchange

final class RemoteFlagsServiceTests {
    enum TestError: Error {
        case invalidJsonData
        case networkError
        case decodingError
    }
    
    private var service: RemoteFlagsService?
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
    func whenServiceConstructed_ThenValidURLSessionDataExecuted() async throws {
        // Given
        let imageService = MockImageService()
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value([String:String]())
        let urlSession = MockURLSession()
        // When
        self.service = RemoteFlagsService(
            imageService: imageService,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // Then
        try await urlSession._data.await(callsCount: 1)
        #expect(urlSession._data.history.count == 1)
        #expect(urlSession._data.history[0].url.absoluteString == "https://raw.githubusercontent.com/Ssimboss/CurrencyExchangeApp/refs/heads/main/flags.json")
    }
    
    @Test
    func givenURLSessionDataFails_WhenRemoteFlagImageExecuted_ThenResultIsNil() async throws {
        // Given
        let imageService = MockImageService()
        let jsonDecoder = MockJSONDecoder()
        let urlSession = MockURLSession()
        urlSession._data.result = .throwError(TestError.networkError)
        let service = RemoteFlagsService(
            imageService: imageService,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        let result = await service.remoteFlagImage(for: "CUR")
        // Then
        #expect(result == nil)
    }
    
    @Test
    func whenServiceConstructed_ThenValidJSONDecodeExecuted() async throws {
        // Given
        let loadedData = try self.mockJsonData
        let imageService = MockImageService()
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value([String:String]())
        let urlSession = MockURLSession()
        urlSession._data.result = .value(loadedData, URLResponse())
        // When
        self.service = RemoteFlagsService(
            imageService: imageService,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // Then
        try await jsonDecoder._decode.await(callsCount: 1)
        #expect(jsonDecoder._decode.history.count == 1)
        #expect(jsonDecoder._decode.history[0].data == loadedData)
        #expect(jsonDecoder._decode.history[0].type == [String : String].self)
    }

    @Test
    func givenJSONDecodeFails_WhenRemoteFlagImageExecuted_ThenResultIsNil() async throws {
        // Given
        let imageService = MockImageService()
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .throwError(TestError.decodingError)
        let urlSession = MockURLSession()
        urlSession._data.result = .value(Data(), URLResponse())
        // When
        let service = RemoteFlagsService(
            imageService: imageService,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        let result = await service.remoteFlagImage(for: "CUR")
        // Then
        #expect(result == nil)
    }
    
    @Test
    func givenCurrencyIDKnown_WhenRemoteFlagImageExecuted_ThenImageIsLoaded() async throws {
        let curImage = UIImage()
        let imageService = MockImageService()
        let _loadImage = await imageService._loadImage
        _loadImage.result = curImage
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value(["CUR":"https://example.com/cur.jpg"])
        let urlSession = MockURLSession()
        self.service = RemoteFlagsService(
            imageService: imageService,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        let result = await self.service?.remoteFlagImage(for: "CUR")
        // Then
        try await _loadImage.await(callsCount: 1)
        #expect(_loadImage.history.count == 1)
        #expect(_loadImage.history[0].absoluteString == "https://example.com/cur.jpg")
        #expect(result === curImage)
    }
    
    @Test
    func givenCurrencyIDNotKnown_WhenRemoteFlagImageExecuted_ThenImageIsNotLoaded() async throws {
        let imageService = MockImageService()
        let jsonDecoder = MockJSONDecoder()
        jsonDecoder._decode.result = .value(["CUR1":"https://example.com/cur.jpg"])
        let urlSession = MockURLSession()
        self.service = RemoteFlagsService(
            imageService: imageService,
            jsonDecoder: jsonDecoder,
            urlSession: urlSession
        )
        // When
        let result = await self.service?.remoteFlagImage(for: "CUR2")
        // Then
        let _loadImage = await imageService._loadImage
        #expect(_loadImage.history.count == 0)
        #expect(result == nil)
    }
}
