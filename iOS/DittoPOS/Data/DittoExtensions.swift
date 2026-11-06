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

// Shared UTC precision keeps stored dates chronologically sortable across platforms.
enum DittoWireDate {
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
    func decode<T: Decodable>(decoder: JSONDecoder = .ditto) throws -> [T] {
        try items.map { try $0.decode(decoder: decoder) }
    }

    // One incomplete document must not hide the rest of the observed catalog/orders.
    func decodeOrSkip<T: Decodable>(decoder: JSONDecoder = .ditto) -> [T] {
        items.compactMap { try? $0.decode(decoder: decoder) }
    }
}

// MARK: - Combine wrappers

// Combine subjects lack Sendable; callbacks here are confined to the main queue.
private final class ObserverSubject<Output: Sendable>: @unchecked Sendable {
    let subject = CurrentValueSubject<Output?, Error>(nil)
}

// MARK: - Subscription error reporting

// A sync-registration failure must not disable independent local UI queries.
func reportSubscriptionFailure(_ context: String, _ error: Error) {
    print("⚠️ \(context): \(error.localizedDescription)")
}

extension DittoStore {
    // Hidden UI must release its native query; cache the first result to avoid losing it.
    // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
    func observePublisher<T: Decodable & Sendable>(
        query: String,
        arguments: [String: Any?]? = nil,
        mapTo: T.Type
    ) -> AnyPublisher<[T], Error> {
        Deferred { () -> AnyPublisher<[T], Error> in
            let subject = ObserverSubject<[T]>()
            do {
                let observer = try self.registerObserver(
                    query: query,
                    arguments: arguments,
                    deliverOn: .main,
                    handlerWithSignalNext: { result, signalNext in
                        let items: [T] = result.decodeOrSkip()
                        subject.subject.send(items)
                        signalNext()
                    }
                )
                return subject.subject.compactMap { $0 }
                    .handleEvents(receiveCancel: { observer.cancel() })
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
}
