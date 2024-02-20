import XCTest
import EssentialDeveloper

final class EssentialDeveloperCacheIntegrationTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        try setupEmptyStoreState()
    }
    
    override func tearDownWithError() throws {
        try undoStoreSideEffects()

        try super.tearDownWithError()
    }
    
    func test_loadFeed_deliversEmptyOnEmptyCache() throws {
        let feedLoader = try makeFeedLoader()

        expect(feedLoader, toRetrieve: .success(.none))
    }
    
    func test_loadFeed_deliversFeedInsertedOnAnotherInstance() throws {
        let storeToInsert = try makeFeedLoader()
        let storeToLoad = try makeFeedLoader()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: storeToInsert)

        expect(storeToLoad, toRetrieve: .success(CachedFeed(feed: feed, timestamp: timestamp)))
    }
    
    func test_saveFeed_overridesFeedInsertedOnAnotherInstance() throws {
        let storeToInsert = try makeFeedLoader()
        let storeToOverride = try makeFeedLoader()
        let storeToLoad = try makeFeedLoader()

        insert((uniqueImageFeed().local, Date()), to: storeToInsert)

        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((latestFeed, latestTimestamp), to: storeToOverride)

        expect(storeToLoad, toRetrieve:  .success(CachedFeed(feed: latestFeed, timestamp: latestTimestamp)))
    }
    
    func test_delete_deletesFeedInsertedOnAnotherInstance() throws {
        let storeToInsert = try makeFeedLoader()
        let storeToDelete = try makeFeedLoader()
        let storeToLoad = try makeFeedLoader()

        insert((uniqueImageFeed().local, Date()), to: storeToInsert)

        deleteCache(from: storeToDelete)

        expect(storeToLoad, toRetrieve: .success(.none))
    }
    
    // MARK: Helpers
    private func makeFeedLoader(file: StaticString = #file, line: UInt = #line) throws -> FeedStore {
        let sut = try CoreDataFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func setupEmptyStoreState() throws {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() throws {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
