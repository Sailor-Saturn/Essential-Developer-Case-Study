import XCTest


final class FeedImagePresenter {
    
    init(view: Any) {
    }
}

final class FeedImagePresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessagesToView() {
        let view = ImageViewSpy()
        
        let sut = FeedImagePresenter(view: view)
        
        XCTAssertEqual(view.messages.isEmpty, true)
    }
    
    final class ImageViewSpy {
        let messages = [Any]()
    }
}
