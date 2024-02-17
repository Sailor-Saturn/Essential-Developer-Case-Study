public final class RemoteFeedImageDataLoader {
    let client: HTTPClient
    let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    private final class HTTPURLPropertyWrapper: FeedImageDataLoaderTask {
        var completion: (Result<Data, Error>) -> Void
        
        var wrapped: HTTPClientTask?
        
        init(completion: @escaping (Result<Data, Error>) -> Void) {
            self.completion = completion
        }
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    public func loadImageData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) -> FeedImageDataLoaderTask {
        let task = HTTPURLPropertyWrapper(completion: completion)
        
        task.wrapped = client.get(from: url) { result in
            switch result {
            case let .success((data, response)) where response.statusCode == 200:
                guard !data.isEmpty
                else {
                    completion(.failure(.invalidData))
                    return
                }
                completion(.success(data))
            case .success:
                completion(.failure(.invalidData))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
        
        return task
    }
}
