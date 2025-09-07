//
//  ScreenShotCoordinator.swift
//  ClipMate
//
//  Created by 김용해 on 8/30/25.
//

import SwiftUI
import AppKit
import HotKey

extension ScreenShotView {
    class Coordinator: NSObject, ObservableObject {
        private var screenShotWindow: NSWindow?
        var windowContentView: ScreenShotNSView?
        var toggleScreenMode: (() -> Void)?
        var clipboardTextCloser: ((String) -> Void)?
        var escHotKey: HotKey?
        var selectionRect: CGRect?
        var saveButton: NSButton?
        var cancelButton: NSButton?
        var stackView: NSStackView?
        var screenImage: CGImage?
        let manager: ScreenShotManager = .init()
        
        func showWindow() {
            guard screenShotWindow == nil else { return }
            let squre: CGFloat = 32
            let pointSize: CGFloat = 16
            // ESC key always closes the screenshot view.
            escHotKey = HotKey(key: .escape, modifiers: .init())
            escHotKey?.keyDownHandler = { [weak self] in
                self?.toggleScreenMode?()
            }

            if let screen = NSScreen.main {
                let contentView = ScreenShotNSView(frame: screen.frame)
                contentView.wantsLayer = true
                contentView.layer?.borderWidth = 3
                contentView.layer?.borderColor = NSColor.yellow.cgColor

                // Set closures to communicate from view to coordinator
                contentView.onSelectionFinalized = { [weak self] rect in
                    self?.selectionRect = rect
                    self?.updateButtonPositions(for: rect)
                }
                contentView.onSelectionCancelled = { [weak self] in
                    self?.hideButtons()
                }
                
                
                // Symbols config
                let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular, scale: .medium)
                
                let ocr = manager.nsButtonLayoutConfig(config: config, title: "텍스트 추출", squre: squre, target: self ,action: #selector(copyImageTextOCRTapped),icon: "camera.viewfinder")
                
                let download = manager.nsButtonLayoutConfig(config: config, title: "저장", squre: squre, target: self ,action: #selector(downLoadButtonTapped),icon: "square.and.arrow.down")
                
                // Create and configure buttons
                let save = manager.nsButtonLayoutConfig(config: config, title: "복사", squre: squre, target: self ,action: #selector(saveButtonTapped), icon: "document.on.clipboard")
                
                // Create and configure buttons
                let cancel = manager.nsButtonLayoutConfig(config: config, title: "취소", squre: squre, target: self ,action: #selector(cancelButtonTapped), icon: "clear")
                
                let stackView = NSStackView(views: [ocr, download ,save, cancel])
                stackView.orientation = .horizontal
                stackView.spacing = 12
                stackView.alignment = .centerY
                stackView.isHidden = true
                stackView.layer?.backgroundColor = NSColor.red.cgColor
                contentView.addSubview(stackView)
                self.stackView = stackView
                self.saveButton = save
                self.cancelButton = cancel
                
                Task {
                    do {
                        if let image = try await manager.createFullScreenShot() {
                            await MainActor.run {
                                contentView.backgroundImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                                contentView.needsDisplay = true
                            }
                            self.screenImage = image
                        }
                    } catch {
                        debugPrint("전체 화면 캡처 Error: \(error)")
                    }
                }
                
                self.windowContentView = contentView

                let window = NSWindow(
                    contentRect: screen.frame,
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false
                )
                
                window.level = .screenSaver
                window.isOpaque = false
                window.acceptsMouseMovedEvents = true
                window.backgroundColor = .clear
                window.contentView = contentView
                window.makeFirstResponder(contentView)

                self.screenShotWindow = window
                
                // Show the window.
                window.makeKeyAndOrderFront(nil)
            }
        }
        
        // Hide Screenshot, 메모리 deinit
        func hideWindow() {
            // This is the full cleanup, only called when the view is dismantled.
            guard screenShotWindow != nil else { return }
            escHotKey = nil
            windowContentView = nil
            stackView = nil
            selectionRect = nil
            screenImage = nil
            saveButton = nil
            cancelButton = nil
            screenShotWindow?.orderOut(nil)
            screenShotWindow = nil
        }
        
        @objc func saveButtonTapped() {
            Task {
                do {
                    if let cgImage = try await manager.regionScreenShot(rect: selectionRect, screen: screenImage) {
                        guard let rect = selectionRect else { return}
                        let nsImage = NSImage(cgImage: cgImage, size: rect.size)
                        // copy
                        manager.copyToClipboard(image: nsImage)
                    }
                } catch {
                    debugPrint("부분 캡처 Error: \(error)")
                }
            }
            toggleScreenMode?()
        }

        @objc func cancelButtonTapped() {
            // Clear the selection and hide the buttons, returning to crosshair mode.
            toggleScreenMode?()
            hideWindow()
        }
        
        @objc func downLoadButtonTapped() {
            Task {
                do {
                    guard let cgImage = try await manager.regionScreenShot(rect: self.selectionRect, screen: self.screenImage) else { return }
                    
                    guard let rect = selectionRect else { return}
                    let nsImage = NSImage(cgImage: cgImage, size: rect.size)
                    
                    guard let imageData = nsImage.jpegData(quality: 1.0) else { return }
                    
                    await MainActor.run {
                        let savePanel = NSSavePanel()
                        savePanel.allowedContentTypes = [.jpeg]
                        savePanel.nameFieldStringValue = "\(Date.imageFileName(.now)).jpeg"
                        savePanel.canCreateDirectories = true
                        savePanel.title = "이미지 저장"

                        savePanel.begin { response in
                            guard response == .OK, let fileURL = savePanel.url else { return }
                            Task {
                                do {
                                    try imageData.write(to: fileURL)
                                } catch {
                                    debugPrint("이미지 파일 저장 Error : \(error)")
                                }
                            }
                        }
                    }
                    toggleScreenMode?()
                } catch {
                    debugPrint("NSSavePanel Error : \(error)")
                }
            }
        }
        
        @objc func copyImageTextOCRTapped() {
            Task {
                guard let cgImage = try await manager.regionScreenShot(rect: self.selectionRect, screen: self.screenImage) else { return }
                
                // OCR logic
                let text = await manager.imageOCRExport(image: cgImage)
                
                if !text.isEmpty {
                    self.clipboardTextCloser?(text)
                }
                
                toggleScreenMode?()
            }
        }

        func updateButtonPositions(for rect: NSRect) {
            guard let stack = stackView else { return }
            let spacing: CGFloat = 8
            var x = rect.origin.x
            var y = rect.maxY + spacing
            
            // 스택이 화면을 벗어나면 → 좌측 하단 모서리로 이동
            if let screen = NSScreen.main {
                let screenHeight = screen.frame.height
                let screenWidth = screen.frame.width
                if y + stack.frame.height > screenHeight {
                    y = rect.minY - stack.frame.height - spacing
                } else if x + stack.frame.width > screenWidth {
                    let move = x + stack.frame.width - screenWidth
                    x -= move
                }
            }
            
            stack.setFrameOrigin(NSPoint(x: x, y: y))
            
            stack.isHidden = false
        }

        func hideButtons() {
            self.stackView?.isHidden = true
        }
    }
}
