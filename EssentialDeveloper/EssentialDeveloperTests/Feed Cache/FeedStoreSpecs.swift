protocol FeedStoreSpecs {
    func test_retrieves_deliverEmptyOnEmptyCache()
    func test_retrieves_twice_hasNoSideEffects()
    func test_retrieve_deliversFoundValuesOnNonEmptyCache()
    func test_retrieve_twice_hasNoSideEffectsOnNonEmptyCache()
    
    func test_insert_deliversNoErrorOnEmptyCache()
    func test_insert_deliversNoErrorNonEmptyCache()
    func test_insert_overridesPreviouslyInsertedCacheValues()
    
    func test_delete_deliversNoErrorOnEmptyCache()
    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_deliversNoErrorOnNonEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()
    
    func test_storeSideEffects_RunSerially()
}

protocol FailableRetrieveSpecs: FeedStoreSpecs {
    func test_retrieve_twice_deliversFailureOnRetrievalError()
    func test_retrieve_deliversFailureOnRetrievalError()
}

protocol FailableInsertSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_hasNoSideEffectsOnDeletionError()
}

typealias FailableFeedStoreSpecs = FailableRetrieveSpecs & FailableInsertSpecs & FailableDeleteSpecs
