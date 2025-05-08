import SwiftUI

public extension Backport where Content == Any {
    struct NavigationLink<Label: View, Element: Hashable>: View {
        let content: () -> Label
        let value: Element
        @Environment(\.useBackport) private var useOldNavigationStyle
        
        public init(value : Element, @ViewBuilder label: @escaping () -> Label) {
            self.value = value
            self.content = label
        }
        
        public var body: some View {
            if #available(iOS 16.0, *), !useOldNavigationStyle {
                SwiftUI.NavigationLink(value: value, label: content)
            } else {
                NavigationLinkBackported(value: value, label: content)
            }
        }
    }
}

private extension Backport where Content == Any {
    struct NavigationLinkBackported<Label: View, Element: Hashable>: View {
        
        let content: () -> Label
        let value: Element
        @Environment(\.appendValue) private var appendValue
        
        public init(value : Element, @ViewBuilder label: @escaping () -> Label) {
            self.value = value
            self.content = label
        }
        
        var body: some View {
            Button {
                appendValue(value)
            } label: {
                content()
            }
        }
    }
}

#Preview {
    Backport.NavigationStack(path: .constant(Array<String>()), useOldNavigationStyle: false) {
        VStack(spacing: 50){
            if #available(iOS 16.0, *) {
                NavigationLink(value: 2) {
                    Text("Foo")
                }
            }
            
            Backport.NavigationLink(value: 2) {
                Text("Foo")
            }
            
            Text("Foo")
        }
    }
}
