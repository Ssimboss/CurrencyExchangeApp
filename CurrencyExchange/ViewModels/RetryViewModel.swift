//
//  RetryViewModel.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 08/11/2025.
//

import Combine
import Foundation

@MainActor
protocol RetryRouterProtocol {
    func dismissRetryLaterView()
}

final class RetryViewModel: RetryViewModelProtocol {
    @MainActor
    let title = String(localized: "retry_alert_title")
    @MainActor
    let bodyText = String(localized: "retry_alert_body_text")
    @MainActor
    let buttonText = String(localized: "retry_alert_cta_text")

    private let ratesService: RatesServiceProtocol
    private let router: RetryRouterProtocol
    init(
        ratesService: RatesServiceProtocol,
        router: RetryRouterProtocol
    ) {
        self.ratesService = ratesService
        self.router = router
    }

    @MainActor
    func buttonDidTap() {
        Task { [ratesService] in
            await ratesService.updateRates()
        }
        self.router.dismissRetryLaterView()
    }
}
