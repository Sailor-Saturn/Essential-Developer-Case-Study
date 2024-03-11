import EssentialDeveloper

final class FeedImageLoaderSpy: FeedImageDataLoader {
    private var messages = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()
    
    var loadedURLs: [URL] {
        return messages.map { $0.url }
    }
    private (set) var cancelledURLs = [URL]()
    
    private struct TaskSpy: FeedImageDataLoaderTask {
        let cancelCallback: () -> Void
        
        func cancel() {
            cancelCallback()
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        messages.append((url, completion))
        return TaskSpy { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func complete(with error: Error, index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with data: Data, index: Int = 0) {
        messages[index].completion(.success(data))
    }
}
