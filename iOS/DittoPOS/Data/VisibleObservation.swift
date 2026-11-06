import Combine

// An obsolete query must not overwrite the currently visible location/order.
@MainActor final class VisibleObservation<Key: Equatable, Value> {
    private var key: Key?
    private var generation = 0
    private var observation: AnyCancellable?

    func set(
        _ key: Key?,
        observe: (Key) -> AnyPublisher<Value, Never>,
        receive: @escaping (Value) -> Void
    ) {
        guard self.key != key else { return }
        generation += 1
        let current = generation
        self.key = key
        observation?.cancel()
        observation = nil
        guard let key else { return }
        let started = observe(key).sink { [weak self] value in
            guard let self, generation == current else { return }
            receive(value)
        }
        if generation == current {
            observation = started
        } else {
            started.cancel()
        }
    }
}
