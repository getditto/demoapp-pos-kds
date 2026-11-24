import XCTest

final class OrderSummaryViewModelTests: XCTestCase {
    func testOrderColumnsReflowForPhoneAndAccessibilityTextThenReturnToWideLayout() throws {
        let order = try OrderFixture.load()
        let widths: [CGFloat] = [393, 1200, 1200, 393, 1200]
        let accessibilityText = [false, false, true, true, false]
        let layouts = zip(widths, accessibilityText).map { width, largeText in
            OrderSummaryViewModel(order: order, availableWidth: width,
                                     accessibilityText: largeText).usesColumns
        }
        XCTAssertEqual(layouts, [false, true, false, false, true])
    }
}
