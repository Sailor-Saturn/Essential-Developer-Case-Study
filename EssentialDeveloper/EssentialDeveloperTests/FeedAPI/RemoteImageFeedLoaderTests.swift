import XCTest
import EssentialDeveloper

final class RemoteImageLoader {
    init(client: HTTPClient) {
        
    }
}

final class RemoteImageFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSut()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // MARK: Helpers
    private func makeSut(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteImageLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteImageLoader(client: client)
        
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
