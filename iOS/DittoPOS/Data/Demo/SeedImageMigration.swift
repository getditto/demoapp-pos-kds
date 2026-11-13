import DittoSwift
import Foundation

// Consuming the legacy field makes repeated observations safe without a global migration flag.
// https://docs.ditto.live/dql/update
struct SeedImageMigration {
    private struct CatalogInput: Decodable {
        let documentId: DocumentID
        let needsPhoto: Bool
        enum CodingKeys: String, CodingKey { case documentId = "_id", needsPhoto }
    }

    private struct OrderInput: Decodable {
        let documentId: DocumentID
        let cart: [String: LineInput]
        enum CodingKeys: String, CodingKey { case documentId = "_id", cart }
    }

    private struct LineInput: Decodable {
        let saleItemId: String
        let hasLegacyName: Bool
        let needsPhoto: Bool
        enum CodingKeys: String, CodingKey { case saleItemId, imageName, image }
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            saleItemId = try values.decode(String.self, forKey: .saleItemId)
            hasLegacyName = values.contains(.imageName)
            needsPhoto = !values.contains(.image)
        }
    }

    private struct Target: Sendable {
        let documentId: DocumentID
        let lineId: String?
        let sourceId: DocumentID
        let needsPhoto: Bool
    }

    static func prepareCatalog(_ items: [SaleItem], locationId: String, store: DittoStore) async throws -> [SaleItem] {
        let inputs = try await store.execute(
            query: """
                SELECT _id, image IS MISSING AS needsPhoto FROM sale_items
                WHERE _id.locationId = :locationId AND imageName IS NOT MISSING
                """, arguments: ["locationId": locationId])
        let rows: [CatalogInput] = try inputs.decode()
        let targets = rows.map { Target(documentId: $0.documentId, lineId: nil, sourceId: $0.documentId, needsPhoto: $0.needsPhoto) }
        let stockNeedsUpgrade = SeedStockMigration.mayNeedUpgrade(items)
        guard stockNeedsUpgrade || !targets.isEmpty else { return items }
        let photos = try await attachments(for: targets, store: store)
        return try await store.transaction { transaction in
            if stockNeedsUpgrade { try await SeedStockMigration.upgrade(locationId: locationId, transaction: transaction) }
            try await apply(targets, photos: photos, transaction: transaction)
            let current = try await transaction.execute(query: SaleItemsRepository.catalogQuery, arguments: ["locationId": locationId])
            return current.decodeOrSkip()
        }
    }

    static func prepareOrders(_ orders: [Order], store: DittoStore) async throws -> [Order] {
        guard !orders.isEmpty else { return orders }
        var targets: [Target] = []
        for location in Set(orders.map { $0.documentId.locationId }).sorted() {
            let ids = orders.filter { $0.documentId.locationId == location }.map { $0.documentId.id }
            let request = orderQuery(ids: ids, locationId: location, projection: "_id, cart")
            let result = try await store.execute(query: request.query, arguments: request.arguments)
            let rows: [OrderInput] = try result.decode()
            for row in rows {
                for (lineId, line) in row.cart where line.hasLegacyName {
                    targets.append(Target(documentId: row.documentId, lineId: lineId,
                                          sourceId: DocumentID(id: line.saleItemId, locationId: location), needsPhoto: line.needsPhoto))
                }
            }
        }
        guard !targets.isEmpty else { return orders }
        let preparedTargets = targets
        let photos = try await attachments(for: targets, store: store)
        return try await store.transaction { transaction in
            try await apply(preparedTargets, photos: photos, transaction: transaction)
            var current: [DocumentID: Order] = [:]
            for location in Set(orders.map { $0.documentId.locationId }).sorted() {
                let request = orderQuery(ids: orders.filter { $0.documentId.locationId == location }.map { $0.documentId.id },
                                         locationId: location, projection: "*")
                let result = try await transaction.execute(query: request.query, arguments: request.arguments)
                let rows: [Order] = result.decodeOrSkip()
                for row in rows { current[row.documentId] = row }
            }
            return orders.compactMap { current[$0.documentId] }
        }
    }

    static func upgradeAll(store: DittoStore) async throws {
        for location in LocationSeed.demoLocations {
            let catalog = try await store.execute(query: SaleItemsRepository.catalogQuery, arguments: ["locationId": location.id])
            let items: [SaleItem] = catalog.decodeOrSkip()
            _ = try await prepareCatalog(items, locationId: location.id, store: store)
            let result = try await store.execute(query: "SELECT * FROM pos_orders WHERE _id.locationId = :locationId", arguments: ["locationId": location.id])
            let orders: [Order] = result.decodeOrSkip()
            _ = try await prepareOrders(orders, store: store)
        }
    }

    private static func attachments(for targets: [Target], store: DittoStore) async throws -> [String: DittoAttachment] {
        var photos: [String: DittoAttachment] = [:]
        for target in targets where target.needsPhoto && photos[target.sourceId.id] == nil {
            guard let data = try StockPhotos.data(for: target.sourceId) else { continue }
            photos[target.sourceId.id] = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: store)
        }
        return photos
    }

    private static func apply(_ targets: [Target], photos: [String: DittoAttachment], transaction: DittoTransaction) async throws {
        for target in targets {
            var arguments: [String: Any?] = ["id": target.documentId.id, "locationId": target.documentId.locationId]
            let collection: String
            let path: String
            let definition: String
            let identity: String
            if let lineId = target.lineId {
                collection = "pos_orders"
                let line = dqlIdentifier(lineId)
                path = "cart.\(line)."
                definition = "cart MAP(\(line) MAP(image ATTACHMENT))"
                arguments["saleItemId"] = target.sourceId.id
                identity = " AND \(path)saleItemId = :saleItemId"
            } else {
                collection = "sale_items"
                path = ""
                definition = "image ATTACHMENT"
                identity = ""
            }
            let predicate = "_id.id = :id AND _id.locationId = :locationId AND \(path)imageName IS NOT MISSING\(identity)"
            if target.needsPhoto, StockPhotos.resource(for: target.sourceId) != nil, let photo = photos[target.sourceId.id] {
                arguments["image"] = photo
                try await transaction.execute(
                    query: "UPDATE COLLECTION \(collection) (\(definition)) SET \(path)image = :image WHERE \(predicate) AND \(path)image IS MISSING",
                    arguments: arguments)
            }
            try await transaction.execute(query: "UPDATE \(collection) UNSET \(path)imageName WHERE \(predicate)", arguments: arguments)
        }
    }

    private static func orderQuery(ids: [String], locationId: String, projection: String) -> (query: String, arguments: [String: Any?]) {
        var arguments: [String: Any?] = ["locationId": locationId]
        let predicates = ids.enumerated().map { index, id in
            let key = "order\(index)"
            arguments[key] = id
            return "_id.id = :\(key)"
        }.joined(separator: " OR ")
        return ("SELECT \(projection) FROM pos_orders WHERE _id.locationId = :locationId AND (\(predicates))", arguments)
    }
}
