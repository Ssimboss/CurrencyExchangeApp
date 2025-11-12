//
//  RatesService.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 08/11/2025.
//

import Combine
import Foundation

enum RatesServiceError: Error, Sendable {
    case loadingFailed
    case selectedRateNotLoaded
}

typealias RateResult = Result<Rate, RatesServiceError>
typealias CurrenciesResult = Result<[String], RatesServiceError>

protocol RatesServiceProtocol: Actor {
    var currentSelectedRate: Loadable<RateResult> { get }
    var selectedRateStream: AsyncStream<Loadable<RateResult>> { get }
    
    var currentCurrencies: Loadable<CurrenciesResult> { get }
    var currenciesStream: AsyncStream<Loadable<CurrenciesResult>> { get }
    
    func updateRates() async
    func selectRate(currencyID: String)
    
    nonisolated func isRateExpired(_ rate: Rate) -> Bool
    nonisolated func expireInterval(for rate: Rate) -> TimeInterval
}

private enum RatesServiceConstants {
    nonisolated static let rateExpireInterval: TimeInterval = 60*60
}

actor RatesService: RatesServiceProtocol {
    private typealias Constants = RatesServiceConstants
    private(set) var currentSelectedRate: Loadable<RateResult> = .loading
    var selectedRateStream: AsyncStream<Loadable<RateResult>> {
        return AsyncStream(
            Loadable<RateResult>.self,
            bufferingPolicy: .bufferingNewest(1)
        ) { continuation in
            Task { [weak self] in
                await self?.setSelectedRateContinuation(continuation)
            }
        }
    }
    private(set) var currentCurrencies: Loadable<CurrenciesResult> = .loading
    var currenciesStream: AsyncStream<Loadable<CurrenciesResult>> {
        return AsyncStream(
            Loadable<CurrenciesResult>.self,
            bufferingPolicy: .bufferingNewest(1)
        ) { continuation in
            Task { [weak self] in
                await self?.setCurrenciesContinuation(continuation)
            }
        }
    }
    
    private var selectedRateStreamContinuations: [UUID: AsyncStream<Loadable<RateResult>>.Continuation] = [:]
    private var currenciesContinuations: [UUID: AsyncStream<Loadable<CurrenciesResult>>.Continuation] = [:]
    
    private var rates: Loadable<Result<[Rate], RatesServiceError>> = .loading

    nonisolated private let currentDateProvider: @Sendable () -> Date
    private let cache: RatesCacheProtocol
    private let rateAPI: RateAPIProtocol

    init(
        cache: RatesCacheProtocol,
        currentDateProvider: @escaping @Sendable () -> Date,
        rateAPI: RateAPIProtocol
    ) {
        self.cache = cache
        self.currentDateProvider = currentDateProvider
        self.rateAPI = rateAPI
        Task { [weak self] in
            async let rates = cache.getCachedRates()
            async let selectedRateID = cache.getCachedSelectedCurrencyID()
            await self?.restoreFromCache(rates: rates, selectedRateID: selectedRateID)
        }
    }
    
    private func restoreFromCache(rates: [Rate]?, selectedRateID: String?) async {
        guard case .loading = self.rates,
              case .loading = self.currentSelectedRate else { return }
        try? self.updateRates(rates: rates, selectedRateID: selectedRateID)
    }
    
    private func setSelectedRateContinuation(_ continuation: AsyncStream<Loadable<RateResult>>.Continuation) {
        let identifier = UUID()
        self.selectedRateStreamContinuations[identifier] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeSelectedRateContinuation(for: identifier)
            }
        }
    }

    private func removeSelectedRateContinuation(for identifier: UUID) {
        self.selectedRateStreamContinuations[identifier] = nil
    }
    
    private func setCurrenciesContinuation(_ continuation: AsyncStream<Loadable<CurrenciesResult>>.Continuation) {
        let identifier = UUID()
        self.currenciesContinuations[identifier] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeCurrenciesContinuation(for: identifier)
            }
        }
    }
    
    private func removeCurrenciesContinuation(for identifier: UUID) {
        self.currenciesContinuations[identifier] = nil
    }
    
    private func setRates(_ rates: Loadable<Result<[Rate], RatesServiceError>>) {
        self.rates = rates
        let currencies = rates.map { rateResult in
            return rateResult.map { rates in
                return rates.map { rate in
                    return rate.currencyID
                }
            }
        }
        self.currentCurrencies = currencies
        for (_, continuation) in self.currenciesContinuations {
            continuation.yield(currencies)
        }
    }

    private func setSelectedRate(_ rate: Loadable<RateResult>) {
        self.currentSelectedRate = rate
        for (_, continuation) in self.selectedRateStreamContinuations {
            continuation.yield(rate)
        }
    }

    func updateRates() async {
        Task { [weak self] in
            do {
                let currencies = try await self?.rateAPI.fetchCurrencies()
                guard let loadedCurrencies = currencies,
                      !loadedCurrencies.isEmpty else {
                    throw RatesServiceError.loadingFailed
                }
                let rates = try await self?.rateAPI.fetchRates(currencyIDs: loadedCurrencies)
                let selectedRate = await self?.currentSelectedRate
                try await self?.updateRates(
                    rates: rates,
                    selectedRateID: {
                        return selectedRate.flatMap { rate in
                            if case .loaded(let result) = rate,
                               case .success(let loadedRate) = result {
                                return loadedRate.currencyID
                            } else {
                                return nil
                            }
                        }
                    }()
                )
                await self?.cacheCurrentState()
            } catch {
                await self?.setLoadingFailedIfNeeded()
            }
        }
    }

    private func updateRates(rates: [Rate]?, selectedRateID: String?) throws(RatesServiceError) {
        guard let loadedRates = rates,
              let firstRate = loadedRates.first else {
            throw RatesServiceError.loadingFailed
        }
        self.setRates(.loaded(.success(loadedRates)))
        let newSelectedRate: Rate
        if let selectedRateID,
           let selectedRate = rates?.first(where: { $0.currencyID == selectedRateID }) {
            newSelectedRate = selectedRate
        } else {
            newSelectedRate = firstRate
        }
        self.setSelectedRate(.loaded(.success(newSelectedRate)))
    }

    private func setLoadingFailedIfNeeded() {
        guard case .loading = self.rates,
              case .loading = self.currentCurrencies,
              case .loading = self.currentSelectedRate else { return }
        self.setRates(.loaded(.failure(.loadingFailed)))
        self.setSelectedRate(.loaded(.failure(.loadingFailed)))
    }

    private func cacheCurrentState() {
        Task {
            guard case .loaded(let result) = self.rates,
                  case .success(let rates) = result else {
                return
            }
            try await self.cache.cache(rates: rates)
        }
        Task {
            guard case .loaded(let result) = self.currentSelectedRate,
                  case .success(let rate) = result else {
                return
            }
            await self.cache.cache(selectedCurrencyID: rate.currencyID)
        }
    }

    func selectRate(currencyID: String) {
        guard case .loaded(let result) = self.rates,
              case .success(let rates) = result,
              let rate = rates.first(where: { $0.currencyID == currencyID }) else {
            return
        }
        self.setSelectedRate(.loaded(.success(rate)))
        Task {
            await self.cache.cache(selectedCurrencyID: currencyID)
        }
    }

    nonisolated func isRateExpired(_ rate: Rate) -> Bool {
        return self.expireInterval(for: rate) < 0
    }

    nonisolated func expireInterval(for rate: Rate) -> TimeInterval {
        let expireDate = rate.date.addingTimeInterval(Constants.rateExpireInterval)
        let currentDate = self.currentDateProvider()
        return expireDate.timeIntervalSince(currentDate)
    }
}
