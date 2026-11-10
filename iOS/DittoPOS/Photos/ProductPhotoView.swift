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
        self.reference = reference
        self.owner = owner
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
        _loader = StateObject(wrappedValue: PhotoLoader(store: store))
    }

    var body: some View {
        DittoPhoto(image: loader.image(matching: reference).map(Image.init(uiImage:)), contentMode: contentMode, cornerRadius: cornerRadius)
            .onAppear { loader.update(reference, owner: owner) }
            .onChange(of: reference?.id) { _ in loader.update(reference, owner: owner) }
            .onChange(of: owner) { _ in loader.update(reference, owner: owner) }
            .onDisappear { loader.stop() }
    }
}
