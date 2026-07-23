import Foundation
import CoreModels

// This stream does not go through `HTTPClient`, so there is no `NetworkError`
// step here: `TickerRepository` maps straight from `URLError`/decoding
// failures to the public domain error.

extension TickerError {
    init(_ urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            self = .offline
        case .cancelled:
            self = .cancelled
        default:
            self = .connectionFailed
        }
    }
}
