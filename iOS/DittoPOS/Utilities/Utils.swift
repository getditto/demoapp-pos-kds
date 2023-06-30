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
        return f
    }
    
    static var isoDateFull: ISO8601DateFormatter {
        let f = Self.isoDate
        f.formatOptions = [.withFullDate]
        return f
    }
}

