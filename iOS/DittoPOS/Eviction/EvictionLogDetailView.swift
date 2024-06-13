///
//  EvictionLogDetailView.swift
//  DittoPOS
//
//  Created by Eric Turner on 4/26/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct EvictionLogDetailView: View {
    let log: EvictionLog
    
    var body: some View {
        VStack {
            VStack {
                Text(log.title)
                    .font(.title2)
                
                Text(log.opTime)
            }
            .padding(.bottom, 16)

            Group {
                
                if !log.resultMsg.isEmpty {
                    VStack {
                        Text("Result:")
                            .font(.body)
                        
                        Text("\(log.resultMsg)")
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .font(.body)
                    }
                }
                
                VStack {
                    Text("Details:")
                        .font(.body)
                    Text("\(log.details)")
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .font(.body)
                }
                
                VStack {
                    Text("Eviction Query:")
                    Text("\(log.query)")
                        .font(.subheadline)
                }
                
                if !log.docIDs.isEmpty {
                    VStack {
                        Text("Document IDs:")
                        Text("\(log.docIDs)")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.bottom, 16)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    EvictionLogDetailView(log: EvictionLog.previewLog)
}
