//
//  CurrencyExchangeApp.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 06/11/2025.
//

import SwiftUI

@main
struct CurrencyExchangeApp: App {
    private var cache: RatesCache
    private var flagService: FlagServiceProtocol
    private var imageService: ImageServiceProtocol
    private var rateAPI: RateAPIProtocol
    private var ratesService: RatesServiceProtocol
    private var remoteFlagsService: RemoteFlagsServiceProtocol
    private var exchangeViewModel: ExchangeViewModel
    @ObservedObject
    private var navigation: Navigation

    init() {
        self.cache = RatesCache(
            fileManager: FileManager.default,
            jsonDecoder: JSONDecoder(),
            jsonEncoder: JSONEncoder(),
            userDefaults: UserDefaults.standard
        )
        self.imageService = ImageService(
            urlSession: URLSession.shared
        )
        self.rateAPI = RateAPI(
            currencyLoadMock: .enabled,
            jsonDecoder: JSONDecoder(),
            urlSession: URLSession.shared
        )
        self.ratesService = RatesService(
            cache: self.cache,
            currentDateProvider: { Date.now },
            rateAPI: self.rateAPI
        )
        self.remoteFlagsService = RemoteFlagsService(
            imageService: self.imageService,
            jsonDecoder: JSONDecoder(),
            urlSession: URLSession.shared
        )
        let navigation = Navigation()
        self.flagService = FlagService(
            bundle: .main,
            ratesService: self.ratesService,
            remoteFlagsService: self.remoteFlagsService
        )
        self.navigation = navigation
        self.exchangeViewModel = ExchangeViewModel(
            currencyConverter: CurrencyConverter(),
            flagService: self.flagService,
            formatter: ExchangeFormatter(),
            ratesService: self.ratesService,
            router: navigation
        )
    }

    var body: some Scene {
        WindowGroup {
            ExchangeView(viewModel: self.exchangeViewModel)
                .sheet(isPresented: self.$navigation.isRetryLaterViewShown) {
                    RetryView(
                        viewModel: RetryViewModel(
                            ratesService: self.ratesService,
                            router: self.navigation
                        )
                    )
                }
                .sheet(isPresented: self.$navigation.isCurrencyPickerShown) {
                    CurrencyPickView(
                        viewModel: CurrencyPickViewModel(
                            flagService: self.flagService,
                            ratesService: self.ratesService,
                            router: self.navigation
                        )
                    )
                }
        }
    }
}
