//
//  DocumentID.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

// Composite Ditto document `_id`. Shared by Order and SaleItem; same shape
// (a stable id within a location scope) lets sync subscriptions filter on
// `_id.locationId`.
struct DocumentID: Codable, Hashable {
    let id: String
    let locationId: String
}
