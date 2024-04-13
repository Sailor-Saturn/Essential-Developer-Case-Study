import UIKit
import EssentialDeveloper
import EssentialDeveloperiOS
import Combine

public final class FeedUIComposer {
    private init() {}
    
    private typealias FeedPresentationAdapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>
    
    public static func feedComposedWith(
        feedLoader: @escaping () -> AnyPublisher<Paginated<FeedImage>, Error>,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selection: @escaping (FeedImage) -> Void = {_ in}
    ) -> ListViewController {
        let presentationAdapter = FeedPresentationAdapter(loader: { feedLoader().dispatchOnMainThread() })
        
        let feedController = ListViewController.makeFeedViewControllerWith( title: FeedPresenter.title)
        feedController.onRefresh = presentationAdapter.loadResource
        
        presentationAdapter.presenter = LoadResourcePresenter(
            errorView: WeakRefVirtualProxy(feedController),
            loadingView: WeakRefVirtualProxy(feedController),
            resourceView: FeedViewAdapter(
                controller: feedController,
                imageLoader: {
                   imageLoader($0).dispatchOnMainThread()
                },
                selection: selection),
            mapper: { $0 }
        )
        
        return feedController
    }
}

private extension ListViewController {
    static func makeFeedViewControllerWith(title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! ListViewController
        feedController.title = FeedPresenter.title
        
        return feedController
    }
}

private final class FeedViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    private let selection: (FeedImage) -> Void
    private let currentFeed: [FeedImage: CellController]
    
    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>
    private typealias LoadMorePresentationAdapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>
    init(
        currentFeed: [FeedImage: CellController] = [:],
        controller: ListViewController,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selection: @escaping (FeedImage) -> Void
    ) {
        self.currentFeed = currentFeed
        self.controller = controller
        self.imageLoader = imageLoader
        self.selection = selection
    }
    
    func display(_ viewModel: Paginated<FeedImage>) {
        guard let controller = controller else { return }
        var currentFeed = self.currentFeed
        let feedSection: [CellController] = viewModel.items.map { model in
            if let controller = currentFeed[model] {
                return controller
            }
            
            let adapter = ImageDataPresentationAdapter(loader: { [imageLoader] in
                imageLoader(model.url)
            })
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(model),
                delegate: adapter,
                selection: { [selection] in
                    selection(model)
                }
            )
            
            adapter.presenter = LoadResourcePresenter(
                errorView: WeakRefVirtualProxy(view),
                loadingView: WeakRefVirtualProxy(view),
                resourceView: WeakRefVirtualProxy(view),
                mapper: { data in
                    guard let image = UIImage(data: data) else {
                        throw InvalidImageData()
                    }
                    return image
                    
                })
            
            let controller = CellController(id: model, view)
            currentFeed[model] = controller
            
            return controller
        }
        
        guard let loadMorePublisher = viewModel.loadMorePublisher else {
            controller.display(feedSection)
            return
        }
        let loadMoreAdapter = LoadMorePresentationAdapter(loader: { loadMorePublisher().dispatchOnMainThread() })
        let loadMoreCellController = LoadMoreCellController(callback: loadMoreAdapter.loadResource)

        loadMoreAdapter.presenter = LoadResourcePresenter(
            errorView: WeakRefVirtualProxy(loadMoreCellController),
            loadingView: WeakRefVirtualProxy(loadMoreCellController),
            resourceView: FeedViewAdapter(currentFeed: currentFeed, controller: controller, imageLoader: imageLoader, selection: selection),
            mapper: { $0 }
        )
        
        let loadMoreSection = [CellController(id: UUID(), loadMoreCellController)]
        
        controller.display(feedSection, loadMoreSection)
    }
}
private struct InvalidImageData: Error {}
