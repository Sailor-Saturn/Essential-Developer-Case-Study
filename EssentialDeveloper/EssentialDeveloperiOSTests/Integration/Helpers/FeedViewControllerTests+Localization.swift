import Foundation
import XCTest
import EssentialDeveloperiOS

extension FeedUIIntegrationTests {
    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "FeedTests"
        let bundle = Bundle(for: FeedUIIntegrationTests.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        
        if value == key {
            XCTFail("Missing localized string for key: \(key), in table: \(table)", file: file, line: line)
        }
        return value
    }
}
