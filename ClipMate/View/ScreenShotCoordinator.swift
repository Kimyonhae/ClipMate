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
        var escHotKey: HotKey?
        var selectionRect: CGRect?
        var saveButton: NSButton?
        var cancelButton: NSButton?
        var stackView: NSStackView?
        var screenImage: CGImage?
        
        func showWindow() {
            guard screenShotWindow == nil else { return }

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
                let config = NSImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .medium)
                
                // Create and configure buttons
                let download = NSButton(image: NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "다운로드")!.withSymbolConfiguration(config)!,
                    target: self,
                    action: #selector(downLoadButtonTapped)
                )
                download.bezelStyle = .regularSquare
                download.isBordered = true
                
                download.translatesAutoresizingMaskIntoConstraints = false
                download.widthAnchor.constraint(equalToConstant: 44).isActive = true
                download.heightAnchor.constraint(equalToConstant: 44).isActive = true
                
                // Create and configure buttons
                let save = NSButton(image: NSImage(systemSymbolName: "document.on.clipboard", accessibilityDescription: "저장")!.withSymbolConfiguration(config)!,
                    target: self,
                    action: #selector(saveButtonTapped)
                )
                save.bezelStyle = .regularSquare
                save.isBordered = true
                
                save.translatesAutoresizingMaskIntoConstraints = false
                save.widthAnchor.constraint(equalToConstant: 44).isActive = true
                save.heightAnchor.constraint(equalToConstant: 44).isActive = true
                
                // Create and configure buttons
                let cancel = NSButton(image: NSImage(systemSymbolName: "clear", accessibilityDescription: "취소")!.withSymbolConfiguration(config)!,
                    target: self,
                    action: #selector(cancelButtonTapped)
                )
                
                cancel.bezelStyle = .regularSquare
                cancel.isBordered = true
                
                cancel.translatesAutoresizingMaskIntoConstraints = false
                cancel.widthAnchor.constraint(equalToConstant: 44).isActive = true
                cancel.heightAnchor.constraint(equalToConstant: 44).isActive = true
                
                let stackView = NSStackView(views: [download ,save, cancel])
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
                        if let image = try await ScreenShotUseCases.shared.takeFullScreenShot() {
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
                    if let nsImage = try await ScreenShotUseCases.shared.createRegionShot(
                        rect: self.selectionRect, from: self.screenImage
                    ) {
                        ScreenShotUseCases.shared.copyToClipboard(image: nsImage)
                    }
                } catch {
                    debugPrint("부분 캡처 Error: \(error)")
                }
            }
            toggleScreenMode?()
        }

        @objc func cancelButtonTapped() {
            // Clear the selection and hide the buttons, returning to crosshair mode.
            windowContentView?.selectPoint = nil
            windowContentView?.needsDisplay = true
            hideButtons()
        }
        
        @objc func downLoadButtonTapped() {
            Task {
                do {
                    guard let nsImage = try await ScreenShotUseCases.shared.createRegionShot(
                        rect: self.selectionRect, from: self.screenImage
                    ) else { return }
                    
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

        func updateButtonPositions(for rect: NSRect) {
            guard let stack = stackView else { return }
            
            let centerX = rect.midX - stack.frame.width / 2
            let centerY = rect.midY - stack.frame.height / 2
            stack.setFrameOrigin(NSPoint(x: centerX, y: centerY))
            
            stack.isHidden = false
        }

        func hideButtons() {
            self.stackView?.isHidden = true
        }
    }
}
