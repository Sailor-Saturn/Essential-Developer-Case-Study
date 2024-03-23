import UIKit
import EssentialDeveloper

public protocol FeedImageCellControllerDelegate {
    func didRequestImage()
    func didCancelImageRequest()
}

public final class FeedImageCellController: ResourceView, ResourceLoadingView, ResourceErrorView, FeedImageView{

    
    public typealias ResourceViewModel = UIImage
    
    private let viewModel: FeedImageViewModel<UIImage>
    private let delegate: FeedImageCellControllerDelegate
    private var cell: FeedImageCell?
    
    public init(viewModel: FeedImageViewModel<UIImage>, delegate: FeedImageCellControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    func view(in tableView: UITableView) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()
        cell?.locationContainer.isHidden = !viewModel.hasLocation
        cell?.locationLabel.text = viewModel.location
        cell?.descriptionLabel.text = viewModel.description
        cell?.onRetry = delegate.didRequestImage
        
        delegate.didRequestImage()
        return cell!
    }
    
    func preload() {
        delegate.didRequestImage()
    }
    
    func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelImageRequest()
    }
    
    func releaseCellForReuse() {
        cell = nil
    }
    
    public func display(_ viewModel: FeedImageViewModel<UIImage>) {
        
    }
    
    public func display(_ viewModel: UIImage) {
        cell?.feedImageView.setImageAnimated(viewModel)
    }
    
    public func display(_ viewModel: EssentialDeveloper.ResourceLoadingViewModel) {
        cell?.feedImageContainer.isShimmering = viewModel.isLoading
    }
    
    public func display(_ viewModel: EssentialDeveloper.ResourceErrorViewModel) {
        cell?.feedImageRetryButton.isHidden = viewModel.message == nil
    }
}
