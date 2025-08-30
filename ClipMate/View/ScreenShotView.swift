import AppKit
import SwiftUI
import HotKey


struct ScreenShotView: NSViewRepresentable {
    var toggleScreenMode: (() -> Void)?

    init(toggleScreenMode: @escaping () -> Void) {
        self.toggleScreenMode = toggleScreenMode
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.toggleScreenMode = {
            toggleScreenMode?()
        }
        return coordinator
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.showWindow()
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.hideWindow()
    }
}
