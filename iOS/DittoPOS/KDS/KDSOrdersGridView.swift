import AppUI
import SwiftUI

struct KDSOrdersGridView: View {
    @StateObject private var viewModel: KDSViewModel
    private let ordersRepository: OrdersRepository
    private let isActive: Bool

    init(ordersRepository: OrdersRepository, isActive: Bool = true) {
        self.ordersRepository = ordersRepository
        self.isActive = isActive
        _viewModel = StateObject(wrappedValue: KDSViewModel(ordersRepository: ordersRepository))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TimelineView(.periodic(from: .now, by: KitchenBoardViewModel.relativeTimeRefreshInterval)) { context in
                    KitchenBoard(orders: viewModel.orders, now: context.date) { order in
                        guard let next = order.status.next else { return }
                        ordersRepository.updateStatus(of: order, with: next)
                    }
                }
            }
        }
        .background(AppColors.background)
        .onAppear { viewModel.setVisible(isActive) }
        .onChange(of: isActive) { viewModel.setVisible($0) }
        .onDisappear { viewModel.setVisible(false) }
    }
}

struct KitchenBoard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let orders: [Order]
    let now: Date
    let onAdvance: (Order) -> Void

    var body: some View {
        let viewModel = KitchenBoardViewModel(orders: orders, sizeClass: sizeClass)
        VStack(spacing: viewModel.headerSpacing) {
            if viewModel.expanded {
                HStack(spacing: AppLayout.sectionGap) {
                    stageHeader(viewModel.countTitle("Preparing", count: viewModel.preparing.count), font: viewModel.headerFont, color: AppColors.text)
                    stageHeader(viewModel.countTitle("Ready", count: viewModel.ready.count), font: viewModel.headerFont, color: AppColors.success)
                }
            } else {
                HStack {
                    Text(viewModel.countTitle("Preparing", count: viewModel.preparing.count))
                    Spacer(minLength: AppLayout.gap)
                    Text(viewModel.countTitle("Ready", count: viewModel.ready.count)).foregroundStyle(AppColors.success)
                }.font(AppTypography.body.weight(.medium)).frame(minHeight: AppLayout.compactRowHeight)
            }
            if viewModel.isEmpty {
                AppEmptyState("No active orders", message: "Orders with items appear here.", icon: "check-circle", style: .success)
            } else if viewModel.expanded {
                HStack(alignment: .top, spacing: AppLayout.sectionGap) {
                    stageColumn(viewModel.preparing, showWell: viewModel.showPreparingWell, emptyMessage: "No orders preparing")
                    stageColumn(viewModel.ready, showWell: viewModel.showReadyWell, emptyMessage: "No orders ready")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: AppLayout.mediumGap) { tickets(viewModel.phoneOrders) }
                }
            }
        }
        .padding(viewModel.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func stageHeader(_ title: String, font: Font, color: Color) -> some View {
        Text(title).font(font)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading).accessibilityAddTraits(.isHeader)
    }

    private func stageColumn(_ orders: [Order], showWell: Bool, emptyMessage: String) -> some View {
        ScrollView {
            LazyVStack(spacing: AppLayout.mediumGap) {
                if showWell {
                    AppWell { Text(emptyMessage).font(AppTypography.body).foregroundStyle(AppColors.secondaryText) }
                } else {
                    tickets(orders)
                }
            }
        }.frame(maxWidth: .infinity)
    }

    private func tickets(_ orders: [Order]) -> some View {
        ForEach(orders, id: \.documentId) { order in
            KitchenTicketCard(viewModel: KitchenTicketViewModel(order: order, now: now)) { onAdvance(order) }
        }
    }
}
