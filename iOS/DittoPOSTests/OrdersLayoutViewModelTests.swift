import AppUI
import XCTest

final class OrdersLayoutViewModelTests: XCTestCase {
    func testOrderColumnsReflowForPhoneAndAccessibilityTextThenReturnToWideLayout() {
        let widths: [CGFloat] = [393, 1200, 1200, 393, 1200]
        let accessibilityText = [false, false, true, true, false]
        let layouts = zip(widths, accessibilityText).map { width, largeText in
            AppOrderSummaryViewModel(expanded: AppOrderSummaryViewModel.supportsColumns(availableWidth: width),
                                     accessibilityText: largeText).usesColumns
        }
        XCTAssertEqual(layouts, [false, true, false, false, true])
    }
}
