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

        switch QueueAnalyser.analyse(newQueue: newQueue, oldQueue: currentQueue) {
            
        case .unchanged:
            break

        case .popToRoot:
            nav.popToRootViewController(animated: true)

        case .pop(let to):
            if let targetVC = viewControllerFromStack(for: to, nav: nav) {
                nav.popToViewController(targetVC, animated: true)
            }

        case .push(let pages):
            for value in pages {
                guard let vc = newViewController(for: value) else { continue }
                nav.pushViewController(vc, animated: value == pages.last)
            }

        case .wholeNewStackWithPushAnimation:
            setStackWithPushAnimation(newQueue, on: nav)

        case .wholeNewStackWithPopAnimation:
            setStackWithPopAnimation(newQueue, on: nav)
            
        case .hybridStackWithPushAnimation:
            break
            
        case .hybridStackWithPopAnimation:
            break
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
        
}

#Preview {
    DemoView(useBackport: true)
}
