import SwiftUI

public struct AppOrderSummaryViewModel {
    public let usesColumns: Bool

    public init(expanded: Bool, accessibilityText: Bool) {
        usesColumns = expanded && !accessibilityText
    }

    public static func supportsColumns(availableWidth: CGFloat) -> Bool {
        availableWidth >= AppOrderLayout.minimumTableWidth
    }
}

enum AppOrderLayout {
    static let minimumTableWidth: CGFloat = 760
    static let titleWidth: CGFloat = 168
    static let statusWidth: CGFloat = 100
    static let dateWidth: CGFloat = 150
    static let totalWidth: CGFloat = 80
    static let paginationLabelWidth: CGFloat = 78
}

extension AppStatusTone {
    var color: Color {
        switch self {
        case .active: return AppColors.brandText
        case .success: return AppColors.success
        case .secondary: return AppColors.secondaryText
        }
    }
}
