///
//  FloatPickerView.swift
//  DittoPOS
//
//  Created by Eric Turner on 5/25/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI


struct FloatPickerView: View {
    @Binding var whole: Int
    @Binding var fraction10: Int
    @Binding var fraction100: Int
    @Binding var floatNumber: Float
    
    private var computedFloatNumber: Float {
        let total = ("\(whole).\(fraction10)\(fraction100)" as NSString).floatValue
        return total
    }

    var body: some View {
        VStack(spacing: 0) {

            // Whole number part
            HStack(alignment: .center, spacing: 0) {
                
                VStack(alignment: .center, spacing: 0) {
                    
                    Text("Major").font(.footnote)

                HStack(alignment: .center, spacing: 0) {
                        Picker("", selection: $whole) {
                            ForEach(0..<100) { wholeN in
                                Text("\(wholeN)").tag(wholeN)
                            }
                        }
                        .pickerStyle(.wheel)
                        .clipped()
                        
                    Text(".").font(.title) // decimal
                    }
                .border(width: 1, edges: [.top], color: .black)
                }
                .frame(width: 55, height: 90, alignment: .center)
                
                // Fraction parts
                VStack(alignment: .center, spacing: 0) {

                    Text("Minor").font(.footnote)
                        .padding(.trailing, 4)

                    HStack(alignment: .center, spacing: 0) {
                        Picker("", selection: $fraction10) {
                            ForEach(0..<10) { frac10 in
                                Text("\(frac10)").tag(frac10)
                            }
                        }
                        .pickerStyle(.wheel)
                        .clipped()
                        
                        Picker("", selection: $fraction100) {
                            ForEach(0..<10) { frac100 in
                                Text("\(frac100)").tag(frac100)
                            }
                        }
                        .pickerStyle(.wheel)
                        .clipped()
                    }
                    .border(width: 1, edges: [.top], color: .black)
                    
                }
                .frame(width: 90, height: 90, alignment: .center)
            }
        }
        .border(.black)
        .onChange(of: whole) { _ in updateFloatNumber() }
        .onChange(of: fraction10) { _ in updateFloatNumber() }
        .onChange(of: fraction100) { _ in updateFloatNumber() }
    }

    private func updateFloatNumber() {
        floatNumber = computedFloatNumber
    }
}

#Preview {
    FloatPickerView(
        whole: .constant(3),
        fraction10: .constant(5),
        fraction100: .constant(7),
        floatNumber: .constant(1.5)
    )
}
