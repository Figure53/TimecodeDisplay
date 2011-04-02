/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIInputStream.h
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

#import <CoreMIDI/CoreMIDI.h>
#import <Foundation/Foundation.h>
#import "F53MIDIMessageDestinationProtocol.h"
#import "F53MIDIInputStreamSource.h"

@class F53MIDIEndpoint;
@class F53MIDIMessageParser;


@interface F53MIDIInputStream : NSObject
{
    id <F53MIDIMessageDestination> _nonretainedMessageDestination;
    NSTimeInterval _sysExTimeOut;
}

- (void) setMessageDestination: (id <F53MIDIMessageDestination>) messageDestination;
- (id <F53MIDIMessageDestination>) messageDestination;

- (void) setSysExTimeOut: (NSTimeInterval) value;
- (NSTimeInterval) sysExTimeOut;

- (void) cancelReceivingSysExMessage;

- (NSArray *) takePersistentSettings: (id) settings;  // If any endpoints couldn't be found, their names are returned
- (id) persistentSettings;

	// For subclasses only
- (MIDIReadProc) midiReadProc;
- (F53MIDIMessageParser *) newParserWithOriginatingEndpoint: (F53MIDIEndpoint *) originatingEndpoint;
- (void) postSelectedInputStreamSourceDisappearedNotification: (id <F53MIDIInputStreamSource>) source;
- (void) postSourceListChangedNotification;

	// For subclasses to implement
- (NSArray *) parsers;
- (F53MIDIMessageParser *) parserForSourceConnectionRefCon: (void *) refCon;
- (id <F53MIDIInputStreamSource>) streamSourceForParser: (F53MIDIMessageParser *) parser;

- (NSArray *) inputSources;
- (void) setSelectedInputSources: (NSSet *) sources;
- (NSSet *) selectedInputSources;

@end

// Notifications
extern NSString *F53MIDIInputStreamReadingSysExNotification;		// contains key @"length" with NSNumber (unsigned int) size of data read so far
																// contains key @"source" with id <F53MIDIInputStreamSource> that this sysex data was read from
extern NSString *F53MIDIInputStreamDoneReadingSysExNotification; // contains key @"length" with NSNumber (unsigned int) indicating size of data read
																// contains key @"source" with id <F53MIDIInputStreamSource> that this sysex data was read from
																// contains key @"valid" with NSNumber (BOOL) indicating whether sysex ended properly or not
extern NSString *F53MIDIInputStreamSelectedInputSourceDisappearedNotification;
																// contains key @"source" with id <F53MIDIInputStreamSource> which disappeared
extern NSString *F53MIDIInputStreamSourceListChangedNotification;
