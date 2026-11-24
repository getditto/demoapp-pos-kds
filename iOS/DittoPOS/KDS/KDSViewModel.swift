//
//  KDSViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import AppUI
import SwiftUI
import Combine
import DittoSwift
import Foundation

@MainActor class KDSViewModel: ObservableObject {
    @Published private(set) var orders = [Order]()
    @Published private(set) var isLoading = true
    private var cancellables = Set<AnyCancellable>()
    private let observation = VisibleObservation<String, [Order]>()
    private let ordersRepository: OrdersRepository
    private var locationId: String?
    private var isVisible = false

    init(ordersRepository: OrdersRepository, previewOrders: [Order]? = nil) {
        self.ordersRepository = ordersRepository
        if let previewOrders = previewOrders {
            self.orders = previewOrders
            isLoading = false
            return
        }

        ordersRepository.locationPublisher
            .removeDuplicates()
            .sink { [weak self] location in
                if self?.locationId != location {
                    self?.orders = []
                    self?.isLoading = true
                }
                self?.locationId = location
                self?.updateObservation()
            }
            .store(in: &cancellables)
    }

    func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        orders = []
        isLoading = true
        updateObservation()
    }

    private func updateObservation() {
        observation.set(isVisible ? locationId : nil, observe: ordersRepository.observeKitchenOrders) { [weak self] orders in
            self?.orders = orders
            self?.isLoading = false
        }
    }
}

struct KitchenBoardViewModel {
    static let relativeTimeRefreshInterval: TimeInterval = 60
    let preparing: [Order]
    let ready: [Order]
    let expanded: Bool
    let contentPadding: CGFloat
    let headerSpacing: CGFloat
    var phoneOrders: [Order] { preparing + ready }
    var isEmpty: Bool { preparing.isEmpty && ready.isEmpty }
    var showPreparingWell: Bool { expanded && !isEmpty && preparing.isEmpty }
    var showReadyWell: Bool { expanded && !isEmpty && ready.isEmpty }
    var headerFont: Font { expanded ? AppTypography.title : AppTypography.body.weight(.medium) }

    init(orders: [Order], sizeClass: UserInterfaceSizeClass?) {
        preparing = orders.filter { $0.status == .inProcess }
        ready = orders.filter { $0.status == .processed }
        expanded = AppWindowViewModel(sizeClass: sizeClass).expanded
        contentPadding = expanded ? AppLayout.sectionGap : AppLayout.padding
        headerSpacing = expanded ? AppLayout.padding : AppLayout.mediumGap
    }

    func countTitle(_ title: String, count: Int) -> String {
        expanded ? "\(title) · \(count)" : "\(title) \(count)"
    }
}

@MainActor struct KitchenTicketViewModel {
    let title: String
    let lines: [String]
    let isPaid: Bool
    let elapsed: String
    let isReady: Bool

    init(order: Order, now: Date) {
        title = "#\(order.title)"
        lines = order.summary.sorted(by: { $0.key < $1.key }).map { "\($0.value) × \($0.key)" }
        isPaid = order.isPaid
        elapsed = Self.elapsedFormatter.localizedString(for: order.createdAt, relativeTo: now)
        isReady = order.status == .processed
    }

    private static let elapsedFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}
