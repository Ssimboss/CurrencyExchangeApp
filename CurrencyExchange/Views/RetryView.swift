//
//  RetryView.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 07/11/2025.
//

import Combine
import SwiftUI

protocol RetryViewModelProtocol: ObservableObject {
    var title: String { get }
    var bodyText: String { get }
    var buttonText: String { get }
    
    func buttonDidTap() -> Void
}

private enum RetryViewConstants {
    enum AccessibilityIDs {
        private static let prefix = "retry_view."
        static let title = Self.prefix + "title"
        static let bodyText = Self.prefix + "body_text"
        static let button = Self.prefix + "button"
    }
    enum Color {
        static let background = Design.Color.backgroundPrimary
        static let imageTint = Design.Color.contentBrand
        static let title = Design.Color.contentPrimary
        static let bodyText = Design.Color.contentPrimary
        static let buttonBackground = Design.Color.contentBrand
        static let buttonText = Design.Color.contentOnColor
    }
    enum Image {
        static let error = SwiftUI.Image(systemName: "exclamationmark.triangle.fill")
    }
    enum Font {
        static let title = Design.Font.header4
        static let bodyText = Design.Font.bodySemibold
        static let button = Design.Font.bodyBold
    }
    enum Layout {
        static let imageSide: CGFloat = 120
        static let contentInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let contentSpacing: CGFloat = 16
    }
}

struct RetryView<
    ViewModel: RetryViewModelProtocol
>: View {
    private typealias Constants = RetryViewConstants

    private let viewModel: ViewModel
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: Constants.Layout.contentSpacing) {
                Constants.Image.error
                    .resizable()
                    .foregroundStyle(Constants.Color.imageTint)
                    .frame(
                        width: Constants.Layout.imageSide,
                        height: Constants.Layout.imageSide,
                    )
                    .accessibilityHidden(true)
                    .accessibilityAddTraits(.isHeader)
                Text(self.viewModel.title)
                    .font(Constants.Font.title)
                    .foregroundStyle(Constants.Color.title)
                    .accessibilityIdentifier(Constants.AccessibilityIDs.title)
                Text(self.viewModel.bodyText)
                    .font(Constants.Font.bodyText)
                    .foregroundStyle(Constants.Color.bodyText)
                    .accessibilityIdentifier(Constants.AccessibilityIDs.bodyText)
            }
            Spacer()
            Button {
                self.viewModel.buttonDidTap()
            } label: {
                Text(self.viewModel.buttonText)
                    .font(Constants.Font.button)
                    .foregroundStyle(Constants.Color.buttonText)
            }
            .tint(Constants.Color.buttonBackground)
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(Constants.AccessibilityIDs.button)
        }
        .padding(Constants.Layout.contentInsets)
        .frame(
            maxWidth: .greatestFiniteMagnitude,
            idealHeight: 0,
            maxHeight: .greatestFiniteMagnitude
        )
        .background {
            Constants.Color.background
                .ignoresSafeArea()
        }
        .presentationDetents([
            .medium
        ])
        .interactiveDismissDisabled()
    }
}

#if DEBUG
#Preview("Regular") {
    Color.red
        .ignoresSafeArea()
        .sheet(
            isPresented: Binding<Bool>(get: { true }, set: { _  in })
        ) {
            RetryView(viewModel: FakeRetryView())
        }    
}
#Preview("Dark Mode") {
    Color.red
        .ignoresSafeArea()
        .sheet(
            isPresented: Binding<Bool>(get: { true }, set: { _  in })
        ) {
            RetryView(viewModel: FakeRetryView())
        }
        .preferredColorScheme(.dark)
}

private final class FakeRetryView: RetryViewModelProtocol {
    let title = "Ooops..."
    let bodyText = "Something went wrong. Check our service later."
    let buttonText = "Try again"
    
    func buttonDidTap() {
        print("buttonDidTap")
    }
}
#endif
