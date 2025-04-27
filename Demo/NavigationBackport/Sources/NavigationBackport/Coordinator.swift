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

struct QueueAnalyser {
    enum Result<Path> where Path: MutableCollection & RandomAccessCollection & RangeReplaceableCollection, Path.Element: Hashable {
        case unchanged
        case push(pagesToPush: Path)
        case pop(to: Path.Element)      // pop until *after* that element is on top
        case popToRoot                 // pop everything (new queue empty)
        case setPush                    // completely different, rebuild but animate
        case setPop                     // completely different, no animate
    }

    static func analyse<Path>(newQueue: Path, oldQueue: Path) -> Result<Path> where Path: MutableCollection & RandomAccessCollection & RangeReplaceableCollection, Path.Element: Hashable {

        // 0. identical?
        if newQueue.elementsEqual(oldQueue) { return .unchanged }

        // 1. new queue empty → pop all
        if newQueue.isEmpty { return .popToRoot }

        // 2. old queue is strict prefix of new queue → push remainder
        if oldQueue.count < newQueue.count && newQueue.starts(with: oldQueue) {
            let suffixStart = oldQueue.count
            let toPush = Path(newQueue.dropFirst(suffixStart))
            return .push(pagesToPush: toPush)
        }

        // 3. new queue is strict prefix of old queue → pop to last element of new queue
        if newQueue.count < oldQueue.count && oldQueue.starts(with: newQueue) {
            if let last = newQueue.last { return .pop(to: last) }
        }

        // 4. otherwise, stacks diverged → set
        return newQueue.count > oldQueue.count ? .setPush : .setPop
    }
}

#Preview {
    DemoView()
}

