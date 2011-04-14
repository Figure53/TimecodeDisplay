/**

 @author  Kurt Revis
 @file    F53MIDIVoiceMessage.m

 Copyright (c) 2001-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/


#import "F53MIDIVoiceMessage.h"

#import "F53MIDIUtilities.h"


@implementation F53MIDIVoiceMessage : F53MIDIMessage

///
///  @param aLength must be 1 or 2
///
+ (F53MIDIVoiceMessage *) voiceMessageWithTimeStamp: (MIDITimeStamp) aTimeStamp 
                                         statusByte: (Byte) aStatusByte 
                                               data: (const Byte *) aData 
                                             length: (UInt16) aLength
{
    F53MIDIVoiceMessage *message;
    
    message = [[[F53MIDIVoiceMessage alloc] initWithTimeStamp:aTimeStamp statusByte:aStatusByte] autorelease];

    F53Assert(aLength >= 1 && aLength <= 2);
    if (aLength >= 1)
        message->dataBytes[0] = *aData;
    if (aLength == 2)
        message->dataBytes[1] = *(aData + 1);
    
    return message;
}

#pragma mark -
#pragma mark F53MIDIMessage overrides

- (id) copyWithZone: (NSZone *) zone
{
    F53MIDIVoiceMessage *newMessage;
    
    newMessage = [super copyWithZone:zone];
    newMessage->dataBytes[0] = dataBytes[0];
    newMessage->dataBytes[1] = dataBytes[1];

    return newMessage;
}

- (F53MIDIMessageType) messageType
{
    switch ([self status]) {
        case F53MIDIVoiceMessageStatusNoteOff:
            return F53MIDIMessageTypeNoteOff;
            
        case F53MIDIVoiceMessageStatusNoteOn:
            return F53MIDIMessageTypeNoteOn;
            
        case F53MIDIVoiceMessageStatusAftertouch:
            return F53MIDIMessageTypeAftertouch;
            
        case F53MIDIVoiceMessageStatusControl:
            return F53MIDIMessageTypeControl;
            
        case F53MIDIVoiceMessageStatusProgram:
            return F53MIDIMessageTypeProgram;
            
        case F53MIDIVoiceMessageStatusChannelPressure:
            return F53MIDIMessageTypeChannelPressure;
            
        case F53MIDIVoiceMessageStatusPitchWheel:
            return F53MIDIMessageTypePitchWheel;

        default:
            return F53MIDIMessageTypeUnknown;
    }
}

- (unsigned int) otherDataLength
{
    switch ([self status]) {
        case F53MIDIVoiceMessageStatusProgram:
        case F53MIDIVoiceMessageStatusChannelPressure:
            return 1;
            break;
    
        case F53MIDIVoiceMessageStatusNoteOff:
        case F53MIDIVoiceMessageStatusNoteOn:
        case F53MIDIVoiceMessageStatusAftertouch:
        case F53MIDIVoiceMessageStatusControl:
        case F53MIDIVoiceMessageStatusPitchWheel:        
            return 2;
            break;

        default:
            return 0;
            break;
    }
}

- (const Byte *) otherDataBuffer
{
    return dataBytes;
}

- (NSString *) typeForDisplay
{
    switch ([self status]) {
        case F53MIDIVoiceMessageStatusNoteOn:
            if (dataBytes[1] != 0)
                return NSLocalizedStringFromTableInBundle(@"Note On", @"F53MIDI", F53BundleForObject(self), "displayed type of Note On event");
            // else fall through to Note Off

        case F53MIDIVoiceMessageStatusNoteOff:
            return NSLocalizedStringFromTableInBundle(@"Note Off", @"F53MIDI", F53BundleForObject(self), "displayed type of Note Off event");
            
        case F53MIDIVoiceMessageStatusAftertouch:
            return NSLocalizedStringFromTableInBundle(@"Aftertouch", @"F53MIDI", F53BundleForObject(self), "displayed type of Aftertouch (poly pressure) event");
            
        case F53MIDIVoiceMessageStatusControl:
            return NSLocalizedStringFromTableInBundle(@"Control", @"F53MIDI", F53BundleForObject(self), "displayed type of Control event");
            
        case F53MIDIVoiceMessageStatusProgram:
            return NSLocalizedStringFromTableInBundle(@"Program", @"F53MIDI", F53BundleForObject(self), "displayed type of Program event");
            
        case F53MIDIVoiceMessageStatusChannelPressure:
            return NSLocalizedStringFromTableInBundle(@"Channel Pressure", @"F53MIDI", F53BundleForObject(self), "displayed type of Channel Pressure (aftertouch) event");
            
        case F53MIDIVoiceMessageStatusPitchWheel:
            return NSLocalizedStringFromTableInBundle(@"Pitch Wheel", @"F53MIDI", F53BundleForObject(self), "displayed type of Pitch Wheel event");

        default:
            return [super typeForDisplay];
    }
}

- (NSString *) channelForDisplay
{
    return [NSString stringWithFormat:@"%u", [self channel]];
}

- (NSString *) dataForDisplay
{
    NSString *part1 = nil, *part2 = nil;

    switch ([self status]) {
        case F53MIDIVoiceMessageStatusNoteOff:
        case F53MIDIVoiceMessageStatusNoteOn:
        case F53MIDIVoiceMessageStatusAftertouch:
            part1 = [F53MIDIMessage formatNoteNumber:dataBytes[0]];
            part2 = [F53MIDIMessage formatDataByte:dataBytes[1]];
            break;

        case F53MIDIVoiceMessageStatusControl:
            part1 = [F53MIDIMessage formatControllerNumber:dataBytes[0]];
            part2 = [F53MIDIMessage formatDataByte:dataBytes[1]];
            break;
            
        case F53MIDIVoiceMessageStatusProgram:
        case F53MIDIVoiceMessageStatusChannelPressure:
            // Use super's implementation
            break;
            
        case F53MIDIVoiceMessageStatusPitchWheel:
            part1 = [F53MIDIMessage formatSignedDataByte1:dataBytes[0] byte2:dataBytes[1]];
            break;

        default:
            break;
    }
    
    if (part1) {
        if (part2)
            return [[part1 stringByAppendingString:@"\t"] stringByAppendingString:part2];
        else
            return part1;
    } else {
        return [super dataForDisplay];
    }
}

#pragma mark -
#pragma mark Additional API

- (void) setStatus: (F53MIDIVoiceMessageStatus) newStatus
{
    _statusByte = newStatus | ([self channel] - 1);
}

- (F53MIDIVoiceMessageStatus) status
{
    return _statusByte & 0xF0;
}

///
///  NOTE: newChannel is 1-16, not 0-15
///
- (void) setChannel: (Byte) newChannel
{
    _statusByte = [self status] | (newChannel - 1);
}

///
///  NOTE: Channel is 1-16, not 0-15
///
- (Byte) channel
{
    return (_statusByte & 0x0F) + 1;
}

- (void) setDataByte1: (Byte) newValue
{
    F53Assert([self otherDataLength] >= 1);
    dataBytes[0] = newValue;
}

- (Byte) dataByte1
{
    return dataBytes[0];
}

- (void) setDataByte2: (Byte) newValue
{
    F53Assert([self otherDataLength] >= 2);
    dataBytes[1] = newValue;
}

- (Byte) dataByte2
{
    return dataBytes[1];
}

- (BOOL) matchesChannelMask: (F53MIDIChannelMask) mask
{
    // NOTE:
    // We could implement -matchesChannelMask on all F53MIDIMessages, 
    // but I don't know if the default should be YES or NO...
    // I could see it going either way, in different contexts.
    
    return (mask & (1 << ([self channel] - 1))) ? YES : NO;
}

///
///  Returns NO if the transposition puts the note out of the representable range.
///
- (BOOL) transposeBy: (Byte) transposeAmount
{
    F53MIDIVoiceMessageStatus status;
    
    status = [self status];
    if (status == F53MIDIVoiceMessageStatusNoteOff || status == F53MIDIVoiceMessageStatusNoteOn || status == F53MIDIVoiceMessageStatusAftertouch) {
        int value;
        
        value = (int)[self dataByte1] + transposeAmount;
        if (value < 0 || value > 127)
            return NO;
        
        [self setDataByte1:value];
        return YES;
    }
    
    return NO;
}

@end
