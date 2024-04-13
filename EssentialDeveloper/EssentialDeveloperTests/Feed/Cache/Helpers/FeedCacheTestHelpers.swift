import Foundation
import EssentialDeveloper

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let localItems = models.map {
        LocalFeedImage(id: $0.id, description:  $0.description, location: $0.location, url: $0.url)}
    return (models, localItems)
}

// MARK: Cache Policy DSL Helper
extension Date {
    
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    
    
}
