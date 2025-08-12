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
            print("copyText clipBoard error : \(error)")
        }
    }
    
    // MARK: 복사한 이미지를 감지해서 swiftData에 insert
    func createImageClipBoard(imageData: Data, selectedFolder: Folder?) {
        guard let folder = selectedFolder else {
            print("Not Found Folder")
            return
        }
        
        // filtering 중복 imageData CHECK
        let allImageData = folder.clips.compactMap { $0.image }
        guard !allImageData.contains(imageData) else {
            return
        }
        
        // Create Context.Insert ClipBoard
        let clipBoard: ClipBoard = .init(folder: folder, image: imageData)
        do {
            context.insert(clipBoard)
            try context.save()
        }catch {
            print("copy ImageData clipBoard error : \(error)")
        }
    }
    
    func matchedClip(id clipId: String) -> ClipBoard? {
        let condition = FetchDescriptor<ClipBoard>(
            predicate: #Predicate { $0.id == clipId }
        )
        
        do {
            if let clip = try context.fetch(condition).first {
                return clip
            }
        } catch {
            print("Paste Clip Error : \(error)")
        }
        return nil
    }
}
