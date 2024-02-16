import XCTest
import EssentialDeveloper

final class RemoteImageLoader {
    let client: HTTPClient
    let url: URL
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load(completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        client.get(from: url, completion: completion)
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
