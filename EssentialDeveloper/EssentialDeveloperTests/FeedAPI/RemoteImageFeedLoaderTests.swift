import XCTest
import EssentialDeveloper

final class RemoteFeedImageDataLoader {
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
    
    private final class HTTPURLPropertyWrapper: FeedImageDataLoaderTask {
        var completion: (Result<Data, Error>) -> Void
        
        var wrapped: HTTPClientTask?
        
        init(completion: @escaping (Result<Data, Error>) -> Void) {
            self.completion = completion
        }
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) -> FeedImageDataLoaderTask {
        let task = HTTPURLPropertyWrapper(completion: completion)
        
        task.wrapped = client.get(from: url) { result in
            switch result {
            case let .success((data, response)) where response.statusCode == 200:
                guard !data.isEmpty
                else {
                    completion(.failure(.invalidData))
                    return
                }
                completion(.success(data))
            case .success:
                completion(.failure(.invalidData))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
        
        return task
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
        
        _ = sut.loadImageData(from: url){ _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) = makeSut(url: url)
        
        _ = sut.loadImageData(from: url){ _ in }
        _ = sut.loadImageData(from: url){ _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSut()
        let clientError = NSError(domain: "a client error", code: 0)
        
        expect(
            sut,
            toCompleteWith: failure(.connectivity),
            when: {
                client.complete(with: clientError)
            }
        )
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSut()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(
                sut,
                toCompleteWith: failure(.invalidData),
                when: {
                    client.complete(withStatusCode: code, data: anyData(), at: index)
                }
            )
        }
    }
    
    func test_loadImageDataFromURL_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        let (sut, client) = makeSut()
        
        expect(
            sut,
            toCompleteWith: failure(.invalidData),
            when: {
                client.complete(withStatusCode: 200, data: Data())
            }
        )
    }
    
    // MARK: Happy Path
    func test_loadImageDataFromURL_deliversReceivedNonEmptyDataOn200HTTPResponse() {
        let (sut, client) = makeSut()
        let nonEmptyData = Data("non-empty data".utf8)
        
        expect(
            sut,
            toCompleteWith: .success(nonEmptyData),
            when: {
                client.complete(withStatusCode: 200, data: nonEmptyData)
            }
        )
    }
    
    func test_cancelLoadImageDataURLTask_cancelsClientURLRequest() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSut(url: url)
        
        let task = sut.loadImageData(from: url){ _ in }
        XCTAssertEqual(client.cancelledURLs, [])
        
        task.cancel()
        
        XCTAssertEqual(client.cancelledURLs, [url])
    }
    
    // MARK: Helpers
    private func makeSut(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteFeedImageDataLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedImageDataLoader(client: client, url: url)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        
        return (sut, client)
    }
    
    
    
    private func failure(_ error: RemoteFeedImageDataLoader.Error) -> FeedImageDataLoader.Result {
        return .failure(error)
    }
    
    private func expect(_ sut: RemoteFeedImageDataLoader, toCompleteWith expectedResult: FeedImageDataLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let url = URL(string: "https://a-given-url.com")!
        let exp = expectation(description: "Wait for load completion")
        
        _ = sut.loadImageData(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            case let (.failure(receivedError), .failure(expectedError as RemoteFeedImageDataLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
}
