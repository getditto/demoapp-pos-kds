///
//  EvictionIntervalPickerView.swift
//  DittoPOS
//
//  Created by Eric Turner on 5/25/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct EvictionIntervalPickerView: View {
    @EnvironmentObject var vm: AppConfigVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                
                Text("Eviction Cycle Interval")
                    .padding(.top)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    DaysHoursMinutesPickerView(
                        days: $vm.intervalDays,
                        hours: $vm.intervalHours,
                        minutes: $vm.intervalMinutes,
                        totalSeconds: $vm.selectedInterval
                    )
                    .frame(width: 160, height: 100, alignment: .center)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "Selected interval: \(selectedIntervalText)")
                        .padding(.trailing)

                Text(verbatim: "Current interval:   \(currentIntervalText)")
            }
            .scaledFont(size: 15)
            .padding(.top)
        }
    }
    
    var selectedIntervalText: String {
        "Days: \(vm.intervalDays), Hours: \(vm.intervalHours), Minutes: \(vm.intervalMinutes)"
    }
    
    var currentIntervalText: String {
        guard vm.currentInterval > 0 else {
            return "-- Undefined --"
        }
        let dhm = vm.currentIntervalDHM()
        return "Days: \(dhm.days), Hours: \(dhm.hours), Minutes: \(dhm.minutes)"
    }
}

#Preview {
    TTLPickerView()
        .environmentObject(AppConfigVM())
}
