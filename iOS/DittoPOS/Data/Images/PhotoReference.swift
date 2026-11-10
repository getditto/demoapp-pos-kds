import Foundation

struct PhotoReference: Decodable, Hashable, Sendable {
    let id: String
    let len: UInt64
    let metadata: [String: String]

    var token: [String: Any] { ["id": id, "len": len, "metadata": metadata] }
}
