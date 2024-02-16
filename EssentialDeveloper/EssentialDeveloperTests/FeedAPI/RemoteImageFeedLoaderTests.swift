import XCTest
import EssentialDeveloper

final class RemoteImageLoader {
    let client: HTTPClient
    let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load(completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.failure(.invalidData))
            case .failure(let error):
                completion(.failure(.connectivity))
            }
        }
    }
}

final class RemoteImageFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSut()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) = makeSut(url: url)
        
        sut.load{ _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) = makeSut(url: url)
        
        sut.load{ _ in }
        sut.load{ _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSut()
        let error = NSError(domain: "Test", code: 0)
        let expectation = expectation(description: "Wait for load completion with error.")
        
        sut.load{ result in
            switch result {
            case .success(let success):
                XCTFail("Expected error due to client error, got \(success) instead.")
            case .failure(let failure):
                XCTAssertEqual(failure, .connectivity)
            }
            
            expectation.fulfill()
        }
        
        client.complete(with: error)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSut()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expectConnectivityError(
                sut: sut,
                client: client,
                action: { client.complete(withStatusCode: code, data: anyData(), at: index) }
            )
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSut()
        
        let expectation = expectation(description: "Wait for load completion with error.")
        
        sut.load{ result in
            switch result {
            case .success(let success):
                XCTFail("Expected error due to client error, got \(success) instead.")
            case .failure(let failure):
                XCTAssertEqual(failure, .invalidData)
            }
            
            expectation.fulfill()
        }
        
        client.complete(withStatusCode: 200, data: Data("invalid json".utf8))
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func expectConnectivityError(sut: RemoteImageLoader, client: HTTPClientSpy, action: () -> Void ) {
        let expectation = expectation(description: "Wait for load completion with error.")
        sut.load{ result in
            switch result {
            case .success(let success):
                XCTFail("Expected error due to client error, got \(success) instead.")
            case .failure(let failure):
                XCTAssertEqual(failure, .invalidData)
            }
            
            expectation.fulfill()
        }
        
        action()
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: Helpers
    private func makeSut(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteImageLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteImageLoader(client: client, url: url)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        
        return (sut, client)
    }
    
    private func anyData() -> Data {
        Data("any data".utf8)
    }
    
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(
            url: URL,
            completion:  (HTTPClient.Result) -> Void
        )]()
        
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        func get(
            from url: URL,
            completion: @escaping (HTTPClient.Result) -> Void
        ) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(
            withStatusCode code: Int,
            data: Data,
            at index: Int = 0
        ) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            
            
            messages[index].completion(.success((data, response)))
        }
    }
}
