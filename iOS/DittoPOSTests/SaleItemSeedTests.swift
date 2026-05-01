//
//  SaleItemSeedTests.swift
//  DittoPOSTests
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import XCTest
@testable import DittoPOS

final class SaleItemSeedTests: XCTestCase {

    func testEveryDemoLocationHasAtLeastOneMenuItem() {
        let items = SaleItemSeed.saleItemsForAllLocations()
        for location in LocationSeed.demoLocations {
            let perLocation = items.filter { $0.documentId.locationId == location.id }
            XCTAssertFalse(
                perLocation.isEmpty,
                "Location \(location.id) (\(location.name)) has no menu items"
            )
        }
    }

    func testCompositeIdsAreUniqueAcrossAllSeededItems() {
        let items = SaleItemSeed.saleItemsForAllLocations()
        let keys = items.map { "\($0.documentId.id)|\($0.documentId.locationId)" }
        XCTAssertEqual(
            keys.count,
            Set(keys).count,
            "Duplicate (id, locationId) pairs detected in seed data"
        )
    }

    func testEverySeededItemHasAPositivePrice() {
        for item in SaleItemSeed.saleItemsForAllLocations() {
            XCTAssertGreaterThan(
                item.price.amount,
                0,
                "Item \(item.name) (\(item.documentId.id)) at \(item.documentId.locationId) has non-positive cents"
            )
        }
    }
}
