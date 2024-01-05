import UIKit

protocol FeedLoader {
    func loadFeed(completion: @escaping ([String]) -> Void)
}

private class FeedViewController: UIViewController {
    var loader: FeedLoader!
    
    convenience init(loader: FeedLoader){
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader.loadFeed { loadFeed in
            // update UI
        }
    }
}

class RemoteFeedLoader: FeedLoader {
    func loadFeed(completion: @escaping ([String]) -> Void) {
        
    }
}

class LocalFeedLoader: FeedLoader {
    func loadFeed(completion: @escaping ([String]) -> Void) {
        
    }
}

struct Reachability {
    static let networkAvailable = false
}

class RemoteWithLocalFallbackFeedService: FeedLoader {
    let remote: RemoteFeedLoader
    let local: LocalFeedLoader
    
    init(remote: RemoteFeedLoader, local: LocalFeedLoader) {
        self.remote = remote
        self.local = local
    }
    
    func loadFeed(completion: @escaping ([String]) -> Void) {
        let load = Reachability.networkAvailable ?
        remote.loadFeed : local.loadFeed
        load(completion)
    }
}
