//
//  CurrencyPickView.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 07/11/2025.
//

import Combine
import SwiftUI

protocol CurrencyPickViewModelProtocol: ObservableObject {
    var title: String { get }
    var closeButtonA11yLabel: String { get }
    var currencies: [CurrencyPickViewData] { get }
    var selectedCurrencyId: String { get }

    func closeButtonDidTap()
    func currencyDidSelect(id: String)
}

private enum CurrencyPickViewConstants {
    enum AccessibilityIDs {
        private static let prefix = "currency_picker."
        static let title = Self.prefix + "title"
        static let closeButton = Self.prefix + "close_button"
        static let row_format = Self.prefix + "row_%d"
    }
    enum Color {
        static let background = Design.Color.backgroundPrimary
        static let title = Design.Color.contentPrimary
        static let closeButton = Design.Color.contentPrimary
        static let listBackground = Design.Color.backgroundSecondary
    }
    enum Font {
        static let title = Design.Font.header4
    }
    enum Image {
        static let closeButton = SwiftUI.Image("close_button")
    }
    enum Layout {
        static let topInset: CGFloat = 24
        static let headerContentInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let titleToCloseButtonInset: CGFloat = 8
        static let closeButtonSide: CGFloat = 32
        static let headerToListInset: CGFloat = 16
        static let listInsets: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let listCornerRadius: CGFloat = 16
    }
}

struct CurrencyPickView<
    ViewModel: CurrencyPickViewModelProtocol
>: View {
    private typealias Constants = CurrencyPickViewConstants
    
    @ObservedObject
    private var viewModel: ViewModel
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: Constants.Layout.headerToListInset) {
            self.header
            self.list
        }
        .padding(.top, Constants.Layout.topInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Constants.Color.background
                .ignoresSafeArea(.all)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([
            .height(328)
        ])
    }
    
    @ViewBuilder
    var header: some View {
        HStack(spacing: Constants.Layout.titleToCloseButtonInset) {
            Text(self.viewModel.title)
                .font(Constants.Font.title)
                .foregroundStyle(Constants.Color.title)
                .accessibilityIdentifier(Constants.AccessibilityIDs.title)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                self.viewModel.closeButtonDidTap()
            } label: {
                Constants.Image
                    .closeButton
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(Constants.Color.closeButton)
                    .frame(
                        width: Constants.Layout.closeButtonSide,
                        height: Constants.Layout.closeButtonSide
                    )
                    .accessibilityIdentifier(Constants.AccessibilityIDs.closeButton)
                    .accessibilityLabel(self.viewModel.closeButtonA11yLabel)
            }
        }
        .padding(Constants.Layout.headerContentInsets)
    }
    
    @ViewBuilder
    private var list: some View {
        List(self.viewModel.currencies) { currency in
            Button(
                action:{
                    self.viewModel.currencyDidSelect(id: currency.id)
                },
                label: {
                    CurrencyPickRowView(
                        data: currency,
                        isSelected: currency.id == self.viewModel.selectedCurrencyId
                    )
                }
            )
            .listRowBackground(Constants.Color.listBackground)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .accessibilityIdentifier(
                String(
                    format: Constants.AccessibilityIDs.row_format,
                    self.viewModel.currencies.firstIndex(of: currency) ?? 0
                )
            )
        }
        .listStyle(.plain)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Constants.Layout.listCornerRadius
            )
        )
        .frame(maxHeight: 248)
        .padding(Constants.Layout.listInsets)
    }
}

#if DEBUG
#Preview("Regular") {
    Color.green
        .sheet(
            isPresented: Binding<Bool>(get: { true }, set: { _ in }),
            content: {
                CurrencyPickView(viewModel: FakeCurrencyPickViewModel())
            }
        )
}
#Preview("Dark Mode") {
    Color.green
        .sheet(
            isPresented: Binding<Bool>(get: { true }, set: { _ in }),
            content: {
                CurrencyPickView(viewModel: FakeCurrencyPickViewModel())
            }
        )
        .preferredColorScheme(.dark)
}

private final class FakeCurrencyPickViewModel: CurrencyPickViewModelProtocol {
    let title = "Choose currency"
    let closeButtonA11yLabel = "Close picker"
    let currencies: [CurrencyPickViewData] = [
        .testARS,
        .testCOP,
        .testMXN,
        .testBRL,
    ]
    @Published
    private(set) var selectedCurrencyId = "mxn"

    func closeButtonDidTap() {
        print("closeButtonDidTap")
    }
    func currencyDidSelect(id: String) {
        self.selectedCurrencyId = id
    }
}

#endif
