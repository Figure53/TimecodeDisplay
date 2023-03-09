//
//  TimecodeAnalyzer.swift
//  Timecode Display
//
//  Created by Siobhán Dougall on 3/8/23.
//

import AppKit

class TimecodeAnalyzer: MIDIReceiverDelegate {
    private var timeLastFrameReceived: TimeInterval?
    private var lastReceivedTimecode: F53Timecode?
    private var freewheelTimer: Timer?
    
    func midiReceiver(_ sender: MIDIReceiver, didReceive timecode: F53Timecode) {
        let now = NSDate.timeIntervalSinceReferenceDate
        let timecodeString = timecode.stringRepresentation
        let framerateString = timecode.framerate.speedAgnosticDescription
        let appDelegate = NSApp.delegate as! AppDelegate

        // Test for new starts or discontinuities
        if timeLastFrameReceived == nil || now - timeLastFrameReceived! > 0.1 {
            // It's been long enough that this is a new start.
            appDelegate.appendLog("MTC start at \(timecodeString) - \(framerateString)")
        } else {
            if let lastReceivedTimecode, timecode.framesFromZero != lastReceivedTimecode.framesFromZero + 1 {
                appDelegate.appendLog("MTC discontinuity - from \(lastReceivedTimecode.stringRepresentation) to \(timecodeString)")
            }
        }
        
        // Show in timecode window
        appDelegate.timecodeView.stringValue = timecode.stringRepresentation
        
        // Freewheel
        freewheelTimer?.invalidate()
        freewheelTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { timer in
            appDelegate.appendLog("MTC stop at \(timecodeString)")
            self.timeLastFrameReceived = nil
            self.lastReceivedTimecode = nil
            appDelegate.reserReceiver()
        })
        
        lastReceivedTimecode = timecode
        timeLastFrameReceived = now
    }
}
