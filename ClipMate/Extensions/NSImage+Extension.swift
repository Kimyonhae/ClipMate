import AppKit

extension NSImage {
    func jpegData(quality: CGFloat) -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        
        let props: [NSBitmapImageRep.PropertyKey : Any] = [
            .compressionFactor: quality
        ]
        
        return bitmapImageRep.representation(using: .jpeg, properties: props)
    }
}
