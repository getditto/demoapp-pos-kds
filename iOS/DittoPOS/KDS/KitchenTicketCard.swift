import AppUI
import SwiftUI

struct KitchenTicketCard: View {
    let viewModel: KitchenTicketViewModel
    let onAdvance: () -> Void

    var body: some View {
        AppSurface(style: .outlined) {
            VStack(alignment: .leading, spacing: AppLayout.gap) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        titleText
                        Spacer(minLength: AppLayout.gap)
                        paymentText
                    }
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) { titleText; paymentText }
                }
                ForEach(viewModel.lines.indices, id: \.self) { index in
                    Text(viewModel.lines[index]).font(AppTypography.body).frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.elapsed).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText)
                    Spacer(minLength: AppLayout.gap)
                    Text(viewModel.stageTitle).font(AppTypography.body)
                        .foregroundStyle(viewModel.stageColor)
                }
                Button(action: onAdvance) {
                    Text(viewModel.actionTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(AppButtonStyle(viewModel.actionKind))
                .accessibilityLabel(viewModel.actionLabel)
            }
        }
    }

    private var titleText: some View { Text(viewModel.title).font(AppTypography.title).accessibilityAddTraits(.isHeader) }
    private var paymentText: some View {
        Text(viewModel.paymentTitle).font(AppTypography.caption)
            .foregroundStyle(viewModel.paymentColor)
    }
}
