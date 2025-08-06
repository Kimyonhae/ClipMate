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
