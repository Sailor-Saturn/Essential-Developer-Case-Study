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
    
    func didStartLoadingImageData(for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false))
    }
}

final class FeedImagePresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertEqual(view.messages.isEmpty, true)
    }
    
    func test_didFinishLoadingImageData_displaysInformation() {
        let (sut, view) = makeSUT()
        let expectedModel = uniqueImage()
        let expectedFeedImageModel = FeedImageViewModel<AnyImage>(description: expectedModel.description, location: expectedModel.location, image: nil, isLoading: true, shouldRetry: false)
        
        sut.didStartLoadingImageData(for: expectedModel)
        
        XCTAssertEqual(view.messages, [.display(expectedFeedImageModel)])
    }
    
    // Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedImagePresenter<ImageViewSpy, AnyImage>, ImageViewSpy) {
        let view = ImageViewSpy()
        let sut = FeedImagePresenter(view: view)
        
        trackForMemoryLeaks(view)
        trackForMemoryLeaks(sut)
        return (sut, view)
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
