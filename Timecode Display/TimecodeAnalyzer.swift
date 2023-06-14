//
//  TimecodeAnalyzer.swift
//  Timecode Display
//
//  Created by Siobhán Dougall on 3/8/23.
//

import AppKit
import Foundation
import Network
import SystemConfiguration

class TimecodeAnalyzer: MIDIReceiverDelegate {
    private var timeLastFrameReceived: TimeInterval?
    private var lastReceivedTimecode: F53Timecode?
    private var freewheelTimer: Timer?
    private let targetIPAddress = "172.20.102.255" // Replace with the IP address of your Art-Net device
    private let targetPort: UInt16 = 6454 // Replace with the port number of your Art-Net device
        private var udpConnection: NWConnection?
        
        init() {
            setupUDPConnection()
        }
        
        func setupUDPConnection() {
            let udpParameters = NWParameters.udp
            udpParameters.allowLocalEndpointReuse = true // Allow multiple connections to use the same port
            
            // Create a broadcast endpoint
            let endpoint = NWEndpoint.hostPort(host: .ipv4(IPv4Address(targetIPAddress)!), port: NWEndpoint.Port(rawValue: targetPort)!)
            
            udpConnection = NWConnection(to: endpoint, using: udpParameters)
            
            udpConnection?.stateUpdateHandler = { [weak self] newState in
                switch newState {
                case .ready:
                    print("UDP connection established")
                case .failed(let error):
                    print("UDP connection failed: \(error)")
                default:
                    break
                }
            }
            
            udpConnection?.start(queue: DispatchQueue.main)
        }
        
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
                if let lastReceivedTimecode = lastReceivedTimecode, timecode.framesFromZero != lastReceivedTimecode.framesFromZero + 1 {
                    appDelegate.appendLog("MTC discontinuity - from \(lastReceivedTimecode.stringRepresentation) to \(timecodeString)")
                }
            }
            
            // Convert MIDI timecode to Art-Net timecode
            let artnetTimecode = convertToArtNetTimecode(timecode)
                    
            // Send Art-Net timecode via UDP
            sendArtNetTimecode(artnetTimecode)
            
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
        
    private func convertToArtNetTimecode(_ midiTimecode: F53Timecode) -> Data {
        // Create an Art-Net timecode packet
        var packet: [UInt8] = [
            // Art-Net ID
            0x41, 0x72, 0x74, 0x2D, 0x4E, 0x65, 0x74, 0x00,
            // ArtTimecode OpCode
            0x00, 0x97,
            // ProtVer
            0x00, 0x0E,
            // Filler1-2
            0x00, 0x00,
            // ArtTimeCode
            0x00, // Frames
            0x00, // Seonds
            0x00, // Minutes
            0x00, // Hours
            0x00, // Type Frame rate (0 = 24fps, 1 = 25fps, 2 = 30fps, 3 = 29.97fps)
        ]
        
        // Set the hours, minutes, seconds, and frames based on the MIDI timecode
        packet[14] = UInt8(midiTimecode.ff)
        packet[15] = UInt8(midiTimecode.ss)
        packet[16] = UInt8(midiTimecode.mm)
        packet[17] = UInt8(midiTimecode.hh)
        
        // Set the frame rate based on the MIDI timecode frame rate
        let frameRate: UInt8
        switch midiTimecode.framerate {
        case ._24:
            frameRate = 0x00
        case ._25:
            frameRate = 0x01
        case ._30nd:
            frameRate = 0x02
        case ._2997nd:
            frameRate = 0x03
        default:
            frameRate = 0x00
        }
        packet[18] = frameRate
        
        // Convert the packet to Data
        let packetData = Data(packet)
        return packetData
    }
            
        private func sendArtNetTimecode(_ timecode: Data) {
            udpConnection?.send(content: timecode, completion: .contentProcessed { error in
                if let error = error {
                    print("Failed to send Art-Net timecode: \(error)")
                } else {
                    print("Art-Net timecode sent successfully")
                }
            })
        }
    }
