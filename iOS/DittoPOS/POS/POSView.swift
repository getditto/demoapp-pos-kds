///
//  POSView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/15/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

class POSViewModel: ObservableObject {
    @Published var menuViewWidth: CGFloat
    @Published var orderViewWidth: CGFloat
    init() {
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            menuViewWidth = .screenWidth * 0.66
            orderViewWidth = .screenWidth * 0.30
        default:
            menuViewWidth = .screenWidth * 0.56
            orderViewWidth = .screenWidth * 0.40
        }
    }
}

struct POSView: View {
    @ObservedObject var dataVM = DataViewModel.shared
    @ObservedObject var vm = POSViewModel()
//    @State private var menuViewWidth: CGFloat
//    @State private var orderViewWidth: CGFloat
    
    @State var orientation = UIDevice.current.orientation
    
//    init() {
//        switch UIDevice.current.orientation {
//        case .landscapeLeft, .landscapeRight:
//            menuViewWidth = .screenWidth * 0.66
//            orderViewWidth = .screenWidth * 0.30
//        default:
//            menuViewWidth = .screenWidth * 0.56
//            orderViewWidth = .screenWidth * 0.40
//        }
//    }
    
    var body: some View {
        NavigationStack{
            HStack {
                MenuGridView()
                    .frame(width: vm.menuViewWidth)
//                .border(.red)
                
                Divider()
                
                OrderView()
                    .padding(8)
                    .frame(width: vm.orderViewWidth)
//                .border(.green)
            }
            .onAppear { print("POSView.onAppear") }
            .navigationBarTitle(barTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .onRotate { newOrientation in
                DispatchQueue.main.async {
                    orientation = newOrientation
                    
                    print("newOrientation: \(orientation.description)")
                    switch orientation {
                    case .landscapeLeft, .landscapeRight:
                        vm.menuViewWidth = .screenWidth * 0.66
                        vm.orderViewWidth = .screenWidth * 0.30
                    default:
                        vm.menuViewWidth = .screenWidth * 0.56
                        vm.orderViewWidth = .screenWidth * 0.40
                    }
                }
            }
        }
    }
    
    var barTitle: String {
        if let locName = dataVM.currentLocation?.name {
            return locName
        } else {
            return "Please Select Location"
        }
    }
}

struct POSView_Previews: PreviewProvider {
    static var previews: some View {
        POSView()
    }
}
