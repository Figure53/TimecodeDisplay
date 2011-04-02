/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIPortInputStream.m
@date    Created on 8/11/06.
@brief   

Copyright (c) 2001-2004, Kurt Revis.  All rights reserved.
Copyright (c) 2006 Christopher Ashworth.  All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

**/

#import "F53MIDIPortInputStream.h"

#import "F53MIDIUtilities.h"
#import "F53MIDIClient.h"
#import "F53MIDIEndpoint.h"
#import "F53MIDISourceEndpoint.h"
#import "F53MIDIMessageParser.h"
#import "F53MIDIInputStreamSource.h"


@interface F53MIDIPortInputStream (Private)

- (void) endpointListChanged: (NSNotification *) notification;
- (void) endpointDisappeared: (NSNotification *) notification;
- (void) endpointWasReplaced: (NSNotification *) notification;

@end


@implementation F53MIDIPortInputStream

- (id) init
{
    OSStatus status;

    if (!(self = [super init]))
        return nil;

    status = MIDIInputPortCreate([[F53MIDIClient sharedClient] midiClient], (CFStringRef)@"Input port", [self midiReadProc], self, &_inputPort);
    if (status != noErr)
        [NSException raise:NSGenericException format:NSLocalizedStringFromTableInBundle(@"Couldn't create a MIDI input port (error %ld)", @"F53MIDI", F53BundleForObject(self), "exception with OSStatus if MIDIInputPortCreate() fails"), status];

    _endpoints = [[NSMutableSet alloc] init];

    _parsersForEndpoints = NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endpointListChanged:) name:F53MIDIObjectListChangedNotification object:[F53MIDISourceEndpoint class]];
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (_inputPort)
        MIDIPortDispose(_inputPort);
    _inputPort = NULL;

    [_endpoints release];
    _endpoints = nil;

    NSFreeMapTable(_parsersForEndpoints);
    _parsersForEndpoints = NULL;
    
    [super dealloc];
}

- (NSSet *) endpoints
{
    return [NSSet setWithSet:_endpoints];
}

- (void) addEndpoint: (F53MIDISourceEndpoint *) endpoint
{
    F53MIDIMessageParser *parser;
    OSStatus status;
    NSNotificationCenter *center;

    if (!endpoint)
        return;
    
    if ([_endpoints containsObject:endpoint])
        return;

    parser = [self newParserWithOriginatingEndpoint:endpoint];
    
    status = MIDIPortConnectSource(_inputPort, [endpoint endpointRef], parser);
    if (status != noErr) {
        NSLog(@"Error from MIDIPortConnectSource: %d", status);
        return;
    }

    NSMapInsert(_parsersForEndpoints, endpoint, parser);

    center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(endpointDisappeared:) name:F53MIDIObjectDisappearedNotification object:endpoint];
    [center addObserver:self selector:@selector(endpointWasReplaced:) name:F53MIDIObjectWasReplacedNotification object:endpoint];

    [_endpoints addObject:endpoint];
}

- (void) removeEndpoint: (F53MIDISourceEndpoint *) endpoint
{
    OSStatus status;
    NSNotificationCenter *center;

    if (!endpoint)
        return;

    if (![_endpoints containsObject:endpoint])
        return;
    
    status = MIDIPortDisconnectSource(_inputPort, [endpoint endpointRef]);
    if (status != noErr) {
        // An error can happen in normal circumstances (if the endpoint has disappeared), so ignore it.
    }

    NSMapRemove(_parsersForEndpoints, endpoint);
    
    center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:F53MIDIObjectDisappearedNotification object:endpoint];
    [center removeObserver:self name:F53MIDIObjectWasReplacedNotification object:endpoint];

    [_endpoints removeObject:endpoint];
}

- (void) setEndpoints: (NSSet *) newEndpoints
{
    NSMutableSet *endpointsToRemove;
    NSMutableSet *endpointsToAdd;
    NSEnumerator *enumerator;
    F53MIDISourceEndpoint *endpoint;

    // remove (_endpoints - newEndpoints)
    endpointsToRemove = [NSMutableSet setWithSet:_endpoints];
    [endpointsToRemove minusSet:newEndpoints];

    // add (newEndpoints - _endpoints)
    endpointsToAdd = [NSMutableSet setWithSet:newEndpoints];
    [endpointsToAdd minusSet:_endpoints];

    enumerator = [endpointsToRemove objectEnumerator];
    while ((endpoint = [enumerator nextObject]))
        [self removeEndpoint:endpoint];

    enumerator = [endpointsToAdd objectEnumerator];
    while ((endpoint = [enumerator nextObject]))
        [self addEndpoint:endpoint];
}


//
// F53MIDIInputStream subclass
//

- (NSArray *) parsers
{
    return NSAllMapTableValues(_parsersForEndpoints);
}

- (F53MIDIMessageParser *) parserForSourceConnectionRefCon: (void *) refCon
{
    return (F53MIDIMessageParser *)refCon;
}

- (id <F53MIDIInputStreamSource>) streamSourceForParser: (F53MIDIMessageParser *) parser
{
    return [parser originatingEndpoint];
}

- (NSArray *) inputSources
{
    return [F53MIDISourceEndpoint sourceEndpoints];
}

- (NSSet *) selectedInputSources
{
    return [self endpoints];
}

- (void) setSelectedInputSources: (NSSet *) sources
{
    [self setEndpoints:sources];
}

@end


@implementation F53MIDIPortInputStream (Private)

- (void) endpointListChanged: (NSNotification *) notification
{
    [self postSourceListChangedNotification];
}

- (void) endpointDisappeared: (NSNotification *) notification
{
    F53MIDISourceEndpoint *endpoint;

    endpoint = [[[notification object] retain] autorelease];
    F53Assert([_endpoints containsObject:endpoint]);

    [self removeEndpoint:endpoint];

    [self postSelectedInputStreamSourceDisappearedNotification:endpoint];
}

- (void) endpointWasReplaced: (NSNotification *) notification
{
    F53MIDISourceEndpoint *oldEndpoint, *newEndpoint;

    oldEndpoint = [notification object];
    F53Assert([_endpoints containsObject:oldEndpoint]);

    newEndpoint = [[notification userInfo] objectForKey:F53MIDIObjectReplacement];

    [self removeEndpoint:oldEndpoint];
    [self addEndpoint:newEndpoint];    
}

@end
