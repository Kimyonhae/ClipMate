//
//  ChangeClipBoardMonitor.swift
//  ClipMate
//
//  Created by 김용해 on 8/12/25.
//

import Foundation
import AppKit

class ChangeClipBoardMonitor {
    static let shared: ChangeClipBoardMonitor = .init()
    private var lastChangeCount: Int
    private var timer: Timer?
    private let board = NSPasteboard.general
    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func startMonitoring(completionHandler: @escaping(Data) -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.board.changeCount != self.lastChangeCount {
                self.lastChangeCount = self.board.changeCount
                self.handleClipboardChange { imageData in
                    completionHandler(imageData)
                }
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func handleClipboardChange(completionHandler: @escaping(Data) -> Void) {
        // 클립보드 내용 변경시 처리 로직
        let types = self.board.types ?? []
        if types.contains(.tiff) || types.contains(.png) {
            if let imageData = board.data(forType: .tiff) {
                completionHandler(imageData)
            }
        }
    }
}
