import XCTest
import EssentialDeveloper

final class SharedLocalizationStrings: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Feed"
        let bundle = Bundle(for: LoadResourcePresenter<Any, DummyView>.self)
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }

    // MARK: - Helpers
    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {
            
        }
    }
}
