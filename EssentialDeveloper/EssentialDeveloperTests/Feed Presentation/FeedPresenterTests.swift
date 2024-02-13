
import XCTest

final class FeedPresenter {
    init(view: Any){
        
    }
}

final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {        
        let(_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty, "Expected no view messages.")
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = FeedPresenter(view: view)
        
        trackForMemoryLeaks(view)
        trackForMemoryLeaks(sut)
        return (sut, view)
    }
    
    private class ViewSpy {
        let messages = [Any]()
    }
}
