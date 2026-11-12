import SwiftUI

public struct DittoTicket: View {
    private let title: String
    private let lines: [String]
    private let isPaid: Bool
    private let elapsed: String
    private let isReady: Bool
    private let onAdvance: () -> Void

    public init(title: String, lines: [String], isPaid: Bool, elapsed: String, isReady: Bool, onAdvance: @escaping () -> Void) {
        self.title = title; self.lines = lines; self.isPaid = isPaid
        self.elapsed = elapsed; self.isReady = isReady; self.onAdvance = onAdvance
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DittoLayout.gap) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    titleText
                    Spacer(minLength: 8)
                    paymentText
                }
                VStack(alignment: .leading, spacing: 4) { titleText; paymentText }
            }
            ForEach(lines.indices, id: \.self) { index in
                Text(lines[index]).font(DittoTypography.body).frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(elapsed).font(DittoTypography.caption).foregroundStyle(DittoColors.secondaryText)
                Spacer(minLength: 8)
                Text(isReady ? "Ready" : "Preparing").font(DittoTypography.body)
                    .foregroundStyle(isReady ? DittoColors.success : DittoColors.brandText)
            }
            Button(action: onAdvance) {
                Text(isReady ? "Complete order" : "Mark ready").frame(maxWidth: .infinity)
            }
            .buttonStyle(DittoButtonStyle(isReady ? .secondary : .primary))
            .accessibilityLabel("\(isReady ? "Complete order" : "Mark ready"), \(title)")
        }
        .padding(DittoLayout.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DittoColors.surface, in: RoundedRectangle(cornerRadius: DittoLayout.radius))
        .overlay(RoundedRectangle(cornerRadius: DittoLayout.radius).strokeBorder(DittoColors.subtleBorder))
    }

    private var titleText: some View { Text(title).font(DittoTypography.title).accessibilityAddTraits(.isHeader) }
    private var paymentText: some View {
        Text(isPaid ? "Paid" : "Unpaid").font(DittoTypography.caption)
            .foregroundStyle(isPaid ? DittoColors.success : DittoColors.secondaryText)
    }
}

#Preview {
    DittoTheme {
        VStack(spacing: 12) {
            DittoTicket(title: "#1042ABCD", lines: ["2 × Burger", "1 × Coffee"], isPaid: false, elapsed: "2 min ago", isReady: false) {}
            DittoTicket(title: "#1040ABCD", lines: ["1 × French fries"], isPaid: true, elapsed: "5 min ago", isReady: true) {}
        }.padding()
    }
}
