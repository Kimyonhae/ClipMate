import AppKit

// A custom view to draw the crosshair for screenshot selection.
final class ScreenShotNSView: NSView {
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
