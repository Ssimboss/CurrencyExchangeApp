//
//  CurrencyPickSectionView.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 07/11/2025.
//

import Combine
import SwiftUI

struct CurrencyPickViewData: Identifiable, Equatable {
    let id: String
    var image: Image?
    let title: String
}

private enum CurrencyPickRowViewConstants {
    enum Color {
        static let text = Design.Color.contentPrimary
        static let imageBackground = Design.Color.backgroundOnSecondary
        static let unselectedIndicator = Design.Color.borderOnSecondary
        static let selectedIndicator = Design.Color.contentOnColor
        static let selectedIndicatorBackground = Design.Color.backgroundSelected
    }
    enum Font {
        static let text = Design.Font.bodySemibold
    }
    enum Image {
        static let selectedIndicator = SwiftUI.Image("check")
    }
    enum Layout {
        static let contentInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let height: CGFloat = 62
        static let imageContainerSide: CGFloat = 40
        static let imageContainerCornerRadius: CGFloat = 10
        static let imageSide: CGFloat = 28
        static let selectIndicatorSide: CGFloat = 24
        static let selectedIndicatorImageSize = CGSize(width: 12, height: 8)
        static let unselectedIndicatorStrokeWidth: CGFloat = 2
        static let imageToTextInset: CGFloat = 8
        static let textToSelectIndicatorInset: CGFloat = 4
    }
}

struct CurrencyPickRowView: View {
    private typealias Constants = CurrencyPickRowViewConstants
    
    private let data: CurrencyPickViewData
    private let isSelected: Bool
    
    init(
        data: CurrencyPickViewData,
        isSelected: Bool
    ) {
        self.data = data
        self.isSelected = isSelected
    }
    
    var body: some View {
        HStack(spacing: 0) {
            self.image
                .padding(.trailing, Constants.Layout.imageToTextInset)
            self.text
            Spacer(minLength: Constants.Layout.textToSelectIndicatorInset)
            self.selectIndicator
        }
        .padding(Constants.Layout.contentInsets)
        .frame(height: Constants.Layout.height)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(self.isSelected ? [.isSelected] : [])
    }
    
    @ViewBuilder
    private var image: some View {
        RoundedRectangle(
            cornerRadius: Constants.Layout.imageContainerCornerRadius
        )
        .fill(Constants.Color.imageBackground)
        .frame(
            width: Constants.Layout.imageContainerSide,
            height: Constants.Layout.imageContainerSide
        )
        .overlay {
            Group {
                if let image = self.data.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(
                            width: Constants.Layout.imageSide,
                            height: Constants.Layout.imageSide
                        )
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    @ViewBuilder
    private var text: some View {
        Text(self.data.title)
            .font(Constants.Font.text)
            .foregroundStyle(Constants.Color.text)
    }
    
    @ViewBuilder
    private var selectIndicator: some View {
        Group {
            if self.isSelected {
                Circle()
                    .fill(Constants.Color.selectedIndicatorBackground)
                    .overlay {
                        Constants.Image.selectedIndicator
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(Constants.Color.selectedIndicator)
                            .frame(
                                width: Constants.Layout.selectedIndicatorImageSize.width,
                                height: Constants.Layout.selectedIndicatorImageSize.height
                            )
                    }
            } else {
                Circle()
                    .stroke(
                        Constants.Color.unselectedIndicator,
                        lineWidth: Constants.Layout.unselectedIndicatorStrokeWidth
                    )
            }
        }
        .frame(
            width: Constants.Layout.selectIndicatorSide,
            height: Constants.Layout.selectIndicatorSide
        )
    }
}

#if DEBUG
#Preview("Regular") {
    Color.red.ignoresSafeArea().overlay {
        CurrencyPickRowView(
            data: .testARS,
            isSelected: false
        )
        .background {
            Design.Color.backgroundSecondary
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
}

#Preview("Selected") {
    Color.red.ignoresSafeArea().overlay {
        CurrencyPickRowView(
            data: .testMXN,
            isSelected: true
        )
        .background {
            Design.Color.backgroundSecondary
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
}

extension CurrencyPickViewData {
    static let testARS = CurrencyPickViewData(
        id: "ars",
        image: Image("flag_ars"),
        title: "ARS"
    )
    
    static let testCOP = CurrencyPickViewData(
        id: "cop",
        image: Image("flag_cop"),
        title: "COP"
    )
    
    static let testMXN = CurrencyPickViewData(
        id: "mxn",
        image: Image("flag_mxn"),
        title: "MXN"
    )
    
    static let testBRL = CurrencyPickViewData(
        id: "brl",
        image: Image("flag_brl"),
        title: "BRL"
    )
}

#endif
