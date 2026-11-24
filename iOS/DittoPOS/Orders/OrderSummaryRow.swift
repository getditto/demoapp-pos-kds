import AppUI
import SwiftUI

struct OrderSummaryRow: View {
    let viewModel: OrderSummaryViewModel

    var body: some View {
        AppSurface(style: .compact) {
            if viewModel.usesColumns {
                HStack(spacing: AppLayout.gap) {
                    titleText.frame(width: OrderSummaryLayout.titleWidth, alignment: .leading)
                    summaryText.frame(maxWidth: .infinity, alignment: .leading)
                    statusText.frame(width: OrderSummaryLayout.statusWidth, alignment: .leading)
                    dateText.frame(width: OrderSummaryLayout.dateWidth, alignment: .leading)
                    totalText.frame(width: OrderSummaryLayout.totalWidth, alignment: .leading)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var titleText: some View { Text(viewModel.title).font(AppTypography.body.weight(.medium)) }
    private var summaryText: some View { Text(viewModel.summary).font(AppTypography.body) }
    private var totalText: some View { Text(viewModel.total).font(AppTypography.body.weight(.medium)) }
    private var dateText: some View { Text(viewModel.date).font(AppTypography.footnote).foregroundStyle(AppColors.secondaryText) }
    private var statusText: some View {
        Text(viewModel.status).font(AppTypography.footnote)
            .foregroundStyle(viewModel.statusColor)
    }
}
