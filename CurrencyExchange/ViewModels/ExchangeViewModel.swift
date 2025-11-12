//
//  ExchangeViewModel.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 07/11/2025.
//

import Combine
import SwiftUI

@MainActor
protocol ExchangeRouterProtocol {
    func showRetryLaterView()
    func showCurrencyPicker()
}

final class ExchangeViewModel: ExchangeViewModelProtocol {
    @MainActor
    let title = String(localized: "main_screen_title")
    @MainActor
    @Published private(set) var content: Loadable<ExchangeContentViewData> = .loading
    @MainActor
    let swapButoonA11tyLabel = String(localized: "main_screen_swap_button")
    
    private let currencyConverter: CurrencyConverterProtocol
    private let flagService: FlagServiceProtocol
    private let formatter: ExchangeFormatterProtocol
    private let ratesService: RatesServiceProtocol
    private let router: ExchangeRouterProtocol

    private var currentRate: Rate?

    init(
        currencyConverter: CurrencyConverterProtocol,
        flagService: FlagServiceProtocol,
        formatter: ExchangeFormatterProtocol,
        ratesService: RatesServiceProtocol,
        router: ExchangeRouterProtocol
    ) {
        self.currencyConverter = currencyConverter
        self.flagService = flagService
        self.formatter =  formatter
        self.ratesService = ratesService
        self.router = router
        Task { [weak self] in
            let currentSelectedRate = await ratesService.currentSelectedRate
            await self?.handleRatesUpdate(currentSelectedRate)
            for await selectedRate in await ratesService.selectedRateStream {
                await self?.handleRatesUpdate(selectedRate)
            }
        }
        Task { [weak self] in
            let currenFlagImages = await flagService.currenFlagImages
            self?.handleFlagImagesUpdate(currenFlagImages)
            for await flagImages in await flagService.flagImagesStream {
                self?.handleFlagImagesUpdate(flagImages)
            }
        }
        Task { [weak self] in
            await self?.ratesService.updateRates()
        }
    }

    @MainActor
    func topCurrencyChangeButtonDidTap() {
        self.router.showCurrencyPicker()
    }

    @MainActor
    func topCurrencyTextDidChange(_ text: String) -> Bool {
        return self.currencyTextDidChange(text, isTop: true)
    }
    
    @MainActor
    func topCurrencyDidFocus() {
        self.currencyTextDidFocus(isTop: true)
    }
    
    private func currencyTextDidFocus(isTop: Bool) {
        guard case .loaded(var content) = self.content else {
            assertionFailure("Unexpected state. `content` is not loaded.")
            return
        }
        var currency: ExchangeSectionViewData
        var otherCurrency: ExchangeSectionViewData
        if isTop {
            currency = content.topCurrency
            otherCurrency = content.bottomCurrency
        } else {
            currency = content.bottomCurrency
            otherCurrency = content.topCurrency
        }
        let text = currency.valueText
        do {
            _ = try self.formatter.formatInputText(text)
        } catch {
            guard error == ExchangeFormatterError.valueIsTooBig else { return }
            do {
                currency.valueText = try self.formatter.maxInputText
                if let rate = self.currentRate {
                    let otherCents = self.currencyConverter.convert(
                        self.formatter.maxInputCents,
                        from: currency.id,
                        to: otherCurrency.id,
                        rate: rate,
                        isSell: isTop
                    )
                    otherCurrency.valueText = self.formatter.outputText(cents: otherCents)
                } else {
                    assertionFailure("Unexpected state. `currentRate` missing.")
                }
                if isTop {
                    content.topCurrency = currency
                    content.bottomCurrency = otherCurrency
                } else {
                    content.bottomCurrency = currency
                    content.topCurrency = otherCurrency
                }
                self.content = .loaded(content)
            } catch {}
        }
    }
    
    private func currencyTextDidChange(
        _ text: String,
        isTop: Bool
    ) -> Bool {
        guard case .loaded(var content) = self.content else {
            assertionFailure("Unexpected state. `content` is not loaded.")
            return true
        }
        var currency: ExchangeSectionViewData
        var otherCurrency: ExchangeSectionViewData
        if isTop {
            currency = content.topCurrency
            otherCurrency = content.bottomCurrency
        } else {
            currency = content.bottomCurrency
            otherCurrency = content.topCurrency
        }
        guard text != currency.valueText else {
            return true
        }
        let newText: String
        let cents: Int
        do {
            (newText, cents) = try self.formatter.formatInputText(text)
        } catch {
            return false
        }
        currency.valueText = newText
        if newText.isEmpty {
            otherCurrency.valueText = ""
        } else if let rate = self.currentRate {
            let otherCents = self.currencyConverter.convert(
                cents,
                from: currency.id,
                to: otherCurrency.id,
                rate: rate,
                isSell: isTop
            )
            otherCurrency.valueText = self.formatter.outputText(cents: otherCents)
        } else {
            assertionFailure("Unexpected state. `currentRate` missing.")
        }
        if isTop {
            content.topCurrency = currency
            content.bottomCurrency = otherCurrency
        } else {
            content.bottomCurrency = currency
            content.topCurrency = otherCurrency
        }
        self.content = .loaded(content)
        return true
    }

    @MainActor
    func bottomCurrencyChangeButtonDidTap() {
        self.router.showCurrencyPicker()
    }
    
    @MainActor
    func bottomCurrencyTextDidChange(_ text: String) -> Bool {
        return self.currencyTextDidChange(text, isTop: false)
    }
    
    @MainActor
    func bottomCurrencyDidFocus() {
        self.currencyTextDidFocus(isTop: false)
    }

    @MainActor
    func swapButtonDidTap() {
        guard case .loaded(var content) = self.content else {
            assertionFailure("Unexpected state. `content` is not loaded.")
            return
        }
        let topCurrency = content.topCurrency
        content.topCurrency = content.bottomCurrency
        content.bottomCurrency = topCurrency
        if let rate = self.currentRate {
            content.rate = self.rateViewData(
                rate: rate,
                isAsk: content.topCurrency.id != USDc.currencyID
            )
        } else {
            assertionFailure("Unexpected state. `currentRate` missing.")
        }
        self.content = .loaded(content)
    }
    
    @MainActor
    private func handleRatesUpdate(_ rate: Loadable<RateResult>) async {
        switch rate {
        case .loading:
            break
        case .loaded(let result):
            switch result {
            case .success(let rate):
                await self.handleRatesUpdate(selectedRate: rate)
            case .failure(let error):
                self.handleRatesUpdateFailed(error: error)
            }
        }
    }

    @MainActor
    private func handleRatesUpdate(selectedRate: Rate) async {
        self.currentRate = selectedRate
        let rate: RateViewData
        let topCurrency: ExchangeSectionViewData
        let bottomCurrency: ExchangeSectionViewData
        switch self.content {
        case .loading:
            rate = self.rateViewData(rate: selectedRate, isAsk: false)
            topCurrency = await self.initialSectionViewData(for: USDc.currencyID, isTop: true)
            bottomCurrency = await self.initialSectionViewData(for: selectedRate.currencyID, isTop: false)
        case .loaded(let content):
            if content.topCurrency.id == USDc.currencyID {
                rate = self.rateViewData(rate: selectedRate, isAsk: false)
                topCurrency = content.topCurrency
                bottomCurrency = await self.nonUSDsSectionViewData(
                    for: selectedRate.currencyID,
                    usdcValueText: content.topCurrency.valueText,
                    isTop: false
                )
            } else {
                rate = self.rateViewData(rate: selectedRate, isAsk: true)
                topCurrency = await self.nonUSDsSectionViewData(
                    for: selectedRate.currencyID,
                    usdcValueText: content.bottomCurrency.valueText,
                    isTop: true
                )
                bottomCurrency = content.bottomCurrency
            }
        }
        self.content = .loaded(
            ExchangeContentViewData(
                rate: rate,
                topCurrency: topCurrency,
                bottomCurrency: bottomCurrency
            )
        )
        if rate.additionalText == nil {
            let expireInterval = self.ratesService.expireInterval(for: selectedRate)
            let expireNanoseconds = UInt64((expireInterval+0.1)*1_000_000_000)
            Task { [weak self] in
                try await Task.sleep(nanoseconds: expireNanoseconds)
                guard let currentRate = self?.currentRate, currentRate == selectedRate else {
                    return
                }
                await self?.handleRatesUpdate(selectedRate: selectedRate)
            }
        }
    }

    @MainActor
    private func handleRatesUpdateFailed(error: RatesServiceError) {
        guard case .loading = self.content else { return }
        self.router.showRetryLaterView()
    }

    @MainActor
    private func handleFlagImagesUpdate(_ flagImages: [String : Image]) {
        guard case .loaded(var content) = self.content else {
            return
        }
        content.topCurrency.image = flagImages[content.topCurrency.id]
        content.bottomCurrency.image = flagImages[content.bottomCurrency.id]
        self.content = .loaded(content)
    }
    
    private func rateViewData(rate: Rate, isAsk: Bool) -> RateViewData {
        let text: String
        let rateStringFormat = String(localized: "exchange_rate_format")
        if isAsk {
            text = String(format: rateStringFormat, USDc.currencyID, rate.ask, rate.currencyID)
        } else {
            text = String(format: rateStringFormat, USDc.currencyID, rate.bid, rate.currencyID)
        }
        return RateViewData(
            text: text,
            additionalText: self.ratesService.isRateExpired(rate)
                ? self.formatter.outdatedDateText(date: rate.date)
                : nil
        )
    }
    
    private func initialSectionViewData(for currencyID: String, isTop: Bool) async -> ExchangeSectionViewData {
        let flagImages = await  self.flagService.currenFlagImages
        let inputTextA11yLabelFormat = isTop ? String(localized: "section_sell_format") : String(localized: "section_buy_format")
        return ExchangeSectionViewData(
            id: currencyID,
            image: flagImages[currencyID],
            title: currencyID,
            inputTextA11yLabel: String(format: inputTextA11yLabelFormat, currencyID),
            valueText: "",
            valuePlaceholderText: self.formatter.outputText(cents: 0),
            changeable: currencyID == USDc.currencyID
                ? .notChangeable
                : .changeable(a11yButtonHint: String(localized: "main_screen_change_currency_button_hint"))
        )
    }
    
    private func nonUSDsSectionViewData(
        for currencyID: String,
        usdcValueText: String,
        isTop: Bool
    ) async -> ExchangeSectionViewData {
        let valueText: String = {
            guard !usdcValueText.isEmpty else { return "" }
            guard let rate = self.currentRate else {
                assertionFailure("Unexpected state. `currentRate` missing.")
                return ""
            }
            let usdcCents = (try? self.formatter.formatInputText(usdcValueText))?.cents ?? 0
            let otherCents = self.currencyConverter.convert(
                usdcCents,
                from: USDc.currencyID,
                to: currencyID,
                rate: rate,
                isSell: !isTop
            )
            return self.formatter.outputText(cents: otherCents)
        }()
        let flagImages = await  self.flagService.currenFlagImages
        let inputTextA11yLabelFormat = isTop ? String(localized: "section_sell_format") : String(localized: "section_buy_format")
        return ExchangeSectionViewData(
            id: currencyID,
            image: flagImages[currencyID],
            title: currencyID,
            inputTextA11yLabel: String(format: inputTextA11yLabelFormat, currencyID),
            valueText: valueText,
            valuePlaceholderText: self.formatter.outputText(cents: 0),
            changeable: .changeable(a11yButtonHint: String(localized: "main_screen_change_currency_button_hint"))
        )
    }
}
