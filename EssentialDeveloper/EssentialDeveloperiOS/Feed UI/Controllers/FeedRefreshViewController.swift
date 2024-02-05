import UIKit
import EssentialDeveloper

final class FeedViewModel {
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    private enum State {
        case pending
        case loaded([FeedImage])
        case loading
        case failed
    }
    
    private var state = State.pending {
        didSet {
            onChange?(self)
        }
    }
    
    var onChange: ((FeedViewModel) -> Void)?
    
    var isLoading: Bool {
        switch state {
        case .loaded, .failed, .pending: return false
        case .loading: return true
        }
    }
    
    var feed: [FeedImage]? {
        switch state {
        case .loaded(let feedImage): return feedImage
        case .loading, .pending, .failed: return nil
        }
    }
    
    func loadFeed() {
        state = .loading
        
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.state = .loaded(feed)
            } else {
                self?.state = .failed
            }
        }
    }
}


public final class FeedRefreshViewController: NSObject {
    public lazy var view: UIRefreshControl = {
        return bind(UIRefreshControl())
    }()
    
    private let viewModel: FeedViewModel
    
    init(feedLoader: FeedLoader) {
        self.viewModel = FeedViewModel(feedLoader: feedLoader)
    }
    
    var onRefresh: (([FeedImage]) -> Void)?
    
    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    private func bind(_ view: UIRefreshControl) -> UIRefreshControl{
        viewModel.onChange = { [weak self] viewModel in
            if viewModel.isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
            
            if let feed = viewModel.feed {
                self?.onRefresh?(feed)
            }
        }
        
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        return view
    }
}
