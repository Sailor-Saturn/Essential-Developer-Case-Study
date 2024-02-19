import XCTest
import EssentialDeveloper

protocol FeedImageStore {
    func retrieveImageData()
}

final class LocalImageFeedLoader: FeedImageDataLoader {
    private struct Task: FeedImageDataLoaderTask {
        func cancel() {
            
        }
    }
    
    let store: FeedImageStore

    init(store: FeedImageStore) {
        self.store = store
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> EssentialDeveloper.FeedImageDataLoaderTask {
        store.retrieveImageData()
        
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
    
    class FeedImageStoreSpy: FeedImageStore {
        enum Message: Equatable {
            case retrieve
        }
        
        var receivedMessages = [Message]()
        
        func retrieveImageData() {
            receivedMessages.append(.retrieve)
        }
    }
    
}
