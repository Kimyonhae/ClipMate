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
    func eventMonitor(copyCompleteHandler: @escaping (() -> Void), pasteComplateHandler: @escaping() -> Void) {
        // 손쉬운 사용 권한을 확인하고, 없는 경우 사용자에게 요청합니다.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            print("손쉬운 사용 권한이 없습니다. 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서 권한을 추가해주세요.")
            return
        }
        
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let handlers: Handlers = .init(copyHandler: copyCompleteHandler, pasteHandler: pasteComplateHandler)
        let ref = UnsafeMutableRawPointer(Unmanaged.passUnretained(handlers).toOpaque())
        self.retainHandlers = handlers
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: {_,type, event, refcon in
                guard type == .keyDown else { return Unmanaged.passUnretained(event) }
                let handlers = Unmanaged<Handlers>.fromOpaque(refcon!).takeUnretainedValue()
                let flags = event.flags
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                
                if flags.contains(.maskCommand), keyCode == 8 {
                    print("----------------------")
                    print("복사하기 기능이 감지")
                    handlers.copyHandler()
                    print("커스텀 코드 여기에 넣자")
                    print("----------------------")
                }
              
                if keyCode == 36 {
                    handlers.pasteHandler()
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