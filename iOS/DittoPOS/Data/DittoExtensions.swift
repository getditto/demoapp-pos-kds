//
//  DittoExtensions.swift
//  DittoPOS
//
//  Created by Shunsuke Kondo on 2023/12/28.
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

// MARK: - JSON encoding / decoding

enum DittoDateFormatting {
    static let iso8601: Date.ISO8601FormatStyle = .ditto
}

extension Date.ISO8601FormatStyle {
    static var ditto: Date.ISO8601FormatStyle {
        .iso8601
            .year().month().day()
            .timeZone(separator: .omitted)
            .time(includingFractionalSeconds: true)
            .timeSeparator(.colon)
    }
}

extension JSONEncoder {
    static var ditto: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(DittoDateFormatting.iso8601))
        }
        return encoder
    }
}

extension JSONDecoder {
    static var ditto: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            return try DittoDateFormatting.iso8601.parse(raw)
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

extension DittoStore {
    /// Uses Ditto's `handlerWithSignalNext` overload so we can apply
    /// backpressure: `signalNext()` is called only after `subject.send(...)`
    /// completes. With a non-buffered downstream this gates Ditto's next
    /// delivery on consumer readiness; with `PassthroughSubject` the
    /// difference is small but the pattern is the canonical one.
    func observePublisher<T: Decodable>(
        query: String,
        arguments: [String: Any?]? = nil,
        deliverOn queue: DispatchQueue = .main,
        mapTo: T.Type
    ) -> AnyPublisher<[T], Error> {
        let subject = PassthroughSubject<[T], Error>()
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
                    subject.send(items)
                    signalNext()
                }
            )
        } catch {
            subject.send(completion: .failure(error))
        }
        return subject.eraseToAnyPublisher()
    }
}
