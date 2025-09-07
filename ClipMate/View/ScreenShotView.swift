import AppKit
import SwiftUI


struct ScreenShotView: NSViewRepresentable {
    var toggleScreenMode: (() -> Void)?
    var clipboardTextCloser: ((String) -> Void)?
    
    init(toggleScreenMode: @escaping () -> Void, clipboardTextCloser: @escaping(String) -> Void) {
        self.toggleScreenMode = toggleScreenMode
        self.clipboardTextCloser = clipboardTextCloser
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.toggleScreenMode = {
            toggleScreenMode?()
        }
        coordinator.clipboardTextCloser = { text in
            clipboardTextCloser?(text)
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
