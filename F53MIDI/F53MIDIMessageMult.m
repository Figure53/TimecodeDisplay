/**

 @author  Kurt Revis
 @file    F53MIDIMessageMult.m

 Copyright (c) 2001-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#import "F53MIDIMessageMult.h"


@implementation F53MIDIMessageMult

- (id) init
{
    if (!(self = [super init]))
        return nil;
    
    _destinations = [[NSMutableArray alloc] init];
    _destinationsLock = [[NSLock alloc] init];
    
    return self;
}

- (void) dealloc
{
    [_destinations release];
    _destinations = nil;
    [_destinationsLock release];
    _destinationsLock = nil;
    
    [super dealloc];
}

- (void) setDestinations: (NSArray *) newDestinations
{
    if ((NSArray *)_destinations == newDestinations)
        return;
    
    [_destinationsLock lock];
    
    [_destinations release];
    _destinations = [newDestinations retain];
    
    [_destinationsLock unlock];
}

- (NSArray *) destinations
{
    return [NSArray arrayWithArray:_destinations];
}

- (void) addDestination: (id <F53MIDIMessageDestination>) destination
{
    [_destinationsLock lock];
    
    [_destinations addObject:destination];
    
    [_destinationsLock unlock];
}

- (void) removeDestination: (id <F53MIDIMessageDestination>) destination
{
    [_destinationsLock lock];
    
    [_destinations removeObject:destination];
    
    [_destinationsLock unlock];
}

- (void) takeMIDIMessages: (NSArray *) messages
{
    [_destinationsLock lock];
    
    [_destinations makeObjectsPerformSelector:@selector(takeMIDIMessages:) withObject:messages];
    
    [_destinationsLock unlock];
}

@end
