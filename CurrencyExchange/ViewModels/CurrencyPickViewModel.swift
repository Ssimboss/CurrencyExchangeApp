//
//  CurrencyPickViewModel.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 09/11/2025.
//

import Combine
import SwiftUI

@MainActor
protocol CurrencyPickRouterProtocol {
    func dismissCurrencyPicker()
}

final class CurrencyPickViewModel: CurrencyPickViewModelProtocol {
    @MainActor
    let title = String(localized: "currency_picker_title")
    @MainActor
    let closeButtonA11yLabel = String(localized: "currency_picker_close_button")
    @MainActor @Published
    private(set) var currencies: [CurrencyPickViewData] = []
    @MainActor @Published
    private(set) var selectedCurrencyId = ""

    private let flagService: FlagServiceProtocol
    private let ratesService: RatesServiceProtocol
    private let router: CurrencyPickRouterProtocol

    init(
        flagService: FlagServiceProtocol,
        ratesService: RatesServiceProtocol,
        router: CurrencyPickRouterProtocol
    ) {
        self.flagService = flagService
        self.ratesService = ratesService
        self.router = router
        Task { [weak self] in
            let currentSelectedRate = await ratesService.currentSelectedRate
            self?.handleRatesUpdate(selectedRate: currentSelectedRate)
            for await selectedRate in await ratesService.selectedRateStream {
                self?.handleRatesUpdate(selectedRate: selectedRate)
            }
        }
        Task { [weak self] in
            let currenCurrencies = await ratesService.currentCurrencies
            await self?.handleCurrenciesUpdate(currenCurrencies)
            for await currencies in await ratesService.currenciesStream {
                await self?.handleCurrenciesUpdate(currencies)
            }
        }
        Task { [weak self] in
            let currenFlagImages = await flagService.currenFlagImages
            self?.handleFlagImagesUpdate(currenFlagImages)
            for await flagImages in await flagService.flagImagesStream {
                self?.handleFlagImagesUpdate(flagImages)
            }
        }
    }

    @MainActor
    func closeButtonDidTap() {
        self.router.dismissCurrencyPicker()
    }

    @MainActor
    func currencyDidSelect(id: String) {
        Task { [weak ratesService] in
            await ratesService?.updateRates()
        }
        Task { [weak ratesService] in
            await ratesService?.selectRate(currencyID: id)
        }
        self.router.dismissCurrencyPicker()
    }

    @MainActor
    private func handleRatesUpdate(selectedRate: Loadable<RateResult>) {
        guard case .loaded(let result) = selectedRate,
              case .success(let selectedRate) = result else {
            return
        }
        self.selectedCurrencyId = selectedRate.currencyID
    }

    @MainActor
    private func handleCurrenciesUpdate(_ currencies: Loadable<CurrenciesResult>) async {
        guard case .loaded(let result) = currencies,
              case .success(let currencies) = result else {
            return
        }
        let flagImages = await self.flagService.currenFlagImages
        self.currencies = currencies.map { currencyID in
            CurrencyPickViewData(
                id: currencyID,
                image: flagImages[currencyID],
                title: currencyID
            )
        }
    }

    @MainActor
    private func handleFlagImagesUpdate(_ flagImages: [String : Image]) {
        self.currencies = self.currencies.map { viewData in
            var newData = viewData
            newData.image = flagImages[viewData.id]
            return newData
        }
    }
}
