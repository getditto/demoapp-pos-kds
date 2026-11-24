import Combine
import Foundation

enum OrdersHistoryQuery {
    static let pageSize = 50
    private static let predicate = "_id.locationId = :locationId AND object_length(cart) > 0"
    static let page = "SELECT * FROM \(Order.collectionName) WHERE \(predicate) ORDER BY createdAt DESC LIMIT 50 OFFSET :offset"
    static let count = "SELECT COUNT(*) AS total FROM \(Order.collectionName) WHERE \(predicate)"
    struct Count: Decodable, Sendable { let total: Int }
}

struct OrdersHistoryState {
    var orders: [Order] = []
    var pageIndex = 0
    var total: Int?
    var isPageLoading = true
    var isLoading: Bool { total == nil || isPageLoading }
    var totalPages: Int { max(1, ((total ?? 0) + OrdersHistoryQuery.pageSize - 1) / OrdersHistoryQuery.pageSize) }
    var canPrevious: Bool { total != nil && pageIndex > 0 }
    var canNext: Bool { total != nil && pageIndex + 1 < totalPages }
}

@MainActor final class OrdersHistory: ObservableObject {
    @Published private(set) var state = OrdersHistoryState()
    private struct Page: Equatable { let location: String; let index: Int }
    private let pageObservation = VisibleObservation<Page, [Order]>()
    private let countObservation = VisibleObservation<String, Int>()
    private let observePage: (String, Int) -> AnyPublisher<[Order], Never>
    private let observeCount: (String) -> AnyPublisher<Int, Never>
    private var locationSubscription: AnyCancellable?
    private var locationId: String?
    private var visible = false
    private var receivedOrders: [Order] = []

    init(repository: OrdersRepository) {
        observePage = repository.observeHistoryPage
        observeCount = repository.observeHistoryCount
        locationSubscription = repository.locationPublisher.removeDuplicates().sink { [weak self] in self?.setLocation($0) }
    }

    init(observePage: @escaping (String, Int) -> AnyPublisher<[Order], Never>,
         observeCount: @escaping (String) -> AnyPublisher<Int, Never>) {
        self.observePage = observePage
        self.observeCount = observeCount
    }

    func setLocation(_ location: String?) {
        guard locationId != location else { return }
        stop()
        locationId = location
        state = OrdersHistoryState()
        start()
    }

    func setVisible(_ visible: Bool) {
        guard self.visible != visible else { return }
        self.visible = visible
        stop()
        state.orders = []
        state.total = nil
        state.isPageLoading = true
        start()
    }

    func previous() { if state.canPrevious { select(state.pageIndex - 1) } }
    func next() { if state.canNext { select(state.pageIndex + 1) } }

    private func select(_ index: Int) {
        state.pageIndex = index
        state.isPageLoading = true
        receivedOrders = []
        state.orders = []
        updatePage()
    }

    private func start() {
        guard visible, let locationId else { return }
        // COUNT stays attached when only the page changes; both are local UI observations.
        // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
        countObservation.set(locationId, observe: observeCount) { [weak self] total in
            guard let self else { return }
            state.total = total
            let lastIndex = state.totalPages - 1
            if state.pageIndex > lastIndex { select(lastIndex) }
            state.orders = total == 0 ? [] : receivedOrders
        }
        updatePage()
    }

    private func updatePage() {
        let page = visible ? locationId.map { Page(location: $0, index: state.pageIndex) } : nil
        pageObservation.set(page, observe: { self.observePage($0.location, $0.index) }) { [weak self] orders in
            guard let self else { return }
            receivedOrders = orders
            state.isPageLoading = false
            state.orders = state.total == 0 ? [] : orders
        }
    }

    private func stop() {
        countObservation.set(nil, observe: observeCount, receive: { _ in })
        pageObservation.set(nil, observe: { self.observePage($0.location, $0.index) }, receive: { _ in })
        receivedOrders = []
    }
}
