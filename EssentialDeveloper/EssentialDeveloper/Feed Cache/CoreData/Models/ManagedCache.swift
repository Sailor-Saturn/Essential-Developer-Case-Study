import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    var localFeed: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
    }
    
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    
    static func createNewUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try findAndDestroy(in: context)
        return ManagedCache(context: context)
    }
    
    static func findAndDestroy(in context: NSManagedObjectContext) throws {
        try find(in: context).map(context.delete)
    }
}
