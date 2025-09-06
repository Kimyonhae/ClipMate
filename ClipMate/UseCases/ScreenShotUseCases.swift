//
//  ScreenShotUseCases.swift
//  ClipMate
//
//  Created by 김용해 on 9/6/25.
//

import AppKit

class ScreenShotUseCases {

    static let shared: ScreenShotUseCases = .init()
    private init() {}

    func takeFullScreenShot() async throws -> CGImage? {
        try await ScreenShotManager.createFullScreenShot()
    }

    func createRegionShot(rect: CGRect?, from image: CGImage?) async throws -> NSImage? {
        try await ScreenShotManager.regionScreenShot(rect: rect, screen: image)
    }

    func copyToClipboard(image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}