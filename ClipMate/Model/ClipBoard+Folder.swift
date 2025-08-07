//
//  ClipBoard.swift
//  ClipMate
//
//  Created by 김용해 on 8/5/25.
//
import SwiftUI
import SwiftData

@Model
final class ClipBoard {
    @Attribute(.unique) var id: String
    @Relationship(deleteRule: .nullify) var folder: Folder?
    var date: Date = Date()
    var text: String?
    var imageURL: String?
    
    init(folder: Folder?, text: String? = nil, imageURL: String? = nil) {
        self.id = UUID().uuidString
        self.folder = folder
        self.text = text
        self.imageURL = imageURL
    }
}

@Model
final class Folder {
    @Attribute(.unique) var id: String
    var name: String
    @Relationship(deleteRule: .cascade ,inverse: \ClipBoard.folder) var clips: [ClipBoard]
    
    init(name: String, clips: [ClipBoard] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.clips = clips
    }
}
