import SwiftUI
import HotKey

@main
struct ClipMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var vm: ContentView.ViewModel
    
    init() {
        _vm = StateObject(wrappedValue: ContentView.ViewModel())
        // Key 적용
        
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .frame(minWidth: (NSScreen.main?.frame.width ?? 1000) / 2, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
                .modelContainer(for: [ClipBoard.self, Folder.self])
                .environmentObject(vm)
        } label: {
            ColoredMenuBarIcon()
        }
        .menuBarExtraStyle(.window)
    }
}

struct ColoredMenuBarIcon: View {
    private var iconImage: NSImage {
        let image = NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: "ClipMate")!
        
        let coloredImage = NSImage(size: image.size, flipped: false) { rect in
            image.withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [.green, .green]))?
                .draw(in: rect)
            return true
        }
        coloredImage.isTemplate = false
        return coloredImage
    }

    var body: some View {
        Image(nsImage: iconImage)
    }
}
