import Combine
import DittoSwift
import Foundation
import SwiftUI
import UIKit
import XCTest

@MainActor final class PhotoLoaderTests: XCTestCase {
    private let owner = DocumentID(id: "coffee", locationId: "A")
    private let a = PhotoReference(id: "A", len: 1, metadata: [:])
    private let b = PhotoReference(id: "B", len: 1, metadata: [:])

    func testReferenceAndOwnerChangesCancelAndRejectObsoleteCompletions() {
        let source = ControlledPhotos()
        let loader = PhotoLoader(cache: PhotoImageCache(), fetch: source.fetch)
        loader.update(a, owner: owner)
        loader.update(a, owner: owner)
        XCTAssertEqual(source.requests.count, 1)
        loader.update(b, owner: owner)
        XCTAssertEqual(source.canceled, [0])
        source.requests[1].complete(PhotoTestImages.png(.blue))
        let current = loader.image
        XCTAssertNotNil(current)
        XCTAssertNil(loader.image(matching: a))
        XCTAssertTrue(loader.image(matching: b) === current)
        source.requests[0].complete(PhotoTestImages.png(.red))
        XCTAssertTrue(loader.image === current)
        loader.update(nil, owner: owner)
        XCTAssertNil(loader.image)
        XCTAssertEqual(source.canceled, [0, 1])
        loader.update(a, owner: owner)
        loader.update(a, owner: DocumentID(id: owner.id, locationId: "B"))
        XCTAssertEqual(source.canceled, [0, 1, 2])
        source.requests[2].complete(PhotoTestImages.png(.red))
        XCTAssertNil(loader.image)
        loader.stop()
        source.requests[3].complete(PhotoTestImages.png(.red))
        XCTAssertNil(loader.image)
        XCTAssertEqual(source.canceled, [0, 1, 2, 3])
    }

    func testCachedImagesSurviveOfflineReuseAndCorruptDataUsesThePlaceholder() {
        let source = ControlledPhotos()
        let loader = PhotoLoader(cache: PhotoImageCache(), fetch: source.fetch)
        loader.update(a, owner: owner)
        source.requests[0].complete(PhotoTestImages.png(.red))
        let cached = loader.image
        loader.stop()
        loader.update(a, owner: DocumentID(id: "other", locationId: "B"))
        XCTAssertTrue(loader.image === cached)
        XCTAssertEqual(source.requests.count, 1)
        loader.update(b, owner: owner)
        XCTAssertNil(loader.image)
        source.requests[1].complete(Data("corrupt".utf8))
        XCTAssertNil(loader.image)
        source.requests[1].complete(nil)
        XCTAssertNil(loader.image)
        loader.update(a, owner: owner)
        XCTAssertTrue(loader.image === cached)
        loader.stop()
    }

    func testObservedCatalogDrivesPhotoViewReplacementReuseRemovalAndVisibility() async throws {
        try await TestDitto.withInstance { ditto in
            let source = ControlledPhotos()
            let loader = PhotoLoader(cache: PhotoImageCache(), fetch: source.fetch)
            let state = PhotoViewState(owner: owner)
            let repository = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            try await repository.create(SaleItemCreation(metadata: SaleItemMetadata(documentId: owner, name: "Coffee", price: Price(cents: 199)), initialQuantity: 2))
            let observation = repository.observeLocationSaleItems(owner.locationId).sink { state.item = $0.first }
            defer { observation.cancel() }
            let host = UIHostingController(rootView: ObservedPhoto(state: state, loader: loader))
            let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
            let window = try XCTUnwrap(scene.windows.first { $0.isKeyWindow })
            let root = try XCTUnwrap(window.rootViewController)
            root.addChild(host)
            host.view.frame = root.view.bounds
            root.view.addSubview(host.view)
            host.didMove(toParent: root)
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            XCTAssertTrue(host.view.window === window)
            defer {
                host.willMove(toParent: nil)
                host.view.removeFromSuperview()
                host.removeFromParent()
            }
            try await waitForView(host.view) { scene.activationState == .foregroundActive }
            try await waitForView(host.view) { state.appeared }

            let a = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.red), mimeType: "image/png", store: ditto.store)
            let b = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: ditto.store)
            try await PhotoAttachments.replace(a, for: owner, executor: ditto.store)
            try await waitForView(host.view) { state.item?.image?.id == a.id }
            try await waitForView(host.view) { state.renderedReference == a.id }
            try await waitForView(host.view) { !source.requests.isEmpty }
            XCTAssertEqual(source.requests.count, 1)
            XCTAssertEqual(source.requests.first?.reference.id, a.id)
            try await repository.increment(1, id: owner)
            try await waitForView(host.view) { state.item?.quantity == 3 }
            XCTAssertEqual(source.requests.count, 1)
            try await PhotoAttachments.replace(b, for: owner, executor: ditto.store)
            try await waitForView(host.view) { source.requests.count == 2 }
            XCTAssertEqual(source.requests.last?.reference.id, b.id)
            XCTAssertEqual(source.canceled, [0])
            try await PhotoAttachments.remove(for: owner, executor: ditto.store)
            try await waitForView(host.view) { source.canceled == [0, 1] }
            XCTAssertNil(loader.image)
            try await PhotoAttachments.replace(a, for: owner, executor: ditto.store)
            try await waitForView(host.view) { source.requests.count == 3 }
            state.owner = DocumentID(id: owner.id, locationId: "B")
            try await waitForView(host.view) { source.requests.count == 4 }
            XCTAssertEqual(source.canceled, [0, 1, 2])
            state.visible = false
            try await waitForView(host.view) { source.canceled == [0, 1, 2, 3] }
            state.visible = true
            try await waitForView(host.view) { source.requests.count == 5 }
            state.visible = false
            try await waitForView(host.view) { source.canceled == [0, 1, 2, 3, 4] }
        }
    }

    private func waitForView(_ view: UIView, file: StaticString = #filePath, line: UInt = #line, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(5)
        while !condition(), Date() < deadline {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
        guard condition() else {
            XCTFail("The observed photo view did not update", file: file, line: line)
            throw ViewWaitFailure.timedOut
        }
    }

    private enum ViewWaitFailure: Error { case timedOut }

    func testSDKFileAvailabilityUpdatesTheImageWithoutAnotherDocumentResultAndStopReleasesTheFetcher() async throws {
        try await TestDitto.withInstance { origin in
            let data = PhotoTestImages.png(.red)
            let attachment = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: origin.store)
            let reference = PhotoAttachments.reference(to: attachment)
            try await TestDitto.withInstance { receiver in
                try await receive(reference, store: receiver.store)
                let loader = PhotoLoader(store: receiver.store)
                defer { loader.stop() }
                loader.update(reference, owner: owner)
                XCTAssertNil(loader.image)
                XCTAssertEqual(receiver.store.attachmentFetchers.count, 1)
                let ready = expectation(description: "File availability updates the current photo")
                let observation = loader.$image.compactMap { $0 }.prefix(1).sink { _ in ready.fulfill() }
                defer { observation.cancel() }
                let local = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: receiver.store)
                XCTAssertEqual(local.id, attachment.id)
                await fulfillment(of: [ready], timeout: 5)
                XCTAssertNotNil(loader.image)
                loader.stop()
                XCTAssertTrue(receiver.store.attachmentFetchers.isEmpty)
                let missing = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: origin.store)
                let missingReference = PhotoAttachments.reference(to: missing)
                try await receive(missingReference, store: receiver.store)
                loader.update(missingReference, owner: owner)
                XCTAssertEqual(receiver.store.attachmentFetchers.count, 1)
                loader.stop()
                XCTAssertTrue(receiver.store.attachmentFetchers.isEmpty)
            }
        }
    }

    private func receive(_ reference: PhotoReference, store: DittoStore) async throws {
        // A received document introduces the token before its separately transferred file.
        try await store.execute(
            query: "INSERT INTO sale_items INITIAL DOCUMENTS (:document)",
            arguments: ["document": ["_id": ["id": owner.id, "locationId": owner.locationId]]]
        )
        try await store.execute(
            query: "UPDATE COLLECTION sale_items (image ATTACHMENT) SET image = :image WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": owner.id, "locationId": owner.locationId, "image": reference.token]
        )
    }
}

@MainActor private final class PhotoViewState: ObservableObject {
    @Published var item: SaleItem?
    @Published var owner: DocumentID
    @Published var visible = true
    @Published var appeared = false
    @Published var renderedReference: String?

    init(owner: DocumentID) { self.owner = owner }
}

private struct ObservedPhoto: View {
    @ObservedObject var state: PhotoViewState
    let loader: PhotoLoader

    var body: some View {
        if state.visible {
            ProductPhotoView(reference: state.item?.image, owner: state.owner, loader: loader)
                .frame(width: 40, height: 40)
                .onAppear { state.appeared = true }
                .onChange(of: state.item?.image?.id) { state.renderedReference = $0 }
        }
    }
}

@MainActor private final class ControlledPhotos {
    struct Request {
        let reference: PhotoReference
        let complete: @MainActor @Sendable (Data?) -> Void
    }
    var requests: [Request] = []
    var canceled: [Int] = []

    func fetch(_ reference: PhotoReference, completion: @escaping @MainActor @Sendable (Data?) -> Void) -> () -> Void {
        let index = requests.count
        requests.append(Request(reference: reference, complete: completion))
        return { self.canceled.append(index) }
    }
}
