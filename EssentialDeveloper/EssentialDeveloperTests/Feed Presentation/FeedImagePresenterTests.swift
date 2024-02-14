import XCTest
import EssentialDeveloper

struct FeedImageViewModel<Image>: Equatable where Image: Equatable {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool {
        return location != nil
    }
}

protocol FeedImageView {
    associatedtype Image: Equatable
    
    func display(_ model: FeedImageViewModel<Image>)
}

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image, Image: Equatable {
    private let view: View
    
    init(view: View) {
        self.view = view
    }
    
    struct InvalidImageDataError: Error, Equatable {}
    
    func didStartLoadingImageData(for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false))
    }
    
    func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        return didFinishLoadingImageData(with: InvalidImageDataError(), for: model)
    }
    
    private func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        return view.display(FeedImageViewModel(description: model.description, location: model.location, image: nil, isLoading: false, shouldRetry: true))
    }
        
}

final class FeedImagePresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertEqual(view.messages.isEmpty, true)
    }
    
    func test_didStartLoadingImageData_displaysInformationWithLoading() {
        let (sut, view) = makeSUT()
        let expectedModel = uniqueImage()
        let expectedFeedImageModel = FeedImageViewModel<AnyImage>(description: expectedModel.description, location: expectedModel.location, image: nil, isLoading: true, shouldRetry: false)
        
        sut.didStartLoadingImageData(for: expectedModel)
        
        XCTAssertEqual(view.messages, [.display(expectedFeedImageModel)])
    }
    
    func test_didFinishLoadingImageData_WithInvalidData_ShouldDisplayError() {
        let (sut, view) = makeSUT()
        let expectedModel = uniqueImage()
        let expectedErrorInformation = FeedImageViewModel<AnyImage>(
            description: expectedModel.description,
            location: expectedModel.location,
            image: nil,
            isLoading: false,
            shouldRetry: true)
        
        sut.didFinishLoadingImageData(with: anyData(), for: expectedModel)
        
        XCTAssertEqual(view.messages, [.display(expectedErrorInformation)])
    }
    
    // Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedImagePresenter<ImageViewSpy, AnyImage>, ImageViewSpy) {
        let view = ImageViewSpy()
        let sut = FeedImagePresenter(view: view)
        
        trackForMemoryLeaks(view)
        trackForMemoryLeaks(sut)
        return (sut, view)
    }
    private func anyData() -> Data {
        Data("any data".utf8)
    }
    
    
    struct AnyImage: Equatable {}

    final class ImageViewSpy: FeedImageView {
        
        enum Message: Equatable {
            case display(FeedImageViewModel<AnyImage>)
        }
        
        var messages = [Message]()
        
        func display(_ model: FeedImageViewModel<AnyImage>) {
            messages.append(.display(model))
        }
        
    }
}
