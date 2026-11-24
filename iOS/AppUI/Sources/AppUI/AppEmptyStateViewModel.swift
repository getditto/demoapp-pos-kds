import SwiftUI

struct AppEmptyStateViewModel {
    let spacing = AppLayout.mediumGap
    let iconSize: CGFloat
    let iconColor: Color
    let titleFont: Font
    let messageFont: Font

    init(prominent: Bool) {
        iconSize = prominent ? AppLayout.successIconSize : AppLayout.emptyIconSize
        iconColor = prominent ? AppColors.success : AppColors.secondaryText
        titleFont = prominent ? AppTypography.title : AppTypography.heading
        messageFont = prominent ? AppTypography.body : AppTypography.caption
    }
}
