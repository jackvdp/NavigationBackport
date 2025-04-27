import SwiftUI

public extension Backport where Content: View {
    @MainActor @ViewBuilder
    func navigationDestination<D: Hashable, C: View>(
        for data: D.Type,
        useBackport: Bool = false,
        @ViewBuilder destination: @escaping @MainActor (D) -> C
    ) -> some View {
        if #available(iOS 16.0, *), !useBackport {
            content.navigationDestination(for: data, destination: destination)
        } else {
            let block: DestinationBlock = { any in
                guard let typed = any as? D else {
                    return nil
                }
                return AnyView(destination(typed))
            }
            content.modifier(NavigationDestinationModifier(block: block))
        }
    }
}

// MARK: - Destination plumbing

private struct NavigationDestinationModifier: ViewModifier {
    let block: DestinationBlock
    @Environment(\.coordinatorDestinationSetter) private var setter

    func body(content: Content) -> some View {
        content.onAppear {
            setter(block)
        }
    }
}

typealias DestinationBlock = @MainActor (Any) -> AnyView?

private struct CoordinatorDestinationSetterKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (@escaping DestinationBlock) -> Void = { _ in }
}

extension EnvironmentValues {
    var coordinatorDestinationSetter: (@escaping DestinationBlock) -> Void {
        get { self[CoordinatorDestinationSetterKey.self] }
        set { self[CoordinatorDestinationSetterKey.self] = newValue }
    }
}

extension View {
    func coordinatorDestinationSetter(
        _ handler: @escaping (@escaping DestinationBlock) -> Void
    ) -> some View {
        environment(\.coordinatorDestinationSetter, handler)
    }
}

#Preview {
    DemoView()
}
