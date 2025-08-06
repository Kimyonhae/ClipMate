//
//  Folder+CoreData.swift
//  ClipMate
//
//  Created by 김용해 on 8/5/25.
//
import SwiftData
import SwiftUI

class FolderUseCases {
    static let shared: FolderUseCases = .init()
    private init() {}
    
    private var context: ModelContext!
    
    func getContext(context: ModelContext) {
        self.context = context
    }
    
    // MARK: 초기 folder가 없을 시 Undifined 폴더 생성 함수
    func loadInitFolder() -> Folder {
        let initFolder = Folder(name: "UnTitled", clips: [])
        context.insert(initFolder)
        
        do {
            try context.save()
        }catch {
            print("err : \(error)")
        }
        
        return initFolder
    }
    
    // MARK: 특정 FolderName vaild 함수
    func vaildFolderName(select: Folder, compare: Folder) -> Bool {
        if select.id == compare.id {
            return true
        }
        return false
    }
    
    func changeFolderName(name: String, select: Folder) {
        let id = select.id
        let condition = FetchDescriptor<Folder>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            if let folder = try context.fetch(condition).first {
                folder.name = name
                try context.save()
            }
        } catch {
            print("폴더 변경 : \(error)")
        }
    }
}
