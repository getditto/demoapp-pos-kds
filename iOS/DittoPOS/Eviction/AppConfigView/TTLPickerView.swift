///
//  TTLPickerView.swift
//  DittoPOS
//
//  Created by Eric Turner on 5/25/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct TTLPickerView: View {
    @EnvironmentObject var vm: AppConfigVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Orders")
                    Text("Time To Live")
                }
                .padding(.top)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    DaysHoursMinutesPickerView(
                        days: $vm.ttlDays,
                        hours: $vm.ttlHours,
                        minutes: $vm.ttlMinutes,
                        totalSeconds: $vm.selectedTTL
                    )
                    .frame(width: 160, height: 100, alignment: .center)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "Selected TTL: \(selectedTTLText)")
                        .padding(.trailing)

                Text(verbatim: "Current TTL:   \(currentTTLText)")
                    .foregroundColor(.secondary)
            }
            .scaledFont(size: 15)
            .padding(.top)
        }
    }
    
    var selectedTTLText: String {
        "Days: \(vm.ttlDays), Hours: \(vm.ttlHours), Minutes: \(vm.ttlMinutes)"
    }
    
    var currentTTLText: String {
        guard vm.currentTTL > 0 else {
            return "-- Undefined --"
        }
        let dhm = vm.currentTTLDHM()
        return "Days: \(dhm.days), Hours: \(dhm.hours), Minutes: \(dhm.minutes)"
    }
}

#Preview {
    TTLPickerView()
        .environmentObject(AppConfigVM())
}
