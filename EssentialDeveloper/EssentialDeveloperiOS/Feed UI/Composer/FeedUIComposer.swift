import EssentialDeveloper
import UIKit

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let presenter = FeedPresenter()
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader, presenter: presenter)
        
        let refreshController = FeedRefreshViewController(loadFeed: presentationAdapter.loadFeed)
        let feedController = FeedViewController(refreshController: refreshController)

        presenter.loadingView = WeakReferenceVirtualProxy(refreshController)
        presenter.feedView = FeedViewAdapter(controller: feedController, imageLoader: imageLoader)
        
        return feedController
    }
    
    private static func adaptFeedCellControllers(forwardingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        return { [weak controller] feed in
            controller?.tableModel = feed.map { model in
                FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: loader, imageTransformer: UIImage.init))
            }
        }
    }
}

private final class WeakReferenceVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakReferenceVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(viewModel: FeedLoadingViewModel) {
        object?.display(viewModel: viewModel)
    }
}

private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private var imageLoader: FeedImageDataLoader
    
    init(controller: FeedViewController? = nil, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { model in
            FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init))
        }
    }
}

private final class FeedLoaderPresentationAdapter {
    private let feedLoader: FeedLoader
    private let presenter: FeedPresenter
    
    init(feedLoader: FeedLoader, presenter: FeedPresenter) {
        self.feedLoader = feedLoader
        self.presenter = presenter
    }
    
    func loadFeed() {
        presenter.didStartLoadingFeed()
        
        feedLoader.load { [weak self] result in
            switch result {
            case let .success(feed):
                self?.presenter.didFinishLoadingFeed(with: feed)
                
            case let .failure(error):
                self?.presenter.didFinishLoadingFeed(with: error)
            }
        }
    }
}
