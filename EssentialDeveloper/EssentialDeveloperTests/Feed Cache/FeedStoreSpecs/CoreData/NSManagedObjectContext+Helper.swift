import CoreData

extension NSManagedObjectContext {
    func allExistingObjects() throws -> [NSManagedObject] {
        guard let model = persistentStoreCoordinator?.managedObjectModel else {
            return []
        }

        return try model
            .entities
            .compactMap { $0.name }
            .reduce([NSManagedObject](), { acc, entity in
                let request = NSFetchRequest<NSManagedObject>(entityName: entity)
                return try acc + fetch(request)
            })
    }
}
