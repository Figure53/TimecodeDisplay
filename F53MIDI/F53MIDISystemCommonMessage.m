/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDISystemCommonMessage.m
@date    Created on 4/03/06.
@brief   

Copyright (c) 2001-2004, Kurt Revis.  All rights reserved.
Copyright (c) 2006 Christopher Ashworth. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

**/

#import "F53MIDISystemCommonMessage.h"

#import "F53MIDIUtilities.h"


@implementation F53MIDISystemCommonMessage

///  @param aLength must be 0, 1, or 2
+ (F53MIDISystemCommonMessage *) systemCommonMessageWithTimeStamp: (MIDITimeStamp) aTimeStamp 
														type: (F53MIDISystemCommonMessageType) aType 
														data: (const Byte *) aData 
													  length: (UInt16) aLength
{
    F53MIDISystemCommonMessage *message;
    
    message = [[[F53MIDISystemCommonMessage alloc] initWithTimeStamp:aTimeStamp statusByte:aType] autorelease];
	
    F53Assert(aLength <= 2);
    if (aLength >= 1)
        message->dataBytes[0] = aData[0];
    if (aLength == 2)
        message->dataBytes[1] = aData[1];
    
    return message;
}

#pragma mark -
#pragma mark F53MIDIMessage overrides

- (id) copyWithZone: (NSZone *) zone
{
    F53MIDISystemCommonMessage *newMessage;
    
    newMessage = [super copyWithZone:zone];
    newMessage->dataBytes[0] = dataBytes[0];
    newMessage->dataBytes[1] = dataBytes[1];
	
    return newMessage;
}

- (F53MIDIMessageType) messageType
{
    switch ([self type]) {
        case F53MIDISystemCommonMessageTypeTimeCodeQuarterFrame:
            return F53MIDIMessageTypeTimeCode;
            
        case F53MIDISystemCommonMessageTypeSongPositionPointer:
            return F53MIDIMessageTypeSongPositionPointer;
            
        case F53MIDISystemCommonMessageTypeSongSelect:
            return F53MIDIMessageTypeSongSelect;
            
        case F53MIDISystemCommonMessageTypeTuneRequest:
            return F53MIDIMessageTypeTuneRequest;
			
        default:
            return F53MIDIMessageTypeUnknown;
    }
}

- (unsigned int) otherDataLength
{
    switch ([self type]) {
        case F53MIDISystemCommonMessageTypeTuneRequest:
        default:
            return 0;
            break;    
			
        case F53MIDISystemCommonMessageTypeTimeCodeQuarterFrame:
        case F53MIDISystemCommonMessageTypeSongSelect:
            return 1;
            break;
			
        case F53MIDISystemCommonMessageTypeSongPositionPointer:
            return 2;
            break;
    }
}

- (const Byte *) otherDataBuffer
{
    return dataBytes;
}

- (NSString *) typeForDisplay
{
    switch ([self type]) {
        case F53MIDISystemCommonMessageTypeTimeCodeQuarterFrame:
            return NSLocalizedStringFromTableInBundle(@"MTC Quarter Frame", @"F53MIDI", F53BundleForObject(self), "displayed type of MTC Quarter Frame event");
            
        case F53MIDISystemCommonMessageTypeSongPositionPointer:
            return NSLocalizedStringFromTableInBundle(@"Song Position Pointer", @"F53MIDI", F53BundleForObject(self), "displayed type of Song Position Pointer event");
            
        case F53MIDISystemCommonMessageTypeSongSelect:
            return NSLocalizedStringFromTableInBundle(@"Song Select", @"F53MIDI", F53BundleForObject(self), "displayed type of Song Select event");
            
        case F53MIDISystemCommonMessageTypeTuneRequest:
            return NSLocalizedStringFromTableInBundle(@"Tune Request", @"F53MIDI", F53BundleForObject(self), "displayed type of Tune Request event");
			
        default:
            return [super typeForDisplay];
    }
}

#pragma mark -
#pragma mark Additional API

- (void) setType: (F53MIDISystemCommonMessageType) newType
{
    _statusByte = newType;
}

- (F53MIDISystemCommonMessageType) type
{
    return _statusByte;
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

@end
