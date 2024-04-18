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
    
    func test_loadFeed_deliversNoItemsOnEmptyCache() throws {
        let feedLoader = try makeFeedLoader()
        
        expect(feedLoader, toLoad: [])
    }
    
    func test_loadFeed_deliversFeedInsertedOnAnotherInstance() throws {
        let feedLoaderToPerformSave = try makeFeedLoader()
        let feedLoaderToPerformLoad = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        save(feed, with: feedLoaderToPerformSave)
        
        expect(feedLoaderToPerformLoad, toLoad: feed)
    }
    
    func test_saveFeed_overridesFeedInsertedOnAnotherInstance() throws {
        let feedLoaderToPerformFirstSave = try makeFeedLoader()
        let feedLoaderToPerformLastSave = try makeFeedLoader()
        let feedLoaderToPerformLoad = try makeFeedLoader()
        
        let firstFeed = uniqueImageFeed().models
                let latestFeed = uniqueImageFeed().models
        
        save(firstFeed, with: feedLoaderToPerformFirstSave)
        
        save(latestFeed, with: feedLoaderToPerformLastSave)
        
        expect(feedLoaderToPerformLoad, toLoad: latestFeed)
    }
    
    func test_loadFeedImageData_deliversFeedInsertedOnAnotherInstance() throws {
        let storeToInsert = try makeFeedImage()
        let storeToLoad = try makeFeedImage()
        let feedLoader = try makeFeedLoader()
        let image = uniqueImage()
        let dataToSave = anyData()
        
        save([image], with: feedLoader)
        save(dataToSave, for: image.url, with: storeToInsert)
        
        expect(storeToLoad, toLoad: dataToSave, for: image.url)
    }
    
    func test_saveImageData_overridesSavedImageDataOnASeparateInstance() throws {
        let storeToInsertFirst = try makeFeedImage()
        let storeToInsertLast = try makeFeedImage()
        let storeToLoad = try makeFeedImage()
        let feedLoader = try makeFeedLoader()
        let image = uniqueImage()
        let dataToSaveFirst = Data("first".utf8)
        let dataToSaveLast = Data("last".utf8)
        
        save([image], with: feedLoader)
        save(dataToSaveFirst, for: image.url, with: storeToInsertFirst)
        save(dataToSaveLast, for: image.url, with: storeToInsertLast)
        
        expect(storeToLoad, toLoad: dataToSaveLast, for: image.url)
    }
    
    func test_validateFeedCache_doesNotDeleteRecentlySavedFeed() throws {
        let feedLoaderToPerformSave = try makeFeedLoader()
        let feedLoaderToPerformValidation = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        save(feed, with: feedLoaderToPerformSave)
        validateCache(with: feedLoaderToPerformValidation)
        
        expect(feedLoaderToPerformSave, toLoad: feed)
    }
    
    func test_validateFeedCache_deletesFeedSavedInADistantPast() throws {
        let feedLoaderToPerformSave = try makeFeedLoader(currentDate: .distantPast)
        let feedLoaderToPerformValidation = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        save(feed, with: feedLoaderToPerformSave)
        validateCache(with: feedLoaderToPerformValidation)
        
        expect(feedLoaderToPerformSave, toLoad: [])
    }
    
    // MARK: Helpers
    private func makeFeedLoader(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) throws -> LocalFeedLoader {
        let store = try CoreDataFeedStore(storeURL: testSpecificStoreURL())
        let sut = LocalFeedLoader(store: store, currentDate: {currentDate})
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage], file: StaticString = #filePath, line: UInt = #line) {
        do {
            let loadedFeed = try sut.load()
            XCTAssertEqual(loadedFeed, expectedFeed, file: file, line: line)
        } catch {
            XCTFail("Expected successful feed result, got \(error) instead", file: file, line: line)
        }
    }
    
    private func save(_ feed: [FeedImage], with loader: LocalFeedLoader, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try loader.save(feed)
        } catch {
            XCTFail("Expected to save feed successfully, got error: \(error)", file: file, line: line)
        }
    }
    
    private func validateCache(with loader: LocalFeedLoader, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try loader.validateCache()
        } catch {
            XCTFail("Expected to validate feed successfully, got error: \(error)", file: file, line: line)
        }
    }
    
    private func save(_ data: Data, for url: URL, with loader: LocalFeedImageDataLoader, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try loader.save(data, for: url)
        } catch {
            XCTFail("Expected to save image data successfully, got error: \(error)", file: file, line: line)
        }
    }
    
    private func expect(_ sut: LocalFeedImageDataLoader, toLoad expectedData: Data, for url: URL, file: StaticString = #filePath, line: UInt = #line) {
        do {
            let loadedData = try sut.loadImageData(from: url)
            XCTAssertEqual(loadedData, expectedData, file: file, line: line)
        } catch {
            XCTFail("Expected successful image data result, got \(error) instead", file: file, line: line)
        }
    }
    
    private func makeFeedImage(file: StaticString = #filePath, line: UInt = #line) throws -> LocalFeedImageDataLoader {
        let store = try CoreDataFeedStore(storeURL: testSpecificStoreURL())
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
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
