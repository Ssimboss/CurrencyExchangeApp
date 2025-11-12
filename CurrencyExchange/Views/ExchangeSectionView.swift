//
//  ExchangeCurrencySection.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 06/11/2025.
//

import Combine
import SwiftUI

enum ExchangeSectionChangeableState: Equatable {
    case changeable(a11yButtonHint: String)
    case notChangeable
}

struct ExchangeSectionViewData: Identifiable, Equatable {
    let id: String
    var image: Image?
    let title: String
    let inputTextA11yLabel: String
    var valueText: String
    let valuePlaceholderText: String
    let changeable: ExchangeSectionChangeableState
}

private enum ExchangeSectionViewConstants {
    enum Color {
        static let loadingPlaceholder = Design.Color.contentSecondary
        static let background = Design.Color.backgroundSecondary
        static let label = Design.Color.contentPrimary
        static let labelChangeImage = Design.Color.contentPrimary
        static let field = Design.Color.contentPrimary
    }
    enum Font {
        static let label = Design.Font.bodySemibold
        static let field = Design.Font.bodyBold
    }
    enum Image {
        static let labelChange = SwiftUI.Image("chevron_down_button")
    }
    enum Layout {
        static let flagImageSide: CGFloat = 16
        static let height: CGFloat = 66
        static let flagToTextInset: CGFloat = 8
        static let labelToTextFieldInset: CGFloat = 16
        static let labelChangeIconSize = CGSize(width: 12, height: 7.5)
        static let contentInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        
        static let cornerRadius: CGFloat = 16
    }
}

struct ExchangeSectionView: View {
    private typealias Constants = ExchangeSectionViewConstants
    struct AccessibilityIDs {
        let label: String
        let textField: String
        static func regular(base: String) -> Self {
            return AccessibilityIDs(
                label: base + ".label",
                textField: base + ".text_field"
            )
        }
    }
    
    private let accessibilityIDs: AccessibilityIDs
    private let data: Loadable<ExchangeSectionViewData>
    private let onChangeButtonDidTap: () -> Void
    private let onTextInputChange: (String) -> Bool
    private let onFocus: () -> Void

    @FocusState private var isFocused: Bool

    init(
        accessibilityIDs: AccessibilityIDs,
        data: Loadable<ExchangeSectionViewData>,
        onChangeButtonDidTap: @escaping () -> Void,
        onTextInputChange: @escaping (String) -> Bool,
        onFocus: @escaping () -> Void
    ) {
        self.accessibilityIDs = accessibilityIDs
        self.data = data
        self.onChangeButtonDidTap = onChangeButtonDidTap
        self.onTextInputChange = onTextInputChange
        self.onFocus = onFocus
    }
    
    var body: some View {
        HStack(spacing: Constants.Layout.labelToTextFieldInset) {
            Group {
                if case .loaded(let data) = self.data, case .changeable(let buttonA11yHint) = data.changeable {
                    Button(action: self.onChangeButtonDidTap, label: self.inputLabel)
                        .accessibilityHint(buttonA11yHint)
                } else {
                    self.inputLabel()
                    Spacer()
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(self.accessibilityIDs.label)
            self.inputTextField()
        }
        .padding(Constants.Layout.contentInsets)
        .frame(
            maxWidth: .greatestFiniteMagnitude,
            minHeight: Constants.Layout.height
        )
        .background {
            Constants.Color.background
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: Constants.Layout.cornerRadius
            )
        )
    }
    
    @ViewBuilder
    private func inputLabel() -> some View {
        HStack(spacing: Constants.Layout.flagToTextInset) {
            self.flag
            self.title
            self.changeIcon
        }
    }
    
    @ViewBuilder
    private var flag: some View {
        Group {
            if case .loaded(let data) = self.data,
               let image = data.image {
                image
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Constants.Color.loadingPlaceholder)
                    .modifier(Shimmer())
            }
        }
        .frame(
            width: Constants.Layout.flagImageSide,
            height: Constants.Layout.flagImageSide
        )
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var title: some View {
        Group {
            switch self.data {
            case .loaded(let data):
                Text(data.title)
                    .font(Constants.Font.label)
                    .foregroundStyle(Constants.Color.label)
            case .loading:
                Text("⠀⠀⠀⠀")
                    .font(Constants.Font.label)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Constants.Color.loadingPlaceholder)
                            .modifier(Shimmer())
                    }
            }
        }
    }
    
    @ViewBuilder
    private var changeIcon: some View {
        if case .loaded(let data) = self.data, case .changeable = data.changeable {
            Constants.Image.labelChange
                .renderingMode(.template)
                .resizable()
                .scaledToFill()
                .foregroundStyle(Constants.Color.labelChangeImage)
                .frame(
                    width: Constants.Layout.labelChangeIconSize.width,
                    height: Constants.Layout.labelChangeIconSize.height
                )
        }
    }
    
    @State
    private var inputText = ""
    private var dataValueText: String {
        switch self.data {
        case .loading:
            return ""
        case .loaded(let data):
            return data.valueText
        }
    }

    @ViewBuilder
    private func inputTextField() -> some View {
        switch self.data {
        case .loaded(let data):
            TextField(data.valuePlaceholderText, text: self.$inputText)
            .keyboardType(.decimalPad)
            .font(Constants.Font.field)
            .foregroundStyle(Constants.Color.field)
            .labelsHidden()
            .multilineTextAlignment(.trailing)
            .accessibilityIdentifier(self.accessibilityIDs.textField)
            .accessibilityLabel(data.inputTextA11yLabel)
            .focused(self.$isFocused)
            .onChange(of: self.inputText, { _, newValue in
                guard newValue != data.valueText else { return }
                let keepChange = self.onTextInputChange(newValue)
                guard !keepChange else { return }
                self.inputText = data.valueText
            })
            .onChange(of: self.dataValueText, { _, newValue in
                guard newValue != self.inputText else { return }
                self.inputText = newValue
            })
            .onChange(of: self.isFocused, { oldValue, newValue in
                guard newValue == true, oldValue == false else { return }
                self.onFocus()
            })
            .onAppear {
                self.inputText = self.dataValueText
            }
        default:
            Text("⠀⠀⠀⠀")
                .font(Constants.Font.field)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Constants.Color.loadingPlaceholder)
                        .modifier(Shimmer())
                }
                .accessibilityHidden(true)
        }
    }
}

#if DEBUG
private struct PreviewExchangeSectionView: View {
    let data: Loadable<ExchangeSectionViewData>

    var body: some View {
        Color.red.ignoresSafeArea().overlay {
            ExchangeSectionView(
                accessibilityIDs: .regular(base: "test"),
                data: self.data,
                onChangeButtonDidTap: {
                    print("onChangeButtonDidTap")
                },
                onTextInputChange: { newText in
                    print("onTextInputChange: \(newText)")
                    return true
                },
                onFocus: {
                    print("onFocus")
                }
            )
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
    }
}

#Preview("Regular") {
    PreviewExchangeSectionView(data: .loaded(.testUSDc))
}

#Preview("Changeable") {
    PreviewExchangeSectionView(data: .loaded(.testMXN))
}

#Preview("Empty") {
    PreviewExchangeSectionView(data: .loaded(.testEmptyValue))
}

#Preview("Loading") {
    PreviewExchangeSectionView(data: .loading)
}

extension ExchangeSectionViewData {
    static let testMXN = ExchangeSectionViewData(
        id: "mxn",
        image: Image("flag_mxn"),
        title: "MXN",
        inputTextA11yLabel: "amount of MXN",
        valueText: "$184,065.59",
        valuePlaceholderText: "$0.00",
        changeable: .changeable(a11yButtonHint: "Tap to change")
    )

    static let testUSDc = ExchangeSectionViewData(
        id: "usdc",
        image: Image("flag_usdc"),
        title: "USDc",
        inputTextA11yLabel: "amount of USDc",
        valueText: "$99,999,999,999.99",
        valuePlaceholderText: "$0.00",
        changeable: .notChangeable
    )
    
    static let testEmptyValue = ExchangeSectionViewData(
        id: "brl",
        image: Image("flag_brl"),
        title: "BRL",
        inputTextA11yLabel: "amount of BRL",
        valueText: "",
        valuePlaceholderText: "$0.00",
        changeable: .changeable(a11yButtonHint: "Tap to change")
    )
}

#endif
