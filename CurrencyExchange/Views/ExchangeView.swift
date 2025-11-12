//
//  ExchangeView.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 06/11/2025.
//

import Combine
import SwiftUI

struct RateViewData: Equatable {
    let text: String
    let additionalText: String?
}

struct ExchangeContentViewData: Equatable {
    var rate: RateViewData?
    var topCurrency: ExchangeSectionViewData
    var bottomCurrency: ExchangeSectionViewData
}

protocol ExchangeViewModelProtocol: ObservableObject {
    var title: String { get }
    var content: Loadable<ExchangeContentViewData> { get }
    var swapButoonA11tyLabel: String { get }
    
    func topCurrencyChangeButtonDidTap()
    func topCurrencyTextDidChange(_ text: String) -> Bool
    func topCurrencyDidFocus()
    func bottomCurrencyChangeButtonDidTap()
    func bottomCurrencyTextDidChange(_ text: String) -> Bool
    func bottomCurrencyDidFocus()
    func swapButtonDidTap()
}

private enum ExchangeViewConstants {
    enum AccessibilityID {
        private static let prefix = "exchange_view."
        static let title = Self.prefix + "title"
        static let rate = Self.prefix + "rate"
        static let addionalRateText = Self.prefix + "addional_rate_text"
        static let swapButton = Self.prefix + "swap_button"
        static let topRate = Self.prefix + "top_rate"
        static let bottomRate = Self.prefix + "bottom_rate"
    }
    enum Font {
        static let title = Design.Font.header3
        static let rate = Design.Font.bodySemibold
        static let addionalRateText = Design.Font.bodySemibold
    }
    enum Color {
        static let background = Design.Color.backgroundPrimary
        static let loadingPlaceholder = Design.Color.contentSecondary
        static let title = Design.Color.contentPrimary
        static let rate = Design.Color.contentBrand
        static let addionalRateText = Design.Color.contentSecondary
    }
    enum Image {
        static let rate = SwiftUI.Image("trend_up")
        static let swapButton = SwiftUI.Image("arrow_down_button")
    }
    enum Layout {
        static let contentInsets = EdgeInsets(top: 44, leading: 16, bottom: 0, trailing: 16)
        static let rateImageSide: CGFloat = 20
        static let rateItemsSpacing: CGFloat = 4
        static let titleToRateInset: CGFloat = 8
        static let headerToContentInset: CGFloat = 24
        static let currencyInputsSpacing: CGFloat = 16
        static let swapButtonSide: CGFloat = 24
        static let swapButtonStroke: CGFloat = 12
    }
}

struct ExchangeView<
    ViewModel: ExchangeViewModelProtocol
>: View {
    private typealias Constants = ExchangeViewConstants
    
    @ObservedObject
    private var viewModel: ViewModel
    
    @Namespace
    private var namespace
    
    @State
    private var previousCurrencyIds: [String] = []
    private var currentCurrencyIds: [String] {
        guard case .loaded(let content) = self.viewModel.content else {
            return []
        }
        return [content.topCurrency.id, content.bottomCurrency.id]
    }
    
    private var shouldShowSwapped: Bool {
        guard !self.previousCurrencyIds.isEmpty else {
            return false
        }
        // Show swapped if the IDs have actually swapped positions
        return self.previousCurrencyIds == self.currentCurrencyIds.reversed()
    }
    
    private var isRateAdditionalTextAvailable: Bool {
        guard case .loaded(let content) = self.viewModel.content else {
            return false
        }
        return content.rate?.additionalText != nil
    }
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.headerToContentInset) {
            self.header
            self.content
        }
        .padding(Constants.Layout.contentInsets)
        .frame(
            maxWidth: .greatestFiniteMagnitude,
            maxHeight: .greatestFiniteMagnitude,
            alignment: .top
        )
        .background {
            Constants.Color.background
                .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.titleToRateInset) {
            self.title(text: self.viewModel.title)
            if case .loaded(let content) = self.viewModel.content,
               let rate = content.rate {
                self.rateView(data: rate)
            }
        }
    }
    @ViewBuilder
    private var content: some View {
        ZStack {
            VStack(alignment: .leading, spacing: Constants.Layout.currencyInputsSpacing) {
                if self.shouldShowSwapped {
                    // Temporarily show swapped order for animation
                    self.bottomExchangeSectionView
                    self.topExchangeSectionView
                } else {
                    // Normal semantic order
                    self.topExchangeSectionView
                    self.bottomExchangeSectionView
                }
            }
            .animation(.linear(duration: 0.2), value: self.previousCurrencyIds)
            .onChange(of: self.currentCurrencyIds, { oldValue, newValue in
                guard oldValue != newValue else { return }
                if oldValue == newValue.reversed() {
                    Task {
                        await MainActor.run {
                            self.updatePreviousCurrencyIds()
                        }
                    }
                } else {
                    self.updatePreviousCurrencyIds()
                }
            })
            .onAppear {
                self.updatePreviousCurrencyIds()
            }
            self.swapButton()
        }
    }
    
    private func updatePreviousCurrencyIds() {
        self.previousCurrencyIds = self.currentCurrencyIds
    }
    
    @ViewBuilder
    private var topExchangeSectionView: some View {
        ExchangeSectionView(
            accessibilityIDs: .regular(base: Constants.AccessibilityID.topRate),
            data: self.viewModel.content.map { $0.topCurrency },
            onChangeButtonDidTap: self.viewModel.topCurrencyChangeButtonDidTap,
            onTextInputChange: {
                self.viewModel.topCurrencyTextDidChange($0)
            },
            onFocus: self.viewModel.topCurrencyDidFocus
        )
        .matchedGeometryEffect(
            id: {
                switch self.viewModel.content {
                case .loaded(let content):
                    return content.topCurrency.id
                case .loading:
                    return "top_section_loading"
                }
            }(),
            in: self.namespace
        )
    }
    
    @ViewBuilder
    private var bottomExchangeSectionView: some View {
        ExchangeSectionView(
            accessibilityIDs: .regular(base: Constants.AccessibilityID.bottomRate),
            data: self.viewModel.content.map { $0.bottomCurrency },
            onChangeButtonDidTap: self.viewModel.bottomCurrencyChangeButtonDidTap,
            onTextInputChange: self.viewModel.bottomCurrencyTextDidChange(_:),
            onFocus: self.viewModel.bottomCurrencyDidFocus
        )
        .matchedGeometryEffect(
            id: {
                switch self.viewModel.content {
                case .loaded(let content):
                    return content.bottomCurrency.id
                case .loading:
                    return "bottom_section_loading"
                }
            }(),
            in: self.namespace
        )
    }
    
    @ViewBuilder
    private func title(text: String) -> some View {
        Text(self.viewModel.title)
            .font(Constants.Font.title)
            .foregroundStyle(Constants.Color.title)
            .accessibilityIdentifier(Constants.AccessibilityID.title)
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private func rateView(data: RateViewData) -> some View {
        VStack(alignment: .leading, spacing: Constants.Layout.rateItemsSpacing) {
            HStack(spacing: Constants.Layout.rateItemsSpacing) {
                Constants.Image.rate
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(Constants.Color.rate)
                    .frame(
                        width: Constants.Layout.rateImageSide,
                        height: Constants.Layout.rateImageSide
                    )
                    .accessibilityHidden(true)
                Text(data.text)
                    .font(Constants.Font.rate)
                    .foregroundStyle(
                        Constants.Color.rate
                    )
                    .accessibilityIdentifier(Constants.AccessibilityID.rate)
            }
            if let additionalText = data.additionalText {
                Text(additionalText)
                    .font(Constants.Font.addionalRateText)
                    .foregroundStyle(
                        Constants.Color.addionalRateText
                    )
                    .accessibilityIdentifier(Constants.AccessibilityID.addionalRateText)
            }
        }
        .animation(.linear(duration: 0.2), value: self.isRateAdditionalTextAvailable)
    }
    
    @ViewBuilder
    private func swapButton() -> some View {
        Button(
            action: self.viewModel.swapButtonDidTap,
            label: {
                Circle()
                    .fill(Constants.Color.background)
                    .frame(
                        width: Constants.Layout.swapButtonSide + 2*Constants.Layout.swapButtonStroke
                    )
                    .overlay {
                        Group {
                            switch self.viewModel.content {
                            case .loaded:
                                Constants.Image.swapButton
                            case .loading:
                                Circle()
                                    .fill(Constants.Color.loadingPlaceholder)
                                    .modifier(Shimmer())
                            }
                        }
                        .frame(
                            width: Constants.Layout.swapButtonSide,
                            height: Constants.Layout.swapButtonSide
                        )
                    }
            }
        )
        .disabled(self.viewModel.content == .loading)
        .accessibilityIdentifier(Constants.AccessibilityID.swapButton)
        .accessibilityLabel(self.viewModel.swapButoonA11tyLabel)
    }
}

#if DEBUG
#Preview("Regular") {
    ExchangeView(viewModel: FakeExchangeViewModel(isLoading: false))
}
#Preview("Loading") {
    ExchangeView(viewModel: FakeExchangeViewModel(isLoading: true))
}
#Preview("Dark Mode") {
    ExchangeView(viewModel: FakeExchangeViewModel(isLoading: false))
        .preferredColorScheme(.dark)
}
#Preview("Loading - Dark Mode") {
    ExchangeView(viewModel: FakeExchangeViewModel(isLoading: true))
        .preferredColorScheme(.dark)
}

private final class FakeExchangeViewModel: ExchangeViewModelProtocol {
    
    let title = "Exchange calculator"
    @Published private(set) var content: Loadable<ExchangeContentViewData>
    let swapButoonA11tyLabel = "Swap currencies"
    
    init(isLoading: Bool) {
        if isLoading {
            self.content = .loading
        } else {
            self.content = .loaded(
                ExchangeContentViewData(
                    rate: RateViewData(
                        text: "1 USDc = 18.4097 MXN",
                        additionalText: "2025-11-10 20:36"
                    ),
                    topCurrency: .testUSDc,
                    bottomCurrency: .testMXN
                )
            )
        }
    }
    
    func topCurrencyChangeButtonDidTap() {
        print("topCurrencyChangeButtonDidTap")
    }
    func topCurrencyTextDidChange(_ text: String) -> Bool {
        print("topCurrencyTextDidChange: \(text)")
        return true
    }
    func topCurrencyDidFocus() {
        print("topCurrencyDidFocus")
    }
    func bottomCurrencyChangeButtonDidTap() {
        print("bottomCurrencyChangeButtonDidTap")
    }
    func bottomCurrencyTextDidChange(_ text: String) -> Bool {
        print("bottomCurrencyTextDidChange: \(text)")
        return true
    }
    func bottomCurrencyDidFocus() {
        print("bottomCurrencyDidFocus")
    }
    func swapButtonDidTap() {
        guard case .loaded(var content) = self.content else { return }
        let topCurrency = content.topCurrency
        content.topCurrency = content.bottomCurrency
        content.bottomCurrency = topCurrency
        switch content.topCurrency.id {
        case ExchangeSectionViewData.testUSDc.id:
            content.rate = RateViewData(
                text: "1 USDc = 18.4097 MXN",
                additionalText: "2025-11-10 20:36"
            )
        default:
            content.rate = RateViewData(
                text: "1 USDc = 18.9543 MXN",
                additionalText: "2025-11-10 20:36"
            )
        }
        self.content = .loaded(content)
    }
}
#endif
