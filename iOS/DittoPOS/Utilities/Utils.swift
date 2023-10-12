///
//  Utils.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

extension CGFloat {
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
}

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

extension UIDeviceOrientation: CustomStringConvertible {
    public var isLandscape: Bool {
        self == .landscapeLeft || self == .landscapeRight
    }
    public var isPortrait: Bool {
        self == .portrait || self == .portraitUpsideDown
    }
    
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .faceUp:
            return "faceUp"
        case .faceDown:
            return "faceDown"
        default:
            return "unknown case"
        }
    }
}

extension NSNotification.Name {
    static let willUpdateToLocationId = Notification.Name("willUpdateToLocationId")
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
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    static var isoDate: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions.insert(.withFractionalSeconds)
        return f
    }
    
    static var isoDateFull: ISO8601DateFormatter {
        let f = Self.isoDate
        f.formatOptions = [.withFullDate]
        return f
    }
    
    static func isoTimeFromNowString(_ seconds: TimeInterval) -> String {
        isoDate.string(from: Date().addingTimeInterval(seconds))
    }
}

struct ScaledFont: ViewModifier {
    // https://stackoverflow.com/questions/59770477/how-to-scale-system-font-in-swiftui-to-support-dynamic-type
    // Asks the system to provide the current size category from the
    // environment, which determines what level Dynamic Type is set to.
    // The trick is that we don’t actually use it – we don’t care what the
    // Dynamic Type setting is, but by asking the system to update us when
    // it changes our UIFontMetrics code will be run at the same time,
    // causing our font to scale correctly.
    @Environment(\.sizeCategory) var sizeCategory
    var size: CGFloat
    
    func body(content: Content) -> some View {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return content.font(.system(size: scaledSize))
    }
}

extension View {
    func scaledFont(size: CGFloat) -> some View {
        return self.modifier(ScaledFont(size: size))
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
