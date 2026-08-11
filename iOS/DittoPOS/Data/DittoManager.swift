//
//  DittoManager.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

/// Owns the `Ditto` instance and starts sync. Holds the transport-level
/// sync group driven by the currently active location. Mirrors Android's
/// `DittoManager` (in the `ditto-wrapper` module).
final class DittoManager: ObservableObject {
    static var shared = DittoManager()
    let ditto: Ditto

    private init() {
        let directory: FileManager.SearchPathDirectory = .documentDirectory

        let persistenceDirURL = try? FileManager()
            .url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ditto-pos-demo")

        precondition(!Env.DITTO_DATABASE_ID.isEmpty, "DITTO_DATABASE_ID is missing. Set it in .env before building.")
        precondition(!Env.DITTO_DEVELOPMENT_TOKEN.isEmpty, "DITTO_DEVELOPMENT_TOKEN is missing. Set it in .env before building.")
        guard let serverURL = URL(string: Env.DITTO_SERVER_URL), serverURL.scheme == "https" else {
            fatalError("DITTO_SERVER_URL must be an https:// URL (the v5 portal \"Connect via SDK\" URL): \"\(Env.DITTO_SERVER_URL)\"")
        }

        DittoLogger.minimumLogLevel = .debug

        // Configure → Initialize → Authenticate → Sync. The server URL is the
        // portal's "Connect via SDK" URL. Strict mode defaults to off, giving
        // DQL map/object CRDT semantics.
        // https://docs.ditto.live/sdk/latest/ditto-config
        let config = DittoConfig(
            databaseID: Env.DITTO_DATABASE_ID,
            connect: .server(url: serverURL),
            persistenceDirectory: persistenceDirURL
        )

        do {
            ditto = try Ditto.openSync(config: config)
        } catch {
            fatalError("Failed to open Ditto: \(error)")
        }

        // Authenticate before sync starts: provide a fresh token whenever the
        // current one is missing or near expiry.
        ditto.auth?.expirationHandler = { ditto, _ in
            ditto.auth?.login(token: Env.DITTO_DEVELOPMENT_TOKEN, provider: .development) { _, error in
                if let error {
                    print("ERROR: Ditto auth login failed: \(error)")
                }
            }
        }

        Task {
            let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            if !isPreview {
                do {
                    try ditto.sync.start()
                } catch {
                    print("ERROR: starting sync failed: \(error)")
                }
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

    /// Reset the sync group back to the default (0) when no location is active,
    /// so the device leaves its per-location mesh. Bounces sync like
    /// `applySyncGroup`, since transport changes only take effect at sync start.
    func resetSyncGroup() {
        ditto.sync.stop()
        ditto.updateTransportConfig { config in
            config.global.syncGroup = 0
        }
        do { try ditto.sync.start() } catch {
            print("Failed to restart sync: \(error)")
        }
    }
}
