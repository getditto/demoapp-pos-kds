///
//  AdvancedSettings.swift
//  DittoPOS
//
//  Created by Eric Turner on 3/7/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI


class AdvancedSettingsVM: ObservableObject {
    @Published var shouldUseDemo: Bool = Settings.useDemoLocations
    private var shadowUseDemo: Bool = Settings.useDemoLocations
    
    func saveSettings() {
        if shadowUseDemo != shouldUseDemo {
            DittoService.shared.updateDemoLocationsSetting(enable: shouldUseDemo)
        }
    }
}

struct AdvancedSettings: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var vm = AdvancedSettingsVM()
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack {
                        Toggle(isOn: $vm.shouldUseDemo) {
                            
                            Text("Use demo locations").bold()
                        }
                        .padding(.bottom, 8)
                        .overlay(Divider(), alignment: .bottom)
                        
                        Text(
                            "You can switch between shared demo restaurant locations.\n"
                            + "Or, create a custom location and all orders in your demo "
                            + "will be for that location."
                        )
                        .font(.footnote)
                        .padding(.trailing, 32)
                    }
                }
            } header: {
                if let locName = Settings.locationId, Settings.useDemoLocations == false {
                    Text("Current location: \"\(locName)\"")
                }
            }
            
            Section {
                HStack(alignment: .bottom) {
                    Spacer()
                    
                    Button{
                        vm.saveSettings()
                    } label: {
                        Text("Save")
                    }
                    .frame(alignment: .center)
                    .disabled(vm.shouldUseDemo == Settings.useDemoLocations)

                    Spacer()
                }
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    AdvancedSettings()
}
