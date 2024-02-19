import EssentialDeveloper

class FeedImageDataStoreSpy: FeedImageStore {
    enum Message: Equatable {
        case retrieve
        case insert(data: Data, for: URL)
    }
    
    private var retrievalCompletions = [(FeedImageStore.Result) -> Void]()
    private var insertionCompletions = [(LocalFeedImageDataLoader.SaveResult) -> Void]()
    
    var receivedMessages = [Message]()
    
    func retrieveImageData(from url: URL, completion: @escaping (FeedImageStore.Result) -> Void) {
        receivedMessages.append(.retrieve)
        retrievalCompletions.append(completion)
    }
    
    func completeRetrieval(with error: Error, at index: Int = 0){
        retrievalCompletions[index](.failure(error))
    }
    
    func completeRetrievalSuccessfully(with data: Data?, at index: Int = 0){
        retrievalCompletions[index](.success(data))
    }
    
    func insert(data: Data, for url: URL, completion: @escaping (LocalFeedImageDataLoader.SaveResult) -> Void) {
        receivedMessages.append(.insert(data: data, for: url))
        insertionCompletions.append(completion)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0){
        insertionCompletions[index](.failure(error))
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](.success(()))
    }
}
