import XCTest
@testable import NavigationBackport
import SwiftUI

@MainActor
final class CoordinatorTests: XCTestCase, @unchecked Sendable {
    
    var coordinator: Coordinator<[Int]>!
    fileprivate var mockNavController: MockNavigationController!
    var path: Binding<[Int]>!
    
    override func setUp() async throws {
        try await super.setUp()
        mockNavController = MockNavigationController()
        mockNavController.viewControllers = [UIViewController()] // Root controller
        coordinator = Coordinator<[Int]>()
        
        var pathValue: [Int] = []
        path = Binding<[Int]>(
            get: { pathValue },
            set: { pathValue = $0 }
        )
        
        coordinator.setup(mockNavController, path: path)
    }
    
    override func tearDown() async throws {
        mockNavController = nil
        coordinator = nil
        path = nil
        try await super.tearDown()
    }
    
    // Set up destination block for testing
    private func setupDestinationBlock() {
        coordinator.addDestinationBlock { value in
            guard let intValue = value as? Int else {
                return nil
            }
            return AnyView(Text("\(intValue)"))
        }
    }
    
    // MARK: - Push Tests
    
    func testPushSingleItemToEmptyStack() {
        // Arrange
        setupDestinationBlock()
        let newPath = [1]
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertEqual(mockNavController.viewControllers.count, 2)
        if let hostingVC = mockNavController.viewControllers[1] as? HostingController<Int> {
            XCTAssertEqual(hostingVC.element, 1)
        } else {
            XCTFail("Second view controller should be HostingController")
        }
    }
    
    func testPushMultipleItemsToEmptyStack() {
        // Arrange
        setupDestinationBlock()
        let newPath = [1, 2, 3]
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertEqual(mockNavController.viewControllers.count, 4) // Root + 3 items
        
        // Verify each controller has the expected element
        for i in 0..<3 {
            if let hostingVC = mockNavController.viewControllers[i+1] as? HostingController<Int> {
                XCTAssertEqual(hostingVC.element, i+1)
            } else {
                XCTFail("Expected HostingController at index \(i+1)")
            }
        }
    }
    
    // MARK: - Pop Tests
    
    func testPopToSpecificItem() {
        // Arrange
        setupDestinationBlock()
        
        // First set up a stack with 3 items
        coordinator.sync(with: [1, 2, 3])
        
        // Reset the tracking flags
        mockNavController.popToViewControllerCalled = false
        
        // Act - pop to the second item
        coordinator.sync(with: [1, 2])
        
        // Assert
        XCTAssertTrue(mockNavController.popToViewControllerCalled)
        
        // Verify the target controller is the one with element 2
        if let targetVC = mockNavController.popToViewControllerReceivedArguments?.viewController as? HostingController<Int> {
            XCTAssertEqual(targetVC.element, 2)
        } else {
            XCTFail("Expected to pop to a HostingController with element 2")
        }
    }
    
    func testPopToRoot() {
        // Arrange
        setupDestinationBlock()
        
        // First set up a stack with items
        coordinator.sync(with: [1, 2, 3])
        
        // Reset tracking flags
        mockNavController.popToRootViewControllerCalled = false
        
        // Act
        coordinator.sync(with: [])
        
        // Assert
        XCTAssertTrue(mockNavController.popToRootViewControllerCalled)
    }
    
    // MARK: - Hybrid Stack Tests
    
    func testHybridStackWithPushAnimation() {
        // Arrange
        setupDestinationBlock()
        
        // Set up initial stack
        coordinator.sync(with: [1, 2, 3])
        mockNavController.setViewControllersAnimatedCalled = false
        
        // Act - modify to have common prefix [1, 2] but then diverge
        coordinator.sync(with: [1, 2, 4, 5])
        
        // Assert
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
        XCTAssertEqual(mockNavController.viewControllers.count, 5) // Root + 4 items
        
        // Verify the controllers have the correct elements
        for (i, expectedValue) in [1, 2, 4, 5].enumerated() {
            if let hostingVC = mockNavController.viewControllers[i+1] as? HostingController<Int> {
                XCTAssertEqual(hostingVC.element, expectedValue)
            } else {
                XCTFail("Expected HostingController at index \(i+1)")
            }
        }
    }
    
    func testHybridStackWithPopAnimation() {
        // Arrange
        setupDestinationBlock()
        
        // Set up initial stack
        coordinator.sync(with: [1, 2, 4, 5])
        mockNavController.setViewControllersAnimatedCalled = false
        
        // Act - modify to have common prefix [1, 2] but then diverge with shorter path
        coordinator.sync(with: [1, 2, 3])
        
        // Assert
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
        
        // Check the final state of the navigation stack
        XCTAssertEqual(mockNavController.viewControllers.count, 4) // Root + 3 items
        
        // Verify the elements are correct
        let expectedValues = [1, 2, 3]
        for (i, expectedValue) in expectedValues.enumerated() {
            if let hostingVC = mockNavController.viewControllers[i+1] as? HostingController<Int> {
                XCTAssertEqual(hostingVC.element, expectedValue)
            } else {
                XCTFail("Expected HostingController at index \(i+1)")
            }
        }
    }
    
    // MARK: - Back Button Tests
    
        func testBackButtonUpdatesSyncedPath() {
            // Arrange
            setupDestinationBlock()
    
            var pathValue = [1, 2]
            path = Binding<[Int]>(
                get: { pathValue },
                set: { pathValue = $0 }
            )
            coordinator.setup(mockNavController, path: path)
    
            // Set up the stack
            coordinator.sync(with: pathValue)
    
            // Simulate navigation controller popping the last view controller
            let remainingControllers = Array(mockNavController.viewControllers.dropLast())
    
            // Act - simulate back button by updating the navigation stack
            mockNavController.viewControllers = remainingControllers
    
            // Assert
            XCTAssertEqual(pathValue, [1])
        }
    
    // MARK: - Duplicate Element Tests

    func testPathWithDuplicateElements() {
        // Arrange
        setupDestinationBlock()
        let newPath = [1, 2, 2, 3] // Contains duplicate 2
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertEqual(mockNavController.viewControllers.count, 5) // Root + 4 items
        
        // Verify each controller has the expected element including duplicates
        for (i, expectedValue) in [1, 2, 2, 3].enumerated() {
            if let hostingVC = mockNavController.viewControllers[i+1] as? HostingController<Int> {
                XCTAssertEqual(hostingVC.element, expectedValue)
            } else {
                XCTFail("Expected HostingController at index \(i+1)")
            }
        }
    }

    func testNavigatingFromDuplicatesToUnique() {
        // Arrange
        setupDestinationBlock()
        
        // First set up a stack with duplicate elements
        coordinator.sync(with: [1, 2, 2, 3])
        mockNavController.setViewControllersAnimatedCalled = false
        
        // Act - change to path without duplicates
        coordinator.sync(with: [1, 2, 3, 4])
        
        // Assert
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
        XCTAssertEqual(mockNavController.viewControllers.count, 5) // Root + 4 items
        
        // Verify the elements are correct
        let expectedValues = [1, 2, 3, 4]
        for (i, expectedValue) in expectedValues.enumerated() {
            if let hostingVC = mockNavController.viewControllers[i+1] as? HostingController<Int> {
                XCTAssertEqual(hostingVC.element, expectedValue)
            } else {
                XCTFail("Expected HostingController at index \(i+1)")
            }
        }
    }

    func testNavigatingToPathWithDuplicatesAtEnd() {
        // Arrange
        setupDestinationBlock()
        
        // Set up initial stack
        coordinator.sync(with: [1, 2, 3])
        mockNavController.setViewControllersAnimatedCalled = false
        
        // Act - append duplicates at the end
        coordinator.sync(with: [1, 2, 3, 3, 3])
        
        // Assert
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
        XCTAssertEqual(mockNavController.viewControllers.count, 6) // Root + 5 items
        
        // Verify the elements are correct
        let expectedValues = [1, 2, 3, 3, 3]
        for (i, expectedValue) in expectedValues.enumerated() {
            if let hostingVC = mockNavController.viewControllers[i+1] as? HostingController<Int> {
                XCTAssertEqual(hostingVC.element, expectedValue)
            } else {
                XCTFail("Expected HostingController at index \(i+1)")
            }
        }
    }

    func testNavigatingToPathWithDuplicatesInMiddle() {
        // Arrange
        setupDestinationBlock()
        
        // Set up initial stack
        coordinator.sync(with: [1, 2, 3, 4])
        mockNavController.setViewControllersAnimatedCalled = false
        
        // Act - create duplicates in the middle
        coordinator.sync(with: [1, 2, 2, 2, 4])
        
        // Assert
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
        XCTAssertEqual(mockNavController.viewControllers.count, 6) // Root + 5 items
        
        // Verify the elements are correct
        let expectedValues = [1, 2, 2, 2, 4]
        for (i, expectedValue) in expectedValues.enumerated() {
            if let hostingVC = mockNavController.viewControllers[i+1] as? HostingController<Int> {
                XCTAssertEqual(hostingVC.element, expectedValue)
            } else {
                XCTFail("Expected HostingController at index \(i+1)")
            }
        }
    }

    func testPoppingFromPathWithDuplicates() {
        // Arrange
        setupDestinationBlock()
        
        // First set up a stack with duplicate elements
        coordinator.sync(with: [1, 2, 2, 2, 3])
        mockNavController.popToViewControllerCalled = false
        
        // Act - pop back to first instance of 2
        coordinator.sync(with: [1, 2])
        
        // Assert
        XCTAssertTrue(mockNavController.popToViewControllerCalled)
        
        // Verify we popped to the first instance of 2
        if let targetVC = mockNavController.popToViewControllerReceivedArguments?.viewController as? HostingController<Int> {
            XCTAssertEqual(targetVC.element, 2)
            // Ideally we'd verify it's the first instance, but that's hard in this test framework
        } else {
            XCTFail("Expected to pop to a HostingController with element 2")
        }
    }

    func testBackButtonWithDuplicateElements() {
        // Arrange
        setupDestinationBlock()
        
        var pathValue = [1, 2, 2, 3]
        path = Binding<[Int]>(
            get: { pathValue },
            set: { pathValue = $0 }
        )
        coordinator.setup(mockNavController, path: path)
        
        // Set up the stack
        coordinator.sync(with: pathValue)
        
        // Simulate navigation controller popping the last view controller
        let remainingControllers = Array(mockNavController.viewControllers.dropLast())
        
        // Act - simulate back button by updating the navigation stack
        mockNavController.viewControllers = remainingControllers
        
        // Assert
        XCTAssertEqual(pathValue, [1, 2, 2])
    }
}

// MARK: - Mock UINavigationController

@MainActor
private class MockNavigationController: UINavigationController {
    var setViewControllersAnimatedCalled = false
    var popToViewControllerCalled = false
    var popToRootViewControllerCalled = false
    var popViewControllerCalled = false
    
    var popToViewControllerReceivedArguments: (viewController: UIViewController, animated: Bool)?
    
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: false)
        delegate?.navigationController?(self, willShow: UIViewController(), animated: false)
        setViewControllersAnimatedCalled = true
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        popToViewControllerCalled = true
        popToViewControllerReceivedArguments = (viewController, animated)
        
        // Update controllers to simulate the pop
        if let index = viewControllers.firstIndex(of: viewController) {
            viewControllers = Array(viewControllers[0...index])
        }
        delegate?.navigationController?(self, willShow: UIViewController(), animated: false)
        
        return nil
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        popToRootViewControllerCalled = true
        if !viewControllers.isEmpty {
            viewControllers = [viewControllers[0]]
        }
        delegate?.navigationController?(self, willShow: UIViewController(), animated: false)
        return nil
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        popViewControllerCalled = true
        if viewControllers.count > 1 {
            let popped = viewControllers.removeLast()
            return popped
        }
        delegate?.navigationController?(self, willShow: UIViewController(), animated: false)
        return nil
    }
}
