/**

 @author  Kurt Revis
 @file    F53MIDIMessageParser.m

 Copyright (c) 2001-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/


#import "F53MIDIMessageParser.h"

#import "F53MIDIMessage.h"
#import "F53MIDIVoiceMessage.h"
#import "F53MIDISystemCommonMessage.h"
#import "F53MIDISystemRealTimeMessage.h"
#import "F53MIDISystemExclusiveMessage.h"
#import "F53MIDIInvalidMessage.h"


@interface F53MIDIMessageParser (Private)

- (NSArray *) messagesForPacket: (const MIDIPacket *) packet;

- (F53MIDISystemExclusiveMessage *) finishSysExMessageWithValidEnd: (BOOL) isEndValid;
- (void) sysExTimedOut;

@end


@implementation F53MIDIMessageParser

- (id) init
{
    if (!(self = [super init]))
        return nil;

    _readingSysExLock = [[NSLock alloc] init];
    _sysExTimeOut = 1.0;    // seconds
    _ignoreInvalidData = NO;

    return self;
}

- (void) dealloc
{
    [_readingSysExData release];
    _readingSysExData = nil;
    [_readingSysExLock release];
    _readingSysExLock = nil;
    [_sysExTimeOutTimer release];
    _sysExTimeOutTimer = nil;
    
    [super dealloc];
}

- (void) setDelegate: (id) value
{
    _nonretainedDelegate = value;
}

- (id) delegate
{
    return _nonretainedDelegate;
}

- (void) setOriginatingEndpoint: (F53MIDIEndpoint *) value
{
    _nonretainedOriginatingEndpoint = value;
}

- (F53MIDIEndpoint *) originatingEndpoint
{
    return _nonretainedOriginatingEndpoint;
}

- (void) setSysExTimeOut: (NSTimeInterval) value
{
    _sysExTimeOut = value;
}

- (NSTimeInterval) sysExTimeOut
{
    return _sysExTimeOut;
}

- (void) setIgnoresInvalidData: (BOOL) value
{
    _ignoreInvalidData = value;
}

- (BOOL) ignoresInvalidData
{
    return _ignoreInvalidData;
}

- (void) takePacketList: (const MIDIPacketList *) packetList
{
    // NOTE: This function is called in our MIDI processing thread.
    // (This is NOT the MIDI receive thread which CoreMIDI creates for us.)
    // All downstream processing will also be done in this thread, until someone jumps it into another.
    
    // CHANGED BY CA: This function is now called on the main thread.

    NSMutableArray *messages = nil;
    unsigned int packetCount;
    const MIDIPacket *packet;
    
    packetCount = packetList->numPackets;
    packet = packetList->packet;
    while (packetCount--) {
        NSArray *messagesForPacket;

        messagesForPacket = [self messagesForPacket:packet];
        if (messagesForPacket) {
            if (!messages)
                messages = [NSMutableArray arrayWithArray:messagesForPacket];
            else
                [messages addObjectsFromArray:messagesForPacket];
        }

        packet = MIDIPacketNext(packet);
    }

    if (messages)
        [_nonretainedDelegate parser:self didReadMessages:messages];
    
    if (_readingSysExData) {
        if (!_sysExTimeOutTimer) {
            // Create a timer which will fire after we have received no sysex data for a while.
            // This takes care of interruption in the data (devices being turned off or unplugged) as well as
            // ill-behaved devices which don't terminate their sysex messages with 0xF7.
            NSRunLoop *runLoop;
            NSString *mode;

            runLoop = [NSRunLoop currentRunLoop];
            mode = [runLoop currentMode];
            if (mode) {
                _sysExTimeOutTimer = [[NSTimer timerWithTimeInterval:_sysExTimeOut target:self selector:@selector(sysExTimedOut) userInfo:nil repeats:NO] retain];
                [runLoop addTimer:_sysExTimeOutTimer forMode:mode];
            } else {
#if DEBUG
                NSLog(@"F53MIDIMessageParser trying to add timer but the run loop has no mode--giving up");
#endif
            }
        } else {
            // We already have a timer, so just bump its fire date forward.
            // Use CoreFoundation because this function is available back to 10.1 (and probably 10.0) whereas
            // the corresponding NSTimer method only became available in 10.2.
            CFRunLoopTimerSetNextFireDate((CFRunLoopTimerRef)_sysExTimeOutTimer, CFAbsoluteTimeGetCurrent() + _sysExTimeOut);
        }
    } else {
        // Not reading sysex, so if we have a timeout pending, forget about it
        if (_sysExTimeOutTimer) {
            [_sysExTimeOutTimer invalidate];
            [_sysExTimeOutTimer release];
            _sysExTimeOutTimer = nil;
        }        
    }
}

///
///  @return YES if it successfully cancels a sysex message which is being received, and NO otherwise.
///
- (BOOL) cancelReceivingSysExMessage
{
    BOOL cancelled = NO;

    [_readingSysExLock lock];

    if (_readingSysExData) {
        [_readingSysExData release];
        _readingSysExData = nil;
        cancelled = YES;
    }

    [_readingSysExLock unlock];

    return cancelled;
}

@end


@implementation F53MIDIMessageParser (Private)

- (NSArray *) messagesForPacket: (const MIDIPacket *) packet
{
    // Split this packet into separate MIDI messages    
    NSMutableArray *messages = nil;
    const Byte *data;
    UInt16 length;
    Byte byte;
    Byte pendingMessageStatus;
    Byte pendingData[2];
    UInt16 pendingDataIndex, pendingDataLength;
    NSMutableData* readingInvalidData = nil;
    
    pendingMessageStatus = 0;
    pendingDataIndex = pendingDataLength = 0;

    data = packet->data;
    length = packet->length;
    while (length--) {
        F53MIDIMessage *message = nil;
        BOOL byteIsInvalid = NO;
        
        byte = *data++;
    
        if (byte >= 0xF8) {
            // Real Time message    
            switch (byte) {
                case F53MIDISystemRealTimeMessageTypeClock:
                case F53MIDISystemRealTimeMessageTypeStart:
                case F53MIDISystemRealTimeMessageTypeContinue:
                case F53MIDISystemRealTimeMessageTypeStop:
                case F53MIDISystemRealTimeMessageTypeActiveSense:
                case F53MIDISystemRealTimeMessageTypeReset:
                    message = [F53MIDISystemRealTimeMessage systemRealTimeMessageWithTimeStamp:packet->timeStamp type:byte];
                    break;
        
                default:
                    // Byte is invalid
                    byteIsInvalid = YES;
                    break;
            }
        } else {
            if (byte < 0x80) {
                if (_readingSysExData) {
                    [_readingSysExLock lock];
                    if (_readingSysExData) {
                        unsigned int length;

                        [_readingSysExData appendBytes:&byte length:1];

                        length = 1 + [_readingSysExData length];
                        // Tell the delegate we're still reading, every 256 bytes
                        if (length % 256 == 0)
                            [_nonretainedDelegate parser:self isReadingSysExWithLength:length];
                    }
                    [_readingSysExLock unlock];
                } else if (pendingDataIndex < pendingDataLength) {
                    pendingData[pendingDataIndex] = byte;
                    pendingDataIndex++;

                    if (pendingDataIndex == pendingDataLength) {
                        // This message is now done--send it
                        if (pendingMessageStatus >= 0xF0)
                            message = [F53MIDISystemCommonMessage systemCommonMessageWithTimeStamp:packet->timeStamp type:pendingMessageStatus data:pendingData length:pendingDataLength];
                        else
                            message = [F53MIDIVoiceMessage voiceMessageWithTimeStamp:packet->timeStamp statusByte:pendingMessageStatus data:pendingData length:pendingDataLength];

                        pendingDataLength = 0;
                    }                    
                } else {
                    // Skip this byte -- it is invalid
                    byteIsInvalid = YES;
                }
            } else {
                if (_readingSysExData)
                    message = [self finishSysExMessageWithValidEnd:(byte == 0xF7)];

                pendingMessageStatus = byte;
                pendingDataLength = 0;
                pendingDataIndex = 0;
                
                switch (byte & 0xF0) {            
                    case 0x80:    // Note off
                    case 0x90:    // Note on
                    case 0xA0:    // Aftertouch
                    case 0xB0:    // Controller
                    case 0xE0:    // Pitch wheel
                        pendingDataLength = 2;
                        break;
    
                    case 0xC0:    // Program change
                    case 0xD0:    // Channel pressure
                        pendingDataLength = 1;
                        break;
                    
                    case 0xF0: {
                        // System common message
                        switch (byte) {
                            case 0xF0:
                                // System exclusive
                                _readingSysExData = [[NSMutableData alloc] init];  // This is atomic, so there's no need to lock
                                _startSysExTimeStamp = packet->timeStamp;
                                [_nonretainedDelegate parser:self isReadingSysExWithLength:1];
                                break;
                                
                            case 0xF7:
                                // System exclusive ends--already handled above.
                                // But if this is showing up outside of sysex, it's invalid.
                                if (!message)
                                    byteIsInvalid = YES;
                                break;
                            
                            case F53MIDISystemCommonMessageTypeTimeCodeQuarterFrame:
                            case F53MIDISystemCommonMessageTypeSongSelect:
                                pendingDataLength = 1;
                                break;
    
                            case F53MIDISystemCommonMessageTypeSongPositionPointer:
                                pendingDataLength = 2;
                                break;
    
                            case F53MIDISystemCommonMessageTypeTuneRequest:
                                message = [F53MIDISystemCommonMessage systemCommonMessageWithTimeStamp:packet->timeStamp type:byte data:NULL length:0];
                                break;
                            
                            default:
                                // Invalid message
                                byteIsInvalid = YES;
                                break;
                        }                 
                        break;
                    }
                
                    default:
                        // This can't happen, but handle it anyway
                        byteIsInvalid = YES;
                        break;
                }
            }
        }

        if (!_ignoreInvalidData) {
            if (byteIsInvalid) {
                if (!readingInvalidData)
                    readingInvalidData = [NSMutableData data];
                [readingInvalidData appendBytes:&byte length:1];
            }
    
            if (readingInvalidData && (!byteIsInvalid || length == 0)) {
                // We hit the end of a stretch of invalid data.
                message = [F53MIDIInvalidMessage invalidMessageWithTimeStamp:packet->timeStamp data:readingInvalidData];
                readingInvalidData = nil;
            }
        }
        
        if (message) {
            [message setOriginatingEndpoint:_nonretainedOriginatingEndpoint];
            
            if (!messages)
                messages = [NSMutableArray arrayWithObject:message];
            else
                [messages addObject:message];
        }
    }

    return messages;
}

- (F53MIDISystemExclusiveMessage *) finishSysExMessageWithValidEnd: (BOOL) isEndValid
{
    F53MIDISystemExclusiveMessage *message = nil;

    // NOTE: If we want, we could refuse sysex messages that don't end in 0xF7.
    // The MIDI spec says that messages should end with this byte, but apparently that is not always the case in practice.

    [_readingSysExLock lock];
    if (_readingSysExData) {
        message = [F53MIDISystemExclusiveMessage systemExclusiveMessageWithTimeStamp:_startSysExTimeStamp data:_readingSysExData];
        
        [_readingSysExData release];
        _readingSysExData = nil;
    }
    [_readingSysExLock unlock];

    if (message) {
        [message setOriginatingEndpoint:_nonretainedOriginatingEndpoint];
        [message setWasReceivedWithEOX:isEndValid];
        [_nonretainedDelegate parser:self finishedReadingSysExMessage:message];
    }

    return message;
}

- (void) sysExTimedOut
{
    F53MIDISystemExclusiveMessage *message;

    [_sysExTimeOutTimer release];
    _sysExTimeOutTimer = nil;

    message = [self finishSysExMessageWithValidEnd:NO];
    if (message)
        [_nonretainedDelegate parser:self didReadMessages:[NSArray arrayWithObject:message]];
}

@end
