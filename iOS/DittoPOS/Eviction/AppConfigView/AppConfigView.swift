///
//  AppConfigView.swift
//  DittoPOS
//
//  Created by Eric Turner on 5/7/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Combine
import OSLog
import SwiftUI

class AppConfigVM: ObservableObject {
    @Published var appConfig: AppConfig
    private var _wipConfig: AppConfig
    @Published var configHasChanges: Bool = false

    @Published var showPublishedInfo = false
    @Published var showIntervalInfo = false
    @Published var showPolicyInfo = false
    @Published var showTTLInfo = false
    @Published var showQueryInfo = false
    @Published var showSelectedConfigInfo = false
    
    @Published var showConfirmationSheet = false
    @Published var showNoticeAlert = false
    var noticeTitle = ""
    var noticeMessage: String = ""
        
    // Local/Published Config
    @Published var usePublishedConfig: Bool = Settings.usePublishedAppConfig
    @Published var formattedLocalPublishedMode: String = ""
    private var needsSaveSwitchedConfig = false
    
    // Eviction Interval
    @Published var intervalDays: Int = 0
    @Published var intervalHours: Int = 0
    @Published var intervalMinutes: Int = 0
    @Published var selectedInterval: TimeInterval = 0.0
    @Published var currentInterval: TimeInterval = 0.0
    @Published var formattedCurrentCycle: String = ""
    
    // TTL (orders)
    @Published var ttlDays: Int = 0
    @Published var ttlHours: Int = 0
    @Published var ttlMinutes: Int = 0
    @Published var selectedTTL: TimeInterval = 0.0
    @Published var currentTTL: TimeInterval = 0.0

    // Policy start/end
    @Published var policyStartDate = Date.startOfToday
    @Published var policyEndDate = Date.startOfTomorrow
    var policyRangeStart = Date.startOfToday
    var policyRangeEnd = Date.endOfTomorrow
    
    // Version
    @Published var vMajor: Int = 0
    @Published var vMinor: Int = 0
    @Published var vPatch: Int = 0
    @Published var selectedVersion: Float = 0.0
    @Published var currentVersion: Float = 0.0

    // Query
    @Published var queryText: String = ""

    private var evictionService = EvictionService.shared
    private var dittoService = DittoService.shared
    private var configCancellable = AnyCancellable({})
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let config = DittoService.shared.appConfig
        appConfig = config
        _wipConfig = config
        
        updateAppConfigPublisher()
        
        // required for Xcode preview
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            DispatchQueue.main.async {[weak self] in
                self?.refreshState()
            }
        }
        
        $selectedInterval
            .dropFirst()
            .sink {[weak self] interval in
                self?.updateInterval(interval)
            }
            .store(in: &cancellables)


        $selectedTTL
            .dropFirst()
            .sink {[weak self] interval in
                self?.updateTTL(interval)
            }
            .store(in: &cancellables)

        $selectedVersion
            .dropFirst()
            .sink {[weak self] version in
                self?.updateVersion(version)
            }
            .store(in: &cancellables)
    }
    
    func updateAppConfigPublisher() {
        configCancellable = DittoService.shared.$appConfig
            .receive(on: DispatchQueue.main)
            .sink {[weak self] config in
                guard let self = self else { return }
                
                let logChange = config ~== appConfig ? "UNCHANGED" : "CHANGED"
                Logger.eviction.info("AppConfigVM.\(#function,privacy:.public): appConfig v\(config.version!,privacy:.public) in \(logChange,privacy:.public)")
                
                if needsSaveSwitchedConfig {
                    Settings.storedAppConfig = config
                    needsSaveSwitchedConfig = false
                }
                appConfig = config
                _wipConfig = appConfig
                resetEvictionInterval()
                updateFormattedCurrentCycle()
                resetTTL()
                resetPolicy()
                resetVersion()
                refreshState()
            }
    }
    
    func refreshState() {
        updateformattedLocalPublishedMode()
        updateFormattedCurrentCycle()
        updateSelectedQuery()
        updateConfigChangedState()
    }
    
    func updateformattedLocalPublishedMode() {
        usePublishedConfig = Settings.usePublishedAppConfig
        let version = String(format: "%.2f", currentVersion)
        let str = "Currently using \(usePublishedConfig ? "Published" : "Local") "
        + "AppConfig v\(version)"
        formattedLocalPublishedMode = str
    }
    
    //----------------------------------------------------------------------------------------------
    //MARK: EVICTION INTERVAL
    func resetEvictionInterval() {
        guard let interval = _wipConfig.evictionInterval else {
            intervalDays = 0; intervalHours = 0; intervalMinutes = 0; selectedInterval = 0
            return
        }
        let dhm = dhm(interval: interval)
        intervalDays = dhm.days; intervalHours = dhm.hours; intervalMinutes = dhm.minutes
        selectedInterval = interval
        currentInterval = appConfig.evictionInterval ?? 0.0
    }
    
    func currentIntervalDHM() -> (days: Int, hours: Int, minutes: Int) {
        dhm(interval: appConfig.evictionInterval ?? 0.0)
    }
    
    // called from $selectedInterval.sink in init()
    func updateInterval(_ interval: TimeInterval) {
//        Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): SET selectedInterval: \(interval,privacy:.public)")
        _wipConfig.evictionInterval = interval
        refreshState()
    }
    
    func updateFormattedCurrentCycle() {
//        let lastRun = evictionService.lastEvictionEpoch().shortFormat()
//        let next = evictionService.nextEvictionEpoch().shortFormat()
//        formattedCurrentCycle = "Last Run: \(lastRun)\nNext Scheduled: \(next)"
        let lastRun = evictionService.lastEvictionEpoch()?.standardFormat() ?? "[none]"
        let next = evictionService.nextEvictionEpoch().standardFormat()
        formattedCurrentCycle = "Last Run: \(lastRun)\nNext Scheduled: \(next)"
    }
    //----------------------------------------------------------------------------------------------
  
    
    //----------------------------------------------------------------------------------------------
    //MARK: TTL
    // N.B. - we're only looking at TTL for orders collection in this demo
    func resetTTL() {
        guard let interval = _wipConfig.TTLs?[ordersKey] else {
            ttlDays = 0; ttlHours = 0; ttlMinutes = 0; selectedTTL = 0
            return
        }
        let dhm = dhm(interval: interval)
        ttlDays = dhm.days; ttlHours = dhm.hours; ttlMinutes = dhm.minutes
        selectedTTL = interval
        currentTTL = appConfig.TTLs?[ordersKey] ?? 0.0
    }
    
    func dhm(interval: TimeInterval) -> (days: Int, hours: Int, minutes: Int) {
        let dhm = Date.timeIntervalToDHM(interval)
        return (days: dhm.days, hours: dhm.hours, minutes: dhm.minutes)
    }
    func currentTTLDHM() -> (days: Int, hours: Int, minutes: Int) {
        dhm(interval: appConfig.TTLs?[ordersKey] ?? 0.0)
    }
    
    // called from $selectedTTL.sink in init()
    func updateTTL(_ interval: TimeInterval) {
//        Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): SET TTL[orders]: \(interval,privacy:.public)")
        if let _ = _wipConfig.TTLs {
            _wipConfig.TTLs![ordersKey] = interval
        } else {
            _wipConfig.TTLs = [ordersKey: interval]
        }
        refreshState()
    }
    //----------------------------------------------------------------------------------------------
    
    
    //----------------------------------------------------------------------------------------------
    //MARK: POLICY
    // Changing the policy dates will cause the UI observers to call the updatePolicy methods
    func resetPolicy() {
        policyStartDate = Date.startOfToday.addingTimeInterval(
            _wipConfig.noEvictPeriodStartSeconds!
        )
        
        policyEndDate = Date.startOfTomorrow.addingTimeInterval(
            _wipConfig.noEvictPeriodEndSeconds!
        )
    }

    func updatePolicyStartTime(_ date: Date) {
        _wipConfig.noEvictPeriodStartSeconds = date.localTimeSeconds

//        Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): SET noEvictStart: \(self._wipConfig.noEvictPeriodStartSeconds!,privacy:.public)")

        refreshState()
    }
    
    func updatePolicyEndTime(_ date: Date) {
        _wipConfig.noEvictPeriodEndSeconds = date.localTimeSeconds
        
//        Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): SET noEvictEnd: \(self._wipConfig.noEvictPeriodEndSeconds!,privacy:.public)")

        refreshState()
    }
    //----------------------------------------------------------------------------------------------

    
    //MARK: Version
    func resetVersion() {
        let version = _wipConfig.version ?? Float(0.0)
        vMajor = Int(modf(version).0)
        let twoDecimals = version.floorFirstTwoDecimals()
        vMinor = twoDecimals.first
        vPatch = twoDecimals.second
        
//        Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): RESET selectedVersion: \(self.selectedVersion,privacy:.public)")
        currentVersion = appConfig.version ?? Float(0.0)
//        Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): RESET currentVersion: \(self.currentVersion,privacy:.public)")

        return
    }
    
    // called from $versionFloat.sink in init()
    func updateVersion(_ version: Float) {
//        Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): SET version: \(version,privacy:.public)")
        _wipConfig.version = version
        refreshState()
    }

    
    //MARK: QUERY
    func updateSelectedQuery() {
        var queryStub = Order.defaultEvictQueryStub()
        if let currentStub = _wipConfig.queries?[ordersKey] {
            queryStub = currentStub
        }

        if let fullQuery = evictionService.fullEvictionQueryString(for: ordersKey, config: _wipConfig) {
            queryText = fullQuery
        } else {
            queryText = queryStub
        }
    }
    
    var queryInfoDate: Date {
        Date.now.addingTimeInterval(-_wipConfig.ttlOrDefault(collection: ordersKey))
    }
    
    
    //MARK: WIP text
    var selectedConfigText: String {
        _wipConfig.prettyPrint()
    }

    
    //----------------------------------------------------------------------------------------------
    //MARK: Verify & Save
    func updateConfigChangedState() {
        let isNotApproximatelyEqual = _wipConfig !~== appConfig
        configHasChanges = isNotApproximatelyEqual
    }

    func saveForLocalOnly() {
        saveConfig(publish: false)
    }
    
    func saveAndPublish() {
        saveConfig(publish: true)
    }

    private func saveConfig(publish: Bool) {
        _wipConfig.lastUpdated = Date.now
        Task {
            do {
                if publish {
                    _wipConfig._id = [
                        "id": AppConfig.Defaults.publishedDefaultId,
                        "locationId": dittoService.currentLocationId!
                    ]
                    try await DittoService.shared.publishAppConfig(_wipConfig)
                    
                    Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): PUBLISH updated AppConfig")
                    
                    await MainActor.run {
                        updateAppConfigPublisher()
                        usePublishedConfig = Settings.usePublishedAppConfig
                    }
                } else {
                    // inserts and triggers DittoService publisher to update
                    DittoService.shared.updateLocalOnlyAppConfig(_wipConfig)
                    
                    await MainActor.run {
                        usePublishedConfig = Settings.usePublishedAppConfig
                    }
                }
            } catch {
                let errMsg = error.localizedDescription
                Logger.eviction.error("AppConfigVM.\(#function,privacy:.public): saveConfig() FAIL: \(errMsg,privacy:.public)")
                await MainActor.run {
                    Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): update error msg + show showErrorAlert")
                    self.noticeMessage = errMsg
                    self.showNoticeAlert = true
                }
            }
        }
    }
    //----------------------------------------------------------------------------------------------
    
    func clearChanges() {
        updateAppConfigPublisher()
    }
    
    func switchToPublished() {
        // This condition shouldn't ever be true, but...
        guard Settings.usePublishedAppConfig == false else {
            Logger.eviction.error("AppConfigVM.\(#function,privacy:.public): usePublishedAppConfig == false --> Return")
            return
        }
        
        needsSaveSwitchedConfig = true
        dittoService.enablePublishedAppConfig()
    }
    
    // Evicts documents per _wipConfig configuration but respects No-Evict policy and aborts
    func runTestEviction() {
        guard let _ = _wipConfig.queries else {
            Logger.eviction.warning("AppConfigVM.\(#function,privacy:.public): no WIP queries found --> Return")
            return
        }
        Task {
            let msg = await evictionService.runEvictionQueries(mode: .test, config: _wipConfig)
            Logger.eviction.debug("AppConfigVM.\(#function,privacy:.public): Run TEST eviction with result: \(msg,privacy:.public)")
            await MainActor.run {
                noticeTitle = "Test Run"
                noticeMessage = msg
                showNoticeAlert = true
            }
        }
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


struct AppConfigView: View {
    @StateObject var vm = AppConfigVM()
    
    var body: some View {
        
        Form {
            
            // Local/Published Mode
            Section {
                Text(vm.formattedLocalPublishedMode) //localPublishedModeTitle)
                    .foregroundColor(.secondary)
            } header: {
                infoHeader(text: "Local-only or Published Mode", action: vm.showPublishedInfo.toggle())
            } footer: {
                if vm.showPublishedInfo {
                    Text(localOrPublishedConfigFooterText)
                }
            }
            
            // EVICTION INTERVAL
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    EvictionIntervalPickerView()
                        .environmentObject(vm)
                }

                // CURRENT INTERVAL formatted label
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current cycle:\n\(vm.formattedCurrentCycle)")
                }
                .foregroundColor(.secondary)
                .scaledFont(size: 15)
            } header: {
                infoHeader(text: "Eviction Cycle Interval", action: vm.showIntervalInfo.toggle())
            } footer: {
                if vm.showIntervalInfo {
                    Text(evictionFooterText)
                }
            }
            
            // TTL
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    TTLPickerView()
                        .environmentObject(vm)
                }
            } header: {
                infoHeader(text: "Orders TTL", action: vm.showTTLInfo.toggle())
            } footer: {
                if vm.showTTLInfo {
                    Text(ordersTTLFooterText)
                }
            }
            
            // POLICY
            Section {
                Group {
                    DatePicker("Start", selection: $vm.policyStartDate,
                               in: vm.policyRangeStart...vm.policyRangeEnd,
                               displayedComponents: [.hourAndMinute]
                    )
                    DatePicker("End", selection: $vm.policyEndDate,
                               in: vm.policyRangeStart...vm.policyRangeEnd,
                               displayedComponents: [.hourAndMinute]
                    )
                }
                .datePickerStyle(.automatic)
                .onChange(of: vm.policyStartDate) { time in
                    vm.updatePolicyStartTime(time)
                }
                .onChange(of: vm.policyEndDate) { time in
                    vm.updatePolicyEndTime(time)
                }
            } header: {
                HStack {
                    infoHeader(text: "No-Evict Policy Times", action: vm.showPolicyInfo.toggle())
                }
            } footer: {
                if vm.showPolicyInfo {
                    Text(policyInfoFooterText)
                }
            }
                        
            // VERSION
            Section("Version") {
                VStack(alignment: .leading, spacing: 0) {
                    VersionPickerView()
                        .environmentObject(vm)
                }
            }
            
            // QUERY
            Section {
                Text(vm.queryText)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            } header: {
                infoHeader(text: "Eviction Query", action: vm.showQueryInfo.toggle())
            } footer: {
                if vm.showQueryInfo {
                    Text(queryInfoFooterText)
                }
            }
            
            // WIP CONFIG TEXT
            Section {
                Text(vm.selectedConfigText)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            } header: {
                infoHeader(
                    text: vm.configHasChanges ? "Current Unsaved Configuration" : "Current Configuration Unchanged",
                    action: vm.showSelectedConfigInfo.toggle()
                )
            } footer: {
                if vm.showSelectedConfigInfo {
                    Text(selectedConfigFooterText)
                }
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    vm.clearChanges()
                }
                .disabled(vm.configHasChanges == false)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        Button("Save") { vm.showConfirmationSheet = true }
                            .padding(16)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .confirmationDialog("Confirm", isPresented: $vm.showConfirmationSheet, titleVisibility: .visible) {
                                Button("Local only") {
                                    vm.saveForLocalOnly()
                                }
                                Button("Publish to All This Location") {
                                    vm.saveAndPublish()
                                }
                            }
                        
                        if Settings.usePublishedAppConfig == false {
                            Button("Use Published") {
                                vm.switchToPublished()
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                        
                        Button("Force Evict") {
                            vm.runForcedEviction()
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                        Button("Test Evict") {
                            vm.runTestEviction()
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
            }
        }
    }
    
    var localOrPublishedConfigFooterText: String {
        var txt = ""
        if vm.usePublishedConfig {
            txt += "The eviction configuration for this device is currently defined by an "
            + "AppConfig document for this location in the \"configuration\" collection, which may "
            + "be updated here, remotely, or by another device from time to time.\n"
        } else {
            txt += "Eviction settings for are defined locally for this device only, which is the "
            + "default. Use the \"Use Published\" button below to subscribe to a published "
            + "AppConfig for all devices at this location."
        }
        
        let tagline = "You may make changes in this screen and save them to be used by this device "
        + "only, or save to publish an updated configuration for all devices at this location."
        
        return txt + tagline
    }
    
    var evictionFooterText: String {
        "The eviction interval is the time period between evictions. Use the control to set the "
        + "number of days, hours, and minutes between eviction cycles. For example, to set eviction "
        + "to run every 24 hours, set the Day value to 1 and set Hour and Min values to zero."
    }

    var ordersTTLFooterText: String {
        "Note: in this demo, we are only evicting documents from the \"orders\" collection. The "
        + "control sets the length of the time to live (TTL) for orders in days, hours, and "
        + "minutes. For example, to retain orders in the database for one week, set the Day value "
        + "to 7 and set Hour and Min to zero.\n"
        + "Using the example of a setting of 7 days, at the moment the eviction query is run, all "
        + "orders 7 days and older from that moment will be evicted. At that time also, the "
        + "orders subscription will be updated to subscribe to orders only 7 days old and newer.\n"
        + "This is a \"sliding time window\" eviction strategy. For example, assume the eviction "
        + "interval is set to run eviction once a day, and the TTL of orders is 7 days. After each "
        + "eviction cycle, 7 days of orders are left in the database. Every day another day's "
        + "worth of orders are added. When the eviction cycle for that day runs, there will be 8 "
        + "days of orders in the database in total; at that time, orders older than 7 days, i.e., "
        + "the orders 8 days old, will be evicted, leaving 7 day's worth."
    }

    var queryInfoFooterText: String {
        "The timestamp in the eviction query WHERE clause is the TTL "
        + "defined for orders documents as an ISO8601 timestamp, in UTC time. "
        + "The clause specifies evicting documents created on or before "
        + "\(vm.queryInfoDate.standardFormat()) local time.\n"
        + "Note that the query displayed here is calculated with the orders TTL from the present "
        + "time, as an example. At the time the actual eviction executes, a timestamp is "
        + "calculated and inserted into the query to reflect TTL from that moment."
    }
    
    var policyInfoFooterText: String {
        "Define a policy to prevent eviction from running between start and end "
        + "times, for example during store hours. Times can overlap midnight. "
        + "Set both to the same time to disable the No-Evict policy and allow "
        + "eviction to run at any time of day or night."
    }
    
    var selectedConfigFooterText: String {
        "This view displays the configuration as currently defined by the settings "
        + "controls on this form. Note that the \"lastUpdated\" timestamp field reflects the "
        + "time it was last published by any device, in the case of a published AppConfig, or the "
        + "time it was saved by this device for local-only use."
    }
    
    @ViewBuilder
    func infoView(action: @escaping () -> Void) -> some View {
        Button(action: { action() }) {
            Image(systemName: "info.circle").font(.subheadline)
        }
    }
    
    @ViewBuilder
    func infoHeader(text: String, action: @autoclosure @escaping () -> ()) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .overlay(
                infoView { action() }
                .opacity(0.65)
                .padding(2)
                .offset(x: 10, y: -2),
                alignment: .topTrailing
            )
    }
}

#Preview {
    NavigationView {
        AppConfigView()
    }
}
