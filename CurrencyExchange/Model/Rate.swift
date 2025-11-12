//
//  Rate.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 07/11/2025.
//

import Foundation

private enum RateConstants {
    nonisolated static let idPrefix: String = "usdc_"
}

nonisolated
struct Rate: Codable, Equatable, Sendable {
    private typealias Constants = RateConstants

    nonisolated static let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS"
    
    let ask: Double
    let bid: Double
    let currencyID: String
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case ask
        case bid
        case book
        case date
    }

    nonisolated init(
        ask: Double,
        bid: Double,
        currencyID: String,
        date: Date,
    ) {
        self.ask = ask
        self.bid = bid
        self.currencyID = currencyID
        self.date = date
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let book = try? container.decode(String.self, forKey: .book) else {
            let key = Rate.CodingKeys.book
            let context = DecodingError.Context(
                codingPath: [key],
                debugDescription: "`book` value was not decoded"
            )
            throw DecodingError.keyNotFound(key, context)
        }
        guard book.hasPrefix(Constants.idPrefix) else {
            let context = DecodingError.Context(
                codingPath: [Rate.CodingKeys.book],
                debugDescription: "`book` value has no prefix `\(Constants.idPrefix)`"
            )
            throw DecodingError.dataCorrupted(context)
        }
        let currencyID = String(book.dropFirst(Constants.idPrefix.count).uppercased())
        self.ask = try container.decodeDouble(forKey: .ask)
        self.bid = try container.decodeDouble(forKey: .bid)
        self.currencyID = currencyID
        self.date = try container.decode(Date.self, forKey: .date)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.ask, forKey: .ask)
        try container.encode(self.bid, forKey: .bid)
        try container.encode(Constants.idPrefix + self.currencyID.lowercased(), forKey: .book)
        try container.encode(self.date, forKey: .date)
    }
}

private extension KeyedDecodingContainer where K : CodingKey {
    nonisolated func decodeDouble(forKey key: K) throws -> Double {
        do {
            let doubleValue = try self.decode(Double.self, forKey: key)
            return doubleValue
        } catch {
            let string = try self.decode(String.self, forKey: key)
            if let doubleValue = Double(string) {
                return doubleValue
            } else {
                throw error
            }
        }
    }
}
