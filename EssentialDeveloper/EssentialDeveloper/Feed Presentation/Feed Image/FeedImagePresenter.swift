import Foundation

public protocol FeedImageView {
    associatedtype Image: Equatable
    
    func display(_ model: FeedImageViewModel<Image>)
}

public final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image, Image: Equatable {
    private let view: View
    private let imageTransformer: (Data) -> Image?
    
    public init(view: View,  imageTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
    }
    
    struct InvalidImageDataError: Error, Equatable {}
    
    public func didStartLoadingImageData(for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false))
    }
    
    public func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        guard let image = imageTransformer(data) else {
            return didFinishLoadingImageData(with: InvalidImageDataError(), for: model)
        }
        
        return  view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: image,
            isLoading: false,
            shouldRetry: false)
        )
    }
    
    public func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        return view.display(FeedImageViewModel(description: model.description, location: model.location, image: nil, isLoading: false, shouldRetry: true))
    }
 
    public static func map(_ image: FeedImage) -> FeedImageViewModel<Image>{
        FeedImageViewModel(description: image.description, location: image.location, image: nil, isLoading: false, shouldRetry: false)
    }
}
