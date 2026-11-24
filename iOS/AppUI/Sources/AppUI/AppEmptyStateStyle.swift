import SwiftUI

public enum AppEmptyStateStyle {
    case standard, success, large

    var spacing: CGFloat { self == .large ? AppLayout.padding : AppLayout.mediumGap }
    var iconSize: CGFloat {
        switch self {
        case .large: AppLayout.largeEmptyIconSize
        case .success: AppLayout.successIconSize
        case .standard: AppLayout.emptyIconSize
        }
    }
    var iconColor: Color {
        switch self {
        case .large: AppColors.text
        case .success: AppColors.success
        case .standard: AppColors.secondaryText
        }
    }
    var titleFont: Font { self == .standard ? AppTypography.heading : AppTypography.title }
    var messageFont: Font { self == .standard ? AppTypography.caption : AppTypography.body }
}
