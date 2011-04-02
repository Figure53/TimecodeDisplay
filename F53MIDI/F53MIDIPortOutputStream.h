/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIPortOutputStream.h
@date    Created on 4/07/06.
@brief   

Copyright (c) 2001-2004, Kurt Revis.  All rights reserved.
Copyright (c) 2006 Christopher Ashworth. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

**/

#import "F53MIDIOutputStream.h"
#import <CoreMIDI/CoreMIDI.h>
#import <Foundation/Foundation.h>

@class F53MIDIDestinationEndpoint;
@class F53MIDISysExSendRequest;


@interface F53MIDIPortOutputStream : F53MIDIOutputStream
{
    struct {
        unsigned int sendsSysExAsynchronously:1;
    } _portFlags;
	
    MIDIPortRef _outputPort;
    NSMutableSet *_endpoints;
    NSMutableArray *_sysExSendRequests;
}

- (void) setEndpoints: (NSSet *) newEndpoints;
- (NSSet *) endpoints;

- (void) setSendsSysExAsynchronously: (BOOL) value;
- (BOOL) sendsSysExAsynchronously;

- (void) cancelPendingSysExSendRequests;
- (NSArray *) pendingSysExSendRequests;

@end

// Notifications

extern NSString *F53MIDIPortOutputStreamEndpointDisappearedNotification;	// Sent if the stream's destination endpoint goes away
extern NSString *F53MIDIPortOutputStreamWillStartSysExSendNotification;	// user info has key @"sendRequest", object F53MIDISysExSendRequest
extern NSString *F53MIDIPortOutputStreamFinishedSysExSendNotification;	// user info has key @"sendRequest", object F53MIDISysExSendRequest
