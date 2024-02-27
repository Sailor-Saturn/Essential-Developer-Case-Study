import XCTest
import EssentialDeveloper

protocol FeedImageCache {
    typealias SaveResult = Result<Void, Error>
    
    func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void)
}

final class FeedImageLoaderCacheDecorator: FeedImageDataLoader {
    let decoratee: FeedImageDataLoader
    let cache: FeedImageCache
    
    init(decoratee: FeedImageDataLoader, cache: FeedImageCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    private final class Task: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = Task()
        
        task.wrapped = decoratee.loadImageData(from: url) {[weak self] result in
            completion(result.map { data in
                self?.cache.save(data, for: url) { _ in }
                return data
            })
        }
        
        return task
    }
}

final class FeedImageLoaderCacheDecoratorTests: XCTestCase, FeedImageTestCase {
    func test_init_doesNotLoadImageData() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadedURLs, [])
    }
    
    func test_loadImageData_loadsFromLoader() {
        let (sut, loader) = makeSUT()
        let url = anyURL()
        
        _ = sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(loader.loadedURLs, [url])
    }
    
    func test_loadImageData_deliversFeedImageOnLoaderSuccess() {
        let (sut, loader) = makeSUT()
        
        expect(sut, toCompleteWith: .success(anyData()), when: {
            loader.complete(with: anyData())
        } )
    }
    
    func test_loadImageData_deliversErrorOnLoaderError() {
        let (sut, loader) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(anyNSError()), when: {
            loader.complete(with: anyNSError())
        })
    }
    
    func test_cancelLoadImageData_cancelsLoaderTask() {
        let (sut, loader) = makeSUT()
        let url = anyURL()
        
        let task = sut.loadImageData(from: url) { _ in  }
        
        task.cancel()
        
        XCTAssertEqual(loader.cancelledURLs, [url], "Expected to cancel URL loading from loader.")
    }
    
    func test_loadImageData_cachesLoadedImageDataOnLoaderSuccess() {
        let cache = CacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        
        let imageData = anyData()
        let url = anyURL()
        let exp = expectation(description: "Wait for load expectation")
        
        
        _ = sut.loadImageData(from: url) { _ in
            exp.fulfill()
        }
        
        loader.complete(with: imageData)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(cache.messages, [.save(imageData)])
    }
    
    func test_loadImageData_doesNotCacheOnLoaderFailure() {
        let cache = CacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        
        let url = anyURL()
        let exp = expectation(description: "Wait for load expectation")
        
        _ = sut.loadImageData(from: url) { _ in
            exp.fulfill()
        }
        
        loader.complete(with: anyNSError())
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(cache.messages, [])
    }
    
    // MARK: - Helpers
    private func makeSUT(cache: CacheSpy = .init(), file: StaticString = #file, line: UInt = #line) -> (FeedImageDataLoader, FeedImageLoaderSpy) {
        let loader = FeedImageLoaderSpy()
        let sut = FeedImageLoaderCacheDecorator(decoratee: loader, cache: cache)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private final class CacheSpy: FeedImageCache {
        var messages = [Messages]()
        
        enum Messages: Equatable  {
            case save(Data)
        }
        
        func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
            messages.append(.save(data))
        }
    }
}
