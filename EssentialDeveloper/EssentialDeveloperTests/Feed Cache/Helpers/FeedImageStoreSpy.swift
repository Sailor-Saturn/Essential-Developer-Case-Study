import EssentialDeveloper

class StoreSpy: FeedImageStore {
    enum Message: Equatable {
        case retrieve
        case insert(data: Data, for: URL)
    }
    
    private var retrievalCompletions = [(FeedImageStore.Result) -> Void]()
    
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
    
    func insert(data: Data, for url: URL, completion: @escaping (FeedImageStore.Result) -> Void) {
        receivedMessages.append(.insert(data: data, for: url))
    }
}
