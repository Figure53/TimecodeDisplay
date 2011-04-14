/**

 @author  Kurt Revis
 @file    F53MIDIMessageFilter.m

 Copyright (c) 2001-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#import "F53MIDIMessageFilter.h"


@interface F53MIDIMessageFilter (Private)

- (NSArray *) filterMessages: (NSArray *) messages;

@end


@implementation F53MIDIMessageFilter

- (id) init
{
    if (!(self = [super init]))
        return nil;
    
    _filterMask = F53MIDIMessageTypeNothingMask;
    _channelMask = F53MIDIChannelMaskAll;
    
    _settingsLock = [[NSLock alloc] init];
    
    return self;
}

- (void) dealloc
{
    _nonretainedMessageDestination = nil;
    [_settingsLock release];
    _settingsLock = nil;
    
    [super dealloc];
}

- (void) setMessageDestination: (id <F53MIDIMessageDestination>) aMessageDestination
{
    _nonretainedMessageDestination = aMessageDestination;
}

- (id <F53MIDIMessageDestination>) messageDestination
{
    return _nonretainedMessageDestination;
}

- (void) setFilterMask: (F53MIDIMessageType) newFilterMask
{
    [_settingsLock lock];
    _filterMask = newFilterMask;
    [_settingsLock unlock];
}

- (F53MIDIMessageType) filterMask
{
    return _filterMask;
}

- (void) setChannelMask: (F53MIDIChannelMask) newChannelMask
{
    [_settingsLock lock];
    _channelMask = newChannelMask;
    [_settingsLock unlock];
}

- (F53MIDIChannelMask) channelMask
{
    return _channelMask;
}

//
// F53MIDIMessageDestination protocol
//

- (void) takeMIDIMessages: (NSArray *) messages
{
    NSArray *filteredMessages;
    
    filteredMessages = [self filterMessages:messages];
    if ([filteredMessages count])
        [_nonretainedMessageDestination takeMIDIMessages:filteredMessages];
}

@end


@implementation F53MIDIMessageFilter (Private)

- (NSArray *) filterMessages: (NSArray *) messages
{
    unsigned int messageIndex, messageCount;
    NSMutableArray *filteredMessages;
    F53MIDIMessageType localFilterMask;
    F53MIDIChannelMask localChannelMask;
    
    messageCount = [messages count];
    filteredMessages = [NSMutableArray arrayWithCapacity:messageCount];
    
    // Copy the filter settings so we act consistent, if someone else changes them while we're working
    [_settingsLock lock];
    localFilterMask = _filterMask;
    localChannelMask = _channelMask;
    [_settingsLock unlock];
    
    for (messageIndex = 0; messageIndex < messageCount; messageIndex++) {
        F53MIDIMessage *message;
        
        message = [messages objectAtIndex:messageIndex];
        if ([message matchesMessageTypeMask:localFilterMask]) {
            // NOTE: This type checking kind of smells, but I can't think of a better way to do it.
            // We could implement -matchesChannelMask on all F53MIDIMessages, but I don't know if the default should be YES or NO...
            // I could see it going either way, in different contexts.
            if ([message isKindOfClass:[F53MIDIVoiceMessage class]] && ![(F53MIDIVoiceMessage *)message matchesChannelMask:localChannelMask]) {
                // drop this message
            } else {
                [filteredMessages addObject:message];
            }
        }
    }
    
    return filteredMessages;
}

@end
