//
//  POSOrderView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import SwiftUI

@MainActor class POSOrderVM: ObservableObject {
    @ObservedObject var dataVM = POS_VM.shared
    // (lineItemId, line item) pairs in display order
    @Published var orderItems: [(id: String, item: CartLineItem)] = []
    @Published var barTitle = "Order #\(POS_VM.shared.currentOrder?.title ?? "...")"
    var cancellables = Set<AnyCancellable>()

    init() {
        dataVM.$currentOrder
            .sink {[weak self] order in
                guard let self = self else { return }
                if let order = order {
                    barTitle = "Order #\(order.title)"
                    orderItems = order.cart
                        .sorted { $0.value.createdAt < $1.value.createdAt }
                        .map { (id: $0.key, item: $0.value) }
                } else {
                    barTitle = "Order #..."
                }
            }
            .store(in: &cancellables)
    }
}

struct POSOrderView: View {
    @StateObject var vm = POSOrderVM()

    var body: some View {
        VStack(spacing: 0) {
            Text(vm.barTitle)
                .scaledFont(size: 16)
                .padding(.bottom, 8)
            divider()
                .padding(.bottom, 8)

            ScrollViewReader { svr in
                ScrollView(showsIndicators: false) {
                    Section {
                        ForEach(vm.orderItems, id: \.id) { entry in
                            POSOrderItemView(lineItemId: entry.id, entry.item)
                            divider()
                        }
                        .onChange(of: vm.orderItems.count) { _ in
                            if let last = vm.orderItems.last?.id {
                                withAnimation { svr.scrollTo(last, anchor: .top) }
                            }
                        }
                        #if !os(tvOS)
                        .onRotate { _ in
                            withAnimation { scrollToBottom(proxy: svr) }
                        }
                        #endif
                    }
                }
            }
            .padding(.bottom, 4)
            .listStyle(.plain)

            POSOrderTotalView()
        }
    }

    func scrollToBottom(proxy: ScrollViewProxy) {
        #if !os(tvOS)
        let orientation = UIDevice.current.orientation
        guard orientation.isLandscape || orientation.isPortrait else { return }
        #endif

        if let last = vm.orderItems.last?.id {
            #if os(tvOS)
            let delay = 0.5
            #else
            let delay = (UIScreen.isPortrait && UIDevice.current.orientation.isLandscape && vm.orderItems.count > 4) ? 0.5 : 0.0
            #endif

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation { proxy.scrollTo(last, anchor: .bottom) }
            }
        }
    }
}

struct POSOrderView_Previews: PreviewProvider {
    static var previews: some View {
        POSOrderView()
    }
}
