/**

 @author  Kurt Revis
 @file    F53MIDIVoiceMessage.h

 Copyright (c) 2001-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

#import "F53MIDIMessage.h"


typedef enum _F53MIDIChannelMask {
    F53MIDIChannelMaskNone = 0,
    F53MIDIChannelMask1 = (1 << 0),
    F53MIDIChannelMask2 = (1 << 1),
    F53MIDIChannelMask3 = (1 << 2),
    F53MIDIChannelMask4 = (1 << 3),
    F53MIDIChannelMask5 = (1 << 4),
    F53MIDIChannelMask6 = (1 << 5),
    F53MIDIChannelMask7 = (1 << 6),
    F53MIDIChannelMask8 = (1 << 7),
    F53MIDIChannelMask9 = (1 << 8),
    F53MIDIChannelMask10 = (1 << 9),
    F53MIDIChannelMask11 = (1 << 10),
    F53MIDIChannelMask12 = (1 << 11),
    F53MIDIChannelMask13 = (1 << 12),
    F53MIDIChannelMask14 = (1 << 13),
    F53MIDIChannelMask15 = (1 << 14),
    F53MIDIChannelMask16 = (1 << 15),
    F53MIDIChannelMaskAll = (1 << 16) - 1
} F53MIDIChannelMask;

typedef enum _F53MIDIVoiceMessageStatus {
    F53MIDIVoiceMessageStatusNoteOff = 0x80,
    F53MIDIVoiceMessageStatusNoteOn = 0x90,
    F53MIDIVoiceMessageStatusAftertouch = 0xA0,
    F53MIDIVoiceMessageStatusControl= 0xB0,
    F53MIDIVoiceMessageStatusProgram = 0xC0,
    F53MIDIVoiceMessageStatusChannelPressure = 0xD0,
    F53MIDIVoiceMessageStatusPitchWheel = 0xE0
} F53MIDIVoiceMessageStatus;

@interface F53MIDIVoiceMessage : F53MIDIMessage
{
    Byte dataBytes[2];
}

+ (F53MIDIVoiceMessage *) voiceMessageWithTimeStamp: (MIDITimeStamp) aTimeStamp 
                                         statusByte: (Byte) aStatusByte 
                                               data: (const Byte *) aData 
                                             length: (UInt16) aLength;

- (void) setStatus: (F53MIDIVoiceMessageStatus) newStatus;
- (F53MIDIVoiceMessageStatus) status;

- (void) setChannel: (Byte) newChannel;
- (Byte) channel;

- (void) setDataByte1: (Byte) newValue;
- (Byte) dataByte1;

- (void) setDataByte2: (Byte) newValue;
- (Byte) dataByte2;

- (BOOL) matchesChannelMask: (F53MIDIChannelMask) mask;

- (BOOL) transposeBy: (Byte) transposeAmount;

@end
