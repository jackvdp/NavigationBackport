import XCTest
@testable import NavigationBackport

@MainActor
final class CoordinatorTests: XCTestCase {
    
    var coordinator: Coordinator<[Int]>!
    var mockNavController: MockNavigationController!
    var path: Binding<[Int]>!
    
    override func setUp() async throws {
        super.setUp()
        mockNavController = MockNavigationController()
        coordinator = Coordinator<[Int]>()
        path = Binding<[Int]>(get: { [] }, set: { _ in })
        coordinator.setup(mockNavController, path: path)
    }
    
    override func tearDown() async throws {
        mockNavController = nil
        coordinator = nil
        path = nil
        super.tearDown()
    }
    
    // MARK: - Simple Push Tests
    
    func testPushSingleItemToEmptyStack() {
        // Arrange
        mockNavController.viewControllers = [UIViewController()] // Root VC
        let newPath = [1]
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertEqual(mockNavController.viewControllers.count, 2)
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
    }
    
    func testPushMultipleItemsToExistingStack() {
        // Arrange
        let rootVC = UIViewController()
        let item1VC = HostingController(rootView: AnyView(Text("1")), element: 1)
        mockNavController.viewControllers = [rootVC, item1VC]
        let newPath = [1, 2, 3]
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertEqual(mockNavController.viewControllers.count, 4) // Root + 3 items
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
    }
    
    // MARK: - Pop Tests
    
    func testPopToSpecificItem() {
        // Arrange
        let rootVC = UIViewController()
        let item1VC = HostingController(rootView: AnyView(Text("1")), element: 1)
        let item2VC = HostingController(rootView: AnyView(Text("2")), element: 2)
        let item3VC = HostingController(rootView: AnyView(Text("3")), element: 3)
        mockNavController.viewControllers = [rootVC, item1VC, item2VC, item3VC]
        let newPath = [1, 2]
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertTrue(mockNavController.popToViewControllerCalled)
        XCTAssertEqual(mockNavController.popToViewControllerReceivedArguments?.viewController, item2VC)
    }
    
    func testPopToRoot() {
        // Arrange
        let rootVC = UIViewController()
        let item1VC = HostingController(rootView: AnyView(Text("1")), element: 1)
        let item2VC = HostingController(rootView: AnyView(Text("2")), element: 2)
        mockNavController.viewControllers = [rootVC, item1VC, item2VC]
        let newPath: [Int] = []
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertTrue(mockNavController.popToRootViewControllerCalled)
    }
    
    // MARK: - Hybrid Stack Tests
    
    func testHybridStackWithPushAnimation() {
        // Arrange
        let rootVC = UIViewController()
        let item1VC = HostingController(rootView: AnyView(Text("1")), element: 1)
        let item2VC = HostingController(rootView: AnyView(Text("2")), element: 2)
        let item3VC = HostingController(rootView: AnyView(Text("3")), element: 3)
        mockNavController.viewControllers = [rootVC, item1VC, item2VC, item3VC]
        let newPath = [1, 2, 4, 5] // Common prefix [1, 2], then diverges
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
        XCTAssertEqual(mockNavController.viewControllers.count, 5) // Root + 4 items
        
        // Verify the first two elements remain the same
        if let hostingVC1 = mockNavController.viewControllers[1] as? HostingController<Int> {
            XCTAssertEqual(hostingVC1.element, 1)
        } else {
            XCTFail("Expected HostingController at index 1")
        }
        
        if let hostingVC2 = mockNavController.viewControllers[2] as? HostingController<Int> {
            XCTAssertEqual(hostingVC2.element, 2)
        } else {
            XCTFail("Expected HostingController at index 2")
        }
    }
    
    func testHybridStackWithPopAnimation() {
        // Arrange
        let rootVC = UIViewController()
        let item1VC = HostingController(rootView: AnyView(Text("1")), element: 1)
        let item2VC = HostingController(rootView: AnyView(Text("2")), element: 2)
        let item4VC = HostingController(rootView: AnyView(Text("4")), element: 4)
        let item5VC = HostingController(rootView: AnyView(Text("5")), element: 5)
        mockNavController.viewControllers = [rootVC, item1VC, item2VC, item4VC, item5VC]
        let newPath = [1, 2, 3] // Common prefix [1, 2], then diverges, shorter than before
        
        // Act
        coordinator.sync(with: newPath)
        
        // Assert
        XCTAssertTrue(mockNavController.setViewControllersAnimatedCalled)
        XCTAssertTrue(mockNavController.popViewControllerCalled)
    }
    
    // MARK: - Navigation Delegate Tests
    
    func testManualBackButtonUpdatesPath() {
        // Arrange
        let rootVC = UIViewController()
        let item1VC = HostingController(rootView: AnyView(Text("1")), element: 1)
        let item2VC = HostingController(rootView: AnyView(Text("2")), element: 2)
        mockNavController.viewControllers = [rootVC, item1VC, item2VC]
        
        var pathValue = [1, 2]
        path = Binding<[Int]>(
            get: { pathValue },
            set: { pathValue = $0 }
        )
        coordinator.path = path
        
        // Act - simulate back button press
        coordinator.navigationController(mockNavController, willShow: item1VC, animated: true)
        
        // Assert
        XCTAssertEqual(pathValue, [1]) // Should have removed the last item
    }
    
    func testProgrammaticUpdateDoesNotModifyPath() {
        // Arrange
        let rootVC = UIViewController()
        let item1VC = HostingController(rootView: AnyView(Text("1")), element: 1)
        let item2VC = HostingController(rootView: AnyView(Text("2")), element: 2)
        mockNavController.viewControllers = [rootVC, item1VC, item2VC]
        
        var pathValue = [1, 2]
        path = Binding<[Int]>(
            get: { pathValue },
            set: { pathValue = $0 }
        )
        coordinator.path = path
        
        // Set programmatic flag
        coordinator.sync(with: [1, 2]) // This sets latestNavigationTrigger to .programmatic
        
        // Act - simulate navigation controller delegate call
        coordinator.navigationController(mockNavController, willShow: item1VC, animated: true)
        
        // Assert
        XCTAssertEqual(pathValue, [1, 2]) // Should not have modified the path
    }
}

// MARK: - Mock UINavigationController

private class MockNavigationController: UINavigationController {
    var setViewControllersAnimatedCalled = false
    var popToViewControllerCalled = false
    var popToRootViewControllerCalled = false
    var popViewControllerCalled = false
    
    var popToViewControllerReceivedArguments: (viewController: UIViewController, animated: Bool)?
    
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        setViewControllersAnimatedCalled = true
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        popToViewControllerCalled = true
        popToViewControllerReceivedArguments = (viewController, animated)
        return super.popToViewController(viewController, animated: animated)
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        popToRootViewControllerCalled = true
        return super.popToRootViewController(animated: animated)
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        popViewControllerCalled = true
        return super.popViewController(animated: animated)
    }
}