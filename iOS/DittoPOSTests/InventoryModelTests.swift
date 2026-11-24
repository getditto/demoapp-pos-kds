import Combine
import XCTest

@MainActor final class InventoryModelTests: XCTestCase {
    private let id = DocumentID(id: "coffee", locationId: "A")
    private enum Command: Equatable { case increment(Int64, DocumentID), restart(Int64, DocumentID) }

    func testInvalidAndCanceledDraftsNeverWriteAndDuplicateDoneRestartsOnlyOnce() async throws {
        let item = SaleItem(documentId: id, name: "Coffee", price: Price(cents: 195), quantity: 2)
        var commands: [Command] = []
        let started = expectation(description: "Restart reached the production command boundary")
        var completion: CheckedContinuation<Void, Never>?
        let model = InventoryModel(observe: { _ in Just([item]).eraseToAnyPublisher() }, increment: {
            commands.append(.increment($0, $1))
            started.fulfill()
        }, restart: { value, id in
            commands.append(.restart(value, id))
            started.fulfill()
            await withCheckedContinuation { completion = $0 }
        })
        model.setLocation("A"); model.setVisible(true)
        for text in ["", "-1", "1.5", " 2", "+2", "1e3", "9223372036854775808"] {
            model.beginEditing(id); model.updateText(text)
            XCTAssertNotNil(model.state.edit?.error, text)
            try await model.submit()
            XCTAssertEqual(model.state.edit?.text, text)
        }
        XCTAssertTrue(commands.isEmpty)
        model.updateText("12"); model.cancelEditing()
        try await model.submit()
        XCTAssertTrue(commands.isEmpty)
        model.beginEditing(id); model.updateText("0")
        let firstDone = Task { try await model.submit() }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertNil(model.state.edit)
        if model.state.edit == nil { try await model.submit() }
        XCTAssertEqual(commands, [.restart(0, id)])
        XCTAssertNil(model.state.edit)
        completion?.resume()
        try await firstDone.value
    }

    func testSignedStepsRespectEditingAndLatestObservedStockWithoutReplacingTheDraft() async throws {
        let item = SaleItem(documentId: id, name: "Coffee", price: Price(cents: 195), quantity: 2)
        let observed = CurrentValueSubject<[SaleItem], Never>([item])
        var commands: [Command] = []
        let model = InventoryModel(observe: { _ in observed.eraseToAnyPublisher() }, increment: { commands.append(.increment($0, $1)) }, restart: { commands.append(.restart($0, $1)) })
        model.setLocation("A"); model.setVisible(true)
        try await model.step(-1, id: id)
        try await model.step(1, id: id)
        model.beginEditing(id); model.updateText("6")
        try await model.step(1, id: id)
        observed.send([SaleItem(documentId: id, name: item.name, price: item.price, quantity: -2)])
        XCTAssertEqual(model.state.items.first?.quantity, -2)
        XCTAssertEqual(model.state.edit?.text, "6")
        model.cancelEditing()
        try await model.step(-1, id: id)
        try await model.step(1, id: id)
        try await model.step(1, id: DocumentID(id: id.id, locationId: "B"))
        model.setVisible(false)
        try await model.step(1, id: id)
        XCTAssertEqual(commands, [.increment(-1, id), .increment(1, id), .increment(1, id)])
    }
}
