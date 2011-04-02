/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDISystemRealTimeMessage.m
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

#import "F53MIDISystemRealTimeMessage.h"

#import "F53MIDIUtilities.h"


@implementation F53MIDISystemRealTimeMessage

+ (F53MIDISystemRealTimeMessage *) systemRealTimeMessageWithTimeStamp: (MIDITimeStamp) aTimeStamp 
																type: (F53MIDISystemRealTimeMessageType) aType
{
    F53MIDISystemRealTimeMessage *message;
    
    message = [[[F53MIDISystemRealTimeMessage alloc] initWithTimeStamp:aTimeStamp statusByte:aType] autorelease];
    
    return message;
}

#pragma mark -
#pragma mark F53MIDIMessage overrides

- (F53MIDIMessageType) messageType
{
    switch ([self type]) {
        case F53MIDISystemRealTimeMessageTypeClock:
            return F53MIDIMessageTypeClock;
            
        case F53MIDISystemRealTimeMessageTypeStart:
            return F53MIDIMessageTypeStart;
			
        case F53MIDISystemRealTimeMessageTypeContinue:
            return F53MIDIMessageTypeContinue;
            
        case F53MIDISystemRealTimeMessageTypeStop:
            return F53MIDIMessageTypeStop;
			
        case F53MIDISystemRealTimeMessageTypeActiveSense:
            return F53MIDIMessageTypeActiveSense;
			
        case F53MIDISystemRealTimeMessageTypeReset:
            return F53MIDIMessageTypeReset;
			
        default:
            return F53MIDIMessageTypeUnknown;
    }
}

- (NSString *) typeForDisplay
{
    switch ([self type]) {
        case F53MIDISystemRealTimeMessageTypeClock:
            return NSLocalizedStringFromTableInBundle(@"Clock", @"F53MIDI", F53BundleForObject(self), "displayed type of Clock event");
            
        case F53MIDISystemRealTimeMessageTypeStart:
            return NSLocalizedStringFromTableInBundle(@"Start", @"F53MIDI", F53BundleForObject(self), "displayed type of Start event");
			
        case F53MIDISystemRealTimeMessageTypeContinue:
            return NSLocalizedStringFromTableInBundle(@"Continue", @"F53MIDI", F53BundleForObject(self), "displayed type of Continue event");
            
        case F53MIDISystemRealTimeMessageTypeStop:
            return NSLocalizedStringFromTableInBundle(@"Stop", @"F53MIDI", F53BundleForObject(self), "displayed type of Stop event");
			
        case F53MIDISystemRealTimeMessageTypeActiveSense:
            return NSLocalizedStringFromTableInBundle(@"Active Sense", @"F53MIDI", F53BundleForObject(self), "displayed type of Active Sense event");
			
        case F53MIDISystemRealTimeMessageTypeReset:
            return NSLocalizedStringFromTableInBundle(@"Reset", @"F53MIDI", F53BundleForObject(self), "displayed type of Reset event");
			
        default:
            return [super typeForDisplay];
    }
}

#pragma mark -
#pragma mark Additional API

- (void) setType: (F53MIDISystemRealTimeMessageType) newType
{
    _statusByte = newType;
}

- (F53MIDISystemRealTimeMessageType) type
{
    return _statusByte;
}

@end
