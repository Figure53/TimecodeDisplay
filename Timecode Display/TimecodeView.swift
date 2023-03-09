//
//  TimecodeView.swift
//  Timecode Display
//
//  Created by Siobhán Dougall on 3/8/23.
//

import AppKit

class TimecodeView: NSView {
    var stringValue: String? {
        didSet {
            self.needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let stringValue,
              let ctx = NSGraphicsContext.current?.cgContext
        else {
            return
        }
        
        let size = min(1.0 * self.frame.height, 0.15 * self.frame.width)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: .regular),
            .foregroundColor: NSColor(white: 1.0, alpha: 0.9)
        ]
        let attributedString = NSAttributedString(string: stringValue, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        ctx.saveGState()
        ctx.textMatrix = .identity
        ctx.textPosition = CGPoint(x: 0.5 * (self.frame.width - attributedString.size().width), y: 0.65 * self.frame.height - 0.5 * attributedString.size().height)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}
