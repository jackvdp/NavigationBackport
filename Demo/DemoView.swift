import SwiftUI
import NavigationBackport

struct DemoView: View {
    var useBackport: Bool = true
    @State private var path: [AppPage] = []
    
    var body: some View {
        Backport.NavigationStack(path: $path, useOldNavigationStyle: useBackport) {
            Text("Root View")
                .frame(maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    Button("Go red") {
                        path.append(.red)
                    }
                    .buttonStyle(.bordered)
                }
                .backport.navigationDestination(
                    for: AppPage.self
                ) { page in
                    PageView(page: page, path: $path)
                }
        }
    }
}

enum AppPage: Hashable {
    case red
    case blue
    case yellow(Int)
    case green(String)
    case purple(Bool)
    case orange
    case pink
    
    var colour: Color {
        switch self {
        case .red:
            return .red
        case .blue:
            return .blue
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .purple:
            return .purple
        case .orange:
            return .orange
        case .pink:
            return .pink
        }
    }
    
    var nextPage: AppPage? {
        switch self {
        case .red:
            return .blue
        case .blue:
            return .yellow(2)
        case .yellow:
            return .green("Foo")
        case .green:
            return .purple(true)
        case .purple:
            return .orange
        case .orange:
            return .pink
        case .pink:
            return nil
        }
    }
}

struct BlueView: View {
    @State var count: Int = 0
    
    var body: some View {
        Text("Blue View: \(count)")
            .padding()
            .background(Color.cyan)
            .cornerRadius(8)
            .onTapGesture {
                count += 1
            }
    }
}

struct PageView: View {
    let page: AppPage
    @Binding var path: [AppPage]
    
    var body: some View {
        VStack{
            
            Text("Current Page: \(page.colour.description)")
                .padding()
                .background(Color.white)
                .cornerRadius(8)
            
            if case .blue = page {
                BlueView()
            }
            
            VStack {
                Text("Path:")
                ForEach(path, id: \.self) { page in
                    switch page {
                    case .blue, .red, .orange, .pink:
                        Text(page.colour.description)
                    case .green(let text):
                        Text("Green " + text)
                    case .yellow(let count):
                        Text("Yellow (\(count))")
                    case .purple(let bool):
                        Text("Purple \(bool)")
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            
            VStack {
                Text("Set path like: `path = [.yellow(3)]`")
                Button("Go back to yellow (pop)") {
                    path = [.yellow(3)]
                }
                .buttonStyle(.bordered)
                Button("Go forward many yellow (push)") {
                    path = [.red, .orange, .pink, .yellow(3)]
                }
                .buttonStyle(.bordered)
                Button("Hybrid set (keep initial, new end)") {
                    path = [.red, .blue, .pink, .yellow(3)]
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            
            VStack {
                
                if let nextPage = page.nextPage {
                    Button("Next") {
                        path.append(nextPage)
                    }
                    .buttonStyle(.bordered)
                    
                    Backport.NavigationLink(value: nextPage) {
                        Text("Go to next page")
                    }
                    .buttonStyle(.bordered)
                }
                Button("Previous") {
                    path.removeLast()
                }
                .buttonStyle(.bordered)
                Button("Go to root") {
                    path = []
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            
            VStack {
                Text("Old Navigation Link example, will navigate but breaks path – same behaviour on both.")
                NavigationLink {
                    PageView(page: .green("bar"), path: $path)
                } label: {
                    Text("Go green")
                }
                NavigationLink {
                    PageView(page: .blue, path: $path)
                } label: {
                    Text("Go blue")
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(page.colour)
    }
}

#Preview {
    DemoView(useBackport: true)
}
