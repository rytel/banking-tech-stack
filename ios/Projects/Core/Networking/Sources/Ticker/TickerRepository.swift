import Foundation
@preconcurrency import Combine
import CoreModels

/// Bridges `URLSessionWebSocketTask`'s callback-based receive loop into a
/// Combine `Publisher`. The class stores a live task per subscription, but
/// all of its mutation happens serialized on the WebSocket task's own
/// callback queue (never touched directly by callers), so `@unchecked
/// Sendable` is safe here even though the stored properties are not
/// immutable.
public final class TickerRepository: TickerRepositoryProtocol, @unchecked Sendable {
    private let environment: APIEnvironment
    private let urlSession: URLSession

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    public init(environment: APIEnvironment = .local, urlSession: URLSession = .shared) {
        self.environment = environment
        self.urlSession = urlSession
    }

    public func tickerUpdates() -> AnyPublisher<TickerUpdate, TickerError> {
        let url = environment.webSocketBaseURL.appendingPathComponent("/ws/ticker")
        let task = urlSession.webSocketTask(with: url)
        let subject = PassthroughSubject<TickerUpdate, TickerError>()

        task.resume()
        Self.receiveLoop(task: task, subject: subject)

        // Cancelling the Combine subscription (e.g. the view model setting
        // its `AnyCancellable` to nil) is what actually closes the socket.
        return subject
            .handleEvents(receiveCancel: {
                task.cancel(with: .goingAway, reason: nil)
            })
            .eraseToAnyPublisher()
    }

    private static func receiveLoop(
        task: URLSessionWebSocketTask,
        subject: PassthroughSubject<TickerUpdate, TickerError>
    ) {
        task.receive { result in
            switch result {
            case .success(let message):
                guard publish(message, subject: subject) else { return }
                receiveLoop(task: task, subject: subject)
            case .failure(let error):
                let urlError = error as? URLError
                subject.send(completion: .failure(urlError.map(TickerError.init) ?? .connectionFailed))
            }
        }
    }

    /// Decodes one frame and sends it downstream. Returns `false` if the
    /// stream should stop (an unrecoverable frame type or decoding error).
    private static func publish(
        _ message: URLSessionWebSocketTask.Message,
        subject: PassthroughSubject<TickerUpdate, TickerError>
    ) -> Bool {
        let data: Data
        switch message {
        case .data(let raw): data = raw
        case .string(let text): data = Data(text.utf8)
        @unknown default:
            subject.send(completion: .failure(.unknown))
            return false
        }

        do {
            subject.send(try decoder.decode(TickerUpdate.self, from: data))
            return true
        } catch {
            subject.send(completion: .failure(.decodingError))
            return false
        }
    }
}
