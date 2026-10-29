//
//  DittoExtensions.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

// MARK: - JSON encoding / decoding

/// Canonical ISO 8601 wire format used across iOS and Android:
/// `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'` (UTC, millisecond precision, `Z` suffix).
/// Ditto stores timestamps as opaque strings, so the format has to match
/// across producers for lexicographic comparison to equal chronological order
/// in DQL filters like `WHERE createdAt > :TTL`.
enum DittoWireDate {
    // DateFormatter is Sendable and safe to share across threads, unlike
    // ISO8601DateFormatter. en_US_POSIX + UTC pins the exact wire format.
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }

    static func date(from string: String) throws -> Date {
        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "invalid ISO 8601 date: \(string)")
            )
        }
        return date
    }
}

extension JSONEncoder {
    static var ditto: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(DittoWireDate.string(from: date))
        }
        return encoder
    }
}

extension JSONDecoder {
    static var ditto: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            return try DittoWireDate.date(from: raw)
        }
        return decoder
    }
}

extension Encodable {
    /// Encode to a JSON string for passing to DQL `deserialize_json(:arg)`.
    func dittoJSONString() throws -> String {
        let data = try JSONEncoder.ditto.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

extension DittoQueryResultItem {
    func decode<T: Decodable>(decoder: JSONDecoder = .ditto) throws -> T {
        defer { dematerialize() }
        return try decoder.decode(T.self, from: jsonData())
    }
}

extension DittoQueryResult {
    /// Decodes every item; throws on any failure. Use when you need all-or-nothing.
    func decode<T: Decodable>(decoder: JSONDecoder = .ditto) throws -> [T] {
        try items.map { try $0.decode(decoder: decoder) }
    }

    /// Decodes every item, silently dropping any that fail. Use for observers
    /// where one bad document shouldn't blank the rest.
    func decodeOrSkip<T: Decodable>(decoder: JSONDecoder = .ditto) -> [T] {
        items.compactMap { try? $0.decode(decoder: decoder) }
    }
}

// MARK: - Combine wrappers

// Ditto calls the @Sendable handler on the delivery queue (serial; main by
// default), so sends never overlap. Combine does not declare the subject Sendable.
private final class ObserverSubject<Output>: @unchecked Sendable {
    let subject = PassthroughSubject<Output, Error>()
}

// MARK: - Subscription error reporting

/// Consistent handling for a failed sync-subscription registration: logs in
/// every build (never silent) and traps in Debug. Mirrors Android's
/// `reportSubscriptionFailure`.
func reportSubscriptionFailure(_ context: String, _ error: Error) {
    print("⚠️ \(context): \(error.localizedDescription)")
    assertionFailure("\(context): \(error.localizedDescription)")
}

extension DittoStore {
    /// Uses Ditto's `handlerWithSignalNext` overload so we can apply
    /// backpressure: `signalNext()` is called only after `subject.send(...)`
    /// completes. With a non-buffered downstream this gates Ditto's next
    /// delivery on consumer readiness; with `PassthroughSubject` the
    /// difference is small but the pattern is the canonical one.
    func observePublisher<T: Decodable & Sendable>(
        query: String,
        arguments: [String: Any?]? = nil,
        deliverOn queue: DispatchQueue = .main,
        mapTo: T.Type
    ) -> AnyPublisher<[T], Error> {
        let subject = ObserverSubject<[T]>()
        do {
            try self.registerObserver(
                query: query,
                arguments: arguments,
                deliverOn: queue,
                handlerWithSignalNext: { result, signalNext in
                    // Decode first; signalNext only after the consumer has the
                    // decoded payload so Ditto's next delivery is gated on us
                    // having actually finished this one.
                    let items: [T] = result.decodeOrSkip()
                    subject.subject.send(items)
                    signalNext()
                }
            )
        } catch {
            subject.subject.send(completion: .failure(error))
        }
        return subject.subject.eraseToAnyPublisher()
    }
}
