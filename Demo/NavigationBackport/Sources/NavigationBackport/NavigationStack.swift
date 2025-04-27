import SwiftUI
import SwiftUIIntrospect

public extension Backport where Content == Any {
    struct NavigationStack<Data, Root: View>: View where
    Data: MutableCollection & RandomAccessCollection & RangeReplaceableCollection,
    Data.Element: Hashable {
        
        let path: Binding<Data>
        let root: () -> Root
        let useOldNavigationStyle: Bool
        
        public init(path: Binding<Data>, useOldNavigationStyle: Bool = false, @ViewBuilder root: @escaping () -> Root) {
            self.path = path
            self.useOldNavigationStyle = useOldNavigationStyle
            self.root = root
        }
        
        public var body: some View {
            if #available(iOS 16.0, *), !useOldNavigationStyle {
                SwiftUI.NavigationStack(path: path, root: root)
            } else {
                NavigationStackBackported(path: path, root: root)
            }
        }
    }
}

private extension Backport where Content == Any {
    struct NavigationStackBackported<Path, Root: View>: View where
    Path: MutableCollection & RandomAccessCollection & RangeReplaceableCollection,
    Path.Element: Hashable {
        
        @Binding var path: Path
        let root: () -> Root
        
        @StateObject private var coordinator = Coordinator()
        
        init(path: Binding<Path>, @ViewBuilder root: @escaping () -> Root) {
            self._path = path
            self.root = root
        }
        
        var body: some View {
            NavigationView {
                root()
            }
            .navigationViewStyle(.stack)
            .coordinatorDestinationSetter { block in
                coordinator.addDestinationBlock(block)
            }
            .onChange(of: dataHashValue) { _ in
                coordinator.sync(with: path)
            }
            .onAppear {
                coordinator.sync(with: path)
            }
            .introspect(
                .navigationView(style: .stack),
                on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18)
            ) { nav in
                coordinator.setup(nav)
            }
        }
        
        private var dataHashValue: Int {
            path.map(\.hashValue).reduce(0, ^)
        }
    }
}
