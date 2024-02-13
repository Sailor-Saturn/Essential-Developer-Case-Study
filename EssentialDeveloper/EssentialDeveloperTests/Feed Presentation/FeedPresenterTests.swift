
import XCTest

final class FeedPresenter {
    init(view: Any){
        
    }
}

final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let view = ViewSpy()
        
        XCTAssertTrue(view.messages.isEmpty, "Expected no view messages.")
    }

    // MARK: - Helpers
    private class ViewSpy {
        let messages = [Any]()
    }
}
