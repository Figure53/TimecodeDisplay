//
//  F53Timecode.swift
//  Timecode Display
//
//  Created by Siobhán Dougall on 3/8/23.
//

import Foundation

struct F53Timecode {
    let framerate: Framerate
    let hh: UInt
    let mm: UInt
    let ss: UInt
    let ff: UInt
    
    init(framerate: Framerate, hh: UInt, mm: UInt, ss: UInt, ff: UInt) {
        self.framerate = framerate
        self.hh = hh
        self.mm = mm
        self.ss = ss
        self.ff = ff
    }
    
    var stringRepresentation: String {
        if framerate.isDropFrame {
            return String(format: "%02d:%02d:%02d;%02d", hh, mm, ss, ff)
        }
        return String(format: "%02d:%02d:%02d:%02d", hh, mm, ss, ff)
    }
    
    var framesFromZero: UInt {
        let rawResult = ff + framerate.integerFPS * (ss + 60 * (mm + 60 * hh))
        if framerate.isDropFrame {
            return rawResult - 2 * (rawResult / 1800) + 2 * (rawResult / 18000)
        } else {
            return rawResult
        }
    }
    
    enum Framerate {
        case _23976
        case _24
        case _24975
        case _25
        case _2997nd
        case _30nd
        case _2997df
        case _30df
        
        var integerFPS: UInt {
            switch self {
            case ._23976, ._24:
                return 24
            case ._24975, ._25:
                return 25
            default:
                return 30
            }
        }
        
        var isDropFrame: Bool {
            switch self {
            case ._2997df, ._30df:
                return true
            default:
                return false
            }
        }
        
        var speedAgnosticDescription: String {
            switch self {
            case ._23976, ._24:
                return "24/23.976 fps"
            case ._24975, ._25:
                return "25/24.975 fps"
            case ._2997nd, ._30nd:
                return "30/29.97 non-drop"
            case ._2997df, ._30df:
                return "30/29.97 drop frame"
            }
        }
    }
}
