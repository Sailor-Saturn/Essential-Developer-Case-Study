import EssentialDeveloper

class StoreSpy: FeedImageStore {
    enum Message: Equatable {
        case retrieve
        case insert(data: Data, for: URL)
    }
    
    private var completions = [(FeedImageStore.Result) -> Void]()
    
    var receivedMessages = [Message]()
    
    func retrieveImageData(from url: URL, completion: @escaping (FeedImageStore.Result) -> Void) {
        receivedMessages.append(.retrieve)
        completions.append(completion)
    }
    
    func insert(data: Data, for url: URL, completion: @escaping (FeedImageStore.Result) -> Void) {
        receivedMessages.append(.insert(data: data, for: url))
    }
    
    func complete(with error: Error, at index: Int = 0){
        completions[index](.failure(error))
    }
    
    func complete(with data: Data?, at index: Int = 0){
        completions[index](.success(data))
    }
}
