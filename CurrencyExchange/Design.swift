//
//  Design.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 06/11/2025.
//

import SwiftUI

enum Design {
    enum Color {
        static let contentPrimary = SwiftUI.Color("content_primary")
        static let contentSecondary = SwiftUI.Color("content_secondary")
        static let contentBrand = SwiftUI.Color("content_brand")
        static let backgroundOnSecondary = SwiftUI.Color("background_on_secondary")
        static let backgroundPrimary = SwiftUI.Color("background_primary")
        static let backgroundSecondary = SwiftUI.Color("background_secondary")
        static let backgroundSelected = SwiftUI.Color("background_selected")
        static let borderOnSecondary = SwiftUI.Color("border_on_secondary")
        static let contentOnColor = SwiftUI.Color("content_on_color")
    }
    enum Font {
        static let header3 = SwiftUI.Font.system(size: 30, weight: .bold)
        static let header4 = SwiftUI.Font.system(size: 24, weight: .bold)
        static let bodyBold = SwiftUI.Font.system(size: 16, weight: .bold)
        static let bodySemibold = SwiftUI.Font.system(size: 16, weight: .semibold)
    }
}
