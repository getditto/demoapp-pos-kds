import DittoSwift
import DittoUI
import SwiftUI

struct ProductPhotoView: View {
    let reference: PhotoReference?
    let owner: DocumentID
    var contentMode: ContentMode = .fit
    var cornerRadius: CGFloat = 8
    @StateObject private var loader: PhotoLoader

    init(reference: PhotoReference?, owner: DocumentID, store: DittoStore, contentMode: ContentMode = .fit, cornerRadius: CGFloat = 8) {
        self.init(reference: reference, owner: owner, loader: PhotoLoader(store: store), contentMode: contentMode, cornerRadius: cornerRadius)
    }

    init(reference: PhotoReference?, owner: DocumentID, loader: PhotoLoader, contentMode: ContentMode = .fit, cornerRadius: CGFloat = 8) {
        self.reference = reference
        self.owner = owner
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
        _loader = StateObject(wrappedValue: loader)
    }

    var body: some View {
        DittoPhoto(image: loader.image(matching: reference).map(Image.init(uiImage:)), contentMode: contentMode, cornerRadius: cornerRadius)
            .task(id: Input(owner: owner, referenceID: reference?.id)) {
                guard !Task.isCancelled else { return }
                loader.update(reference, owner: owner)
            }
            .onDisappear { loader.stop() }
    }

    private struct Input: Hashable {
        let owner: DocumentID
        let referenceID: String?
    }
}
