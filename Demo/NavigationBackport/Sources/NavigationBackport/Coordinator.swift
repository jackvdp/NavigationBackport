import SwiftUI

@MainActor
final class Coordinator: ObservableObject {

    private weak var navController: UINavigationController?
    private var destinationBlocks: [DestinationBlock] = []
    private var cache: [AnyHashable: UIViewController] = [:]

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

        let currentQueue: [Path.Element] = nav.viewControllers.dropFirst().compactMap { vc in
            cache.first { $0.value === vc }?.key as? Path.Element
        }
        let newQueue: [Path.Element] = Array(path)

        switch QueueAnalyser.analyse(newQueue: newQueue, oldQueue: currentQueue) {
        case .unchanged:
            break

        case .popToRoot:
            nav.popToRootViewController(animated: true)

        case .pop(let to):
            if let targetVC = cache[AnyHashable(to)], nav.viewControllers.contains(targetVC) {
                nav.popToViewController(targetVC, animated: true)
            } else {
                replaceStack(newQueue, on: nav, animated: false)
            }

        case .push(let pages):
            for value in pages {
                guard let vc = viewController(for: AnyHashable(value)) else { continue }
                nav.pushViewController(vc, animated: true)
            }

        case .setPush:
            nav.popToRootViewController(animated: false)
            pushEntire(newQueue, on: nav, animated: true)

        case .setPop:
            guard !newQueue.isEmpty else {
                nav.popToRootViewController(animated: true)
                break
            }
            var targetStack: [UIViewController] = [nav.viewControllers.first!]
            for value in newQueue {
                if let vc = viewController(for: AnyHashable(value)) { targetStack.append(vc) }
            }
            let currentTop = nav.topViewController!
            if let last = targetStack.last, last === currentTop {
                nav.setViewControllers(targetStack, animated: false)
            } else {
                targetStack.append(currentTop)
                nav.setViewControllers(targetStack, animated: false)
                nav.popViewController(animated: true)
            }
        }

        purgeCache(keeping: newQueue)
    }

    // MARK: helpers
    /// Remove any cached controller whose element is no longer present in the live queue.
    private func purgeCache<Element: Hashable>(keeping active: [Element]) {
        let activeSet = Set(active.map(AnyHashable.init))
        cache.keys
            .filter { !activeSet.contains($0) }
            .forEach { cache.removeValue(forKey: $0) }
    }


    // MARK: helpers
    private func pushEntire<Element: Hashable>(_ queue: [Element], on nav: UINavigationController, animated: Bool) {
        for value in queue {
            guard let vc = viewController(for: AnyHashable(value)) else { continue }
            nav.pushViewController(vc, animated: animated)
        }
    }

    private func replaceStack<Element: Hashable>(_ queue: [Element], on nav: UINavigationController, animated: Bool) {
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

