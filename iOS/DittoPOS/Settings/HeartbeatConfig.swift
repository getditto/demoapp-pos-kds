//
//  HeartbeatConfig.swift
//  DittoPOS
//
//  Created by Walker Erekson on 3/22/24.
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoHeartbeat
import DittoHealthMetrics
import DittoPermissionsHealth
import DittoDiskUsage

@MainActor class HeartbeatConfigVM: ObservableObject {
    @Published var isHeartbeatOn: Bool = Settings.isHeartbeatOn

    //Heartbeat config
    @Published var secondsInterval: Int = Settings.secondsInterval
        
    //metaData
    @Published var metaData: [String:Any] = Settings.metaData
    @Published var deviceName: String = ""
    
    //location
    @Published var location: [String:Any] = [:]
    @Published var expectedDeviceCount: Int = 0
    @Published var locationId: String = Settings.locationId ?? ""
    @Published var locationName: String = ""

    //deviceAttributes
    @Published var deviceAttributes: [String:String] = [:]
    @Published var deviceAttributesAlert: Bool = false
    @Published var newDeviceAttributesKey: String = ""
    @Published var newDeviceAttributesValue: String = ""
    
    //locationAttributes
    @Published var locationAttributes: [String:String] = [:]
    @Published var locationAttributesAlert: Bool = false
    @Published var newLocationAttributesKey: String = ""
    @Published var newLocationAttributesValue: String = ""
    
    func saveConfig() {
        //construct location
        self.location["locationId"] = self.locationId
        self.location["locationName"] = self.locationName
        self.location["expectedDeviceCount"] = self.expectedDeviceCount
        
        //construct metaData
        self.metaData["deviceName"] = self.deviceName
        self.metaData["location"] = self.location
        self.metaData["locationAttributes"] = self.locationAttributes
        self.metaData["deviceAttributes"] = self.deviceAttributes

        Settings.isHeartbeatOn = self.isHeartbeatOn
        Settings.secondsInterval = self.secondsInterval
        Settings.metaData = self.metaData

        let healthMetricProviders: [HealthMetricProvider] = [
            DittoPermissionsHealth.BluetoothManager(),
            DittoPermissionsHealth.NetworkManager(),
            DittoDiskUsage.DiskUsageViewModel(ditto: DittoService.shared.ditto)
        ]
        DittoService.shared.heartbeatConfig = DittoHeartbeatConfig(id: Settings.deviceId,
                                                                   secondsInterval: self.secondsInterval,
                                                                   metadata: self.metaData,
                                                                   healthMetricProviders: healthMetricProviders)

        if self.isHeartbeatOn {
            DittoService.shared.startHeartbeat()
        } else {
            DittoService.shared.stopHeartbeat()
        }
    }
    
    func addLocationAttributesKey() {
        self.locationAttributes[self.newLocationAttributesKey] = ""
        self.newLocationAttributesKey = ""
    }
    
    func addDeviceAttributesKey() {
        self.deviceAttributes[self.newDeviceAttributesKey] = ""
        self.newDeviceAttributesKey = ""
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
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Device Name:")
                        TextField("name", text: $vm.deviceName)
                            .padding([.leading])
                            .background(Color.gray5)
                            .cornerRadius(5)
                            .frame(maxWidth: 150)
                    }
                    HStack {
                        Text("Seconds Interval:")
                        
                        TextField("0", value: $vm.secondsInterval, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .padding([.leading])
                            .background(Color.gray5)
                            .cornerRadius(5)
                            .frame(maxWidth: 100)
                    }
                }
            }
            Section(header: Text("location:")) {
                VStack(alignment: .leading) {
                    Text("Location Id: \(vm.locationId)")
                    HStack {
                        Text("Location Name:")
                        TextField("name", text: $vm.locationName)
                            .padding([.leading])
                            .background(Color.gray5)
                            .cornerRadius(5)
                            .frame(maxWidth: 150)
                    }
                    HStack {
                        Text("Expected Device Count:")
                        
                        TextField("0", value: $vm.expectedDeviceCount, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .padding([.leading])
                            .background(Color.gray5)
                            .cornerRadius(5)
                            .frame(maxWidth: 100)
                    }
                }
            }
            Section(header: Text("Location Attributes:")) {
                if(!vm.locationAttributes.isEmpty) {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(vm.locationAttributes.sorted(by: <), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                    TextField("value", text: Binding(
                                        get: {
                                            vm.newLocationAttributesValue
                                        },
                                        set: { newValue in
                                            vm.newLocationAttributesValue = newValue
                                            vm.locationAttributes[key] = newValue
                                        }
                                    ))
                                        .padding([.leading])
                                        .background(Color.gray5)
                                        .cornerRadius(5)
                                        .frame(maxWidth: 150)
                                }
                            }
                        }
                    }
                }
                Button("New Entry") {
                    vm.locationAttributesAlert.toggle()
                }
                .buttonStyle(DefaultButtonStyle())
                .alert("New Attribute", isPresented: $vm.locationAttributesAlert) {
                    TextField("key", text: $vm.newLocationAttributesKey)
                    Button("Save", action: vm.addLocationAttributesKey)
                    Button("Cancel") { vm.locationAttributesAlert = false }
                }
            }
            Section(header: Text("Device Attributes:")) {
                if(!vm.deviceAttributes.isEmpty) {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(vm.deviceAttributes.sorted(by: <), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                    TextField("value", text: Binding(
                                        get: {
                                            vm.newDeviceAttributesValue
                                        },
                                        set: { newValue in
                                            vm.newDeviceAttributesValue = newValue
                                            vm.deviceAttributes[key] = newValue
                                        }
                                    ))
                                        .padding([.leading])
                                        .background(Color.gray5)
                                        .cornerRadius(5)
                                        .frame(maxWidth: 150)
                                }
                            }
                        }
                    }
                }
                Button("New Entry") {
                    vm.deviceAttributesAlert.toggle()
                }
                .buttonStyle(DefaultButtonStyle())
                .alert("New Attribute", isPresented: $vm.deviceAttributesAlert) {
                    TextField("key", text: $vm.newDeviceAttributesKey)
                    Button("Save", action: vm.addDeviceAttributesKey)
                    Button("Cancel") { vm.deviceAttributesAlert = false }
                }
            }
            Button(action: vm.saveConfig) {
                Text("Save")
            }
            .buttonStyle(DefaultButtonStyle())
        }
        .navigationTitle("Heartbeat Config")
    }
}

#Preview {
    HeartbeatConfig()
}
