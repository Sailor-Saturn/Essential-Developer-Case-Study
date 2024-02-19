import XCTest

protocol FeedImageStore {
    
}

final class LocalImageFeedLoader {
    let store: FeedImageStore

    init(store: FeedImageStore) {
        self.store = store
    }
}

final class LoadFeedImageFromCacheTests: XCTestCase {
    func test_init_doesNotMessageTheStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
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
        let receivedMessages = [Any]()
    }
    
}
