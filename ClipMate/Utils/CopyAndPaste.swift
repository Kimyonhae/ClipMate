//
//  CopyAndPaste.swift
//  ClipMate
//
//  Created by 김용해 on 8/5/25.
//

import Foundation
import AppKit

class CopyAndPasteManager {
    static let shared: CopyAndPasteManager = .init()
    var isCopyActive: Bool = false
    private init() {}
    
    private var retainHandlers: Handlers?
    
    private class Handlers {
        let copyHandler: () -> Void
        let pasteHandler: () -> Void
        init(copyHandler: @escaping (() -> Void), pasteHandler: @escaping (() -> Void)) {
            self.copyHandler = copyHandler
            self.pasteHandler = pasteHandler
        }
    }
    
    private var eventTap: CFMachPort?
    func eventMonitor(copyCompleteHandler: @escaping (() -> Void), pasteComplateHandler: @escaping() -> Void, completionAuthorization: @escaping (Bool) -> Void) {
        // 손쉬운 사용 권한을 확인하고, 없는 경우 사용자에게 요청합니다.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {

            // 권한이 없다면 True를 반환
            let isNotAuthorization = !AXIsProcessTrustedWithOptions(options)
            completionAuthorization(isNotAuthorization)
            return
        }
        
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let handlers: Handlers = .init(copyHandler: copyCompleteHandler, pasteHandler: pasteComplateHandler)
        self.retainHandlers = handlers
        let ref = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: {_,type, event, refcon in
                guard type == .keyDown else { return Unmanaged.passUnretained(event) }
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<CopyAndPasteManager>.fromOpaque(refcon).takeUnretainedValue()
                let flags = event.flags
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                
                if flags.contains(.maskCommand), keyCode == 8 {
                    if manager.isCopyActive {
                        manager.retainHandlers?.copyHandler()
                    }
                }
              
                if keyCode == 36 {
                    manager.retainHandlers?.pasteHandler()
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: ref
        )
        
        if let eventTap = eventTap {
            let runloopSource = CFMachPortCreateRunLoopSource(
                kCFAllocatorDefault,
                eventTap,
                0
            )
            CFRunLoopAddSource(
                CFRunLoopGetCurrent(),
                runloopSource,
                .commonModes
            )
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }
    
    func stopMonitoring() {
        self.retainHandlers = nil // 필요 시 해제
    }
}
