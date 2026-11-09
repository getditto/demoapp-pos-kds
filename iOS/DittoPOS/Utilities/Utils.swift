//
//  Utils.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

extension UIScreen {
    static var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }
    static var isPortrait: Bool {
        UIScreen.main.bounds.width < UIScreen.main.bounds.height
    }
}

extension View {
    func divider(_ color: Color = .gray) -> some View {
        color.frame(height: 1 / UIScreen.main.scale)
    }
}

extension Color {
    static let gray5 = Color("AppGray5", bundle: .main)
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
// View modifier to track rotation and call an action
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// https://www.swiftbysundell.com/articles/reducers-in-swift/
extension Sequence {
    func sum<T: Numeric>(_ keyPath: KeyPath<Element, T>) -> T {
        return reduce(0) { sum, element in
            sum + element[keyPath: keyPath]
        }
    }
}

extension DateFormatter {
    static var shortTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    /// Local midnight (start of today) in the canonical Ditto wire format.
    /// Using a fixed daily boundary means every device at the same location
    /// produces the same subscription query, which is important for Ditto
    /// sync efficiency.
    static var startOfTodayString: String {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return DittoWireDate.string(from: startOfDay)
    }
}

extension JSONEncoder {
    static func encodedObject<T: Codable>(_ obj: T) -> Data? {
        do {
            let jsonData = try JSONEncoder().encode(obj)
            return jsonData
        } catch {
            print("JSONEncoder.\(#function): ERROR: \(error.localizedDescription)")
            return nil
        }
    }
}
extension JSONDecoder {
    static func objectFromData<T: Codable>(_ jsonData: Data) -> T? {
        let decoder = JSONDecoder()
        do {
            let obj = try decoder.decode(T.self, from: jsonData)
            return obj
        } catch {
            print("JSONDecoder.\(#function): ERROR: \(error.localizedDescription)")
            return nil
        }
    }
}
