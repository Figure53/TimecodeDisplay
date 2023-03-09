//
//  AppDelegate.swift
//  Timecode Display
//
//  Created by Siobhán Dougall on 3/8/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var timecodeWindow: NSWindow!
    @IBOutlet var timecodeView: TimecodeView!
    
    @IBOutlet var eventLogWindow: NSWindow!
    @IBOutlet var eventLogView: NSTextView!

    var receiver = MIDIReceiver()
    var analyzer = TimecodeAnalyzer()
    var logDateFormatter = DateFormatter()
    var log: String = ""

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        logDateFormatter.dateStyle = .medium
        logDateFormatter.timeStyle = .medium
        receiver.delegate = analyzer
        receiver.online = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func appendLog(_ string: String) {
        log.append("\(logDateFormatter.string(from: Date())): \(string)\n")
        eventLogView.string = log
    }
    
    func reserReceiver() {
        receiver.reset()
    }
}

