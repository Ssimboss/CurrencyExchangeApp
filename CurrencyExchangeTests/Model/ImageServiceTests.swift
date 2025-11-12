//
//  ImageServiceTests.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import UIKit
import Testing
@testable import CurrencyExchange

struct ImageServiceTests {
    enum TestError: Error {
        case invalidURL
        case invlaidPNGData
        case urlSessionDataLoadFailed
    }
    
    private var mockURL: URL {
        get throws {
            if let result = URL(string: "https://test.com/image.png") {
                return result
            } else {
                throw TestError.invalidURL
            }
        }
    }
    
    private var mockPNGData: Data {
        get throws {
            if let result = UIImage.checkmark.pngData() {
                return result
            } else {
                throw TestError.invalidURL
            }
        }
    }
    
    @Test
    func whenLoadImage_ThenValidURLSessionDataExecuted() async throws {
        // Given
        let imageURL = try self.mockURL
        let urlSession = MockURLSession()
        let imageService = ImageService(urlSession: urlSession)
        // When
        _ = await imageService.loadImage(for: imageURL)
        // Then
        #expect(urlSession._data.history.count == 1)
        #expect(urlSession._data.history[0].url == imageURL)
    }

    @Test
    func givenURLSessionDataThrowsErrir_WhenLoadImage_ThenResultIsNil() async throws {
        // Given
        let urlSession = MockURLSession()
        urlSession._data.result = .throwError(TestError.urlSessionDataLoadFailed)
        let imageService = ImageService(urlSession: urlSession)
        // When
        let result = await imageService.loadImage(for: try self.mockURL)
        // Then
        #expect(result == nil)
    }
    
    @Test
    func givenURLSessionDataReturnsPNGData_WhenLoadImage_ThenResultIsNotNil() async throws {
        // Given
        let urlSession = MockURLSession()
        urlSession._data.result = .value(try self.mockPNGData, URLResponse())
        let imageService = ImageService(urlSession: urlSession)
        // When
        let result = await imageService.loadImage(for: try self.mockURL)
        // Then
        #expect(result != nil)
    }

    @Test
    func givenURLSessionDataReturnsInvalidData_WhenLoadImage_ThenResultIsNil() async throws {
        // Given
        let urlSession = MockURLSession()
        urlSession._data.result = .value(Data(), URLResponse())
        let imageService = ImageService(urlSession: urlSession)
        // When
        let result = await imageService.loadImage(for: try self.mockURL)
        // Then
        #expect(result == nil)
    }
    
    @Test
    func givenURLSessionDataReturnsPNGData_WhenLoadImageTwice_ThenURLSessionDataNotExecuted() async throws {
        let urlSession = MockURLSession()
        urlSession._data.result = .value(try self.mockPNGData, URLResponse())
        let imageService = ImageService(urlSession: urlSession)
        // When
        let result1 = await imageService.loadImage(for: try self.mockURL)
        let result2 = await imageService.loadImage(for: try self.mockURL)
        // Then
        #expect(urlSession._data.history.count == 1)
        #expect(result1 != nil)
        #expect(result1 === result2)
    }
}
