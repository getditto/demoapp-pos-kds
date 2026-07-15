//
//  DittoManager.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift

/// Owns the `Ditto` instance and starts sync. Holds the transport-level
/// sync group driven by the currently active location. Mirrors Android's
/// `DittoManager` (in the `ditto-wrapper` module).
final class DittoManager: ObservableObject {
    static var shared = DittoManager()
    let ditto: Ditto

    private init() {
        #if os(tvOS)
        let directory: FileManager.SearchPathDirectory = .cachesDirectory
        #else
        let directory: FileManager.SearchPathDirectory = .documentDirectory
        #endif

        let persistenceDirURL = try? FileManager()
            .url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ditto-pos-demo")

        ditto = Ditto(identity: .onlinePlayground(
            appID: Env.DITTO_APP_ID,
            token: Env.DITTO_PLAYGROUND_TOKEN,
            enableDittoCloudSync: false,
            customAuthURL: URL(string: Env.DITTO_AUTH_URL)
        ), persistenceDirectory: persistenceDirURL)

        ditto.updateTransportConfig { transportConfig in
            transportConfig.connect.webSocketURLs.insert(Env.DITTO_WEBSOCKET_URL)
        }

        do {
            try ditto.disableSyncWithV3()
        } catch {
            print("ERROR: disableSyncWithV3() failed: \(error)")
        }

        Task {
            do {
                // strict mode off lets DQL use map/object CRDT semantics
                try await ditto.store.execute(query: "ALTER SYSTEM SET DQL_STRICT_MODE = false")
                let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                if !isPreview {
                    try ditto.sync.start()
                }
            } catch {
                print("ERROR: starting sync failed: \(error)")
            }
        }
    }

    /// Restart sync with the active location's sync group. Transport
    /// configuration changes only take effect at sync start, so we bounce it.
    func applySyncGroup(locationId: String) {
        ditto.sync.stop()
        setSyncGroup(locationId: locationId)
        do { try ditto.sync.start() } catch {
            print("Failed to restart sync: \(error)")
        }
    }

    /// Sets the sync group to the numeric location id so only devices at the
    /// same location form a peer-to-peer mesh.
    ///
    /// https://docs.ditto.live/sdk/latest/sync/creating-sync-groups
    func setSyncGroup(locationId: String) {
        guard let value = UInt32(locationId) else { return }
        ditto.updateTransportConfig { config in
            config.global.syncGroup = value
        }
    }
}
