public final class LocalFeedImageDataLoader {
    let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
}

// MARK: Retrieve
extension LocalFeedImageDataLoader: FeedImageDataLoader {
    public typealias LoadResult = FeedImageDataLoader.Result
    
    private final class Task: FeedImageDataLoaderTask {
        var completion: (((LoadResult)) -> Void)?
        
        init(completion: @escaping (LoadResult) -> Void) {
            self.completion = completion
        }
        
        func deliverCompletion(with result: LoadResult) {
            completion?(result)
        }
        
        func cancel() {
            preventFurtherCompletions()
        }
        
        private func preventFurtherCompletions() {
            completion = nil
        }
    }
    
    public enum RetrievalError: Error {
        case failed
        case notFound
    }
    
    public func loadImageData(from url: URL, completion: @escaping (LoadResult) -> Void) -> EssentialDeveloper.FeedImageDataLoaderTask {
        let task = Task(completion: completion)
        
        store.retrieve(dataForURL: url) { [weak self] result in
            guard self != nil else {
                return
            }
            
            task.deliverCompletion(with: result
                .mapError { _ in RetrievalError.failed}
                .flatMap{ data in
                    data.map { .success($0)} ?? .failure(RetrievalError.notFound)
                }
            )
        }
        
        return task
    }
}
extension LocalFeedImageDataLoader: FeedImageDataCache {
    public typealias SaveResult = FeedImageDataCache.SaveResult
    
    public enum SaveError: Error {
        case failed
    }
    
    public func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        store.insert(data, for: url) { [weak self] result in
            guard self != nil else {
                return
            }
            
            completion(result.mapError { _ in SaveError.failed })
        }
    }
}
