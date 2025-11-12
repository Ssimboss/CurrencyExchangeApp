//
//  ImageService.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import UIKit

protocol ImageServiceProtocol: Actor {
    func loadImage(for url: URL) async -> UIImage?
}

actor ImageService: ImageServiceProtocol {
    private var cache: [URL : UIImage] = [:]
    private let urlSession: URLSessionProtocol
    
    init(
        urlSession: URLSessionProtocol
    ) {
        self.urlSession = urlSession
    }

    func loadImage(for url: URL) async -> UIImage? {
        if let cachedImage = self.cache[url] {
            return cachedImage
        }
        guard let (imageData, _) = try? await self.urlSession.data(from: url, delegate: nil) else {
            return nil
        }
        if let image = UIImage(data: imageData) {
            self.cache[url] = image
            return image
        } else {
            return nil
        }
    }
}
