import Foundation
import XCTest
import EssentialDeveloperiOS

extension FeedViewControllerTests {
    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "Feed"
        let bundle = Bundle(for: FeedViewController.self)
        let localizedKey = "FEED_VIEW_TITLE"
        let value = bundle.localizedString(forKey: localizedKey, value: nil, table: table)
        
        if value == key {
            XCTFail("Missing localized string for key: \(key), in table: \(table)", file: file, line: line)
        }
        return value
    }
}
