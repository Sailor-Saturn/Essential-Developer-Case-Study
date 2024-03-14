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

