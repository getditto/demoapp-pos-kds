///
//  EvictionLogsView.swift
//  DittoPOS
//
//  Created by Eric Turner on 4/20/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Combine
import OSLog
import SwiftUI

class EvictionLogsVM: ObservableObject {
    @Published var evictionLogs = [EvictionLog]()
    private var cancellables = Set<AnyCancellable>()
    private var evictionQuerys = [String]()
    
    init() {
        Settings.evictionLogsPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink {[weak self] logs in
                self?.evictionLogs = logs.sorted(by: { $0.queryTimestamp > $1.queryTimestamp })
            }
            .store(in: &cancellables)
    }
    
    func refreshLogs() async {
        await MainActor.run {
            evictionLogs = Settings.evictionLogs?.sorted(by: { $0.queryTimestamp > $1.queryTimestamp }) ?? []
        }
    }
}

struct EvictionLogRowItem: View {    
    var log: EvictionLog
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(log.title)
            Text(log.opTime)
            Text(log.details)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.all, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EvictionLogsView: View {
    @StateObject var vm = EvictionLogsVM()
    
    var body: some View {
        VStack {
            if vm.evictionLogs.isEmpty {
                Text("No logs")
                Spacer()
            } else {
                List {
                    ForEach(vm.evictionLogs) { log in
                        NavigationLink(destination: EvictionLogDetailView(log: log)) {
                            EvictionLogRowItem(log: log)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .refreshable {
                    await vm.refreshLogs()
                }
            }
            
            Spacer()
        }
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                    
                    Text("Eviction Logs Count: \(vm.evictionLogs.count)")
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                VStack(alignment: .center) {
                    HStack(alignment: .center) {
//                        Button("Force Evict") {
//                            Task {
//                                await EvictionService.shared.runEvictionQueries(mode: .forced)
//                            }
//                        }
//                        .padding(16)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//                        
//                        Spacer().frame(width: 24)
                        
                        Button("Delete Logs") {
                            Logger.eviction.debug("Delete all eviction logs")
                            Settings.evictionLogs = [EvictionLog]()
                        }
                            .padding(16)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
            }
        }
    }
}


#Preview {
    NavigationView {
        EvictionLogsView()
    }
}
