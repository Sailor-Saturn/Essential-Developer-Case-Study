public final class LocalFeedImageDataLoader: FeedImageDataLoader {
    private final class Task: FeedImageDataLoaderTask {
        var completion: (((FeedImageDataLoader.Result)) -> Void)?
        
        init(completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func deliverCompletion(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            preventFurtherCompletions()
        }
        
        private func preventFurtherCompletions() {
            completion = nil
        }
    }
    
    public enum Error: Swift.Error {
        case failed
        case notFound
    }
    
    let store: FeedImageStore
    
    public init(store: FeedImageStore) {
        self.store = store
    }
    
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> EssentialDeveloper.FeedImageDataLoaderTask {
        let task = Task(completion: completion)
        
        store.retrieveImageData(from: url) { [weak self] result in
            guard self != nil else {
                return
            }
            
            task.deliverCompletion(with: result
                .mapError { _ in Error.failed}
                .flatMap{ data in
                    data.map { .success($0)} ?? .failure(Error.notFound)
                }
            )
        }
        
        return task
    }
}
