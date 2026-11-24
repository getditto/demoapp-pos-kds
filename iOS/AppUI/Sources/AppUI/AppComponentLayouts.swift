import SwiftUI

public struct AppWindowLayout {
    public let expanded: Bool
    public let horizontalPadding: CGFloat
    public let sectionSpacing: CGFloat

    public init(sizeClass: UserInterfaceSizeClass?) {
        let expanded = sizeClass == .regular
        self.expanded = expanded
        horizontalPadding = expanded ? AppLayout.expandedPadding : AppLayout.padding
        sectionSpacing = expanded ? AppLayout.padding : AppLayout.mediumGap
    }

    public func contentHeight(in viewportHeight: CGFloat) -> CGFloat {
        max(0, viewportHeight - AppLayout.padding * 2)
    }
}

struct AppHeaderLayout {
    let expanded: Bool
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let height: CGFloat
    let symbolWidth: CGFloat
    let symbolHeight: CGFloat

    init(sizeClass: UserInterfaceSizeClass?) {
        let window = AppWindowLayout(sizeClass: sizeClass)
        let expanded = window.expanded
        self.expanded = expanded
        horizontalPadding = window.horizontalPadding
        verticalPadding = expanded ? AppLayout.padding : 0
        height = expanded ? AppLayout.expandedHeaderHeight : AppLayout.controlHeight
        symbolWidth = expanded ? AppLayout.expandedSymbolWidth : AppLayout.compactSymbolWidth
        symbolHeight = expanded ? AppLayout.expandedSymbolHeight : AppLayout.compactSymbolHeight
    }
}

struct AppRowLayout {
    let minimumHeight: CGFloat
    init(eyebrow: String?) {
        minimumHeight = eyebrow != nil ? AppLayout.controlHeight : AppLayout.compactRowHeight
    }
}
