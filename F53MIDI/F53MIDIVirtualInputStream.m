/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIVirtualInputStream.m
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

#import "F53MIDIVirtualInputStream.h"

#import "F53MIDIUtilities.h"
#import "F53MIDIClient.h"
#import "F53MIDIEndpoint.h"
#import "F53MIDIDestinationEndpoint.h"
#import "F53MIDIMessageParser.h"
#import "F53MIDIInputStreamSource.h"


@interface F53MIDIVirtualInputStream (Private)

- (void) setIsActive: (BOOL) value;
- (BOOL) isActive;

- (void) createEndpoint;
- (void) disposeEndpoint;

@end


@implementation F53MIDIVirtualInputStream

- (id) init
{
    if (!(self = [super init]))
        return nil;

    _endpointName = [[[F53MIDIClient sharedClient] name] retain];
    _uniqueID = 0;	// Let CoreMIDI assign a unique ID to the virtual endpoint when it is created.

    _inputStreamSource = [[F53MIDISimpleInputStreamSource alloc] initWithName:_endpointName];

    _parser = [[self newParserWithOriginatingEndpoint:nil] retain];

    return self;
}

- (void) dealloc
{
    [self setIsActive:NO];

    [_endpointName release];
    _endpointName = nil;
    
    [_inputStreamSource release];
    _inputStreamSource = nil;
    
    [_parser release];
    _parser = nil;

    [super dealloc];
}

- (void) setUniqueID: (MIDIUniqueID) value
{
    _uniqueID = value;
    if (_endpoint) {
        if (![(F53MIDIObject *)_endpoint setUniqueID:value])
            _uniqueID = [(F53MIDIObject *)_endpoint uniqueID];	// we tried to change the unique ID, but failed
    }
}

- (MIDIUniqueID) uniqueID
{
    return _uniqueID;
}

- (void) setVirtualEndpointName: (NSString *) value
{
    if (_endpointName != value) {
        [_endpointName release];
        _endpointName = [value copy];

        if (_endpoint)
            [(F53MIDIObject *)_endpoint setName:_endpointName];
    }
}

- (NSString *) virtualEndpointName
{
    return _endpointName;
}

- (void) setInputSourceName: (NSString *) value
{
    [_inputStreamSource setName:value];
}

//
// F53MIDIInputStream subclass
//

- (NSArray *) parsers
{
    return [NSArray arrayWithObject:_parser];
}

- (F53MIDIMessageParser *) parserForSourceConnectionRefCon: (void *) refCon
{
    // refCon is ignored, since it only applies to connections created with MIDIPortConnectSource()
    return _parser;
}

- (id <F53MIDIInputStreamSource>) streamSourceForParser: (F53MIDIMessageParser *) aParser
{
    return _inputStreamSource;
}

- (NSArray *) inputSources
{
    return [NSArray arrayWithObject:_inputStreamSource];
}

- (void) setSelectedInputSources: (NSSet *) sources
{
    [self setIsActive:(sources && [sources containsObject:_inputStreamSource])];
}

- (NSSet *) selectedInputSources
{
    if ([self isActive])
        return [NSSet setWithObject:_inputStreamSource];
    else
        return [NSSet set];
}

//
// F53MIDIInputStream overrides
//

- (id) persistentSettings
{
    if ([self isActive])
        return [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_uniqueID] forKey:@"uniqueID"];
    else
        return nil;
}

- (NSArray *) takePersistentSettings: (id) settings
{
    if (settings) {
        [self setUniqueID:[[settings objectForKey:@"uniqueID"] intValue]];
        [self setIsActive:YES];
    } else {
        [self setIsActive:NO];
    }

    return nil;
}

@end


@implementation F53MIDIVirtualInputStream (Private)

- (void) setIsActive: (BOOL) value
{
    if (value && !_endpoint)
        [self createEndpoint];
    else if (!value && _endpoint)
        [self disposeEndpoint];
}

- (BOOL) isActive
{
    return (_endpoint != nil);
}

- (void) createEndpoint
{
    _endpoint = [[F53MIDIDestinationEndpoint createVirtualDestinationEndpointWithName:_endpointName readProc:[self midiReadProc] readProcRefCon:self uniqueID:_uniqueID] retain];
    if (_endpoint) {
        [_parser setOriginatingEndpoint:_endpoint];

        // We requested a specific uniqueID earlier, but we might not have gotten it.
        // We have to update our idea of what it is, regardless.
        _uniqueID = [(F53MIDIVirtualInputStream *)_endpoint uniqueID];
        F53Assert(_uniqueID != 0);
    }
}

- (void) disposeEndpoint
{
    F53Assert(_endpoint != nil);

    [_endpoint remove];
    [_endpoint release];
    _endpoint = nil;

    [_parser setOriginatingEndpoint:nil];
}

@end
