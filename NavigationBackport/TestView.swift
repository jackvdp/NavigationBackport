import SwiftUI
import NavigationBackport   // replace with your module name if different

/// Top‑level demo that XCUITests interact with.
/// * Uses Backport.NavigationStack even on iOS 16+ (forceBackport = true).
/// * Provides a vertical **ScenarioChooser** so tests can jump to any queue state
///   without horizontal swipes.
public struct TestView: View {
    /// Force the back‑port implementation.
    public var forceBackport: Bool = true
    @State private var path: [AppPage] = []

    public init(forceBackport: Bool = true) { self.forceBackport = forceBackport }

    public var body: some View {
        Backport.NavigationStack(path: $path, useOldNavigationStyle: forceBackport) {
            RootView(path: $path)
            // 👉 Back‑ported navigationDestination so XCUITests can drive navigation.
            .backport.navigationDestination(for: AppPage.self) { page in
                PageView(page: page, path: $path)
            }
        }
        // 🔽 Scenario chooser is vertically scrollable (no horizontal axis).
        .safeAreaInset(edge: .bottom) {
            ScenarioChooser(path: $path)
        }
    }
    
    // MARK: ‑ Root screen
    private struct RootView: View {
        @Binding var path: [AppPage]
        var body: some View {
            VStack(spacing: 24) {
                Text("Root View")
                    .font(.title)
                    .accessibilityIdentifier("rootLabel")

                Button("Go red") { path.append(.red) }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("goRedButton")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: ‑ Scenario chooser (vertical list of buttons)
    private struct ScenarioChooser: View {
        @Binding var path: [AppPage]

        /// Scenarios mirror the permutations tested in QueueAnalyserTests.
        private static let scenarios: [(id: String, title: String, queue: [AppPage])] = [
            ("123",     "Path 1‑2‑3",           [.red, .blue, .yellow(1)]),
            ("1234",    "Path 1‑2‑3‑4",         [.red, .blue, .yellow(1), .green("A")]),
            ("12345",   "Path 1‑2‑3‑4‑5",       [.red, .blue, .yellow(1), .green("A"), .purple(false)]),
            ("24",      "Path 2‑3",             [.blue, .yellow(1)]),
            ("2345",    "Path 2‑3‑4‑5",         [.blue, .yellow(1), .green("A"), .purple(false)]),
            ("1245",    "Path 1‑2‑4‑5",         [.red, .blue, .green("A"), .purple(false)]),
            ("12dup3",  "Duplicates mid",       [.red, .blue, .blue, .yellow(1)]),
            ("12dup",   "Duplicates at end",    [.red, .blue, .yellow(1), .yellow(1), .yellow(1)]),
            ("1dup2224","Duplicates triple",    [.red, .blue, .blue, .blue, .green("A")])
        ]

        private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

        var body: some View {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Self.scenarios, id: \.id) { scenario in
                        Button(scenario.title) { path = scenario.queue }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("scenario_" + scenario.id)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .accessibilityIdentifier("scenarioList")
            .frame(maxHeight: 320)
        }
    }

    // MARK: ‑ Route enum
    public enum AppPage: Hashable {
        case red
        case blue
        case yellow(Int)
        case green(String)
        case purple(Bool)
        case orange
        case pink

        var colour: Color {
            switch self {
            case .red:    return .red
            case .blue:   return .blue
            case .yellow: return .yellow
            case .green:  return .green
            case .purple: return .purple
            case .orange: return .orange
            case .pink:   return .pink
            }
        }

        var nextPage: AppPage? {
            switch self {
            case .red:    return .blue
            case .blue:   return .yellow(1)
            case .yellow: return .green("A")
            case .green:  return .purple(false)
            case .purple: return .orange
            case .orange: return .pink
            case .pink:   return nil
            }
        }
    }

    // MARK: ‑ Sample Blue view with @State
    private struct BlueView: View {
        @State private var count = 0
        var body: some View {
            Text("Blue View: \(count)")
                .accessibilityIdentifier("blueCounterLabel")
                .padding()
                .background(Color.cyan)
                .cornerRadius(8)
                .onTapGesture { count += 1 }
        }
    }

    // MARK: ‑ Generic page container
    struct PageView: View {
        let page: AppPage
        @Binding var path: [AppPage]

        var body: some View {
            VStack(spacing: 16) {
                Text("Current Page: \(page.colour.description)")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .accessibilityIdentifier("currentPageLabel")

                Text("PathCount: \(path.count)")
                    .accessibilityIdentifier("pathCountLabel")

                if case .blue = page { BlueView() }

                navigationButtons
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(page.colour)
        }

        @ViewBuilder
        private var navigationButtons: some View {
            VStack(spacing: 8) {
                if let next = page.nextPage {
                    Button("Next") { path.append(next) }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("nextButton")
                }
                if !path.isEmpty {
                    Button("Previous") { path.removeLast() }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("previousButton")
                }
                Button("Go to root") { path = [] }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("goRootButton")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}



#Preview {
    TestView(forceBackport: true)
}
