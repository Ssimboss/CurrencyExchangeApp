//
//  UserDefaultsProtocol.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 10/11/2025.
//

import Foundation

protocol UserDefaultsProtocol {
    nonisolated func set(_ value: Any?, forKey defaultName: String)
    nonisolated func string(forKey defaultName: String) -> String?
}

extension UserDefaults: UserDefaultsProtocol {}
