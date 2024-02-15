import XCTest
import EssentialDeveloper
import CoreData

class CoreDataFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    override func setUp() {
        super.setUp()
        
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() throws  {
        let sut = try makeSut()
        
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() throws  {
        let sut = try makeSut()
        
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws  {
        let sut = try makeSut()
        
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
        let sut = try makeSut()

        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() throws  {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = try makeSut()

        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() throws  {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = try makeSut()

        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() throws  {
        let sut = try makeSut()
        
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorNonEmptyCache() throws  {
        let sut = try makeSut()
        
        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() throws  {
        let sut = try makeSut()
        
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_insert_deliversErrorOnInsertionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()

        let sut = try makeSut()

        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()

        let sut = try makeSut()

        assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() throws  {
        let sut = try makeSut()
        
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() throws  {
        let sut = try makeSut()
        
        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() throws  {
        let sut = try makeSut()
        
        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() throws  {
        let sut = try makeSut()
        
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_deliversErrorOnDeletionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let sut = try makeSut()

        insert((feed, timestamp), to: sut)

        stub.startIntercepting()

        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let sut = try makeSut()

        insert((feed, timestamp), to: sut)

        stub.startIntercepting()

        deleteCache(from: sut)

        expect(sut, toRetrieve: .success(CachedFeed(feed: feed, timestamp: timestamp)))
    }
    
    func test_delete_removesAllObjects() throws {
        let store = try makeSut()

        insert((uniqueImageFeed().local, Date()), to: store)

        deleteCache(from: store)

        let context = try NSPersistentContainer.load(
            name: CoreDataFeedStore.modelName,
            model: XCTUnwrap(CoreDataFeedStore.model),
            url: inMemoryStoreURL()
        ).viewContext

        let existingObjects = try context.allExistingObjects()

        XCTAssertEqual(existingObjects, [], "found orphaned objects in Core Data")
    }
    
    func test_storeSideEffects_RunSerially() throws  {
        let sut = try makeSut()

        assertThatSideEffectsRunSerially(on: sut)
    }
    
    func test_imageEntity_properties() throws {
        let entity = try XCTUnwrap(
            CoreDataFeedStore.model?.entitiesByName["ManagedFeedImage"]
        )

        entity.verify(attribute: "id", hasType: .UUIDAttributeType, isOptional: false)
        entity.verify(attribute: "imageDescription", hasType: .stringAttributeType, isOptional: true)
        entity.verify(attribute: "location", hasType: .stringAttributeType, isOptional: true)
        entity.verify(attribute: "url", hasType: .URIAttributeType, isOptional: false)
    }
    
    private func makeSut(file: StaticString = #file, line: UInt = #line) throws -> FeedStore {
        let sut = try CoreDataFeedStore(storeURL: inMemoryStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
}

extension CoreDataFeedStore.ModelNotFound: CustomStringConvertible {
    public var description: String {
        "Core Data Model '\(modelName).xcdatamodeld' not found. You need to create it in the production target."
    }
}
