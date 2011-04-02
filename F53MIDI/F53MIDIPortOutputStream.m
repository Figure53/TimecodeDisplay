/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIPortOutputStream.m
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

#import "F53MIDIPortOutputStream.h"

#import "F53MIDIUtilities.h"
#import "F53MIDIClient.h"
#import "F53MIDIEndpoint.h"
#import "F53MIDIHostTime.h"
#import "F53MIDIMessage.h"
#import "F53MIDISystemExclusiveMessage.h"
#import "F53MIDISysExSendRequest.h"


@interface F53MIDIPortOutputStream (Private)

- (void) endpointDisappeared: (NSNotification *) notification;
- (void) endpointWasReplaced: (NSNotification *) notification;

- (void) splitMessages: (NSArray *) messages 
	  intoCurrentSysex: (NSArray **) sysExMessagesPtr 
			 andNormal: (NSArray **) normalMessagesPtr;

- (void) sendSysExMessagesAsynchronously: (NSArray *) sysExMessages;
- (void) sysExSendRequestFinished: (NSNotification *) notification;

@end

@implementation F53MIDIPortOutputStream (Private)

- (void) endpointDisappeared: (NSNotification *) notification
{
    F53MIDIDestinationEndpoint *endpoint = [notification object];
    NSMutableSet *newEndpoints;
	
    F53Assert([_endpoints containsObject:endpoint]);
	
    newEndpoints = [NSMutableSet setWithSet:_endpoints];
    [newEndpoints removeObject:endpoint];
    [self setEndpoints:newEndpoints];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIPortOutputStreamEndpointDisappearedNotification object:self];
}

- (void) endpointWasReplaced: (NSNotification *) notification
{
    F53MIDIDestinationEndpoint *endpoint = [notification object];
    F53MIDIDestinationEndpoint *newEndpoint;
    NSMutableSet *newEndpoints;
	
    F53Assert([_endpoints containsObject:endpoint]);
	
    newEndpoint = [[notification userInfo] objectForKey:F53MIDIObjectReplacement];
	
    newEndpoints = [NSMutableSet setWithSet:_endpoints];
    [newEndpoints removeObject:endpoint];
    [newEndpoints addObject:newEndpoint];
    [self setEndpoints:newEndpoints];    
}

- (void) splitMessages: (NSArray *) messages intoCurrentSysex: (NSArray **) sysExMessagesPtr andNormal: (NSArray **) normalMessagesPtr
{
    unsigned int messageIndex, messageCount;
    NSMutableArray *sysExMessages = nil;
    NSMutableArray *normalMessages = nil;
    MIDITimeStamp now;
	
    now = F53MIDIGetCurrentHostTime();
	
    messageCount = [messages count];
    for (messageIndex = 0; messageIndex < messageCount; messageIndex++) {
        F53MIDIMessage *message;
        NSMutableArray **theArray;
		
        message = [messages objectAtIndex:messageIndex];
        if ([message isKindOfClass:[F53MIDISystemExclusiveMessage class]] && [message timeStamp] <= now)
            theArray = &sysExMessages;
        else
            theArray = &normalMessages;
		
        if (*theArray == nil)
            *theArray = [NSMutableArray array];
        [*theArray addObject:message];
    }
	
    if (sysExMessagesPtr)
        *sysExMessagesPtr = sysExMessages;
    if (normalMessagesPtr)
        *normalMessagesPtr = normalMessages;
}

- (void) sendSysExMessagesAsynchronously: (NSArray *) messages
{
    unsigned int messageCount, messageIndex;
	
    messageCount = [messages count];
    for (messageIndex = 0; messageIndex < messageCount; messageIndex++) {
        F53MIDISystemExclusiveMessage *message;
        NSEnumerator *enumerator;
        F53MIDIDestinationEndpoint *endpoint;
		
        message = [messages objectAtIndex:messageIndex];
		
        enumerator = [_endpoints objectEnumerator];
        while ((endpoint = [enumerator nextObject])) {
            F53MIDISysExSendRequest *sendRequest;
			
            sendRequest = [F53MIDISysExSendRequest sysExSendRequestWithMessage:message endpoint:endpoint];
            [_sysExSendRequests addObject:sendRequest];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sysExSendRequestFinished:) name:F53MIDISysExSendRequestFinishedNotification object:sendRequest];
			
            [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIPortOutputStreamWillStartSysExSendNotification object:self userInfo:[NSDictionary dictionaryWithObject:sendRequest forKey:@"sendRequest"]];
			
            [sendRequest send];
        }
    }
}

- (void) sysExSendRequestFinished: (NSNotification *) notification
{
    F53MIDISysExSendRequest *sendRequest;
	
    sendRequest = [notification object];
    F53Assert([sysExSendRequests containsObject:sendRequest]);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:sendRequest];
    [sendRequest retain];
    [_sysExSendRequests removeObjectIdenticalTo:sendRequest];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIPortOutputStreamFinishedSysExSendNotification object:self userInfo:[NSDictionary dictionaryWithObject:sendRequest forKey:@"sendRequest"]];
	
    [sendRequest release];
}

@end


@implementation F53MIDIPortOutputStream

NSString *F53MIDIPortOutputStreamEndpointDisappearedNotification = @"F53MIDIPortOutputStreamEndpointDisappearedNotification";
NSString *F53MIDIPortOutputStreamWillStartSysExSendNotification = @"F53MIDIPortOutputStreamWillStartSysExSendNotification";
NSString *F53MIDIPortOutputStreamFinishedSysExSendNotification = @"F53MIDIPortOutputStreamFinishedSysExSendNotification";


- (id) init
{
    OSStatus status;

    if (!(self = [super init]))
        return nil;

    _portFlags.sendsSysExAsynchronously = NO;

    _sysExSendRequests = [[NSMutableArray alloc] init];
    _endpoints = [[NSMutableSet alloc] init];

    status = MIDIOutputPortCreate([[F53MIDIClient sharedClient] midiClient], (CFStringRef)@"Output port",  &_outputPort);
    if (status != noErr) {
        [NSException raise:NSGenericException format:NSLocalizedStringFromTableInBundle(@"Couldn't create a MIDI output port (error %ld)", @"F53MIDI", F53BundleForObject(self), "exception with OSStatus if MIDIOutputPortCreate() fails"), status];
    }

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    MIDIPortDispose(_outputPort);
    _outputPort = NULL;

    [_endpoints release];
    _endpoints = nil;

    [_sysExSendRequests release];
    _sysExSendRequests = nil;    
    
    [super dealloc];
}

- (void) setEndpoints: (NSSet *) newEndpoints
{
    NSNotificationCenter *center;
    NSMutableSet *removedEndpoints, *addedEndpoints;
    NSEnumerator *enumerator;
    F53MIDIDestinationEndpoint *endpoint;

    if (!newEndpoints)
        newEndpoints = [NSSet set];

    if ([_endpoints isEqual:newEndpoints])
        return;
        
    center = [NSNotificationCenter defaultCenter];

    removedEndpoints = [NSMutableSet setWithSet:_endpoints];
    [removedEndpoints minusSet:newEndpoints];
    enumerator = [removedEndpoints objectEnumerator];
    while ((endpoint = [enumerator nextObject]))
        [center removeObserver:self name:nil object:endpoint];

    addedEndpoints = [NSMutableSet setWithSet:newEndpoints];
    [addedEndpoints minusSet:_endpoints];
    enumerator = [addedEndpoints objectEnumerator];
    while ((endpoint = [enumerator nextObject])) {
        [center addObserver:self selector:@selector(endpointDisappeared:) name:F53MIDIObjectDisappearedNotification object:endpoint];
        [center addObserver:self selector:@selector(endpointWasReplaced:) name:F53MIDIObjectWasReplacedNotification object:endpoint];
    }
                                
    [_endpoints release];
    _endpoints = [newEndpoints retain];        
}

- (NSSet *) endpoints
{
    return _endpoints;
}

///
///  If YES, then use MIDISendSysex() to send sysex messages with timestamps now or in the past.
///  (We can't use MIDISendSysex() to schedule delivery in the future.)
///  Otherwise, use plain old MIDI packets.
///
- (void) setSendsSysExAsynchronously: (BOOL) value
{
    _portFlags.sendsSysExAsynchronously = value;
}

- (BOOL) sendsSysExAsynchronously
{
    return _portFlags.sendsSysExAsynchronously;
}

- (void) cancelPendingSysExSendRequests
{
    [_sysExSendRequests makeObjectsPerformSelector:@selector(cancel)];
}

- (NSArray *) pendingSysExSendRequests
{
    return [NSArray arrayWithArray:_sysExSendRequests];
}

//
// F53MIDIOutputStream overrides
//

- (void) takeMIDIMessages: (NSArray *) messages
{
    if ([self sendsSysExAsynchronously]) {
        NSArray *sysExMessages, *normalMessages;

        // Find the messages which are sysex and which have timestamps which are <= now,
        // and send them using MIDISendSysex(). Other messages get sent normally.

        [self splitMessages:messages intoCurrentSysex:&sysExMessages andNormal:&normalMessages];

        [self sendSysExMessagesAsynchronously:sysExMessages];
        [super takeMIDIMessages:normalMessages];
    } else {
        [super takeMIDIMessages:messages];
    }
}

//
// F53MIDIOutputStream subclass-implementation methods
//

- (void) sendMIDIPacketList: (MIDIPacketList *) packetList
{
    NSEnumerator *enumerator;
    F53MIDIDestinationEndpoint *endpoint;

    enumerator = [_endpoints objectEnumerator];
    while ((endpoint = [enumerator nextObject])) {
        MIDIEndpointRef endpointRef;
        OSStatus status;

        if (!(endpointRef = [endpoint endpointRef]))
            continue;
    
        status = MIDISend(_outputPort, endpointRef, packetList);
        if (status) {
#if DEBUG
            NSLog(@"MIDISend(%p, %p, %p) returned error: %ld", outputPort, endpointRef, packetList, status);
#endif
        }
    }
}

@end
