//
//  ExchangeFormatterTests.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 11/11/2025.
//

import Foundation
import Testing
@testable import CurrencyExchange

@MainActor
struct ExchangeFormatterTests {
    let formatter = ExchangeFormatter()
    
    // MARK: - tetsing: formatInputText
    @Test
    func givenEmptyString_WhenFormatInputText_ThenResultIsEmpty() throws {
        // When
        let result = try? self.formatter.formatInputText("")
        // Then
        guard let result else {
            Issue.record("Result should not be nil")
            return
        }
        #expect(result.text.isEmpty)
        #expect(result.cents == 0)
    }

    @Test
    func givenSurrencySymbol_WhenFormatInputText_ThenResultIsEmpty() throws {
        // When
        let result = try? self.formatter.formatInputText("$")
        // Then
        guard let result else {
            Issue.record("Result should not be nil")
            return
        }
        #expect(result.text.isEmpty)
        #expect(result.cents == 0)
    }

    @Test
    func givenDecimalSeperator_WhenFormatInputText_ThenResultIsZero() throws {
        // When
        let result = try? self.formatter.formatInputText(".")
        // Then
        guard let result else {
            Issue.record("Result should not be nil")
            return
        }
        #expect(result.text == "$0.")
        #expect(result.cents == 0)
    }

    @Test
    func givenOneDigitAfterDecimalSeperator_WhenFormatInputText_ThenResultHasOneDigitAfterDecimalSeperator() async throws {
        // When
        let result = try? self.formatter.formatInputText("12.3")
        // Then
        guard let result else {
            Issue.record("Result should not be nil")
            return
        }
        #expect(result.text == "$12.3")
        #expect(result.cents == 1230)
    }

    @Test
    func givenTwoDigitAfterDecimalSeperator_WhenFormatInputText_ThenResultHasTwoDigitAfterDecimalSeperator() async throws {
        // When
        let result = try? self.formatter.formatInputText("12.39")
        // Then
        guard let result else {
            Issue.record("Result should not be nil")
            return
        }
        #expect(result.text == "$12.39")
        #expect(result.cents == 1239)
    }

    @Test
    func givenThreeDigitAfterDecimalSeperator_WhenFormatInputText_ThenMaximumFractionDigitsLimitOverflowErrorThrown() async throws {
        var thrownError: ExchangeFormatterError?
        // When
        do throws(ExchangeFormatterError) {
            _ = try self.formatter.formatInputText("12.395")
        } catch {
            thrownError = error
        }
        // Then
        guard let thrownError else {
            Issue.record("Formatter should throw an error")
            return
        }
        #expect(thrownError == .maximumFractionDigitsLimitOverflow)
    }

    @Test
    func givenSevenDigitsBeforeDecimalSeperator_WhenFormatInputText_ThenResultDigitsGroupedByThree() async throws {
        // When
        let result = try? self.formatter.formatInputText("123,4567")
        // Then
        guard let result else {
            Issue.record("Result should not be nil")
            return
        }
        #expect(result.text == "$1,234,567")
        #expect(result.cents == 123456700)
    }
    
    @Test
    func givenTenDigitsBeforeDecimalSeperator_WhenFormatInputText_ThenValueIsTooBigErrorThrown() {
        var thrownError: ExchangeFormatterError?
        // When
        do throws(ExchangeFormatterError) {
            _ = try self.formatter.formatInputText("123,456,7890")
        } catch {
            thrownError = error
        }
        // Then
        guard let thrownError else {
            Issue.record("Formatter should throw an error")
            return
        }
        #expect(thrownError == .valueIsTooBig)
    }
    // MARK: - testing: outputText
    @Test
    func givenZeroCents_WhenFormatOutputText_ThenResultIsZeroWithTwoDigitsAfterDecimalSeperator() {
        // When
        let result = self.formatter.outputText(cents: 0)
        // Then
        #expect(result == "$0.00")
    }
    // MARK: - testing: outdatedDateText
    @Test
    func givenZeroTimestampDate_WhenOutdatedDateText_Then() {
        // Given
        let date = Date.init(timeIntervalSince1970: 0)
        // When
        let dateText = self.formatter.outdatedDateText(date: date)
        // Then
        #expect(dateText == "01/01/1970, 01:00:00")
    }
}
