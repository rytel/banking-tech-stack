import Combine
import Foundation
import Observation
import CoreModels

@MainActor
@Observable
public final class TickerViewModel {
    public private(set) var serverTime: String?
    public private(set) var isConnected = false

    private let repository: TickerRepositoryProtocol
    private var cancellable: AnyCancellable?

    public init(repository: TickerRepositoryProtocol) {
        self.repository = repository
    }

    public func start() {
        cancellable = repository.tickerUpdates()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isConnected = false
                },
                receiveValue: { [weak self] update in
                    self?.serverTime = update.serverTime
                    self?.isConnected = true
                }
            )
    }

    public func stop() {
        // Releasing the subscription triggers `receiveCancel` in
        // `TickerRepository`, which closes the underlying WebSocket.
        cancellable = nil
        isConnected = false
    }
}
