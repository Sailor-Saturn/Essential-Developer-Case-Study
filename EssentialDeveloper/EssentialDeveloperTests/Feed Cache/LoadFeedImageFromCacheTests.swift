import XCTest
import EssentialDeveloper

protocol FeedImageStore {
    typealias Result = Swift.Result<Data?, Error>
    
    func retrieveImageData(completion: @escaping (Result) -> Void)
}

final class LocalImageFeedLoader: FeedImageDataLoader {
    private struct Task: FeedImageDataLoaderTask {
        func cancel() {
            
        }
    }
    
    enum Error: Swift.Error {
        case failed
    }
    
    let store: FeedImageStore

    init(store: FeedImageStore) {
        self.store = store
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> EssentialDeveloper.FeedImageDataLoaderTask {
        store.retrieveImageData { result in
            completion(.failure(Error.failed))
        }
        
        return Task()
    }
}

final class LoadFeedImageFromCacheTests: XCTestCase {
    func test_init_doesNotMessageTheStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        let url = anyURL()
        
        _ = sut.loadImageData(from: url) { _ in}
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievelError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(LocalImageFeedLoader.Error.failed), with: anyURL(),  when: { store.completeRetrieval(with: retrievalError)})
    }
    
    // MARK: Helpers
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: LocalImageFeedLoader, store: FeedImageStoreSpy) {
        let store = FeedImageStoreSpy()
        let sut = LocalImageFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(
        _ sut: LocalImageFeedLoader,
        toCompleteWith expectedResult: FeedImageDataLoader.Result,
        with url: URL = anyURL(),
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Expected to retrieve error")
        
        _ = sut.loadImageData(from: url){ receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead.", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    class FeedImageStoreSpy: FeedImageStore {
        enum Message: Equatable {
            case retrieve
        }
        
        private var completions = [(FeedImageStore.Result) -> Void]()
        
        var receivedMessages = [Message]()
        
        func retrieveImageData(completion: @escaping (FeedImageStore.Result) -> Void) {
            receivedMessages.append(.retrieve)
            completions.append(completion)
        }
        
        func completeRetrieval(with error: Error, at index: Int = 0){
            completions[index](.failure(error))
        }
        
    }
    
}
