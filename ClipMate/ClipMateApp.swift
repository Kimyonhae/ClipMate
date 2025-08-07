//
//  ClipMateApp.swift
//  ClipMate
//
//  Created by 김용해 on 8/5/25.
//

import SwiftUI


@main
struct ClipMateApp: App {
    @StateObject private var vm = ContentView.ViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationTitle("Clip Mate")
                .modelContainer(for: [ClipBoard.self, Folder.self])
                .environmentObject(vm)
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
