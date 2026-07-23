public struct TickerUpdate: Equatable, Decodable, Sendable {
    public let serverTime: String

    public init(serverTime: String) {
        self.serverTime = serverTime
    }
}
