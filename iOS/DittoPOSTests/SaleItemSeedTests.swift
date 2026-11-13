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

    func testInitialDocumentsMatchThePinnedLegacySeederExactly() throws {
        // Different INITIAL payloads for one ID have undefined merge behavior.
        // https://docs.ditto.live/dql/insert#insert-with-initial-documents
        let old = LegacySaleItemSeed.saleItemsForAllLocations()
        let current = SaleItemSeed.initialDocuments()
        XCTAssertEqual(current.count, old.count)
        for (current, old) in zip(current, old) {
            let actual = try JSONSerialization.jsonObject(with: JSONEncoder.ditto.encode(current)) as? NSDictionary
            let expected = try JSONSerialization.jsonObject(with: JSONEncoder.ditto.encode(old)) as? NSDictionary
            XCTAssertEqual(actual, expected)
        }
    }
}
