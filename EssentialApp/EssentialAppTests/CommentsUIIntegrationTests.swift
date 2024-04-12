//
//  CommentsUIIntegrationTests.swift
//  EssentialAppTests
//
//  Created by Vera Dias on 02/04/2024.
//

import XCTest

import UIKit
import EssentialDeveloper
import EssentialDeveloperiOS
import EssentialApp
import Combine

final class CommentsUIIntegrationTests: XCTestCase {
    
    func test_commentView_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.title, commentsTitle)
    }
    
    func test_loadCommentsActions_requestCommentsFromLoader() {
        let (sut, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadCommentsCallCount, 0, "Expected no loading requests before view is loaded.")
        
        sut.simulateAppearance()
        
        XCTAssertEqual(loader.loadCommentsCallCount, 1, "Expected a loading request once view is loaded.")
        
        sut.simulateAppearance()
        
        sut.simulateUserInitiatedReload()
        
        XCTAssertEqual(loader.loadCommentsCallCount, 2,"Expected another loading requests once user initiates a load.")
        
        sut.simulateUserInitiatedReload()
        
        XCTAssertEqual(loader.loadCommentsCallCount, 3, "Expected a third loading requests once a user initiates another load.")
    }
    
    func test_loadingCommentsIndicator_isVisibleWhileLoadingComments() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded.")
        
        loader.completeCommentLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully.")
        
        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload.")
        
        loader.completeCommentsLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading completes with error.")
    }
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
        let comment0 = makeComments(message: "a description", username: "a location")
        let comment1 = makeComments(message: "another message", username: "another username")
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [ImageComment]())
        
        loader.completeCommentLoading(with: [comment0], at: 0)
        XCTAssertEqual(sut.numberOfRenderedCommentsViews(), 1)
        
        let _ = sut.commentView(at: 0)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeCommentLoading(with: [comment0, comment1], at: 1)
        assertThat(sut, isRendering: [comment0, comment1])
    }
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedCommentsAfterNonEmptyComments() {
        let comment0 = makeComments(message: "a description", username: "a location")
        
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        loader.completeCommentLoading(with: [comment0], at: 0)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeCommentLoading(with: [], at: 1)
        assertThat(sut, isRendering: [ImageComment]())
    }
    
    func test_loadedCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let comment0 = makeComments(message: "a description", username: "a location")
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeCommentLoading(with: [comment0], at: 0)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoadingWithError(at: 1)
        assertThat(sut, isRendering: [comment0])
    }

    func test_loadCommentsompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        let exp = expectation(description: "Wait for background queue.")
        
        DispatchQueue.global().async {
            loader.completeCommentLoading(at: 0)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_loadCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeCommentsLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeCommentsLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateErrorViewTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_deinit_cancelsRunningRequest() {
        var cancelCount = 0
        var sut: ListViewController?
        autoreleasepool {
            sut = CommentsUIComposer.commentsComposedWith {
                PassthroughSubject<[ImageComment], Error>()
                    .handleEvents(receiveCancel: {
                        cancelCount += 1
                    }).eraseToAnyPublisher()
            }
            
        }
        sut?.simulateAppearance()

        XCTAssertEqual(cancelCount, 0)
        
        sut = nil
        XCTAssertEqual(cancelCount, 1)
    }

    // MARK: Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ListViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CommentsUIComposer.commentsComposedWith(commentsLoader: loader.loadPublisher)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, loader)
    }
    
    private func makeComments(message: String, username: String) -> ImageComment {
        ImageComment(id: UUID(), message: message, createdAt: Date(), username: username)
    }
    
    private class LoaderSpy {
        private var requests = [PassthroughSubject<[ImageComment], Error>]()
        
        var loadCommentsCallCount: Int {
            requests.count
        }
        
        func loadPublisher() ->  AnyPublisher<[ImageComment], Error> {
            let publisher = PassthroughSubject<[ImageComment], Error>()
            requests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }
        
        func completeCommentLoading(with comments: [ImageComment] = [], at index: Int = 0) {
            requests[index].send(comments)
        }
        
        func completeCommentsLoadingWithError(at index: Int) {
            requests[index].send(completion: .failure(NSError()))
        }
    }
    
    private func assertThat(_ sut: ListViewController, isRendering comments: [ImageComment], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(sut.numberOfRenderedCommentsViews(), comments.count, "comments count", file: file, line: line)
        
        let viewModel = ImageCommentsPresenter.map(comments)
        
        viewModel.comments.enumerated().forEach { index, comment in
            XCTAssertEqual(sut.commentMessage(at: index), comment.message, "message at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentDate(at: index), comment.date, "date at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentUsername(at: index), comment.username, "username at \(index)", file: file, line: line)
        }
    }
}
