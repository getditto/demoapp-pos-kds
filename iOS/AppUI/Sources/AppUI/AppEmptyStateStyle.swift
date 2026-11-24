import SwiftUI

public enum AppEmptyStateStyle {
    case standard, success
    var spacing: CGFloat { AppLayout.mediumGap }
    var iconSize: CGFloat { self == .success ? AppLayout.successIconSize : AppLayout.emptyIconSize }
    var iconColor: Color { self == .success ? AppColors.success : AppColors.secondaryText }
    var titleFont: Font { self == .success ? AppTypography.title : AppTypography.heading }
    var messageFont: Font { self == .success ? AppTypography.body : AppTypography.caption }
}
