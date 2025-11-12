//
//  Shimmer.swift
//  CurrencyExchange
//
//  Created by Andrei Simvolokov on 08/11/2025.
//

import SwiftUI

struct Shimmer: ViewModifier {
    
    @State var isInitialState: Bool = true
    
    func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(
                    gradient: .init(colors: [
                        .black.opacity(0.65),
                        .black,
                        .black.opacity(0.65)
                    ]),
                    startPoint: (isInitialState ? .init(x: -0.75, y: -0.75) : .init(x: 1, y: 1)),
                    endPoint: (isInitialState ? .init(x: 0, y: 0) : .init(x: 1.75, y: 1.75))
                )
            }
            .animation(
                .linear(duration: 1.5)
                .delay(0.25)
                .repeatForever(autoreverses: false),
                value: isInitialState
            )
            .onAppear() {
                isInitialState = false
            }
    }
}

#if DEBUG
#Preview {
    RoundedRectangle(cornerRadius: 8)
        .fill(Color.red)
        .frame(width: 200, height: 200)
        .modifier(Shimmer())
}
#endif
