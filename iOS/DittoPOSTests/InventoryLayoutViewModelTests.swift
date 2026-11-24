import AppUI
import XCTest

final class InventoryLayoutViewModelTests: XCTestCase {
    func testQuantityFieldGrowsForDigitsAndTextScalingWithoutDisplacingRowControls() {
        func width(_ text: String, scale: CGFloat = 1) -> CGFloat {
            AppQuantityFieldViewModel(text: text, scaledDigitWidth: AppQuantityFieldViewModel.digitWidth * scale).width
        }
        XCTAssertEqual(width(""), width("0"))
        XCTAssertGreaterThan(width("123456"), width("0"))
        XCTAssertGreaterThan(width("123456", scale: 2), width("123456"))
        XCTAssertEqual(width(String(Int64.max)), width(String(repeating: "9", count: 100)))
        XCTAssertLessThanOrEqual(width(String(repeating: "9", count: 100), scale: 3), 144)
    }
}
