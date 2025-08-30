//  ContentView.swift
//  ClipMate
//
//  Created by 김용해 on 8/5/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var vm: ContentView.ViewModel
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                MainView()
                SideBarView()
            }
            // Hidden Buttons for Keyboard Shortcuts
            VStack {
                Button("") { vm.moveFocus(up: true) }
                    .keyboardShortcut(.upArrow, modifiers: [])
                
                Button("") { vm.moveFocus(up: false) }
                    .keyboardShortcut(.downArrow, modifiers: [])
            }
            .hidden()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ContentView.ViewModel())
}
