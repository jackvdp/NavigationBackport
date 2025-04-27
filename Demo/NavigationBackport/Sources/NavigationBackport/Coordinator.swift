import SwiftUI

@MainActor
final class Coordinator: ObservableObject {
    private weak var navController: UINavigationController?
    private var destinationBlocks: [DestinationBlock] = []

    func setup(_ controller: UINavigationController) {
        navController = controller
    }

    func addDestinationBlock(_ block: @escaping DestinationBlock) {
        destinationBlocks.append(block)
    }

    private func view(for value: Any) -> AnyView? {
        for block in destinationBlocks.reversed() {
            if let view = block(value) { return view }
        }
        return nil
    }

    func sync<Path>(with path: Path) where Path: Collection, Path.Element: Hashable {
        
        guard let nav = navController,
              let rootVC = nav.viewControllers.first else { return }

        var vcs: [UIViewController] = [rootVC]
        for value in path {
            if let view = view(for: value) {
                vcs.append(UIHostingController(rootView: view))
            }
        }

        let animated = vcs.count > nav.viewControllers.count
        nav.setViewControllers(vcs, animated: animated)
    }
}

#Preview {
    DemoView()
}

