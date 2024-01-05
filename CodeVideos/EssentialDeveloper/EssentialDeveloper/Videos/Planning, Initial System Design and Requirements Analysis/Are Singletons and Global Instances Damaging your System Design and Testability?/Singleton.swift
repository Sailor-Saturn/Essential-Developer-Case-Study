import UIKit

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
    var api = ApiClient.shared

    func didTapLoginButton () {
        api.login() { user in
            // show feed screen
        }
    }
}

private extension ApiClient {
    func login(completion: (LoggedInUser) -> Void) {}
}

// Feed Module
private class FeedViewController: UIViewController {
    var api = ApiClient.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        
        api.loadFeed { loadeditems in
            // update UI
        }
    }
}

private extension ApiClient {
    func loadFeed(completion: ([FeedItem]) -> Void) {}
}

private struct FeedItem {}
