import XCTest
import EssentialDeveloper
@testable import EssentialDeveloperiOS

final class ListSnapshotTests: XCTestCase {
    func test_emptyList() {
        let sut = makeSut()
        sut.display(emptyList())
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "EMPTY_LIST_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "EMPTY_LIST_dark")
    }
    
    func test_listWithErrorMessage() {
        let sut = makeSut()
        
        sut.display(.error(message: "This is a \n multiline \n error message"))
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "LIST_WITH_ERROR_MESSAGE_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "LIST_WITH_ERROR_MESSAGE_dark")
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark, contentSize: .extraExtraExtraLarge)), named: "LIST_WITH_ERROR_MESSAGE_dark_extraExtraExtraLarge")
    }
    
    // MARK: - Helpers
    private func makeSut() -> ListViewController {
        let controller = ListViewController()
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        
        return controller
    }
    
    private func emptyList() -> [CellController] {
        return []
    }
}
