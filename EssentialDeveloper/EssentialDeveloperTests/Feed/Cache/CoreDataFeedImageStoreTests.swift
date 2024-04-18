import XCTest
import EssentialDeveloper

final class CoreDataFeedImageStoreTests: XCTestCase, FeedImageDataStoreSpecs {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() throws {
        try makeSUT { sut, imageDataURL in
            self.assertThatRetrieveImageDataDeliversNotFoundOnEmptyCache(on: sut, imageDataURL: imageDataURL)
        }
    }
    
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() throws {
        try makeSUT { sut, imageDataURL in
            self.assertThatRetrieveImageDataDeliversNotFoundWhenStoredDataURLDoesNotMatch(on: sut, imageDataURL: imageDataURL)
        }
    }
    
    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() throws {
        try makeSUT { sut, imageDataURL in
            self.assertThatRetrieveImageDataDeliversFoundDataWhenThereIsAStoredImageDataMatchingURL(on: sut, imageDataURL: imageDataURL)
        }
    }

    func test_retrieveImageData_deliversLastInsertedValue() throws {
        try makeSUT { sut, imageDataURL in
            self.assertThatRetrieveImageDataDeliversLastInsertedValueForURL(on: sut, imageDataURL: imageDataURL)
        }
    }
    
    
    private func makeSUT(_ test: @escaping (CoreDataFeedStore, URL) -> Void, file: StaticString = #filePath, line: UInt = #line) throws {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        let exp = expectation(description: "wait for operation")
        sut.perform {
            let imageDataURL = URL(string: "http://a-url.com")!
            insertFeedImage(with: imageDataURL, into: sut, file: file, line: line)
            test(sut, imageDataURL)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }
}

private func insertFeedImage(with url: URL, into sut: CoreDataFeedStore, file: StaticString = #filePath, line: UInt = #line) {
    do {
        let image = LocalFeedImage(id: UUID(), description: "any", location: "any", url: url)
        try sut.insert([image], timestamp: Date())
    } catch {
        XCTFail("Failed to insert feed image with URL \(url) - error: \(error)", file: file, line: line)
    }
}
protocol FeedImageDataStoreSpecs {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() throws
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() throws
    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() throws
    func test_retrieveImageData_deliversLastInsertedValue() throws
}


extension FeedImageDataStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveImageDataDeliversNotFoundOnEmptyCache(
        on sut: FeedImageDataStore,
        imageDataURL: URL = anyURL(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toCompleteRetrievalWith: notFound(), for: imageDataURL, file: file, line: line)
    }
    
    func assertThatRetrieveImageDataDeliversNotFoundWhenStoredDataURLDoesNotMatch(
        on sut: FeedImageDataStore,
        imageDataURL: URL = anyURL(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let nonMatchingURL = URL(string: "http://a-non-matching-url.com")!
        
        insert(anyData(), for: imageDataURL, into: sut, file: file, line: line)
        
        expect(sut, toCompleteRetrievalWith: notFound(), for: nonMatchingURL, file: file, line: line)
    }
    
    func assertThatRetrieveImageDataDeliversFoundDataWhenThereIsAStoredImageDataMatchingURL(
        on sut: FeedImageDataStore,
        imageDataURL: URL = anyURL(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let storedData = anyData()
        
        insert(storedData, for: imageDataURL, into: sut, file: file, line: line)
        
        expect(sut, toCompleteRetrievalWith: found(storedData), for: imageDataURL, file: file, line: line)
    }
    
    func assertThatRetrieveImageDataDeliversLastInsertedValueForURL(
        on sut: FeedImageDataStore,
        imageDataURL: URL = anyURL(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let firstStoredData = Data("first".utf8)
        let lastStoredData = Data("last".utf8)
        
        insert(firstStoredData, for: imageDataURL, into: sut, file: file, line: line)
        insert(lastStoredData, for: imageDataURL, into: sut, file: file, line: line)
        
        expect(sut, toCompleteRetrievalWith: found(lastStoredData), for: imageDataURL, file: file, line: line)
    }
}


extension FeedImageDataStoreSpecs where Self: XCTestCase {
    func notFound() -> Result<Data?, Error> {
        .success(.none)
    }
    
    func found(_ data: Data) -> Result<Data?, Error> {
        .success(data)
    }
    
    func expect(_ sut: FeedImageDataStore, toCompleteRetrievalWith expectedResult: Result<Data?, Error>, for url: URL,  file: StaticString = #filePath, line: UInt = #line) {
        let receivedResult = Result { try sut.retrieve(dataForURL: url) }
        
        switch (receivedResult, expectedResult) {
        case let (.success( receivedData), .success(expectedData)):
            XCTAssertEqual(receivedData, expectedData, file: file, line: line)
            
        default:
            XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
        }
    }
    
    func insert(_ data: Data, for url: URL, into sut: FeedImageDataStore, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try sut.insert(data, for: url)
        } catch {
            XCTFail("Failed to insert image data: \(data) - error: \(error)", file: file, line: line)
        }
    }
}
