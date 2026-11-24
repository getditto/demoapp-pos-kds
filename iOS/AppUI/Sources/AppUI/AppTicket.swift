import SwiftUI

public struct AppTicket: View {
    private let title: String
    private let lines: [String]
    private let elapsed: String
    private let viewModel: AppTicketViewModel
    private let onAdvance: () -> Void

    public init(title: String, lines: [String], isPaid: Bool, elapsed: String, isReady: Bool, onAdvance: @escaping () -> Void) {
        self.title = title; self.lines = lines; self.elapsed = elapsed; self.onAdvance = onAdvance
        viewModel = AppTicketViewModel(title: title, isPaid: isPaid, isReady: isReady)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.gap) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    titleText
                    Spacer(minLength: AppLayout.gap)
                    paymentText
                }
                VStack(alignment: .leading, spacing: AppLayout.smallGap) { titleText; paymentText }
            }
            ForEach(lines.indices, id: \.self) { index in
                Text(lines[index]).font(AppTypography.body).frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(elapsed).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText)
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
        .padding(AppLayout.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.radius))
        .overlay(RoundedRectangle(cornerRadius: AppLayout.radius).strokeBorder(AppColors.subtleBorder))
    }

    private var titleText: some View { Text(title).font(AppTypography.title).accessibilityAddTraits(.isHeader) }
    private var paymentText: some View {
        Text(viewModel.paymentTitle).font(AppTypography.caption)
            .foregroundStyle(viewModel.paymentColor)
    }
}

#Preview {
    BrandTheme {
        VStack(spacing: AppLayout.mediumGap) {
            AppTicket(title: "#1042ABCD", lines: ["2 × Burger", "1 × Coffee"], isPaid: false, elapsed: "2 min ago", isReady: false) {}
            AppTicket(title: "#1040ABCD", lines: ["1 × French fries"], isPaid: true, elapsed: "5 min ago", isReady: true) {}
        }.padding()
    }
}
