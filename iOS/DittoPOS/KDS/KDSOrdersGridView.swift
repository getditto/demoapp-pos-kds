//
//  KDSOrdersGridView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

struct KDSOrdersGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var vm = KDS_VM()
    #if os(tvOS)
    @State var columns = [GridItem(.adaptive(minimum: 300), alignment: .top)]
    #else
    @State var columns = [GridItem(.adaptive(minimum: 172), alignment: .top)]
    #endif

    var body: some View {
        Group {
            if vm.orders.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns) {
                        ForEach(vm.orders, id: \.documentId.id) { order in
                            KDSOrderView(order)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(.background)
        .toolbarBackground(colorScheme == .dark ? .black : .white, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No active orders")
                .font(.title3.weight(.semibold))
            Text("Orders entered in POS will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct KDSOrdersGridView_Previews: PreviewProvider {
    static var previews: some View {
        KDSOrdersGridView()
    }
}
