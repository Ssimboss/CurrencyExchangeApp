//
//  ExchangeRouter.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 08/11/2025.
//

import Combine

final class Navigation: ExchangeRouterProtocol,
                        CurrencyPickRouterProtocol,
                        RetryRouterProtocol,
                        ObservableObject {
    @Published
    var isRetryLaterViewShown: Bool = false
    @Published
    var isCurrencyPickerShown: Bool = false
    
    func showRetryLaterView() {
        self.isRetryLaterViewShown = true
    }

    func showCurrencyPicker() {
        self.isCurrencyPickerShown = true
    }

    func dismissRetryLaterView() {
        self.isRetryLaterViewShown = false
    }
    
    func dismissCurrencyPicker() {
        self.isCurrencyPickerShown = false
    }
}
