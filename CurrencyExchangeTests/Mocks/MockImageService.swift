//
//  MockImageService.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 12/11/2025.
//

import UIKit
@testable import CurrencyExchange

actor MockImageService: ImageServiceProtocol {
    var _loadImage = _LoadImage()

    func loadImage(for url: URL) async -> UIImage? {
        self._loadImage.history.append(url)
        await self._loadImage.resume()
        return self._loadImage.result
    }

    final class _LoadImage {
        var history: [URL] = []
        var result: UIImage? = nil
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
}
