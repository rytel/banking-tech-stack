import Foundation
import CoreModels

/// All topics API paths in one place, so they cannot be mistyped.
enum TopicsPath {
    case topics
    case topic(id: String)

    var value: String {
        switch self {
        case .topics: "/topics"
        case .topic(let id): "/topics/\(id)"
        }
    }
}

/// Factories for the topics API calls.
enum TopicsAPI {
    static func topics(query: String? = nil) -> Request<[Topic]> {
        let queryItems = query.map { [URLQueryItem(name: "q", value: $0)] } ?? []
        return Request(path: TopicsPath.topics.value, method: .get, queryItems: queryItems)
    }

    static func topic(id: String) -> Request<Topic> {
        Request(path: TopicsPath.topic(id: id).value, method: .get)
    }
}
