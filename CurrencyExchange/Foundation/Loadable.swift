//
//  Loadable.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 08/11/2025.
//

enum Loadable<T> {
    case loading
    case loaded(T)

    nonisolated func map<U: Equatable>(_ transform: (T) throws -> U) rethrows -> Loadable<U> {
        switch self {
        case .loading:
            return .loading
        case .loaded(let value):
            return try .loaded(transform(value))
        }
    }
}

extension Loadable: Equatable where T: Equatable {}
extension Loadable: Sendable where T: Sendable {}
