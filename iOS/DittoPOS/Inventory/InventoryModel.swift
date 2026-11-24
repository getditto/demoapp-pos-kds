import Combine
import Foundation

struct QuantityEdit: Equatable {
    let id: DocumentID
    var text: String
    var value: Int64? { error == nil ? Int64(text) : nil }
    var error: String? {
        guard !text.isEmpty else { return "Enter a quantity." }
        guard text.utf8.allSatisfy({ (48...57).contains($0) }) else { return "Use a whole number of 0 or more." }
        guard Int64(text) != nil else { return "Quantity is too large." }
        return nil
    }
}

struct InventoryState {
    var items: [SaleItem] = []
    var isLoading = true
    var edit: QuantityEdit?
}

@MainActor final class InventoryModel: ObservableObject {
    @Published private(set) var state = InventoryState()
    private let observe: (String) -> AnyPublisher<[SaleItem], Never>
    private let increment: (Int64, DocumentID) async throws -> Void
    private let restart: (Int64, DocumentID) async throws -> Void
    private let observation = VisibleObservation<String, [SaleItem]>()
    private var locationSubscription: AnyCancellable?
    private var location: String?
    private var visible = false

    init(observe: @escaping (String) -> AnyPublisher<[SaleItem], Never>,
         increment: @escaping (Int64, DocumentID) async throws -> Void,
         restart: @escaping (Int64, DocumentID) async throws -> Void) {
        self.observe = observe; self.increment = increment; self.restart = restart
    }

    convenience init(repository: SaleItemsRepository, locationPublisher: AnyPublisher<String?, Never>) {
        self.init(observe: repository.observeLocationSaleItems, increment: repository.increment, restart: repository.restart)
        locationSubscription = locationPublisher.removeDuplicates().sink { [weak self] in self?.setLocation($0) }
    }

    func setLocation(_ location: String?) {
        guard self.location != location else { return }
        self.location = location
        updateObservation()
    }

    func setVisible(_ visible: Bool) {
        guard self.visible != visible else { return }
        self.visible = visible
        updateObservation()
    }

    func beginEditing(_ id: DocumentID) {
        guard let item = item(id) else { return }
        state.edit = QuantityEdit(id: id, text: String(item.quantity))
    }
    func updateText(_ text: String) { state.edit?.text = text }
    func cancelEditing() { state.edit = nil }

    func step(_ delta: Int64, id: DocumentID) async throws {
        guard delta == 1 || delta == -1, state.edit?.id != id,
              let item = item(id), delta > 0 || item.quantity > 0 else { return }
        try await increment(delta, id)
    }

    func submit() async throws {
        guard let edit = state.edit, let value = edit.value, item(edit.id) != nil else { return }
        // Consume the draft before suspension so keyboard and toolbar Done cannot both restart it.
        state.edit = nil
        try await restart(value, edit.id)
    }

    private func item(_ id: DocumentID) -> SaleItem? {
        guard visible, id.locationId == location else { return nil }
        return state.items.first { $0.documentId == id }
    }

    private func updateObservation() {
        state = InventoryState()
        observation.set(visible ? location : nil, observe: observe) { [weak self] items in
            guard let self else { return }
            state.items = items
            state.isLoading = false
            if let edit = state.edit, !items.contains(where: { $0.documentId == edit.id }) { state.edit = nil }
        }
    }
}
