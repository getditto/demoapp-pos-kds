import XCTest

final class InventoryRowViewModelTests: XCTestCase {
    func testQuantityFieldGrowsForDigitsAndTextScalingWithoutDisplacingRowControls() {
        let item = SaleItem(documentId: DocumentID(id: "coffee", locationId: "A"), name: "Coffee", price: Price(cents: 195), quantity: 2)
        func width(_ text: String, scale: CGFloat = 1) -> CGFloat {
            InventoryRowViewModel(item: item, activeEdit: QuantityEdit(id: item.documentId, text: text), scaledDigitWidth: InventoryRowViewModel.digitWidth * scale).quantityWidth
        }
        XCTAssertEqual(width(""), width("0"))
        XCTAssertGreaterThan(width("123456"), width("0"))
        XCTAssertGreaterThan(width("123456", scale: 2), width("123456"))
        XCTAssertEqual(width(String(Int64.max)), width(String(repeating: "9", count: 100)))
        XCTAssertLessThanOrEqual(width(String(repeating: "9", count: 100), scale: 3), 144)
    }
}
