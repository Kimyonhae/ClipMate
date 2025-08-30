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
