import SwiftUI
import UIKit
import XCTest

@MainActor final class POSSplitLayoutTests: XCTestCase {
    func testOrderWidthIsAFractionOfTheAvailableWidth() {
        XCTAssertEqual(POSColumnLayout.orderWidth(for: 402), 160.8, accuracy: 0.001)
        XCTAssertEqual(POSColumnLayout.orderWidth(for: 1180), 472, accuracy: 0.001)
    }

    func testOrderWidthIsNeverNegative() {
        XCTAssertEqual(POSColumnLayout.orderWidth(for: 0), 0)
        XCTAssertEqual(POSColumnLayout.orderWidth(for: -10), 0)
    }

    /// iPhone landscape: the window is as wide as the screen, but the Dynamic
    /// Island or notch adds horizontal safe-area insets. Both columns must stay
    /// inside them.
    func testColumnsStayInsideHorizontalSafeArea() throws {
        let screen = UIScreen.main.bounds.size
        let inset: CGFloat = 62
        let frames = try layOut(
            size: screen,
            safeArea: UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        )
        XCTAssertGreaterThanOrEqual(frames.menu.minX, inset - 0.5)
        XCTAssertLessThanOrEqual(frames.order.maxX, screen.width - inset + 0.5)
        XCTAssertLessThan(frames.menu.maxX, frames.order.minX)
    }

    /// iPad windows and iPhone Duo can be narrower than the screen. The
    /// columns must follow the size the view is given, not the screen.
    func testColumnsFollowTheGivenWidthNotTheScreen() throws {
        let frames = try layOut(size: CGSize(width: 375, height: 556), safeArea: .zero)
        XCTAssertGreaterThanOrEqual(frames.menu.minX, -0.5)
        XCTAssertLessThanOrEqual(frames.order.maxX, 375 + 0.5)
        XCTAssertEqual(frames.order.width, POSColumnLayout.orderWidth(for: 375), accuracy: 0.5)
    }

    // MARK: - Helpers

    private final class FrameBox {
        var menu: CGRect?
        var order: CGRect?
    }

    private func layOut(size: CGSize, safeArea: UIEdgeInsets) throws -> (menu: CGRect, order: CGRect) {
        let box = FrameBox()
        let root = POSSplitLayout(
            menu: { Color.red.background(FrameReader { box.menu = $0 }) },
            order: { Color.blue.background(FrameReader { box.order = $0 }) }
        )
        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        host.additionalSafeAreaInsets = safeArea
        window.makeKeyAndVisible()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        defer { window.isHidden = true }
        return (try XCTUnwrap(box.menu), try XCTUnwrap(box.order))
    }
}

/// Reports a view's frame in global coordinates once it is laid out.
private struct FrameReader: View {
    let report: (CGRect) -> Void

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            Color.clear
                .onAppear { report(frame) }
                .onChange(of: frame) { report($0) }
        }
    }
}
