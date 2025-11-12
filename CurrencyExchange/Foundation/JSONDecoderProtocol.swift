//
//  JSONDecoderProtocol.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 10/11/2025.
//

import Foundation

protocol JSONDecoderProtocol {
    nonisolated var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get set }
    nonisolated func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

extension JSONDecoder: JSONDecoderProtocol {}
