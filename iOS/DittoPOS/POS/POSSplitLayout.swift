//
//  POSSplitLayout.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

enum POSColumnLayout {
    /// Share of the available width given to the current order column.
    static let orderFraction: CGFloat = 0.4

    static func orderWidth(for availableWidth: CGFloat) -> CGFloat {
        max(0, availableWidth) * orderFraction
    }
}

/// Places the sale item grid and the current order side by side.
///
/// Widths come from the space this view is given, not from the screen size.
/// That space already excludes the safe area (Dynamic Island, notch, side
/// tab bars) and follows the window size (iPad windows, iPhone Duo), and it
/// updates on rotation and resizing without listening for device rotation.
struct POSSplitLayout<Menu: View, Order: View>: View {
    private let menu: Menu
    private let order: Order

    init(@ViewBuilder menu: () -> Menu, @ViewBuilder order: () -> Order) {
        self.menu = menu()
        self.order = order()
    }

    var body: some View {
        GeometryReader { proxy in
            HStack {
                menu
                    .frame(maxWidth: .infinity)

                Divider()

                order
                    .frame(width: POSColumnLayout.orderWidth(for: proxy.size.width))
            }
        }
    }
}
