/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIMessage.h
@date    Created on 3/21/06.
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

@class F53MIDIEndpoint;


typedef enum _F53MIDIMessageType {
    F53MIDIMessageTypeUnknown				= 0,
	
    // Voice messages
    F53MIDIMessageTypeNoteOn					= 1 << 0,
    F53MIDIMessageTypeNoteOff				= 1 << 1,
    F53MIDIMessageTypeAftertouch				= 1 << 2,
    F53MIDIMessageTypeControl				= 1 << 3,
    F53MIDIMessageTypeProgram				= 1 << 4,
    F53MIDIMessageTypeChannelPressure		= 1 << 5,
    F53MIDIMessageTypePitchWheel				= 1 << 6,
	
    // System common messages
    F53MIDIMessageTypeTimeCode				= 1 << 7,
    F53MIDIMessageTypeSongPositionPointer	= 1 << 8,
    F53MIDIMessageTypeSongSelect				= 1 << 9,
    F53MIDIMessageTypeTuneRequest			= 1 << 10,
	
    // Real time messages
    F53MIDIMessageTypeClock					= 1 << 11,
    F53MIDIMessageTypeStart					= 1 << 12,
    F53MIDIMessageTypeStop					= 1 << 13,
    F53MIDIMessageTypeContinue				= 1 << 14,
    F53MIDIMessageTypeActiveSense			= 1 << 15,
    F53MIDIMessageTypeReset					= 1 << 16,
    
    // System exclusive
    F53MIDIMessageTypeSystemExclusive		= 1 << 17,
	
    // Invalid
    F53MIDIMessageTypeInvalid				= 1 << 18,
    
    // Groups
    F53MIDIMessageTypeNothingMask			= 0,
    F53MIDIMessageTypeAllVoiceMask			= (F53MIDIMessageTypeNoteOn | F53MIDIMessageTypeNoteOff | F53MIDIMessageTypeAftertouch | F53MIDIMessageTypeControl | F53MIDIMessageTypeProgram | F53MIDIMessageTypeChannelPressure | F53MIDIMessageTypePitchWheel),
    F53MIDIMessageTypeNoteOnAndOffMask		= (F53MIDIMessageTypeNoteOn | F53MIDIMessageTypeNoteOff),
    F53MIDIMessageTypeAllSystemCommonMask	= (F53MIDIMessageTypeTimeCode | F53MIDIMessageTypeSongPositionPointer | F53MIDIMessageTypeSongSelect | F53MIDIMessageTypeTuneRequest),
    F53MIDIMessageTypeAllRealTimeMask		= (F53MIDIMessageTypeClock | F53MIDIMessageTypeStart | F53MIDIMessageTypeStop | F53MIDIMessageTypeContinue | F53MIDIMessageTypeActiveSense | F53MIDIMessageTypeReset),
    F53MIDIMessageTypeStartStopContinueMask	= (F53MIDIMessageTypeStart | F53MIDIMessageTypeStop | F53MIDIMessageTypeContinue),
    F53MIDIMessageTypeAllMask				= (F53MIDIMessageTypeAllVoiceMask | F53MIDIMessageTypeAllSystemCommonMask | F53MIDIMessageTypeAllRealTimeMask | F53MIDIMessageTypeSystemExclusive | F53MIDIMessageTypeInvalid)
	
} F53MIDIMessageType;

typedef enum _F53MIDINoteFormattingOption {
    F53MIDINoteFormatDecimal = 0,
    F53MIDINoteFormatHexadecimal = 1,
    F53MIDINoteFormatNameMiddleC3 = 2,	// Middle C = 60 decimal = C3, aka "Yamaha"
    F53MIDINoteFormatNameMiddleC4 = 3	// Middle C = 60 decimal = C4, aka "Roland"
} F53MIDINoteFormattingOption;

typedef enum _F53MIDIControllerFormattingOption {
    F53MIDIControllerFormatDecimal = 0,
    F53MIDIControllerFormatHexadecimal = 1,
    F53MIDIControllerFormatName = 2
} F53MIDIControllerFormattingOption;

typedef enum _F53MIDIDataFormattingOption {
    F53MIDIDataFormatDecimal = 0,
    F53MIDIDataFormatHexadecimal = 1
} F53MIDIDataFormattingOption;

typedef enum _F53MIDITimeFormattingOption {
    F53MIDITimeFormatHostTimeInteger = 0,
    F53MIDITimeFormatHostTimeNanoseconds = 1,
    F53MIDITimeFormatHostTimeSeconds = 2,
    F53MIDITimeFormatClockTime = 3,
    F53MIDITimeFormatHostTimeHexInteger = 4
} F53MIDITimeFormattingOption;

// Preferences keys
extern NSString *F53MIDINoteFormatPreferenceKey;
extern NSString *F53MIDIControllerFormatPreferenceKey;
extern NSString *F53MIDIDataFormatPreferenceKey;
extern NSString *F53MIDITimeFormatPreferenceKey;


@interface F53MIDIMessage : NSObject <NSCopying>
{
    MIDITimeStamp	_timeStamp;
    Byte			_statusByte;
    F53MIDIEndpoint *_originatingEndpoint;
}

+ (NSString *) formatNoteNumber: (Byte) noteNumber;
+ (NSString *) formatNoteNumber: (Byte) noteNumber usingOption: (F53MIDINoteFormattingOption) option;
+ (NSString *) formatControllerNumber: (Byte) controllerNumber;
+ (NSString *) formatControllerNumber: (Byte) controllerNumber usingOption: (F53MIDIControllerFormattingOption) option;
+ (NSString *) nameForControllerNumber: (Byte) controllerNumber;
+ (NSString *) formatData: (NSData *) data;
+ (NSString *) formatDataBytes: (const Byte *) bytes length: (unsigned int) length;
+ (NSString *) formatDataByte: (Byte) dataByte;
+ (NSString *) formatDataByte: (Byte) dataByte usingOption: (F53MIDIDataFormattingOption) option;
+ (NSString *) formatSignedDataByte1: (Byte) dataByte1 byte2: (Byte) dataByte2;
+ (NSString *) formatSignedDataByte1: (Byte) dataByte1 byte2: (Byte) dataByte2 usingOption: (F53MIDIDataFormattingOption) option;
+ (NSString *) formatLength: (unsigned int) length;
+ (NSString *) formatLength: (unsigned int) length usingOption: (F53MIDIDataFormattingOption) option;
+ (NSString *) nameForManufacturerIdentifier: (NSData *) manufacturerIdentifierData;
+ (NSString *) formatTimeStamp: (MIDITimeStamp) timeStamp;
+ (NSString *) formatTimeStamp: (MIDITimeStamp) timeStamp usingOption: (F53MIDITimeFormattingOption) option;

- (id) initWithTimeStamp: (MIDITimeStamp) aTimeStamp statusByte: (Byte) aStatusByte;

- (void) setTimeStamp: (MIDITimeStamp) value;
- (void) setTimeStampToNow;
- (MIDITimeStamp) timeStamp;

- (Byte) statusByte;

- (F53MIDIMessageType) messageType;
- (BOOL) matchesMessageTypeMask: (F53MIDIMessageType) mask;

- (unsigned int) otherDataLength;
- (const Byte *) otherDataBuffer;
- (NSData *) otherData;

- (void) setOriginatingEndpoint: (F53MIDIEndpoint *) value;
- (F53MIDIEndpoint *) originatingEndpoint;

// Display methods:

- (NSString *) timeStampForDisplay;
- (NSString *) channelForDisplay;
- (NSString *) typeForDisplay;
- (NSString *) dataForDisplay;

@end

