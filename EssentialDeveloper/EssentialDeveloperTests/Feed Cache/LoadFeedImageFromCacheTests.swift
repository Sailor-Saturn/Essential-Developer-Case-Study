import XCTest
import EssentialDeveloper

protocol FeedImageStore {
    typealias Result = Swift.Result<Data?, Error>
    
    func retrieveImageData(from url: URL, completion: @escaping (Result) -> Void)
}

final class LocalFeedImageDataLoader: FeedImageDataLoader {
    
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
    
    enum Error: Swift.Error {
        case failed
        case notFound
    }
    
    let store: FeedImageStore
    
    init(store: FeedImageStore) {
        self.store = store
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> EssentialDeveloper.FeedImageDataLoaderTask {
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
        
        expect(sut, toCompleteWith: .failure(LocalFeedImageDataLoader.Error.failed), with: anyURL(),  when: { store.complete(with: retrievalError)})
    }
    
    func test_load_failsOnNotFoundError() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(LocalFeedImageDataLoader.Error.notFound), with: anyURL(),  when: { store.complete(with: .none)})
    }
    
    func test_loadImageDataFromURL_deliversStoredDataOnFoundData() {
        let (sut, store) = makeSUT()
        let foundData = anyData()
        
        expect(sut, toCompleteWith: .success(foundData), when: {
            store.complete(with: foundData)
        })
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask() {
        let (sut, store) = makeSUT()
        let foundData = anyData()
        
        var received = [FeedImageDataLoader.Result]()
        let task = sut.loadImageData(from: anyURL()) { received.append($0) }
        task.cancel()
        
        store.complete(with: foundData)
        store.complete(with: .none)
        store.complete(with: anyNSError())
        
        XCTAssertTrue(received.isEmpty, "Expected no received results after cancelling task")
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
            let store = StoreSpy()
            var sut: LocalFeedImageDataLoader? = LocalFeedImageDataLoader(store: store)

            var received = [FeedImageDataLoader.Result]()
            _ = sut?.loadImageData(from: anyURL()) { received.append($0) }

            sut = nil
            store.complete(with: anyData())

            XCTAssertTrue(received.isEmpty, "Expected no received results after instance has been deallocated")
        }
    
    // MARK: Helpers
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: LocalFeedImageDataLoader, store: StoreSpy) {
        let store = StoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(
        _ sut: LocalFeedImageDataLoader,
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
    
    class StoreSpy: FeedImageStore {
        enum Message: Equatable {
            case retrieve
        }
        
        private var completions = [(FeedImageStore.Result) -> Void]()
        
        var receivedMessages = [Message]()
        
        func retrieveImageData(from url: URL, completion: @escaping (FeedImageStore.Result) -> Void) {
            receivedMessages.append(.retrieve)
            completions.append(completion)
        }
        
        func complete(with error: Error, at index: Int = 0){
            completions[index](.failure(error))
        }
        
        func complete(with data: Data?, at index: Int = 0){
            completions[index](.success(data))
        }
        
    }
    
}
