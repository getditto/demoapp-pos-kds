import Combine

// An obsolete query must not overwrite the currently visible location/order.
@MainActor final class VisibleObservation<Key: Equatable, Value> {
    private var key: Key?
    private var generation = 0
    private var observation: AnyCancellable?

    func set(
        _ key: Key?,
        observe: (Key) -> AnyPublisher<Value, Error>,
        receive: @escaping (Value) -> Void,
        failure: @escaping (Error) -> Void = { print("Observation: \($0)") }
    ) {
        guard self.key != key else { return }
        generation += 1
        let current = generation
        self.key = key
        observation?.cancel()
        observation = nil
        guard let key else { return }
        let started = observe(key).sink(
            receiveCompletion: { [weak self] result in
                guard let self, generation == current else { return }
                if case .failure(let error) = result { failure(error) }
            },
            receiveValue: { [weak self] value in
                guard let self, generation == current else { return }
                receive(value)
            }
        )
        if generation == current {
            observation = started
        } else {
            started.cancel()
        }
    }
}
