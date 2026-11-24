import SwiftUI

public struct AppPagination: View {
    private let label: String
    private let canPrevious: Bool
    private let canNext: Bool
    private let previous: () -> Void
    private let next: () -> Void
    public init(label: String, canPrevious: Bool, canNext: Bool, previous: @escaping () -> Void, next: @escaping () -> Void) {
        self.label = label; self.canPrevious = canPrevious; self.canNext = canNext
        self.previous = previous; self.next = next
    }
    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppLayout.mediumGap) { previousButton; pageLabel.frame(maxWidth: .infinity); nextButton }
            VStack(spacing: AppLayout.mediumGap) { pageLabel; HStack { previousButton; Spacer(); nextButton } }
        }
    }
    private var pageLabel: some View { Text(label).font(AppTypography.body.weight(.medium)).foregroundStyle(AppColors.secondaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true) }
    private var previousButton: some View { Button(action: previous) { Text("Previous").frame(minWidth: AppPaginationLayout.labelWidth) }.buttonStyle(AppButtonStyle(.secondary)).disabled(!canPrevious) }
    private var nextButton: some View { Button(action: next) { Text("Next").frame(minWidth: AppPaginationLayout.labelWidth) }.buttonStyle(AppButtonStyle(.secondary)).disabled(!canNext) }
}

enum AppPaginationLayout {
    static let labelWidth: CGFloat = 78
}
