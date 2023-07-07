///
//  OrderTotalView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/23/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI

class OrderTotalVM: ObservableObject {
    @Published var orderIsPaid: Bool = false
    @Published var orderIsEmpty: Bool
    private var cancellables = Set<AnyCancellable>()
    private var dataVM = DataViewModel.shared
    
    init() {
        let dvm = DataViewModel.shared
        if let currOrder = dvm.currentOrder {
            self.orderIsEmpty = currOrder.orderItems.isEmpty
        } else {
            self.orderIsEmpty = true
        }
        
        // Pay/Cancel button enablement
        dataVM.$currentOrder
            .sink {[weak self] order in
                guard let order = order else { return }
                
                if self?.orderIsEmpty != order.orderItems.isEmpty {
                    self?.orderIsEmpty.toggle()
                }
                if self?.orderIsPaid != order.isPaid {
                    self?.orderIsPaid.toggle()
                }
            }
            .store(in: &cancellables)
    }
    
    var disableButtons: Bool {
        orderIsPaid || orderIsEmpty
    }
    
    func payOrder() {
        dataVM.payCurrentOrder()
    }
    
    func cancelOrder() {
//        dataVM.cancelCurrentOrderAndRefresh()
        if let items = dataVM.currentOrder?.orderItems, !items.isEmpty {
            dataVM.clearCurrentOrderIems()
        }
    }
}

struct OrderTotalView: View {
    @ObservedObject var dataVM = DataViewModel.shared
    @StateObject var vm = OrderTotalVM()
    
    var body: some View {
        VStack(spacing: 0) {
            divider()
            HStack(alignment: .bottom, spacing: 0) {
                Text("Total")//   count: \(dataVM.currentOrderItems.count)")
                Spacer()
                Text(dataVM.currentOrderTotal().currencyFormatted())
            }
                .padding(.bottom, 4)
            
            HStack {
                Button {
                    print("Cancel button tapped")
                    vm.cancelOrder()
                } label: {
                    Text("X").font(.largeTitle)
                }
                .clipShape(Circle())
                .tint(.red)
                .disabled(vm.disableButtons)

                Spacer()
                
                Button {
                    print("Pay button tapped")
                    vm.payOrder()
                } label: {
                    Text(vm.orderIsPaid ? "Paid" : "Pay")
                        .frame(maxWidth: .infinity, maxHeight: 36.0)
                }
                .tint(.green)
                .disabled(vm.disableButtons)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle)
        }
    }
}

struct OrderTotalView_Previews: PreviewProvider {
    static var previews: some View {
        OrderTotalView()
            .frame(width: .screenWidth * 0.8)
    }
}
