///
//  VersionPickerView.swift
//  DittoPOS
//
//  Created by Eric Turner on 5/26/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct VersionPickerView: View {
    @EnvironmentObject var vm: AppConfigVM

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                
                Text("AppConfig Version ")
                    .padding(.top)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    FloatPickerView(
                        whole: $vm.vMajor,
                        fraction10: $vm.vMinor,
                        fraction100: $vm.vPatch,
                        floatNumber: $vm.selectedVersion
                    )
                    .frame(width: 150, height: 90, alignment: .center)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text(verbatim: "Selected Version: \(vm.selectedVersion.stringToTwoDecimalPlaces())")
                        .padding(.trailing)

                Text(verbatim: "Current Version:   \(vm.currentVersion.stringToTwoDecimalPlaces())")
                    .foregroundColor(.secondary)
            }
            .scaledFont(size: 15)
            .padding(.top)
        }
    }
}

#Preview {
    VersionPickerView()
        .environmentObject(AppConfigVM())
}
