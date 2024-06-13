///
//  POSOrderTotalView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/23/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI

class POSOrderTotalVM: ObservableObject {
    @Published var orderIsPaid: Bool = false
    @Published var orderIsEmpty: Bool
    @Published var orderTotal: Double = 0.0
    private var cancellables = Set<AnyCancellable>()
    private var dataVM = POS_VM.shared
    
    init() {
        let dvm = POS_VM.shared
        if let currOrder = dvm.currentOrder {
            self.orderIsEmpty = currOrder.saleItemIds.isEmpty
        } else {
            self.orderIsEmpty = true
        }
        
        // Pay/Cancel button enablement
        dataVM.$currentOrder
            .sink {[weak self] order in
                guard let self = self else { return }
                guard let order = order else { return }
                
                orderTotal = order.total
                if orderIsEmpty != order.saleItemIds.isEmpty {
                    orderIsEmpty.toggle()
                }
                if orderIsPaid != order.isPaid {
                    orderIsPaid.toggle()
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
    
    /* EVICTION: in testing evictions it was found that if the current order is evicted, the
     addOrder workflow no longer works because there is no order.
     Similarly, it seems, when an order is "cleared" with the cancel button, the order should be
     reset back to a new order state. The only difference between order.clearSaleItems query and
     the reset query is that the date is set to now in reset. 
     
     FURTHER: note that
     */
    func cancelOrder() {
        if let items = dataVM.currentOrder?.saleItemIds, !items.isEmpty {
//            dataVM.clearCurrentOrderSaleItemIds()
            dataVM.cancelCurrentOrder()
        }
    }
}

struct POSOrderTotalView: View {
    @StateObject var vm = POSOrderTotalVM()

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                Text("Total")
                Spacer()
                Text(vm.orderTotal.currencyFormatted())
            }
            .scaledFont(size: 16)
            .padding(.vertical, 4)
            
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
        POSOrderTotalView()
            .frame(width: .screenWidth * 0.8)
    }
}
