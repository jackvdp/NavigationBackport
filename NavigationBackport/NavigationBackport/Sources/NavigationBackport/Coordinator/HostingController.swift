import SwiftUI

class HostingController<Element: Hashable>: UIHostingController<AnyView> {
    
    let element: Element
    
    init(rootView: AnyView, element: Element) {
        self.element = element
        super.init(rootView: AnyView(rootView))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
