public protocol FeedImageStore {
    typealias Result = Swift.Result<Data?, Error>
    
    func retrieveImageData(from url: URL, completion: @escaping (Result) -> Void)
    
    func insert(data: Data, for url: URL, completion: @escaping (Result) -> Void)
}
