//
//  RemoteFlagsService.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import UIKit

enum RemoteFlagsServiceError: Error {
    case invalidRemoteFlagsURL
    case dataFetchingFailed(sessionError: Error)
    case dataDecodingFailed(jsonDecoderError: Error)
}

protocol RemoteFlagsServiceProtocol: Actor {
    func remoteFlagImage(for currencyID: String) async -> UIImage?
}

private enum RemoteFlagsServiceConstants {
    nonisolated static let remoteFlagsURLString = "https://raw.githubusercontent.com/Ssimboss/CurrencyExchangeApp/refs/heads/main/flags.json"
}

actor RemoteFlagsService: RemoteFlagsServiceProtocol {
    private typealias Constants = RemoteFlagsServiceConstants
    private typealias ImageURLStringsResult = Result<[String : String], RemoteFlagsServiceError>

    private var imageURLStrings: Loadable<ImageURLStringsResult> = .loading
    private var loadingImageURLStringsContinuations: [CheckedContinuation<ImageURLStringsResult, Never>] = []
    
    private let imageService: ImageServiceProtocol
    private var jsonDecoder: JSONDecoderProtocol
    private let urlSession: URLSessionProtocol
    
    init(
        imageService: ImageServiceProtocol,
        jsonDecoder: JSONDecoderProtocol,
        urlSession: URLSessionProtocol
    ) {
        self.imageService = imageService
        self.jsonDecoder = jsonDecoder
        self.urlSession = urlSession
        Task { [weak self] in
            await self?.updateImageURLStrings()
        }
    }

    private func setLoadedImageURLStrings(_ result: ImageURLStringsResult) {
        self.imageURLStrings = .loaded(result)
        self.loadingImageURLStringsContinuations.forEach { $0.resume(returning: result) }
        self.loadingImageURLStringsContinuations.removeAll()
    }

    private func updateImageURLStrings() {
        self.imageURLStrings = .loading
        Task { [weak self] in
            do throws(RemoteFlagsServiceError) {
                guard let imageURLStrings = try await self?.loadImageURLStrings() else {
                    return
                }
                await self?.setLoadedImageURLStrings(.success(imageURLStrings))
            } catch {
                await self?.setLoadedImageURLStrings(.failure(error))
            }
        }
    }

    private func loadImageURLStrings() async throws(RemoteFlagsServiceError) -> [String : String] {
        guard let url = URL(string: Constants.remoteFlagsURLString) else {
            throw .invalidRemoteFlagsURL
        }
        let data: Data
        do {
            data = try await self.urlSession.data(from: url, delegate: nil).0
        } catch {
            throw .dataFetchingFailed(sessionError: error)
        }
        let remoteImageURLStrings: [String : String]
        do {
            remoteImageURLStrings = try self.jsonDecoder.decode([String : String].self, from: data)
        } catch {
            throw .dataDecodingFailed(jsonDecoderError: error)
        }
        return remoteImageURLStrings
    }

    func remoteFlagImage(for currencyID: String) async -> UIImage? {
        let imageURLStrings: [String : String]
        switch self.imageURLStrings {
        case .loaded(.success(let loadedDictionary)):
            imageURLStrings = loadedDictionary
        case .loading:
            let result = await withCheckedContinuation { continuation in
                self.loadingImageURLStringsContinuations.append(continuation)
            }
            if case .success(let loadedDictionary) = result {
                imageURLStrings = loadedDictionary
            } else {
                return nil
            }
        case .loaded(.failure):
            self.updateImageURLStrings()
            let result = await withCheckedContinuation { continuation in
                self.loadingImageURLStringsContinuations.append(continuation)
            }
            if case .success(let loadedDictionary) = result {
                imageURLStrings = loadedDictionary
            } else {
                return nil
            }
        }
        guard let imageURLString = imageURLStrings[currencyID] else {
            return nil
        }
        return await self.loadFlagImage(urlString: imageURLString)
    }

    private func loadFlagImage(urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        return await self.imageService.loadImage(for: url)
    }
}
