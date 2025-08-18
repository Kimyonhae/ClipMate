//
//  ClipMateApp.swift
//  ClipMate
//
//  Created by 김용해 on 8/5/25.
//

import SwiftUI
import HotKey

@main
struct ClipMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var vm = ContentView.ViewModel()
    var activeKey: HotKey?
    init() {
        activeKey = HotKey(key: .m, modifiers: [.command])
        activeKey?.keyDownHandler = {
            /// **MenuBar를 숨기거나 활성화**
            /// - 복사할 아이템을 누르면 앱이 다시 비활성화 됨 - contentView
            /// - command + m 에 등록되어있는 로직이므로 재활용
            let statusItem = NSApp.windows.first?.value(forKey: "statusItem") as? NSStatusItem
            statusItem?.button?.performClick(nil)
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .frame(minWidth: (NSScreen.main?.frame.width ?? 1000) / 2, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
                .modelContainer(for: [ClipBoard.self, Folder.self])
                .environmentObject(vm)
                .onAppear {
                    // global Monitor
                    ChangeClipBoardMonitor.shared.startMonitoring() { imageData in
                        // swiftData image insert
                        ClipBoardUseCases.shared.createImageClipBoard(imageData: imageData, selectedFolder: vm.selectedFolder)
                    }
                }
        } label: {
            Label("ClipMate", systemImage: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.window)
    }
}
