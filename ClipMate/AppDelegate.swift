import AppKit
import HotKey
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSApp.windows.first?.value(forKey: "statusItem") as? NSStatusItem
        statusItem?.button?.performClick(nil)
    }
}
