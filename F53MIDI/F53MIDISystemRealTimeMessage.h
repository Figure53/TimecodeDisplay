/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDISystemRealTimeMessage.h
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

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

#import "F53MIDIMessage.h"

typedef enum _F53SystemRealTimeMessageType {
    F53MIDISystemRealTimeMessageTypeClock = 0xF8,
    F53MIDISystemRealTimeMessageTypeStart = 0xFA,
    F53MIDISystemRealTimeMessageTypeContinue = 0xFB,
    F53MIDISystemRealTimeMessageTypeStop = 0xFC,
    F53MIDISystemRealTimeMessageTypeActiveSense = 0xFE,
    F53MIDISystemRealTimeMessageTypeReset = 0xFF
} F53MIDISystemRealTimeMessageType;

@interface F53MIDISystemRealTimeMessage: F53MIDIMessage
{
}

+ (F53MIDISystemRealTimeMessage *) systemRealTimeMessageWithTimeStamp: (MIDITimeStamp) aTimeStamp 
																type: (F53MIDISystemRealTimeMessageType) aType;

- (void) setType: (F53MIDISystemRealTimeMessageType) newType;
- (F53MIDISystemRealTimeMessageType) type;

@end
