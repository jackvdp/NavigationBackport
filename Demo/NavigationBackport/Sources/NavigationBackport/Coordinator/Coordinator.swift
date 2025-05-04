import SwiftUI

@MainActor
final class Coordinator: ObservableObject {

    private weak var navController: UINavigationController?
    private var destinationBlock: DestinationBlock?

    func setup(_ controller: UINavigationController) {
        navController = controller
    }

    func addDestinationBlock(_ block: @escaping DestinationBlock) {
        destinationBlock = block
    }
    
    // MARK: Synchronise navigation stack using QueueAnalyser
    
    func sync<Path>(with path: Path) where Path: Collection, Path.Element: Hashable {
        guard let nav = navController else { return }

        let currentQueue: [Path.Element] = nav.viewControllers.dropFirst().compactMap { vc in
            guard let hostingVC = vc as? HostingController<Path.Element> else { return nil}
            return hostingVC.element
        }
        let newQueue: [Path.Element] = Array(path)

        let result = QueueAnalyser.analyse(newQueue: newQueue, oldQueue: currentQueue)

        switch result {
        case .unchanged:
            break

        case .popToRoot:
            nav.popToRootViewController(animated: true)

        case .pop(let to):
            if let targetVC = viewControllerFromStack(for: to, nav: nav) {
                nav.popToViewController(targetVC, animated: true)
            }

        case .push(let pages):
            let newVCs = pages.compactMap { value in
                newViewController(for: value)
            }
            var existingVCs = nav.viewControllers
            existingVCs.append(contentsOf: newVCs)
            nav.setViewControllers(existingVCs, animated: true)

        case .wholeNewStackWithPushAnimation:
            setStackWithPushAnimation(newQueue, on: nav)

        case .wholeNewStackWithPopAnimation:
            setStackWithPopAnimation(newQueue, on: nav)
            
        case .hybridStackWithPushAnimation(let queueToKeep, let newQueue):
            hybridStackWithPush(queueToKeep: queueToKeep, newQueue: newQueue, nav: nav)
            
        case .hybridStackWithPopAnimation(let queueToKeep, let newQueue):
            hybridStackWithPop(queueToKeep: queueToKeep, newQueue: newQueue, nav: nav)
        }
    }


    // MARK: - View Creators & Getters
    
    private func createSwiftUIView(for value: Any) -> AnyView? {
        guard let destinationBlock,
              let v = destinationBlock(value) else { return nil }
        return v
    }

    private func newViewController<Element: Hashable>(for value: Element) -> UIViewController? {
        guard let view = createSwiftUIView(for: value) else { return nil }
        return HostingController(rootView: view, element: value)
    }
    
    private func viewControllerFromStack<Element: Hashable>(for value: Element, nav: UINavigationController) -> UIViewController? {
        let vcs = nav.viewControllers.compactMap { vc in
            if let hostingVC = vc as? HostingController<Element> {
                return hostingVC
            }
            return nil
        }
        let vc = vcs.first { $0.element == value }
        return vc
    }
    
    // MARK: - Stack Manipulation
    
    private func setStackWithPushAnimation<Element: Hashable>(_ queue: [Element], on nav: UINavigationController) {
        let newViewControllers = queue.compactMap { value in
            newViewController(for: value)
        }
        nav.setViewControllers(newViewControllers, animated: true)
    }
    
    private func setStackWithPopAnimation<Element: Hashable>(_ queue: [Element], on nav: UINavigationController) {
        guard let first = nav.viewControllers.first, let last = nav.viewControllers.last else {
            setStackWithPushAnimation(queue, on: nav)
            return
        }
        nav.viewControllers = [first, last]
        let newViewControllers = queue.compactMap { value in
            newViewController(for: value)
        }
        nav.viewControllers.insert(contentsOf: newViewControllers, at: 1)
        nav.popViewController(animated: true)
    }
    
    private func hybridStackWithPush<Element: Hashable>(queueToKeep: [Element], newQueue: [Element], nav: UINavigationController) {
        // Create a new stack that maintains the common prefix and adds the new suffix with push animation
        let prefixViewControllers = queueToKeep.compactMap { value in
            viewControllerFromStack(for: value, nav: nav) ?? newViewController(for: value)
        }
        
        let newSuffixViewControllers = newQueue.compactMap { value in
            newViewController(for: value)
        }
        
        // Keep the root view controller (not part of the path)
        if let rootVC = nav.viewControllers.first {
            var fullStack = [rootVC]
            fullStack.append(contentsOf: prefixViewControllers)
            fullStack.append(contentsOf: newSuffixViewControllers)
            nav.setViewControllers(fullStack, animated: true)
        }
    }
    
    private func hybridStackWithPop<Element: Hashable>(queueToKeep: [Element], newQueue: [Element], nav: UINavigationController) {
        // First, prepare a complete stack with all controllers
        let prefixViewControllers = queueToKeep.compactMap { value in
            viewControllerFromStack(for: value, nav: nav) ?? newViewController(for: value)
        }
        
        let newSuffixViewControllers = newQueue.compactMap { value in
            newViewController(for: value)
        }
        
        // Keep the root view controller (not part of the path)
        if let rootVC = nav.viewControllers.first {
            var finalStack = [rootVC]
            finalStack.append(contentsOf: prefixViewControllers)
            finalStack.append(contentsOf: newSuffixViewControllers)
            
            // For pop animation, we temporarily add an extra controller that we'll pop from
            let tempStack = finalStack + [nav.viewControllers.last].compactMap { $0 }
            nav.setViewControllers(tempStack, animated: false)
            nav.popViewController(animated: true)
        }
    }
}

#Preview {
    DemoView(useBackport: false)
}
