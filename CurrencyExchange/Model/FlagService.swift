//
//  FlagService.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 09/11/2025.
//

import Combine
import SwiftUI

protocol FlagServiceProtocol: Actor {
    var currenFlagImages: [String : Image] { get }
    var flagImagesStream: AsyncStream<[String : Image]> { get }
}

private enum FlagServiceConstants {
    nonisolated static let resourcsePrefix = "flag_"
}

actor FlagService: FlagServiceProtocol {
    private typealias Constants = FlagServiceConstants
    private(set) var currenFlagImages: [String : Image] = [
        USDc.currencyID : Image(Constants.resourcsePrefix + USDc.currencyID.lowercased())
    ]
    var flagImagesStream: AsyncStream<[String : Image]> {
        return AsyncStream(
            [String : Image].self,
            bufferingPolicy: .bufferingNewest(1)
        ) { continuation in
            Task { [weak self] in
                await self?.setContinuation(continuation)
            }
        }
    }

    private let bundle: Bundle
    private let ratesService: RatesServiceProtocol
    private let remoteFlagsService: RemoteFlagsServiceProtocol

    private var flagImagesContinuations: [UUID : AsyncStream<[String : Image]>.Continuation] = [:]

    init(
        bundle: Bundle,
        ratesService: RatesServiceProtocol,
        remoteFlagsService: RemoteFlagsServiceProtocol
    ) {
        self.bundle = bundle
        self.ratesService = ratesService
        self.remoteFlagsService = remoteFlagsService
        Task { [weak self] in
            let currentCurrencies = await ratesService.currentCurrencies
            await self?.handleCurrenciesUpdate(currentCurrencies)
            for await currencies in await ratesService.currenciesStream {
                await self?.handleCurrenciesUpdate(currencies)
            }
        }
    }
    
    private func setContinuation(_ continuation: AsyncStream<[String : Image]>.Continuation) {
        let identifier = UUID()
        self.flagImagesContinuations[identifier] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeContinuation(for: identifier)
            }
        }
    }
    private func removeContinuation(for identifier: UUID) {
        self.flagImagesContinuations[identifier] = nil
    }
    
    private func handleCurrenciesUpdate(_ currencies: Loadable<CurrenciesResult>) {
        guard case .loaded(let result) = currencies,
              case .success(let currencies) = result else {
            return
        }
        var newFlags: [String : Image] = [:]
        currencies.forEach { currencyID in
            let assetName = Constants.resourcsePrefix + currencyID.lowercased()
            if let image = UIImage(named: assetName) {
                newFlags[currencyID] = Image(uiImage: image)
            } else {
                Task { [weak self] in
                    guard let image = await self?.remoteFlagsService.remoteFlagImage(for: currencyID) else { return }
                    await self?.updateFlagImages([currencyID : Image(uiImage: image)])
                }
            }
        }
        self.updateFlagImages(newFlags)
    }
    
    private func updateFlagImages(_ newValues: [String : Image]) {
        var currenFlagImages = self.currenFlagImages
        newValues.forEach { currencyID, image in
            currenFlagImages[currencyID] = image
        }
        self.currenFlagImages = currenFlagImages
        for (_, continuation) in self.flagImagesContinuations {
            continuation.yield(currenFlagImages)
        }
    }
}
