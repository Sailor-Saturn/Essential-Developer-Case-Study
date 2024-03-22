import Foundation

func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "any eror", code: 0)
}

func anyData() -> Data {
    Data("any data".utf8)
}

func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let itemsJSON = ["items": items]
    return try! JSONSerialization.data(withJSONObject: itemsJSON)
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
