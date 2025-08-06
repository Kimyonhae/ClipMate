//
//  ClipBoard+CoreData.swift
//  ClipMate
//
//  Created by 김용해 on 8/5/25.
//
import SwiftUI
import SwiftData

class ClipBoardUseCases {
    static let shared: ClipBoardUseCases = .init()
    private init() {}
    
    private var context: ModelContext!
    
    func getContext(context: ModelContext) {
        self.context = context
    }
    
    // MARK: 복사한 Text Or Image save SwiftData
    func createClipBoard(copyText: String, selectedFolder: Folder?) {
        guard let folder = selectedFolder else {
            print("Not Found Folder")
            return
        }
        // text를 Copy 한 경우
        let clipBoard: ClipBoard = .init(folder: folder, text: copyText)
        do {
            context.insert(clipBoard)
            try context.save()
        }catch {
            print("clipBoard error : \(error)")
        }
    }
}
