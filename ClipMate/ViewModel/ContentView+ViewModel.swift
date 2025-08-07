//
//  ClipBoardViewModel.swift
//  ClipMate
//
//  Created by 김용해 on 8/6/25.
//
import SwiftUI

extension ContentView {
    @MainActor
    class ViewModel: ObservableObject {
        @Published var selectedFolder: Folder?
        @Published var editId: String?
        @Published var editText: String = ""
        @Published var focusClipId: String?
        
        // ClipBoard create
        func create(_ text: String) {
            ClipBoardUseCases.shared.createClipBoard(copyText: text, selectedFolder: selectedFolder)
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
    }
}


// Getter , Setter
extension ContentView.ViewModel {
    // focusClip Getter
    func getFocusClip(_ id: String) {
        self.focusClipId = id
    }
}

extension ContentView.ViewModel {
    
    // keyBoard up, down move focusClipID
    func moveFocus(up: Bool) {
        guard let folder = selectedFolder else { return }
        guard let currentId = focusClipId else { return }
        let sortedClips = folder.clips.sorted { $0.date > $1.date }

        guard !sortedClips.isEmpty else { return }
        guard let currentIndex = sortedClips.firstIndex(where: { $0.id == currentId }) else { return }

        if up && currentIndex == 0 { return }
        if !up && currentIndex == sortedClips.count - 1 { return }

        let newIndex = up ? currentIndex - 1 : currentIndex + 1
        focusClipId = sortedClips[newIndex].id
    }
}
