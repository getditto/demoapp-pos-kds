import AppUI
import SwiftUI
import XCTest

final class AppWindowLayoutTests: XCTestCase {
    func testWindowChangesSelectTheCurrentLayoutAndKeepShortContentFramesNonnegative() {
        let windows = [UserInterfaceSizeClass.compact, .regular, .compact]
            .map { AppWindowLayout(sizeClass: $0) }
        XCTAssertEqual(windows.map(\.expanded), [false, true, false])

        let compact = windows[0]
        XCTAssertEqual(compact.contentHeight(in: 800), 768)
        XCTAssertEqual(compact.contentHeight(in: 16), 0)
        XCTAssertEqual(compact.contentHeight(in: 0), 0)
    }
}
