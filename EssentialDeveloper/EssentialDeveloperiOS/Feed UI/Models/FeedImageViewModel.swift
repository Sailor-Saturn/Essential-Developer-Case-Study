import Foundation
import EssentialDeveloper

final class FeedImageViewModel<Image> {
    typealias Observer<T> = (T) -> Void
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    let imageLoader: FeedImageDataLoader
    var imageTransformer: (Data) -> Image?
    
    init( model: FeedImage, imageLoader: FeedImageDataLoader, imageTransformer: @escaping (Data) -> Image?) {
        self.model = model
        self.imageLoader = imageLoader
        self.imageTransformer = imageTransformer
    }
    
    var hasLocation: Bool {
        model.location != nil
    }
    
    var location: String? {
        model.location
    }
    
    var description: String? {
        model.description
    }
    
    var onImageLoad: Observer<Image>?
    var onLoadingStateChange: Observer<Bool>?
    var onShouldRetryImageLoadStateChange: Observer<Bool>?
    
    func loadImageData() {
        onLoadingStateChange?(true)
        
        self.task = imageLoader.loadImageData(from: model.url) {[weak self] result in
            self?.handleResult(result)
        }
    }
    
    private func handleResult(_ result: FeedImageDataLoader.Result) {
        if let image = (try? result.get()).flatMap(imageTransformer) {
            onImageLoad?(image)
        } else {
            onShouldRetryImageLoadStateChange?(true)
        }
        onLoadingStateChange?(false)
    }
    
    func cancelImageDataLoad() {
        task?.cancel()
        task = nil
    }
}
