public final class RemoteFeedImageDataLoader: FeedImageDataLoader {
    let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    private final class HTTPURLPropertyWrapper: FeedImageDataLoaderTask {
        var completion: ((FeedImageDataLoader.Result)) -> Void
        
        var wrapped: HTTPClientTask?
        
        init(completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = HTTPURLPropertyWrapper(completion: completion)
        
        task.wrapped = client.get(from: url) { result in
            switch result {
            case let .success((data, response)) where response.statusCode == 200:
                guard !data.isEmpty
                else {
                    completion(.failure(Error.invalidData))
                    return
                }
                completion(.success(data))
            case .success:
                completion(.failure(Error.invalidData))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
        
        return task
    }
}
