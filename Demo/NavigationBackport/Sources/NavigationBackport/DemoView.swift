import SwiftUI

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
                    for: AppPage.self,
                    useBackport: useBackport
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
            return .green("Bar")
        case .purple:
            return .orange
        case .orange:
            return .pink
        case .pink:
            return nil
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
                Button("Go back to yellow") {
                    path = [.red, .yellow(3)]
                }
                .buttonStyle(.bordered)
                if let nextPage = page.nextPage {
                    Button("Next") {
                        path.append(nextPage)
                    }
                    .buttonStyle(.bordered)
                    
//                    NavigationLink(value: nextPage) {
//                        Text("Go to next page")
//                    }
//                    .buttonStyle(.bordered)
                }
                Button("Previous") {
                    path.removeLast()
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
