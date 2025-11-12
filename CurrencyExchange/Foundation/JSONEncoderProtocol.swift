//
//  JSONEncoderProtocol.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 10/11/2025.
//

import Foundation

protocol JSONEncoderProtocol {
    nonisolated var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get set }
    nonisolated func encode<T>(_ value: T) throws -> Data where T : Encodable
}

extension JSONEncoder: JSONEncoderProtocol {}
