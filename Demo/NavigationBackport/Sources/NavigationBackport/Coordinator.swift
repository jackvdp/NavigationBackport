import SwiftUI

@MainActor
final class Coordinator: ObservableObject {

    private weak var navController: UINavigationController?
    private var destinationBlocks: [DestinationBlock] = []
    private var cache: [AnyHashable: UIViewController] = [:]

    // MARK: destination registration
    func setup(_ controller: UINavigationController) {
        navController = controller
    }

    func addDestinationBlock(_ block: @escaping DestinationBlock) {
        destinationBlocks.append(block)
    }

    private func swiftUIView(for value: Any) -> AnyView? {
        for block in destinationBlocks.reversed() {
            if let v = block(value) { return v }
        }
        return nil
    }

    private func viewController(for value: AnyHashable) -> UIViewController? {
        if let vc = cache[value] { return vc }
        guard let view = swiftUIView(for: value) else { return nil }
        let vc = UIHostingController(rootView: view)
        cache[value] = vc
        return vc
    }

    // MARK: Synchronise navigation stack using QueueAnalyser
    func sync<Path>(with path: Path) where Path: Collection, Path.Element: Hashable {
        guard let nav = navController else { return }

        // Reconstruct current queue from cache ↔︎ controller mapping
        let currentQueue: [Path.Element] = nav.viewControllers.dropFirst().compactMap { vc in
            cache.first { $0.value === vc }?.key as? Path.Element
        }
        let newQueue: [Path.Element] = Array(path)

        switch QueueAnalyser.analyse(newQueue: newQueue, oldQueue: currentQueue) {
        case .unchanged:
            return

        case .popToRoot:
            nav.popToRootViewController(animated: true)

        case .pop(let to):
            if let targetVC = cache[AnyHashable(to)], nav.viewControllers.contains(targetVC) {
                nav.popToViewController(targetVC, animated: true)
            } else {
                // fallback – rebuild silently
                replaceStack(newQueue, on: nav, animated: false)
            }

        case .push(let pages):
            for value in pages {
                guard let vc = viewController(for: AnyHashable(value)) else { continue }
                nav.pushViewController(vc, animated: value == pages.last)
            }

        case .setPush:
            let vcs = (try? path.compactMap(viewController(for:))) ?? []
            nav.setViewControllers(vcs, animated: true)

        case .setPop:
            var targetStack: [UIViewController] = [nav.viewControllers.first!]
            for value in newQueue {
                if let vc = viewController(for: AnyHashable(value)) { targetStack.append(vc) }
            }
            
            let currentTop = nav.topViewController!
            
            if let last = targetStack.last, last === currentTop {
                // New top already visible – just replace stack beneath, no anim
                nav.setViewControllers(targetStack, animated: false)
            } else {
                // Place current top on top of target stack, then pop once
                targetStack.append(currentTop)
                nav.setViewControllers(targetStack, animated: false)
                nav.popViewController(animated: true)
            }
        }
    }

    // MARK: helpers
    private func pushEntire<Element: Hashable>(
        _ queue: [Element],
        on nav: UINavigationController,
        animated: Bool
    ) {
        for value in queue {
            guard let vc = viewController(for: AnyHashable(value)) else { continue }
            nav.pushViewController(vc, animated: animated)
        }
    }

    private func replaceStack<Element: Hashable>(
        _ queue: [Element],
        on nav: UINavigationController,
        animated: Bool
    ) {
        guard let root = nav.viewControllers.first else { return }
        var stack: [UIViewController] = [root]
        for value in queue {
            if let vc = viewController(for: AnyHashable(value)) { stack.append(vc) }
        }
        nav.setViewControllers(stack, animated: animated)
    }
}

#Preview {
    DemoView(useBackport: true)
}

