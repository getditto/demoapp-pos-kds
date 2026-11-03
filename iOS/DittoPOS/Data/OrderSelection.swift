enum OrderSelection {
    static func observedOrder(id: String?, locationId: String?, in orders: [Order]) -> Order? {
        guard let id, let locationId else { return nil }
        return orders.first { $0.documentId.id == id && $0.documentId.locationId == locationId }
    }
}
