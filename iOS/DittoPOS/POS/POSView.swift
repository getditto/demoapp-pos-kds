///
//  POSView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/15/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

class POSViewModel: ObservableObject {
    @Published var menuViewWidth: CGFloat = 0.0
    @Published var orderViewWidth: CGFloat = 0.0
    init() {
        updateWidths()
    }
    
    func updateWidths() {
        menuViewWidth = .screenWidth * 0.56
        orderViewWidth = .screenWidth * 0.40
    }
}

struct POSView: View {    
    @StateObject var vm = POSViewModel()
    @ObservedObject var posVM = POS_VM.shared
    
    var body: some View {
        HStack {
            POSGridView()
                .frame(width: vm.menuViewWidth)
            
            Divider()
            
            POSOrderView()
                .padding(8)
                .frame(width: vm.orderViewWidth)
        }
        .alert(
            "Please select a location before ordering",
            isPresented: $posVM.presentSelectLocationAlert) {
                Button("OK", role: .cancel) { 
                    Settings.selectedTabView = nil
                }
            }
        .onRotate { orient in
            guard orient.isLandscape || orient.isPortrait else { return }
            DispatchQueue.main.async {
                vm.updateWidths()
            }
        }
    }
}

struct POSView_Previews: PreviewProvider {
    static var previews: some View {
        POSView()
    }
}
