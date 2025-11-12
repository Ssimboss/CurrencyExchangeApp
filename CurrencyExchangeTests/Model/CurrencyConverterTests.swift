//
//  CurrencyConverterTests.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import Foundation
import Testing
@testable import CurrencyExchange

struct CurrencyConverterTests {
    private let converter = CurrencyConverter()
    private let currencyID = "TestCurrency"
    private let rate = Rate(
        ask: 1.601,
        bid: 1.401,
        currencyID: "TestCurrency",
        date: Date(timeIntervalSince1970: 0)
    )
    
    @Test
    func givenFromUSDc_AndIsSellTrue_WhenConvert_ThenResultIsValid() throws {
        // When
        let result = self.converter.convert(100,
                                            from: USDc.currencyID,
                                            to: self.currencyID,
                                            rate: self.rate,
                                            isSell: true)
        // Then
        #expect(result == 140)
    }
    
    @Test
    func givenFromUSDc_AndIsSellFalse_WhenConvert_ThenResultIsValid() throws {
        // When
        let result = self.converter.convert(100,
                                            from: USDc.currencyID,
                                            to: self.currencyID,
                                            rate: self.rate,
                                            isSell: false)
        // Then
        #expect(result == 161)
    }
    
    @Test
    func givenToUSDc_AndIsSellTrue_WhenConvert_ThenResultIsValid() throws {
        // When
        let result = self.converter.convert(100,
                                            from: self.currencyID,
                                            to: USDc.currencyID,
                                            rate: self.rate,
                                            isSell: true)
        // Then
        #expect(result == 62)
    }
    
    @Test
    func givenToUSDc_AndIsSellFalse_WhenConvert_ThenResultIsValid() throws {
        // When
        let result = self.converter.convert(100,
                                            from: self.currencyID,
                                            to: USDc.currencyID,
                                            rate: self.rate,
                                            isSell: false)
        // Then
        #expect(result == 72)
    }
}
