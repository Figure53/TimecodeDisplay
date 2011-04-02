/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIInvalidMessage.m
@date    Created on 8/11/06.
@brief   

Copyright (c) 2003-2004, Kurt Revis.  All rights reserved.
Copyright (c) 2006 Christopher Ashworth.  All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

**/

#import "F53MIDIInvalidMessage.h"

#import "F53MIDIUtilities.h"


@implementation F53MIDIInvalidMessage : F53MIDIMessage

+ (F53MIDIInvalidMessage *) invalidMessageWithTimeStamp: (MIDITimeStamp) aTimeStamp data: (NSData *) aData
{
    F53MIDIInvalidMessage *message;
    
    message = [[[F53MIDIInvalidMessage alloc] initWithTimeStamp:aTimeStamp statusByte:0x00] autorelease];
    // statusByte is ignored
    [message setData:aData];
	
    return message;
}

- (void) dealloc
{
    [_data release];
	
    [super dealloc];
}

//
// F53MIDIMessage overrides
//

- (id) copyWithZone: (NSZone *) zone
{
    F53MIDIInvalidMessage *newMessage;
    
    newMessage = [super copyWithZone:zone];
    [newMessage setData:_data];
	
    return newMessage;
}

- (F53MIDIMessageType) messageType
{
    return F53MIDIMessageTypeInvalid;
}

- (unsigned int) otherDataLength
{
    return [_data length];
}

- (const Byte *) otherDataBuffer
{
    return [[self otherData] bytes];    
}

- (NSData *) otherData
{
    return [self data];
}

- (NSString *)typeForDisplay;
{
    return NSLocalizedStringFromTableInBundle(@"Invalid", @"F53MIDI", F53BundleForObject(self), "displayed type of Invalid event");
}

- (NSString*)dataForDisplay
{
    return [self sizeForDisplay];
}


//
// Additional API
//

- (void) setData: (NSData *) newData
{
    if (_data != newData) {
        [_data release];
        _data = [newData retain];
    }
}

- (NSData *) data;
{
    return _data;
}

- (NSString *) sizeForDisplay
{
    return [NSString stringWithFormat:
        NSLocalizedStringFromTableInBundle(@"%@ bytes", @"F53MIDI", F53BundleForObject(self), "Invalid message length format string"),
        [F53MIDIMessage formatLength:[self otherDataLength]]];
}

@end
