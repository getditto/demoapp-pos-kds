import DittoSwift
import SwiftUI

struct OrderLinePhotoView: View {
    let line: CartLineItem
    let orderID: DocumentID
    let store: DittoStore

    var body: some View {
        ProductPhotoView(reference: line.image, owner: orderID, store: store)
    }
}
