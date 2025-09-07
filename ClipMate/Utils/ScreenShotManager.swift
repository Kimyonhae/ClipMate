//
//  ScreenShotManager.swift
//  ClipMate
//
//  Created by 김용해 on 8/29/25.
//

import AppKit
import ScreenCaptureKit
import Vision
import VisionKit

class ScreenShotManager {
    /// FullScreenShot 함수
    /// - contentView의 backgroundImage에 넣기 위한 이미지를 제공
    /// - 부분 캡처를 위한 FullScreenShot의 목적도 있음
    func createFullScreenShot() async throws -> CGImage? {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = content.displays.first else {
            debugPrint("캡처 가능한 화면이 없습니다.")
            return nil
        }
        
        let config = SCStreamConfiguration()
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60) // 60fps
        config.width = Int(display.width * 2)
        config.height = Int(display.height * 2)
        
        let stream = SCStream(
            filter: SCContentFilter(display: display, excludingApplications: [], exceptingWindows: []),
            configuration: config,
            delegate: nil
        )
        
        let frameHandler = FrameHandler()
        try stream.addStreamOutput(frameHandler, type: .screen, sampleHandlerQueue: .main)
        
        try await stream.startCapture()
        
        guard let cgImage = try await frameHandler.waitForFirstFrame() else {
            return nil
        }
        
        return cgImage
    }
    
    func regionScreenShot(rect: NSRect?, screen fullScreen: CGImage?) async throws -> CGImage? {
        guard let rect = rect, let fullScreen = fullScreen else {
            return nil
        }
        
        guard let screen = NSScreen.main else { return nil }
        let scaleFactor = screen.backingScaleFactor
        
        let scaleRect = NSRect(
            x: rect.minX * scaleFactor,
            y: rect.minY * scaleFactor,
            width: rect.width * scaleFactor,
            height: rect.height * scaleFactor
        )
        
        let cropRect = CGRect(
            x: scaleRect.minX,
            y: CGFloat(fullScreen.height) - scaleRect.maxY,
            width: scaleRect.width,
            height: scaleRect.height
        )
        
        guard let croppedCGImage = fullScreen.cropping(to: cropRect) else {
            return nil
        }
        
        return croppedCGImage
    }
    
    // 이미지에서 Text 추출 (OCR)
    func imageOCRExport(image: CGImage) async -> String {
        let request = VNRecognizeTextRequest()
            request.revision = VNRecognizeTextRequestRevision3
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR"]
            request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
            guard let observations = request.results else {
                return ""
            }
            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
            return text
        } catch {
            debugPrint("OCR error: \(error)")
            return ""
        }
    }
    
    // NSButton Custon Config func
    func nsButtonLayoutConfig(config: NSImage.SymbolConfiguration, title: String, squre: CGFloat,target: NSObject, action: Selector, icon: String) -> NSButton {
        // Create and configure buttons
        let button = NSButton(image: NSImage(systemSymbolName: icon, accessibilityDescription: title)!.withSymbolConfiguration(config)!,
                              target: target,
                              action: action
        )
        button.bezelStyle = .regularSquare
        button.isBordered = true
        button.toolTip = title
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: squre).isActive = true
        button.heightAnchor.constraint(equalToConstant: squre).isActive = true
        
        return button
    }
    
    // Copy save on ClipBoard
    func copyToClipboard(image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}


/// 프레임을 기다려서 NSImage로 뽑는 핸들러
class FrameHandler: NSObject, SCStreamOutput {
    private var continuation: CheckedContinuation<CGImage?, Error>?
    
    func waitForFirstFrame() async throws -> CGImage? {
        return try await withCheckedThrowingContinuation { cont in
            continuation = cont
        }
    }
    
    func stream(_ stream: SCStream,
                didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of outputType: SCStreamOutputType) {
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(
            options: [
                .useSoftwareRenderer: false,
                .highQualityDownsample: true,
                .outputPremultiplied: true
            ]
        )
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            continuation?.resume(returning: cgImage)
            continuation = nil
            stream.stopCapture { _ in }
        }
    }
}
