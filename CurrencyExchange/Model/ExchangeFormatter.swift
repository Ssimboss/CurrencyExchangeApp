//
//  ExchangeFormatter.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 09/11/2025.
//

import Foundation

enum ExchangeFormatterError: Error {
    case valueIsTooBig
    case maximumFractionDigitsLimitOverflow
    case numberFormaterError
}

@MainActor
protocol ExchangeFormatterProtocol {
    func formatInputText(_ text: String) throws(ExchangeFormatterError) -> (text: String, cents: Int)
    func outputText(cents: Int) -> String
    var maxInputText: String { get throws(ExchangeFormatterError) }
    var maxInputCents: Int { get }
    func outdatedDateText(date: Date) -> String
}

final class ExchangeFormatter: ExchangeFormatterProtocol {
    private let positivePrefix: Character = "$"
    private let decimalSeparator: Character = "."
    private let groupingSeparator: Character = ","
    private let digits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    private let maximumFractionDigits = 2
    let maxInputCents = 99999999999
    
    private let numberFormatter: NumberFormatter
    private let dateFormatter: DateFormatter
    
    init() {
        let numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = String(self.decimalSeparator)
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSeparator = String(self.groupingSeparator)
        numberFormatter.positivePrefix = String(self.positivePrefix)
        self.numberFormatter = numberFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        self.dateFormatter = dateFormatter
    }
    
    func formatInputText(_ text: String) throws(ExchangeFormatterError) -> (text: String, cents: Int) {
        guard text != String(self.positivePrefix), !text.isEmpty else {
            return (text: "", cents: 0)
        }
        var cents = 0
        let lastDecimalSeparatorIndex = text.lastIndex(of: ".")
        let dollarsString: String
        if let lastDecimalSeparatorIndex {
            let centsString = text
                .suffix(from: text.index(after: lastDecimalSeparatorIndex))
                .filter { character in
                    return self.digits.contains(character)
                }
            guard centsString.count <= self.maximumFractionDigits else {
                throw.maximumFractionDigitsLimitOverflow
            }
            dollarsString = text
                .prefix(upTo: lastDecimalSeparatorIndex)
                .filter { character in
                    return self.digits.contains(character)
                }
            if let centsNumber = Int(centsString) {
                if centsString.count == 1 {
                    cents = centsNumber * 10
                } else {
                    cents = centsNumber
                }
            }
            self.numberFormatter.maximumFractionDigits = centsString.count
            self.numberFormatter.minimumFractionDigits = centsString.count
        } else {
            dollarsString = text
                .filter { character in
                    return self.digits.contains(character)
                }
            self.numberFormatter.maximumFractionDigits = 0
            self.numberFormatter.minimumFractionDigits = 0
        }
        if let dollarsNumber = Int(dollarsString) {
            cents += dollarsNumber * 100
        }
        guard cents <= self.maxInputCents else {
            throw .valueIsTooBig
        }
        guard var result = self.numberFormatter.string(for: Double(cents)/100) else {
            throw .numberFormaterError
        }
        if text.last == self.decimalSeparator {
            result.append(self.decimalSeparator)
        }
        return (text: result, cents: cents)
    }

    var maxInputText: String {
        get throws(ExchangeFormatterError) {
            let cents = self.maxInputCents
            guard let result = self.numberFormatter.string(for: Double(cents)/100) else {
                throw .numberFormaterError
            }
            return result
        }
    }

    func outputText(cents: Int) -> String {
        self.numberFormatter.maximumFractionDigits = self.maximumFractionDigits
        self.numberFormatter.minimumFractionDigits = self.maximumFractionDigits
        return self.numberFormatter.string(for: Double(cents)/100) ?? ""
    }
    
    func outdatedDateText(date: Date) -> String {
        return self.dateFormatter.string(from: date)
    }
}
