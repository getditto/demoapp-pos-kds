//
//  SaleItemSeedTests.swift
//  DittoPOSTests
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import XCTest

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

    func testCompositeIDsAreUniqueAcrossSeededItems() {
        let ids = SaleItemSeed.saleItemsForAllLocations().map(\.documentId)
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
