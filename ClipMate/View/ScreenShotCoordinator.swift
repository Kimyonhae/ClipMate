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
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular, scale: .medium)
                
                // Create and configure buttons
                let save = NSButton(image: NSImage(systemSymbolName: "document.on.clipboard", accessibilityDescription: "저장")!.withSymbolConfiguration(config)!,
                    target: self,
                    action: #selector(saveButtonTapped)
                )
                
                // Create and configure buttons
                let cancel = NSButton(image: NSImage(systemSymbolName: "minus", accessibilityDescription: "취소")!.withSymbolConfiguration(config)!,
                    target: self,
                    action: #selector(cancelButtonTapped)
                )
                
                
                let stackView = NSStackView(views: [save, cancel])
                stackView.orientation = .horizontal
                stackView.spacing = 8
                stackView.alignment = .centerY
                stackView.isHidden = true
                contentView.addSubview(stackView)
                self.stackView = stackView
                self.saveButton = save
                self.cancelButton = cancel

                Task {
                    if let image = try? await ScreenShotManager.createFullScreenShot() {
                        await MainActor.run {
                            contentView.backgroundImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                            contentView.needsDisplay = true
                        }
                        self.screenImage = image
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
                    let nsimage = try await ScreenShotManager.regionScreenShot(
                        rect: self.selectionRect, screen: self.screenImage
                    )
                    
                    if let nsimage = nsimage {
                        let pasteBoard = NSPasteboard.general
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([nsimage])
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

        func updateButtonPositions(for rect: NSRect) {
            let buttonSize: CGFloat = 24
            let spacing: CGFloat = 8
            guard let stack = stackView else { return }
            stack.setFrameSize(NSSize(width: buttonSize * 2, height: buttonSize))
            stack.setFrameOrigin(
                NSPoint(
                    x: rect.maxX - stack.frame.width - (buttonSize + spacing),
                    y: rect.minY - stack.frame.height
                )
            )
            
            stack.isHidden = false
        }

        func hideButtons() {
            self.stackView?.isHidden = true
        }
    }
}
