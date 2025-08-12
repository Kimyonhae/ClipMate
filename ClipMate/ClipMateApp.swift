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
    @StateObject private var vm = ContentView.ViewModel()
    var activeKey: HotKey?
    init() {
        activeKey = HotKey(key: .m, modifiers: [.command])
        activeKey?.keyDownHandler = {
            // 나중에 업데이트 되서 지원을 하면 변경
            NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationTitle("Clip Mate")
                .modelContainer(for: [ClipBoard.self, Folder.self])
                .environmentObject(vm)
                .onAppear {
                    // global Monitor
                    ChangeClipBoardMonitor.shared.startMonitoring() { imageData in
                        // swiftData image insert
                        ClipBoardUseCases.shared.createImageClipBoard(imageData: imageData, selectedFolder: vm.selectedFolder)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .textEditing) {
                Button("Move Up") {
                    vm.moveFocus(up: true)
                }
                .keyboardShortcut(.upArrow, modifiers: [])

                Button("Move Down") {
                    vm.moveFocus(up: false)
                }
                .keyboardShortcut(.downArrow, modifiers: [])
            }
        }
    }
}
