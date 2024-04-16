import EssentialDeveloper

class FeedImageDataStoreSpy: FeedImageDataStore {
    enum Message: Equatable {
        case retrieve
        case insert(data: Data, for: URL)
    }
    
    private var retrievalResult: Result<Data?, Error>?
    private var insertionResult: Result<Void, Error>?
    
    var receivedMessages = [Message]()
    
    func insert(_ data: Data, for url: URL) throws {
        receivedMessages.append(.insert(data: data, for: url))
        try insertionResult?.get()
    }
    
    func retrieve(dataForURL url: URL) throws -> Data? {
        receivedMessages.append(.retrieve)
        return try retrievalResult?.get()
    }
    
    func completeRetrieval(with error: Error, at index: Int = 0){
        retrievalResult = .failure(error)
    }
    
    func completeRetrievalSuccessfully(with data: Data?, at index: Int = 0){
        retrievalResult = .success(data)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0){
        insertionResult = .failure(error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionResult = .success(())
    }
}
