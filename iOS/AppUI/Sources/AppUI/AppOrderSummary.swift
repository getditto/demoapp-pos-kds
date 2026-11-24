import SwiftUI

public enum AppStatusTone { case secondary, active, success }

public struct AppOrderSummary: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    private let title: String
    private let summary: String
    private let status: String
    private let tone: AppStatusTone
    private let date: String
    private let total: String
    private let expanded: Bool

    public init(title: String, summary: String, status: String, tone: AppStatusTone, date: String, total: String, expanded: Bool = false) {
        self.title = title; self.summary = summary; self.status = status; self.tone = tone
        self.date = date; self.total = total; self.expanded = expanded
    }

    public var body: some View {
        let viewModel = AppOrderSummaryViewModel(expanded: expanded, accessibilityText: typeSize.isAccessibilitySize)
        Group {
            if viewModel.usesColumns {
                HStack(spacing: AppLayout.gap) {
                    titleText.frame(width: AppOrderLayout.titleWidth, alignment: .leading)
                    summaryText.frame(maxWidth: .infinity, alignment: .leading)
                    statusText.frame(width: AppOrderLayout.statusWidth, alignment: .leading)
                    dateText.frame(width: AppOrderLayout.dateWidth, alignment: .leading)
                    totalText.frame(width: AppOrderLayout.totalWidth, alignment: .leading)
                }.frame(minHeight: AppLayout.contentRowHeight)
            } else {
                VStack(alignment: .leading, spacing: AppLayout.gap) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline) { titleText; Spacer(minLength: AppLayout.gap); statusText.fixedSize() }
                        VStack(alignment: .leading, spacing: AppLayout.gap) { titleText; statusText }
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline) { summaryText; Spacer(minLength: AppLayout.gap); totalText.fixedSize() }
                        VStack(alignment: .leading, spacing: AppLayout.gap) { summaryText; totalText }
                    }
                    dateText
                }
            }
        }
        .padding(AppLayout.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
        .accessibilityElement(children: .combine)
    }

    private var titleText: some View { Text(title).font(AppTypography.body.weight(.medium)) }
    private var summaryText: some View { Text(summary).font(AppTypography.body) }
    private var totalText: some View { Text(total).font(AppTypography.body.weight(.medium)) }
    private var dateText: some View { Text(date).font(AppTypography.footnote).foregroundStyle(AppColors.secondaryText) }
    private var statusText: some View {
        Text(status).font(AppTypography.footnote)
            .foregroundStyle(tone.color)
    }
}

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
    private var previousButton: some View { Button(action: previous) { Text("Previous").frame(minWidth: AppOrderLayout.paginationLabelWidth) }.buttonStyle(AppButtonStyle(.secondary)).disabled(!canPrevious) }
    private var nextButton: some View { Button(action: next) { Text("Next").frame(minWidth: AppOrderLayout.paginationLabelWidth) }.buttonStyle(AppButtonStyle(.secondary)).disabled(!canNext) }
}

#Preview("Orders") {
    BrandTheme {
        VStack(spacing: AppLayout.gap) {
            AppOrderSummary(title: "Order #1234ABCD", summary: "2 × Burger · 1 × Coffee", status: "Preparing", tone: .active, date: "Oct 29, 14:48", total: "$18.95")
            AppOrderSummary(title: "Order #5678ABCD", summary: "1 × Coffee", status: "Delivered", tone: .success, date: "Oct 29, 14:47", total: "$1.95")
            AppPagination(label: "Page 1 of 2", canPrevious: false, canNext: true, previous: {}, next: {})
        }.padding()
    }
}
