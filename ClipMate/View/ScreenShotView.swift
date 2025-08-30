//
//  ScreenShotView.swift
//  ClipMate
//
//  Created by 김용해 on 8/26/25.
//

import AppKit
import SwiftUI
import HotKey

// A custom view to draw the crosshair for screenshot selection.
final class CrosshairView: NSView {
    override var acceptsFirstResponder: Bool { true }
    var backgroundImage: NSImage?
    var mouseLocation: NSPoint = .zero {
        didSet {
            needsDisplay = true
        }
    }
    var selectPoint: (start: NSPoint, end: NSPoint)?
    var dragStartPoint: NSPoint?
    var onSelectionFinalized: ((NSRect) -> Void)?
    var onSelectionCancelled: (() -> Void)?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseMoved, .activeAlways, .inVisibleRect]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseMoved(with event: NSEvent) {
        self.mouseLocation = self.convert(event.locationInWindow, from: nil)
    }

    override func mouseDown(with event: NSEvent) {
        let currentPoint = self.convert(event.locationInWindow, from: nil)

        if let select = selectPoint {
            let selectionRect = NSRect(
                x: min(select.start.x, select.end.x),
                y: min(select.start.y, select.end.y),
                width: abs(select.end.x - select.start.x),
                height: abs(select.end.y - select.start.y)
            )

            if selectionRect.contains(currentPoint) {
                return
            } else {
                // Clicked outside: cancel the selection and hide the buttons.
                selectPoint = nil
                dragStartPoint = nil
                onSelectionCancelled?()
                needsDisplay = true
                return
            }
        }

        // No selection existed, or a new one is being started. Hide any old buttons.
        onSelectionCancelled?()
        
        // Start a new selection.
        dragStartPoint = currentPoint
        if let point = dragStartPoint {
            selectPoint = (start: point, end: point)
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        // Finalize the drag and notify the coordinator to show the buttons.
        dragStartPoint = nil
        if let select = selectPoint {
            let finalRect = NSRect(
                x: min(select.start.x, select.end.x),
                y: min(select.start.y, select.end.y),
                width: abs(select.end.x - select.start.x),
                height: abs(select.end.y - select.start.y)
            )
            // Only finalize if the rect is a meaningful size.
            if finalRect.width > 5 && finalRect.height > 5 {
                onSelectionFinalized?(finalRect)
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStartPoint else { return }
        let currentPoint = self.convert(event.locationInWindow, from: nil)
        selectPoint = (start: start, end: currentPoint)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let backgroundImage = backgroundImage {
            backgroundImage.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1.0)

            if let select = selectPoint {
                // A selection is active.
                let selectionRect = NSRect(
                    x: min(select.start.x, select.end.x),
                    y: min(select.start.y, select.end.y),
                    width: abs(select.end.x - select.start.x),
                    height: abs(select.end.y - select.start.y)
                )

                // Manually draw the four rectangles for the dimmed area.
                NSColor.black.withAlphaComponent(0.5).setFill()
                
                // Top rectangle
                let topRect = NSRect(x: 0, y: selectionRect.maxY, width: bounds.width, height: bounds.height - selectionRect.maxY)
                topRect.fill()

                // Bottom rectangle
                let bottomRect = NSRect(x: 0, y: 0, width: bounds.width, height: selectionRect.minY)
                bottomRect.fill()

                // Left rectangle
                let leftRect = NSRect(x: 0, y: selectionRect.minY, width: selectionRect.minX, height: selectionRect.height)
                leftRect.fill()

                // Right rectangle
                let rightRect = NSRect(x: selectionRect.maxX, y: selectionRect.minY, width: bounds.width - selectionRect.maxX, height: selectionRect.height)
                rightRect.fill()

                // Draw the yellow border for the selection rectangle.
                NSColor.systemYellow.setStroke()
                let borderPath = NSBezierPath(rect: selectionRect)
                borderPath.lineWidth = 2
                borderPath.stroke()

            } else {
                // No selection, just draw the crosshair.
                NSColor.systemYellow.setStroke()
                
                let horizontalPath = NSBezierPath()
                horizontalPath.move(to: NSPoint(x: bounds.minX, y: mouseLocation.y))
                horizontalPath.line(to: NSPoint(x: bounds.maxX, y: mouseLocation.y))
                horizontalPath.lineWidth = 1
                horizontalPath.stroke()

                let verticalPath = NSBezierPath()
                verticalPath.move(to: NSPoint(x: mouseLocation.x, y: bounds.minY))
                verticalPath.line(to: NSPoint(x: mouseLocation.x, y: bounds.maxY))
                verticalPath.lineWidth = 1
                verticalPath.stroke()
            }
        }
    }
}

struct ScreenShotView: NSViewRepresentable {
    var toggleScreenMode: (() -> Void)?

    init(toggleScreenMode: @escaping () -> Void) {
        self.toggleScreenMode = toggleScreenMode
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.toggleScreenMode = {
            toggleScreenMode?()
        }
        return coordinator
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.showWindow()
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.hideWindow()
    }

    class Coordinator: NSObject, ObservableObject {
        private var screenShotWindow: NSWindow?
        var windowContentView: CrosshairView?
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
                let contentView = CrosshairView(frame: screen.frame)
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
