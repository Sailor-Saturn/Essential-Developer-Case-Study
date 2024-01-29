import Foundation

public typealias LoadFeedResult = Swift.Result<[FeedImage], Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
