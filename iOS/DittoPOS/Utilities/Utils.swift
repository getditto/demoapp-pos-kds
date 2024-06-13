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

//MARK: EdgeBorder and ViewModifier
extension View {
    public func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}
struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return self.width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return self.width
                case .leading, .trailing: return rect.height
                }
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}

//MARK: AppConfigView Pickers
extension UIPickerView {
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 90)
    }
}

//MARK: Math

extension Float {
    
    // VersionPicker AppConfig.version number handling
    func floorFirstTwoDecimals() -> (first: Int, second: Int) {
        let shiftedNumber = self * 100
        let integerPart = Int(floor(shiftedNumber))
        let firstDecimal = (integerPart / 10) % 10
        let secondDecimal = integerPart % 10
        return (firstDecimal, secondDecimal)
    }
    
    func stringToTwoDecimalPlaces() -> String {
        String(format: "%.2f", self)
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
