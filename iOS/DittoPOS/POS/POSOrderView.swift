///
//  POSOrderView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI

@MainActor class POSOrderVM: ObservableObject {
    @ObservedObject var dataVM = POS_VM.shared
    @Published var orderItems = [OrderItem]()
    @Published var barTitle = "Order #\(POS_VM.shared.currentOrder?.title ?? "...")"
    var cancellables = Set<AnyCancellable>()
    init() {
        dataVM.$currentOrder
            .sink {[weak self] order in
                guard let self = self  else { return }
                if let order = order {
                    barTitle = "Order #\(order.title)"
                    orderItems = order.orderItems
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
                // title view
                Text(vm.barTitle)
                    .scaledFont(size: 16)
                    .padding(.bottom, 8)
                divider()
                    .padding(.bottom, 8)
                
                // Order items scrollview
                ScrollViewReader { svr in
                    ScrollView(showsIndicators: false) {
                        Section {
                            ForEach(vm.orderItems) { item in
                                POSOrderItemView(item)
                                divider()
                            }
                            .onChange(of: vm.orderItems.count) { _ in
                                if let itemId = vm.orderItems.last?.id {
                                    withAnimation {
                                        svr.scrollTo(itemId, anchor: .top)
                                    }
                                }
                            }
                            #if !os(tvOS)
                            .onRotate { orientation in
                                withAnimation {
                                    scrollToBottom(proxy: svr)
                                }
                            }
                            #endif
                        }
                    }
                }
                .padding(.bottom, 4)
                .listStyle(.plain)
                
                // order total and pay buttons
                POSOrderTotalView()
            }
    }
    
    func scrollToBottom(proxy: ScrollViewProxy) {
        #if !os(tvOS)
        let orientation = UIDevice.current.orientation
        guard orientation.isLandscape || orientation.isPortrait else { return }
        #endif

        if let itemId = vm.orderItems.last?.id {
            /* A delay is needed before scrolling to bottom of orderItems list when rotating to
             landscape orientation, and the amount of delay is different on different devices.
             0.5 second delay seems to work reliably on tested devices: iPhones SE, 12Pro, iPad Air5
             */
            #if os(tvOS)
            let delay = 0.5
            #else
            let delay = (UIScreen.isPortrait && orientation.isLandscape && vm.orderItems.count > 4) ? 0.5 : 0.0
            #endif

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                    proxy.scrollTo(itemId, anchor: .bottom)
                }
            }
        }
    }
}

struct POSOrderView_Previews: PreviewProvider {
    static var previews: some View {
        POSOrderView()
    }
}
