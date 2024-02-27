public protocol FeedImageDataCache {
    typealias SaveResult = Result<Void, Error>
    
    func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void)
}
