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

extension JSONEncoder {
    static let ditto: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(DateFormatter.isoDate.string(from: date))
        }
        return e
    }()
}

extension JSONDecoder {
    static let ditto: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            guard let date = DateFormatter.isoDate.date(from: s) else {
                throw DecodingError.dataCorruptedError(
                    in: c,
                    debugDescription: "Invalid ISO 8601 date: \(s)"
                )
            }
            return date
        }
        return d
    }()
}

extension Encodable {
    /// Encode to a JSON string for passing to DQL `deserialize_json(:arg)`.
    func dittoJSONString() -> String {
        do {
            let data = try JSONEncoder.ditto.encode(self)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            fatalError("dittoJSONString: encoding \(Self.self) failed: \(error)")
        }
    }
}

// MARK: - Extensions of `execute`
extension DittoStore {

    // Emit with mapped objects as an array
    func executePublisher<T: Decodable>(query: String, arguments: [String: Any?]? = [:], mapTo: T.Type) -> AnyPublisher<[T], Error> {
        return Future { promise in
            Task.init {
                do {
                    let result = try await self.execute(query: query, arguments: arguments ?? [:])
                    let items = result.items.compactMap { item in
                        try? JSONDecoder.ditto.decode(T.self, from: item.jsonData())
                    }
                    promise(.success(items))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }

    // Emit with a mapped object as a single value instead of an array
    func executePublisher<T: Decodable>(query: String, arguments: [String: Any?]? = [:], mapTo: T.Type, onlyFirst: Bool) -> AnyPublisher<T?, Error> {
        return Future { promise in
            Task.init {
                do {
                    let result = try await self.execute(query: query, arguments: arguments ?? [:])
                    guard let first = result.items.first else { return promise(.success(nil)) }
                    let item = try? JSONDecoder.ditto.decode(T.self, from: first.jsonData())
                    promise(.success(item))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Extensions of `registerObserver`
extension DittoStore {

    // Send mapped objects as an array
    func observePublisher<T: Decodable>(query: String, arguments: [String: Any?]? = nil, deliverOn queue: DispatchQueue = .main, mapTo: T.Type) -> AnyPublisher<[T], Error> {
        let subject = PassthroughSubject<[T], Error>()

        do {
            try self.registerObserver(query: query, arguments: arguments, deliverOn: queue) { result in
                let items = result.items.compactMap { item in
                    try? JSONDecoder.ditto.decode(T.self, from: item.jsonData())
                }
                subject.send(items)
            }
        } catch {
            subject.send(completion: .failure(error))
        }

        return subject.eraseToAnyPublisher()
    }

    // Send a mapped object as a single value instead of an array
    func observePublisher<T: Decodable>(query: String, arguments: [String: Any?]? = nil, deliverOn queue: DispatchQueue = .main, mapTo: T.Type, onlyFirst: Bool) -> AnyPublisher<T?, Error> {
        let subject = PassthroughSubject<T?, Error>()

        do {
            try self.registerObserver(query: query, arguments: arguments, deliverOn: queue) { result in
                guard let first = result.items.first else { return subject.send(nil) }
                let item = try? JSONDecoder.ditto.decode(T.self, from: first.jsonData())
                subject.send(item)
            }
        } catch {
            subject.send(completion: .failure(error))
        }

        return subject.eraseToAnyPublisher()
    }
}
