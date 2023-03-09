//
//  MIDIReceiver.swift
//  Timecode Display
//
//  Created by Siobhán Dougall on 3/8/23.
//

import Foundation
import SnoizeMIDI

class MIDIReceiver: NSObject {
    var online = false {
        didSet {
            if online {
                start()
            } else {
                stop()
            }
        }
    }
    
    weak var delegate: MIDIReceiverDelegate?
    
    private let context = MIDIContext()
    private var stream: PortInputStream?
    
    private var lastReceivedQuarterFrame: UInt8?
    private var hh: UInt8 = 0
    private var mm: UInt8 = 0
    private var ss: UInt8 = 0
    private var ff: UInt8 = 0
    private var validMask: UInt8 = 0
    private var mtcMode: MTCMode = .invalid

    override init() {
        self.stream = PortInputStream(midiContext: self.context)
        super.init()
    }
    
    private func start() {
        let stream = PortInputStream(midiContext: context)
        for endpoint in context.sources {
            stream.addSource(endpoint)
        }
        stream.messageDestination = self
        stream.delegate = self
        self.hh = 0
        self.mm = 0
        self.ss = 0
        self.ff = 0
        self.validMask = 0
        self.lastReceivedQuarterFrame = 0
        self.stream = stream
    }
    
    private func stop() {
        self.stream = nil
    }
    
    func reset() {
        self.hh = 0
        self.mm = 0
        self.ss = 0
        self.ff = 0
        self.validMask = 0
        self.lastReceivedQuarterFrame = 0
    }
    
    enum MTCMode: UInt8 {
        case invalid = 0xff
        case _24 = 0
        case _25 = 1
        case _30df = 2
        case _30nd = 3
        
        func asFramerate() -> F53Timecode.Framerate {
            switch self {
            case ._24:
                return ._24
            case ._25:
                return ._25
            case ._30df:
                return ._2997df
            case ._30nd:
                return ._2997nd
            default:
                return ._24
            }
        }
    }
}

extension MIDIReceiver: InputStreamDelegate {
    func inputStreamReadingSysEx(_ stream: SnoizeMIDI.InputStream, byteCountSoFar: Int, streamSource: SnoizeMIDI.InputStreamSource) {
        print("reading sysex")
    }
    
    func inputStreamFinishedReadingSysEx(_ stream: SnoizeMIDI.InputStream, byteCount: Int, streamSource: SnoizeMIDI.InputStreamSource, isValid: Bool) {
        print("finished sysex")
    }
    
    func inputStreamSourceListChanged(_ stream: SnoizeMIDI.InputStream) {
        if online {
            stop()
            start()
        }
    }
}

extension MIDIReceiver: MessageDestination {
    func takeMIDIMessages(_ messages: [SnoizeMIDI.Message]) {
        for message in messages {
            if let message = message as? SystemCommonMessage, let d1 = message.dataByte1 {
                switch d1 >> 4 {
                case 0:
                    setLowFF(d1)
                case 1:
                    setHighFF(d1)
                case 2:
                    setLowSS(d1)
                case 3:
                    setHighSS(d1)
                case 4:
                    setLowMM(d1)
                case 5:
                    setHighMM(d1)
                case 6:
                    setLowHH(d1)
                case 7:
                    setHighHH(d1)
                default:
                    break
                }
            }
        }
    }
    
    private func setLowFF(_ lowFF: UInt8) {
        ff = (ff & 0xf0) | (lowFF & 0x0f);
        validMask |= 0x1
    }
    
    private func setHighFF(_ highFF: UInt8) {
        ff = (ff & 0x0f) | ((highFF & 0x0f) << 4)
        validMask |= 0x2
    }
    
    private func setLowSS(_ lowSS: UInt8) {
        ss = (ss & 0xf0) | (lowSS & 0x0f)
        validMask |= 0x4
    }
    
    private func setHighSS(_ highSS: UInt8) {
        ss = (ss & 0x0f) | ((highSS & 0x0f) << 4)
        if ss == 0 && (ff == 0 || (ff == 2 && mtcMode == ._30df)) {
            mm += 1 // Because of the way MTC is structured, the minutes place won't be updated on the frame where it changes over. Dumb? Yes. But this fixes it.
        }
        validMask |= 0x8
        reportFrameReceived()
    }
    
    private func setLowMM(_ lowMM: UInt8) {
        mm = (mm & 0xf0) | (lowMM & 0xf)
        validMask |= 0x10
    }
    
    private func setHighMM(_ highMM: UInt8) {
        mm = (mm & 0x0f) | ((highMM & 0x0f) << 4)
        validMask |= 0x20
    }
    
    private func setLowHH(_ lowHH: UInt8) {
        hh = (hh & 0xf0) | (lowHH & 0x0f)
        validMask |= 0x40
    }
    
    private func setHighHH(_ highHH: UInt8) {
        hh = (hh & 0x0f) | ((highHH & 0x01) << 4)
        mtcMode = MTCMode(rawValue: ((highHH & 0x06) >> 1)) ?? .invalid
        ff += 1
        validMask |= 0x80
        reportFrameReceived()
    }
    
    private func reportFrameReceived() {
        if validMask != 0xff || mtcMode == .invalid {
            return
        }
        
        let tc = F53Timecode(framerate: mtcMode.asFramerate(), hh: UInt(hh), mm: UInt(mm), ss: UInt(ss), ff: UInt(ff))
        delegate?.midiReceiver(self, didReceive: tc)
    }
}

protocol MIDIReceiverDelegate: AnyObject {
    func midiReceiver(_ sender: MIDIReceiver, didReceive timecode: F53Timecode)
}
