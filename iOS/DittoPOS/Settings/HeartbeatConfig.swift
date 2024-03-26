//
//  HeartbeatConfig.swift
//  DittoPOS
//
//  Created by Walker Erekson on 3/22/24.
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoHeartbeat

class HeartbeatConfigVM: ObservableObject {
    
    @Published var isHeartbeatOn: Bool = Settings.isHeartbeatOn
    @Published var secondsInterval: Int = Settings.secondsInterval
    @Published var expectedDeviceCount: Int = Settings.expectedDeviceCount
    @Published var locationId: String = Settings.locationId ?? ""
    @Published var collectionName: String = Settings.collectionName
    @Published var locationName: String = Settings.locationName
    var heartbeatVM: HeartbeatVM = HeartbeatVM(ditto: DittoService.shared.ditto)
    
    func startHeartbeat() {
        if self.heartbeatVM.isEnabled {
            self.stopHeartbeat()
        }
        self.heartbeatVM.startHeartbeat(config: DittoHeartbeatConfig(secondsInterval: self.secondsInterval, collectionName: self.collectionName, metadata: ["locationId": self.locationId, "locationName": self.locationName, "expectedDeviceCount": self.expectedDeviceCount])) {_ in }
    }
    
    func stopHeartbeat() {
        self.heartbeatVM.stopHeartbeat()
    }
    
    func saveConfig() {
        Settings.isHeartbeatOn = self.isHeartbeatOn
        Settings.secondsInterval = self.secondsInterval
        Settings.expectedDeviceCount = self.expectedDeviceCount
        Settings.collectionName = self.collectionName
        Settings.locationName = self.locationName
        
        if self.isHeartbeatOn {
            self.startHeartbeat()
        } else {
            self.stopHeartbeat()
        }
    }
}

struct HeartbeatConfig: View {
    @StateObject private var vm = HeartbeatConfigVM()
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $vm.isHeartbeatOn) {
                    Text("Heartbeat")
                }
            }
            
            Section(header: Text("Heartbeat Config")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Seconds Interval:")
                        
                        TextField("0", value: $vm.secondsInterval, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .padding([.leading])
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(5)
                            .frame(maxWidth: 100)
                    }
                    .padding([.top], 5)
                    HStack {
                        Text("Collection Name:")
                        
                        TextField("0", text: $vm.collectionName)
                            .padding([.leading])
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(5)
                            .frame(maxWidth: 150)
                    }
                    Spacer()
                    Text("Metadata:")
                        .foregroundColor(Color(UIColor.systemGray))
                    Text("Location Id: \(vm.locationId)")
                    HStack {
                        Text("Location Name:")
                        
                        TextField("name", text: $vm.locationName)
                            .padding([.leading])
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(5)
                            .frame(maxWidth: 150)
                    }
                    HStack {
                        Text("Expected Device Count:")
                        
                        TextField("0", value: $vm.expectedDeviceCount, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .padding([.leading])
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(5)
                            .frame(maxWidth: 100)
                    }
                }
            }
            
            Button {
                vm.saveConfig()
            } label: {
                Text("Save")
            }
        }
        .navigationTitle("Heartbeat")
    }
}

#Preview {
    HeartbeatConfig()
}
