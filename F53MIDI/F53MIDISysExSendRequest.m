/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDISysExSendRequest.m
@date    Created on 4/07/06.
@brief   

Copyright (c) 2001-2006, Kurt Revis.  All rights reserved.
Copyright (c) 2006 Christopher Ashworth. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

**/

#import "F53MIDISysExSendRequest.h"

#import "F53MIDIUtilities.h"
#import "F53MIDIEndpoint.h"
#import "F53MIDISystemExclusiveMessage.h"


@interface F53MIDISysExSendRequest (Private)

static void completionProc(MIDISysexSendRequest *request);
- (void) completionProc;

@end

@implementation F53MIDISysExSendRequest (Private)

static void completionProc(MIDISysexSendRequest *request)
{
    NSAutoreleasePool *pool;
	
    pool = [[NSAutoreleasePool alloc] init];    
    [(F53MIDISysExSendRequest *)(request->completionRefCon) completionProc];
    [pool release];
}

- (void) completionProc
{
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDISysExSendRequestFinishedNotification object:self];
    [self release];
}

@end

@implementation F53MIDISysExSendRequest

NSString *F53MIDISysExSendRequestFinishedNotification = @"F53MIDISysExSendRequestFinishedNotification";

+ (F53MIDISysExSendRequest *) sysExSendRequestWithMessage: (F53MIDISystemExclusiveMessage *) aMessage 
												endpoint: (F53MIDIDestinationEndpoint *) endpoint
{
    return [[[self alloc] initWithMessage:aMessage endpoint:endpoint] autorelease];
}

- (id) initWithMessage: (F53MIDISystemExclusiveMessage *) aMessage 
			  endpoint: (F53MIDIDestinationEndpoint *) endpoint
{
    if (![super init])
        return nil;
	
    F53Assert(aMessage != nil);
    
    _message = [aMessage retain];
    _fullMessageData = [[_message fullMessageData] retain];
	
    _request.destination = [endpoint endpointRef];
    _request.data = (Byte *)[_fullMessageData bytes];
    _request.bytesToSend = [_fullMessageData length];
    _request.complete = FALSE;
    _request.completionProc = completionProc;
    _request.completionRefCon = self;
	
    return self;
}

- (id) init
{
    F53RejectUnusedImplementation(self, _cmd);
    return nil;
}

- (void) dealloc
{
    [_message release];
    _message = nil;
    [_fullMessageData release];
    _fullMessageData = nil;
	
    [super dealloc];
}

- (F53MIDISystemExclusiveMessage *) message
{
    return _message;
}

- (void) send
{
    OSStatus status;
	
    // Retain ourself, so we are guaranteed to stick around while the send is happening.
    // When we are notified that the request is finished, we will release ourself.
    [self retain];
    
    status = MIDISendSysex(&_request);
    if (status) {
        NSLog(@"MIDISendSysex() returned error: %ld", status);
        [self release];
    }
}

///
///  Returns YES if the request was cancelled before it was finished sending; NO if it was already finished.
///  In either case, F53MIDISysExSendRequestFinishedNotification will be posted.
///
- (BOOL) cancel
{
    if (_request.complete)
        return NO;
	
    _request.complete = TRUE;
    return YES;
}

- (unsigned int) bytesRemaining
{
    return _request.bytesToSend;
}

- (unsigned int) totalBytes
{
    return [_fullMessageData length];
}

- (unsigned int) bytesSent
{
    unsigned int totalBytes, bytesRemaining;
	
    totalBytes = [self totalBytes];
    bytesRemaining = [self bytesRemaining];
    F53Assert(totalBytes >= bytesRemaining);
	
    return totalBytes - bytesRemaining;
}

- (BOOL)wereAllBytesSent;
{
    return ([self bytesRemaining] == 0);
}

@end

