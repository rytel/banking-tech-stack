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
    static var topics: Request<[Topic]> {
        Request(path: TopicsPath.topics.value, method: .get)
    }

    static func topic(id: String) -> Request<Topic> {
        Request(path: TopicsPath.topic(id: id).value, method: .get)
    }
}
