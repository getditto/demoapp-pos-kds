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
    private var cancellables = Set<AnyCancellable>()
    private var dataVM = DataViewModel.shared
    
    init() {
        // Pay/Cancel button enablement
        dataVM.$currentOrder
            .sink {[weak self] order in
                guard let order = order else { return }
                if self?.orderIsPaid != order.isPaid {
                    self?.orderIsPaid = order.isPaid
                }
            }
            .store(in: &cancellables)
    }
    
    func payOrder() {
        dataVM.payCurrentOrder()
    }
    
    func cancelOrder() {
        dataVM.cancelCurrentOrder()
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
                .disabled(vm.orderIsPaid)

                Spacer()
                
                Button {
                    print("Pay button tapped")
                    vm.payOrder()
                } label: {
                    Text(vm.orderIsPaid ? "Paid" : "Pay")
                        .frame(maxWidth: .infinity, maxHeight: 36.0)
                }
                .tint(.green)
                .disabled(vm.orderIsPaid)
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
