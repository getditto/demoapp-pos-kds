//
//  DocumentID.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

// Composite Ditto document `_id`. Shared by Order and SaleItem.
//
// Why composite: `locationId` is the natural partitioning dimension for this
// app — every order and menu item belongs to exactly one location, and devices
// only sync the location(s) they care about. Putting `locationId` *inside*
// `_id` lets Ditto use it as the document's natural key for sync grouping
// and routing, and lets DQL filter by `_id.locationId` without a secondary
// index. The inner `id` keeps documents unique within their location.
struct DocumentID: Codable, Hashable {
    let id: String
    let locationId: String
}
