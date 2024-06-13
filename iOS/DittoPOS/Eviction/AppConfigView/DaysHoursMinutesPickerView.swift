///
//  DaysHoursMinutesPickerView.swift
//  DittoPOS
//
//  Created by Eric Turner on 5/25/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct DaysHoursMinutesPickerView: View {
    @Binding var days: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var totalSeconds: TimeInterval

    private var computedTotalSeconds: TimeInterval {
        let totalMinutes = (days * 24 * 60) + (hours * 60) + minutes
        return TimeInterval(totalMinutes * 60)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .center, spacing: 2) {
                    Text("Day").font(.footnote)
                    
                    Picker("Days", selection: $days) {
                        ForEach(0..<31) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .clipped()
                    .border(.black)
                }

                VStack(alignment: .center, spacing: 2) {
                    Text("Hour").font(.footnote)
                    
                    Picker("Hours", selection: $hours) {
                        ForEach(0..<24) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .clipped()
                    .border(.black)
                }

                VStack(alignment: .center, spacing: 2) {
                    Text("Min").font(.footnote)
                    
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .clipped()
                    .border(.black)
                }
            }
            .frame(width: 160, height: 90, alignment: .center)
            .border(.black)
            .onChange(of: days) { _ in updateTotalSeconds() }
            .onChange(of: hours) { _ in updateTotalSeconds() }
            .onChange(of: minutes) { _ in updateTotalSeconds() }
            
        }
    }

    private func updateTotalSeconds() {
        totalSeconds = computedTotalSeconds
    }
}

#Preview {
    DaysHoursMinutesPickerView(
        days: .constant(0),
        hours: .constant(0),
        minutes: .constant(0),
        totalSeconds: .constant(0.0)
    )
}
