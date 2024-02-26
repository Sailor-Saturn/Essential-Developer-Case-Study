import XCTest
import EssentialDeveloper

final class FeedImageLoaderCacheDecorator: FeedImageDataLoader {
        
    let decoratee: FeedImageDataLoader
    
    init(decoratee: FeedImageDataLoader) {
        self.decoratee = decoratee
    }
    
    private final class Task: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = Task()
        
        task.wrapped = decoratee.loadImageData(from: url, completion: completion)
        
        return task
    }
}

final class FeedImageLoaderCacheDecoratorTests: XCTestCase {
    func test_load_deliversFeedImageOnLoaderSuccess() {
        let feedImage = uniqueImage()
        let (sut, loader) = makeSUT()
        
        expect(sut, toCompleteWith: .success(anyData()), when: {
            loader.complete(with: anyData())
        } )
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedImageDataLoader, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedImageLoaderCacheDecorator(decoratee: loader)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func expect(_ sut: FeedImageDataLoader, toCompleteWith expectedResult: FeedImageDataLoader.Result, when action: () -> Void,  file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load expectation")
        _ = sut.loadImageData(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed,file: file, line: line)
            case (.failure, .failure):
                break
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class LoaderSpy: FeedImageDataLoader {
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
}
