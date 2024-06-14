///
//  EvictionView.swift
//  DittoPOS
//
//  Created by Eric Turner on 5/7/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Combine
import OSLog
import SwiftUI

struct EvictionView: View {
    @StateObject var vm = EvictionViewVM()
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: AppConfigView()) {
                    Text("AppConfig Settings")
                }
            }
            
            Section {
                NavigationLink(destination: EvictionLogsView()) {
                    Text("Eviction Logs")
                }
            }
            
            Section {
                Button("Force Evict") {
                    vm.runForcedEviction()
                }
            }

            Section {
                Text(vm.selectedConfigText)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            } header: {
                Text("Current Configuration ")
            } footer: {
            }
            .alert(vm.noticeTitle, isPresented: $vm.showNoticeAlert, actions: {
                Button("Dismiss", role: .cancel) {
                    vm.noticeTitle = ""
                    vm.noticeMessage = ""
                }
                }, message: {
                    Text(vm.noticeMessage)
                })
        }
        .navigationTitle("Eviction")
        .interactiveDismissDisabled()
    }
}

#Preview {
    NavigationView {
        EvictionView()
    }
}


class EvictionViewVM: ObservableObject {
    @Published var appConfig: AppConfig
    private var _wipConfig: AppConfig
    private var configCancellable = AnyCancellable({})
    private var evictionService = EvictionService.shared

    @Published var showNoticeAlert = false
    var noticeTitle = ""
    var noticeMessage: String = ""
        
    init() {
        let config = DittoService.shared.appConfig
        appConfig = config
        _wipConfig = config
        
        
        updateAppConfigPublisher()
    }
    
    func updateAppConfigPublisher() {
        configCancellable = DittoService.shared.$appConfig
            .receive(on: DispatchQueue.main)
            .sink {[weak self] config in
                guard let self = self else { return }
                
                appConfig = config
                _wipConfig = appConfig
            }
    }
    
    //MARK: WIP text
    var selectedConfigText: String {
        _wipConfig.prettyPrint()
    }
    // Runs current config and not WIP config
    // N.B. does not respect No-Evict policy window
    func runForcedEviction() {
        Task {
            let msg = await evictionService.runEvictionQueries(mode: .forced)
            Logger.eviction.debug("AppConfigView: Run FORCED eviction with result: \(msg,privacy:.public)")
            await MainActor.run {
                noticeTitle = "Forced Eviction Run"
                noticeMessage = msg
                showNoticeAlert = true
            }
        }
    }
    
}
