import UIKit

// Main Module aka adaptors
private extension ApiClient {
    func login(completion: (LoggedInUser) -> Void) {}
}

private extension ApiClient {
    func loadFeed(completion: ([FeedItem]) -> Void) {}
}

// Api Module
private class ApiClient {
    static let shared = ApiClient()
    
    private init() {}
    func execute(_: URLRequest, completion: (Data) -> Void) {}
}

private class MockApiClient: ApiClient {}

// Login Module
private struct LoggedInUser {}

private class LoginViewController: UIViewController {
    var login: (((LoggedInUser) -> Void) -> Void)?

    func didTapLoginButton () {
        login? { user in
            // show feed screen
        }
    }
}

// Feed Module
private class FeedViewController: UIViewController {
    var loadItems: ((([FeedItem]) -> Void) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadItems? { loadeditems in
            // update UI
        }
    }
}

private struct FeedItem {}
