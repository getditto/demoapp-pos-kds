import AppUI
import Combine
import SwiftUI
import UIKit
import XCTest

@MainActor final class InventoryPresentationTests: XCTestCase {
    func testLargeTextQuantityEditorKeepsItsFullLineVisible() async throws {
        let item = SaleItem(documentId: DocumentID(id: "coffee", locationId: "A"), name: "Coffee", price: Price(cents: 195), quantity: Int64.max)
        let model = InventoryModel(observe: { _ in Just([item]).eraseToAnyPublisher() }, increment: { _, _ in }, restart: { _, _ in })
        model.setLocation("A"); model.setVisible(true)
        defer { model.setVisible(false) }
        let host = UIHostingController(rootView: BrandTheme {
            InventoryContent(inventory: model) { _ in Color.clear }
        }.environment(\.dynamicTypeSize, .accessibility5))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let parent = try XCTUnwrap(scene.windows.first { $0.isKeyWindow }?.rootViewController)
        parent.addChild(host)
        parent.setOverrideTraitCollection(UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge), forChild: host)
        host.view.frame = parent.view.bounds
        parent.view.addSubview(host.view)
        host.didMove(toParent: parent)
        defer {
            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
        }
        model.beginEditing(item.documentId)
        var field: UITextField?
        for _ in 0..<100 {
            host.view.layoutIfNeeded()
            field = numberField(in: host.view)
            if let field, field.bounds.height > 0 { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        let editor = try XCTUnwrap(field)
        let font = try XCTUnwrap(editor.font)
        XCTAssertGreaterThan(font.pointSize, 17)
        XCTAssertEqual(editor.text, String(Int64.max))
        XCTAssertGreaterThanOrEqual(editor.bounds.height, font.lineHeight, "Quantity editor clips its scaled line: frame=\(editor.bounds), font=\(font)")
    }

    private func numberField(in view: UIView) -> UITextField? {
        if let field = view as? UITextField { return field }
        return view.subviews.lazy.compactMap(numberField).first
    }
}
