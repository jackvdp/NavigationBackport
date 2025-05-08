import SwiftUI

public struct Backport<Content> {
    let content: Content
}

public extension View {
    var backport: Backport<Self> { Backport(content: self) }
}

extension EnvironmentValues {
    @Entry var useBackport: Bool = false
}
