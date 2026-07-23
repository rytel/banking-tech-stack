import Combine

// Unlike every other repository in this app, this method is not `async
// throws`: subscribing to the returned publisher is what opens the
// connection, and cancelling the subscription is what closes it.

public protocol TickerRepositoryProtocol: Sendable {
    func tickerUpdates() -> AnyPublisher<TickerUpdate, TickerError>
}
