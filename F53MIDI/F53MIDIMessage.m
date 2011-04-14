/**

 @author  Kurt Revis
 @file    F53MIDIMessage.m

 Copyright (c) 2001-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#import "F53MIDIMessage.h"

#import "F53MIDIUtilities.h"
#import "F53MIDIEndpoint.h"
#import "F53MIDIHostTime.h"
#import "NSData-F53MIDIExtensions.h"


@interface F53MIDIMessage (Private)

static NSString *formatNoteNumberWithBaseOctave(Byte noteNumber, int octave);

@end

@implementation F53MIDIMessage (Private)

static NSString *formatNoteNumberWithBaseOctave(Byte noteNumber, int octave)
{
    // noteNumber 0 is note C in octave provided (should be -2 or -1)
    
    static char *noteNames[] = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
	
    return [NSString stringWithFormat:@"%s%d", noteNames[noteNumber % 12], octave + noteNumber / 12];
}

@end


@implementation F53MIDIMessage

NSString *F53MIDINoteFormatPreferenceKey = @"F53MIDINoteFormat";
NSString *F53MIDIControllerFormatPreferenceKey = @"F53MIDIControllerFormat";
NSString *F53MIDIDataFormatPreferenceKey = @"F53MIDIDataFormat";
NSString *F53MIDITimeFormatPreferenceKey = @"F53MIDITimeFormat";

static UInt64 _startHostTime;
static NSTimeInterval _startTimeInterval;
static NSDateFormatter *_timeStampDateFormatter;


+ (void) initialize
{
    F53Initialize;

    // Establish a base of what host time corresponds to what clock time.
    // TODO We should do this a few times and average the results, and also try to be careful not to get
    // scheduled out during this process. We may need to switch ourself to be a time-constraint thread temporarily
    // in order to do this. See discussion in the CoreAudio-API archives.
    _startHostTime = F53MIDIGetCurrentHostTime();
    _startTimeInterval = [NSDate timeIntervalSinceReferenceDate];

    _timeStampDateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%H:%M:%S.%F" allowNaturalLanguage:NO];
}

+ (NSString *) formatNoteNumber: (Byte) noteNumber
{
    return [self formatNoteNumber:noteNumber usingOption:[[NSUserDefaults standardUserDefaults] integerForKey:F53MIDINoteFormatPreferenceKey]];
}

+ (NSString *) formatNoteNumber: (Byte) noteNumber usingOption: (F53MIDINoteFormattingOption) option
{
    switch (option) {
        case F53MIDINoteFormatDecimal:
        default:
            return [NSString stringWithFormat:@"%d", noteNumber];

        case F53MIDINoteFormatHexadecimal:
            return [NSString stringWithFormat:@"$%02X", noteNumber];

        case F53MIDINoteFormatNameMiddleC3:
            // Middle C ==  60 == "C3", so base == 0 == "C-2"
            return formatNoteNumberWithBaseOctave(noteNumber, -2);

        case F53MIDINoteFormatNameMiddleC4:
            // Middle C == 60 == "C2", so base == 0 == "C-1" 
            return formatNoteNumberWithBaseOctave(noteNumber, -1);
    }
}

+ (NSString *) formatControllerNumber: (Byte) controllerNumber
{
    return [self formatControllerNumber:controllerNumber usingOption:[[NSUserDefaults standardUserDefaults] integerForKey:F53MIDIControllerFormatPreferenceKey]];
}

+ (NSString *) formatControllerNumber: (Byte) controllerNumber usingOption: (F53MIDIControllerFormattingOption) option
{
    switch (option) {
        case F53MIDIControllerFormatDecimal:
        default:
            return [NSString stringWithFormat:@"%d", controllerNumber];
            
        case F53MIDIControllerFormatHexadecimal:
            return [NSString stringWithFormat:@"$%02X", controllerNumber];

        case F53MIDIControllerFormatName:
            return [self nameForControllerNumber:controllerNumber];
    }
}

+ (NSString *) nameForControllerNumber: (Byte) controllerNumber
{
    static NSMutableArray *controllerNames = nil;

    F53Assert(controllerNumber <= 127);
    
    if (!controllerNames) {
        NSString *path;
        NSDictionary *controllerNameDict = nil;
        NSString *unknownName;
        unsigned int controllerIndex;
        
        path = [F53BundleForObject(self) pathForResource:@"ControllerNames" ofType:@"plist"];
        if (path) {        
            controllerNameDict = [NSDictionary dictionaryWithContentsOfFile:path];
            if (!controllerNameDict)
                NSLog(@"Couldn't read ControllerNames.plist!");
        } else {
            NSLog(@"Couldn't find ControllerNames.plist!");
        }

        // It's lame that property lists must have keys which are strings. We would prefer an integer, in this case.
        // We could create a new string for the controllerNumber and look that up in the dictionary, but that gets expensive to do all the time.
        // Instead, we just scan through the dictionary once, and build an NSArray which is quicker to index into.

        unknownName = NSLocalizedStringFromTableInBundle(@"Controller %u", @"F53MIDI", F53BundleForObject(self), "format of unknown controller");

        controllerNames = [[NSMutableArray alloc] initWithCapacity:128];
        for (controllerIndex = 0; controllerIndex <= 127; controllerIndex++) {
            NSString *name;
            
            name = [controllerNameDict objectForKey:[NSString stringWithFormat:@"%u", controllerIndex]];
            if (!name)
                name = [NSString stringWithFormat:unknownName, controllerIndex];

            [controllerNames addObject:name];
        }        
    }

    return [controllerNames objectAtIndex:controllerNumber];
}

+ (NSString *) formatData: (NSData *) data
{
    return [self formatDataBytes:[data bytes] length:[data length]];
}

+ (NSString *) formatDataBytes: (const Byte *) bytes length: (unsigned int) length
{
    F53MIDIDataFormattingOption option;
    NSMutableString *string;
    unsigned int pos;

    option = [[NSUserDefaults standardUserDefaults] integerForKey:F53MIDIDataFormatPreferenceKey];
    string = [NSMutableString string];
    for (pos = 0; pos < length; pos++) {
        [string appendString:[self formatDataByte:*(bytes + pos) usingOption:option]];
        if (pos + 1 < length)
            [string appendString:@" "];
    }
    
    return string;
}

+ (NSString *) formatDataByte: (Byte) dataByte
{
    return [self formatDataByte:dataByte usingOption:[[NSUserDefaults standardUserDefaults] integerForKey:F53MIDIDataFormatPreferenceKey]];
}

+ (NSString *) formatDataByte: (Byte) dataByte usingOption: (F53MIDIDataFormattingOption) option
{
    switch (option) {
        case F53MIDIDataFormatDecimal:
        default:
            return [NSString stringWithFormat:@"%d", dataByte];

        case F53MIDIDataFormatHexadecimal:
            return [NSString stringWithFormat:@"$%02X", dataByte];
    }
}

+ (NSString *) formatSignedDataByte1: (Byte) dataByte1 byte2: (Byte) dataByte2
{
    return [self formatSignedDataByte1:dataByte1 byte2:dataByte2 usingOption:[[NSUserDefaults standardUserDefaults] integerForKey:F53MIDIDataFormatPreferenceKey]];
}

+ (NSString *) formatSignedDataByte1: (Byte) dataByte1 byte2: (Byte) dataByte2 usingOption: (F53MIDIDataFormattingOption) option
{
    // Combine two 7-bit values into one 14-bit value. Treat the result as signed, if displaying as decimal; 0x2000 is the center.
    int value;

    value = (int)dataByte1 + (((int)dataByte2) << 7);

    switch (option) {
        case F53MIDIDataFormatDecimal:
        default:
            return [NSString stringWithFormat:@"%d", value - 0x2000];

        case F53MIDIDataFormatHexadecimal:
            return [NSString stringWithFormat:@"$%04X", value];
    }
}

+ (NSString *) formatLength: (unsigned int) length
{
    return [self formatLength:length usingOption:[[NSUserDefaults standardUserDefaults] integerForKey:F53MIDIDataFormatPreferenceKey]];
}

+ (NSString *) formatLength: (unsigned int) length usingOption: (F53MIDIDataFormattingOption) option
{
    switch (option) {
        case F53MIDIDataFormatDecimal:
        default:
            return [NSString stringWithFormat:@"%u", length];

        case F53MIDIDataFormatHexadecimal:
            return [NSString stringWithFormat:@"$%X", length];
    }
}

+ (NSString *) nameForManufacturerIdentifier: (NSData *) manufacturerIdentifierData
{
    static NSDictionary *manufacturerNames = nil;
    NSString *identifierString, *name;

    F53Assert(manufacturerIdentifierData != nil);
    F53Assert([manufacturerIdentifierData length] >= 1);
    F53Assert([manufacturerIdentifierData length] <= 3);
    
    if (!manufacturerNames) {
        NSString *path;
        
        path = [F53BundleForObject(self) pathForResource:@"ManufacturerNames" ofType:@"plist"];
        if (path) {        
            manufacturerNames = [NSDictionary dictionaryWithContentsOfFile:path];
            if (!manufacturerNames)
                NSLog(@"Couldn't read ManufacturerNames.plist!");
        } else {
            NSLog(@"Couldn't find ManufacturerNames.plist!");
        }
        
        if (!manufacturerNames)
            manufacturerNames = [NSDictionary dictionary];
        [manufacturerNames retain];
    }

    identifierString = [manufacturerIdentifierData F53_lowercaseHexString];
    if ((name = [manufacturerNames objectForKey:identifierString]))
        return name;
    else
        return NSLocalizedStringFromTableInBundle(@"Unknown Manufacturer", @"F53MIDI", F53BundleForObject(self), "unknown manufacturer name");
}

+ (NSString *) formatTimeStamp: (MIDITimeStamp) aTimeStamp
{
    return [self formatTimeStamp:aTimeStamp usingOption:[[NSUserDefaults standardUserDefaults] integerForKey:F53MIDITimeFormatPreferenceKey]];
}

+ (NSString *) formatTimeStamp: (MIDITimeStamp) aTimeStamp usingOption: (F53MIDITimeFormattingOption) option
{
    switch (option) {
        case F53MIDITimeFormatHostTimeInteger:
        {
            // We have 2^64 possible values, which comes out to 1.8e19. So we need at most 20 digits. (Add one for the trailing \0.)
            char buf[21];
            
            snprintf(buf, sizeof(buf), "%llu", aTimeStamp);
            return [NSString stringWithCString:buf encoding:NSASCIIStringEncoding];
        }

        case F53MIDITimeFormatHostTimeHexInteger:
        {
            // 64 bits at 4 bits/character = 16 characters max. (Add one for the trailing \0.)
            char buf[17];
            
            snprintf(buf, sizeof(buf), "%016llX", aTimeStamp);
            return [NSString stringWithCString:buf encoding:NSASCIIStringEncoding];
        }

        case F53MIDITimeFormatHostTimeNanoseconds:
        {
            char buf[21];
            
            snprintf(buf, 21, "%llu", F53MIDIConvertHostTimeToNanos(aTimeStamp));
            return [NSString stringWithCString:buf encoding:NSASCIIStringEncoding];
        }

        case F53MIDITimeFormatHostTimeSeconds:
            return [NSString stringWithFormat:@"%.3lf", F53MIDIConvertHostTimeToNanos(aTimeStamp) / 1.0e9];

        case F53MIDITimeFormatClockTime:
        default:
        {
            if (aTimeStamp == 0) {
                return NSLocalizedStringFromTableInBundle(@"*** ZERO ***", @"F53MIDI", F53BundleForObject(self), "zero timestamp formatted as clock time");
            } else {
                NSTimeInterval timeStampInterval;
                NSDate *date;
                    
                timeStampInterval = F53MIDIConvertHostTimeToNanos(aTimeStamp - _startHostTime) / 1.0e9;
                date = [NSDate dateWithTimeIntervalSinceReferenceDate:(_startTimeInterval + timeStampInterval)];
                return [_timeStampDateFormatter stringForObjectValue:date];
            }
        }
    }
}

- (id) init
{
    // Use the designated initializer instead
    F53RejectUnusedImplementation(self, _cmd);
    return nil;
}

///
///  Designated initializer.
///
- (id) initWithTimeStamp: (MIDITimeStamp) aTimeStamp statusByte: (Byte) aStatusByte
{
    if (!(self = [super init]))
        return nil;

    _timeStamp = aTimeStamp;
    _statusByte = aStatusByte;
        
    return self;
}

- (void) dealloc
{
    [_originatingEndpoint release];
    [super dealloc];
}

- (id) copyWithZone: (NSZone *) zone
{
    F53MIDIMessage *newMessage;
    
    newMessage = [[[self class] allocWithZone:zone] initWithTimeStamp:_timeStamp statusByte:_statusByte];
    [newMessage setOriginatingEndpoint:_originatingEndpoint];
    return newMessage;
}

- (void) setTimeStamp: (MIDITimeStamp) newTimeStamp
{
    _timeStamp = newTimeStamp;
}

- (void) setTimeStampToNow
{
    [self setTimeStamp:F53MIDIGetCurrentHostTime()];
}

- (MIDITimeStamp) timeStamp
{
    return _timeStamp;
}

///
///  First MIDI byte.
///
- (Byte) statusByte
{
    return _statusByte;
}

///
///  Enumerated message type, which doesn't correspond to MIDI value.
///  Must be implemented by subclasses.
///
- (F53MIDIMessageType) messageType
{
    F53RejectUnusedImplementation(self, _cmd);
    return F53MIDIMessageTypeUnknown;
}

- (BOOL) matchesMessageTypeMask: (F53MIDIMessageType) mask
{
    return ([self messageType] & mask) ? YES : NO;
}

///
///  Length of data after the status byte.
///  Subclasses must override if they have other data.
///
- (unsigned int) otherDataLength
{
    return 0;
}

///
///  May return NULL, indicating no additional data.
///  Subclasses must override if they have other data.
///
- (const Byte *) otherDataBuffer
{
    return NULL;
}

///
///  May return nil, indicating no additional data.
///
- (NSData *) otherData
{
    unsigned int length;

    if ((length = [self otherDataLength]))
        return [NSData dataWithBytes:[self otherDataBuffer] length:length];
    else
        return nil;
}

- (void) setOriginatingEndpoint: (F53MIDIEndpoint *) value
{
    if (_originatingEndpoint != value) {
        [_originatingEndpoint release];
        _originatingEndpoint = [value retain];
    }
}

- (F53MIDIEndpoint *) originatingEndpoint
{
    return _originatingEndpoint;
}

#pragma mark -
#pragma mark Display methods

- (NSString *) timeStampForDisplay
{
    return [F53MIDIMessage formatTimeStamp:_timeStamp];
}

- (NSString *) channelForDisplay
{
    return @"";
}

- (NSString *) typeForDisplay
{
    return [NSString stringWithFormat:@"%@ ($%02X)", NSLocalizedStringFromTableInBundle(@"Unknown", @"F53MIDI", F53BundleForObject(self), "displayed type of unknown MIDI status byte"), [self statusByte]];
}

- (NSString *) dataForDisplay
{
    return [F53MIDIMessage formatData:[self otherData]];
}

@end