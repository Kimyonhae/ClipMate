//
//  ClipBoardViewModel.swift
//  ClipMate
//
//  Created by 김용해 on 8/6/25.
//
import SwiftUI
import Foundation
import HotKey

extension ContentView {
    @MainActor
    class ViewModel: NSObject, ObservableObject {
        @Published var selectedFolder: Folder?
        @Published var editId: String?
        @Published var editText: String = ""
        @Published var focusClipId: String?
        @Published var isClosed: String? = nil
        @Published var isActive: Bool = false
        @Published var isAuthorization: Bool = false
        @Published var isTextFieldFocused: Bool = false
        @Published var isSearchTextFieldFocused: Bool = false
        @Published var isCopyToggleVisibled: Bool = false
        @Published var searchText: String = ""
        @Published var isShowScreenShot: Bool = false
        @Published var activeKey: HotKey?
        @Published var screenKey: HotKey?
        @Published var copyKey: HotKey?
        
        
        var sortedClips: [ClipBoard] {
            let filteredClips = self.selectedFolder?.clips.filter { clip in
                guard !self.searchText.isEmpty else { return true }
                return clip.text?.localizedCaseInsensitiveContains(searchText) ?? false
            }
            let sortedClips = filteredClips?.sorted { $0.date > $1.date }
            return sortedClips ?? []
        }
        
        override init() {
            super.init()
            activeKey = HotKey(key: .m, modifiers: [.command])
            screenKey = HotKey(key: .one, modifiers: .option)
            copyKey = HotKey(key: .q, modifiers: .command) // toggle 형식의 상태값
            
            CopyAndPasteManager.shared.eventMonitor(
                copyCompleteHandler: { // Copy Logic
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                        let board = NSPasteboard.general
                        if let copiedString = board.string(forType: .string) {
                            Task {
                                await self.create(copiedString)
                            }
                        }
                    }
                },
                pasteComplateHandler: { // Paste Logic
                    if !self.isTextFieldFocused && NSApp.isActive {
                        self.paste()
                        self.searchText = ""
                    }
                },
                completionAuthorization: { authorization in
                    if authorization { // 권한이 없음
                        self.isAuthorization = authorization
                    }
                }
            )
            
            // Image 감지
            ChangeClipBoardMonitor.shared.startMonitoring() { [weak self] imageData in
                guard let self = self else { return }
                ClipBoardUseCases.shared.createImageClipBoard(imageData: imageData, selectedFolder: self.selectedFolder)
            }
            
            activeKey?.keyDownHandler = {
                /// **MenuBar를 숨기거나 활성화**
                /// - 복사할 아이템을 누르면 앱이 다시 비활성화 됨 - contentView
                /// - command + m 에 등록되어있는 로직이므로 재활용
                let statusItem = NSApp.windows.first?.value(forKey: "statusItem") as? NSStatusItem
                statusItem?.button?.performClick(nil)
            }
            
            screenKey?.keyDownHandler = {
                self.isShowScreenShot = true // ScreenShot Mode 활성화
            }
            
            copyKey?.keyDownHandler = { [weak self] in
                CopyAndPasteManager.shared.isCopyActive.toggle()
                self?.isCopyToggleVisibled.toggle() // connect binding toggle
            }
        }
        
        // MARK: - CoreData
        // ClipBoard create
        func create(_ text: String) {
            ClipBoardUseCases.shared.createClipBoard(copyText: text, selectedFolder: selectedFolder)
        }
        
        // active copyHandler setter
        func toggleCopyClipBoard() {
            CopyAndPasteManager.shared.isCopyActive.toggle()
            self.isCopyToggleVisibled.toggle()
        }
        
        // change name ,if you has selectedFolder
        func vaildFolder(compare: Folder) -> Bool {
            if let select = selectedFolder {
                if FolderUseCases.shared.vaildFolderName(select: select, compare: compare) {
                    return true
                }
            }
            return false
        }
        
        // change folder Name
        func chageFolderName(change name: String) {
            if let select = selectedFolder {
                FolderUseCases.shared.changeFolderName(name: name, select: select)
            }
        }

        // paste Text And Image
        func paste() {
            if let id = focusClipId {
                let board = NSPasteboard.general
                let clip = ClipBoardUseCases.shared.matchedClip(id: id)
                board.clearContents()
                if let text = clip?.text {
                    board.setString(text, forType: .string)
                    activeMenuBarExtraWindow()
                }
                
                if let imageData = clip?.image {
                    board.setData(imageData, forType: .tiff)
                    activeMenuBarExtraWindow()
                }
            }
        }
        
        // new Folder Create
        func createFolder() {
            FolderUseCases.shared.createFolder()
        }
        
        // clips focusClipId Update Method
        func updateFocusIfNeeded() {
            if let selectedFolder = selectedFolder,
                let firstClip = selectedFolder.clips.sorted(by: { $0.date > $1.date }).first {
                self.focusClipId = firstClip.id
            }
        }
        
        // active MenuBarExtra Window
        func activeMenuBarExtraWindow() {
            let statusItem = NSApp.windows.first?.value(forKey: "statusItem") as? NSStatusItem
            statusItem?.button?.performClick(nil)
        }
    }
}


// MARK: Getter , Setter
extension ContentView.ViewModel {
    // focusClip Getter
    func getFocusClip(_ id: String) {
        self.focusClipId = id
    }
}

// MARK: Keyboard Move Scroll
extension ContentView.ViewModel {
    // keyBoard up, down move focusClipID
    func moveFocus(up: Bool) {
        guard let folder = selectedFolder else { return }
        guard let currentId = focusClipId else { return }
        let filteredClips = folder.clips.filter { clip in
            guard !self.searchText.isEmpty else { return true }
            return clip.text?.localizedCaseInsensitiveContains(self.searchText) ?? false
        }
        let sortedClips = filteredClips.sorted { $0.date > $1.date }

        guard !sortedClips.isEmpty else { return }
        guard let currentIndex = sortedClips.firstIndex(where: { $0.id == currentId }) else { return }

        if up && currentIndex == 0 { return }
        if !up && currentIndex == sortedClips.count - 1 { return }

        let newIndex = up ? currentIndex - 1 : currentIndex + 1
        focusClipId = sortedClips[newIndex].id
    }
}
