import XCTest
import EssentialDeveloper
import CoreData

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    override func setUp() {
        super.setUp()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() throws  {
        try makeSut { sut in
            self.assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() throws  {
        try makeSut { sut in
            self.assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws  {
        try makeSut { sut in
            self.assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
        try makeSut { sut in
            self.assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
        }
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() throws  {
        try makeSut { sut in
            self.assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
        }
    }
    
    func test_insert_deliversNoErrorNonEmptyCache() throws  {
        try makeSut { sut in
            self.assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
        }
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() throws  {
        try makeSut { sut in
            self.assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
        }
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() throws  {
        try makeSut { sut in
            self.assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
        }
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() throws  {
        try makeSut { sut in
            self.assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
        }
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() throws  {
        try makeSut { sut in
            self.assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
        }
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() throws  {
        try makeSut { sut in
            self.assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
        }
    }
    
    func test_delete_deliversErrorOnDeletionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        try makeSut { sut in
            
            self.insert((feed, timestamp), to: sut)
            
            stub.startIntercepting()
            
            let deletionError = self.deleteCache(from: sut)
            
            XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
        }
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
    
    private func makeSut(_ test: @escaping (CoreDataFeedStore) -> Void, file: StaticString = #filePath, line: UInt = #line) throws {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        
        let exp = expectation(description: "wait for operation")
        sut.perform {
            test(sut)
            exp.fulfill()
        }
       
        wait(for: [exp], timeout: 0.1)
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
