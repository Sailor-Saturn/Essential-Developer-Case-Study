import Foundation
import EssentialDeveloper

class NullStore: FeedStore & FeedImageDataStore {
    func insert(_ data: Data, for url: URL) throws { }
    
    func retrieve(dataForURL url: URL) throws -> Data? {
        .none
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        completion(.success(()))
    }
    
    func insert(_ feed: [EssentialDeveloper.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        completion(.success(()))
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.success(.none))
    }
}
