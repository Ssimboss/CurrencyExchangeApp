//
//  CurrencyConverter.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 09/11/2025.
//

import Foundation

protocol CurrencyConverterProtocol {
    nonisolated func convert(
        _ value: Int,
        from sourceCurrencyID: String,
        to targetCurrencyID: String,
        rate: Rate,
        isSell: Bool
    ) -> Int
}

final class CurrencyConverter: CurrencyConverterProtocol {
    nonisolated func convert(
        _ value: Int,
        from sourceCurrencyID: String,
        to targetCurrencyID: String,
        rate: Rate,
        isSell: Bool
    ) -> Int {
        let isAsk: Bool = isSell ? targetCurrencyID == USDc.currencyID : sourceCurrencyID == USDc.currencyID
        let rateValue = isAsk ? rate.ask : rate.bid
        let convertRateValue = (sourceCurrencyID == USDc.currencyID) ? rateValue : 1 / rateValue
        var result: Double = Double(value) * (convertRateValue)
        if isSell {
            result = floor(result)
        } else {
            result = ceil(result)
        }
        return Int(result)
    }
}
