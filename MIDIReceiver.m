//
//  MIDIReceiver.m
//  Timecode Display
//
//  Created by Sean Dougall on 3/31/11.
//
//  Copyright (c) 2011 Figure 53 LLC, http://figure53.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MIDIReceiver.h"
#import "F53Timecode.h"
#import "F53Timecode-MTCAdditions.h"
#import "Timecode_DisplayAppDelegate.h"


@interface MIDIReceiver (Private)

- (void) setHighHH: (int) h;
- (void) setLowHH: (int) h;
- (void) setHighMM: (int) m;
- (void) setLowMM: (int) m;
- (void) setHighSS: (int) s;
- (void) setLowSS: (int) s;
- (void) setHighFF: (int) f;
- (void) setLowFF: (int) f;

- (void) refreshMIDIInputs: (NSNotification *) note;
- (void) sysexReceived: (UInt8 *) sysexData length: (UInt32) length;
- (void) updateTimecodeDisplay;

@end



@implementation MIDIReceiver

- (BOOL) online
{
    return _online;
}

- (void) setOnline: (BOOL) newValue
{
    _online = newValue;
    if (_online)
    {
        // Start (or restart) listening to all ports.
        [_portInputStream setEndpoints:[NSSet setWithArray:[SMSourceEndpoint sourceEndpoints]]];
        [_portInputStream setMessageDestination:self];
    }
    else
    {
        [_portInputStream setEndpoints:[NSSet set]];
    }
}

- (id) init
{
    if (self = [super init])
    {
        _portInputStream = [SMPortInputStream new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshMIDIInputs:)
                                                     name:@"SMClientSetupChangedNotification" 
                                                   object:nil];
    }
    return self;
}

- (void) dealloc
{
    [_portInputStream release];
    _portInputStream = nil;
    
    [super dealloc];
}


- (void) takeMIDIMessages: (NSArray *) messages
{
    if (!_online) return;
    
    int data1;
    int quarterFrame;
	NSData *data;
    for (SMMessage *msg in messages)
	{
		switch ([msg messageType])
		{
			case SMMessageTypeSystemExclusive:
				data = [(SMSystemExclusiveMessage *)msg fullMessageData];
				[self sysexReceived:(UInt8 *)[data bytes] length:[data length]];
				break;
			case SMMessageTypeTimeCode:
				if (!_online) break;
				data1 = [(SMSystemCommonMessage *)msg dataByte1];
                if ([[[NSUserDefaultsController sharedUserDefaultsController] defaults] integerForKey:@"debugMTC"] > 0)
                    NSLog(@"MTC in %02x", data1);
                quarterFrame = data1 >> 4;
                if ( ( 8 + quarterFrame - _lastReceivedQuarterFrame ) % 8 != 1
                    && [NSDate timeIntervalSinceReferenceDate] - _timeLastQuarterFrameReceived < 0.1
                    && )
                {
                    [(Timecode_DisplayAppDelegate *)[NSApp delegate] setFramerateString:@"Multiple sources/loopback"];
                    _tcMode = -1;
                }
                else
                {
                    [_lastReceivedEndpoint release];
                    _lastReceivedEndpoint = [[msg originatingEndpointForDisplay] copy];
                }
				switch(quarterFrame) {
					case 0: [self setLowFF:data1]; break;
					case 1: [self setHighFF:data1]; break;
					case 2: [self setLowSS:data1]; break;
					case 3: [self setHighSS:data1]; break;
					case 4: [self setLowMM:data1]; break;
					case 5: [self setHighMM:data1]; break;
					case 6: [self setLowHH:data1]; break;
					case 7: [self setHighHH:data1]; break;
				}
                _lastReceivedQuarterFrame = quarterFrame;
                _timeLastQuarterFrameReceived = [NSDate timeIntervalSinceReferenceDate];
				break;
			default:
				break;
		}
	}
}

@end


@implementation MIDIReceiver (Private)

- (void) updateTimecodeDisplay
{
    F53Timecode *tc = [F53Timecode timecodeWithFramerate:[F53Timecode framerateForMTCIndex:_tcMode] hh:_h mm:_m ss:_s ff:_f];
    NSString *newTCString = [tc stringRepresentation];
    [(Timecode_DisplayAppDelegate *)[NSApp delegate] setTimecodeString:newTCString];
    
    static int lastTCMode = -1;
    if (lastTCMode != _tcMode)
    {
        lastTCMode = _tcMode;
        NSString *framerateString = @"";
        switch (_tcMode)
        {
            case 0:
                framerateString = @"24 fps";
                break;
            case 1:
                framerateString = @"25 fps";
                break;
            case 2:
                framerateString = @"30 (29.97) drop-frame";
                break;
            case 3:
                framerateString = @"30 (29.97) non-drop";
                break;
            default:
                framerateString = @"Unknown framerate";
                break;
        }
        if ( _tcMode >= 0 )
            [(Timecode_DisplayAppDelegate *)[NSApp delegate] setFramerateString:[framerateString stringByAppendingFormat:@" [%@]", _lastReceivedEndpoint]];
    }
}

- (void) setHighHH: (int) h
{
	_h = (_h & 0x0F) | ((h & 0x01) << 4); 
	_tcMode = ((h & 0x06) >> 1);
    _f++;
	
    [self updateTimecodeDisplay];
}

- (void) setLowHH: (int) h
{
    _h = (_h & 0xF0) | (h & 0x0F);
}

- (void) setHighMM: (int) m
{
    _m = (_m & 0x0F) | ((m & 0x0F) << 4);
}

- (void) setLowMM: (int) m
{
    _m = (_m & 0xF0) | (m & 0x0F); 
}

- (void) setHighSS: (int) s 
{ 
	_s = (_s & 0x0F) | ((s & 0x0F) << 4); 
	if (_s == 0 && _f == 0) _m++;	// Because of the way MTC is structured, the minutes place won't be updated on the frame where it changes over. Dumb? Yes. But this fixes it.
    [self updateTimecodeDisplay];
}

- (void) setLowSS: (int) s
{
    _s = (_s & 0xF0) | (s & 0x0F);
}

- (void) setHighFF: (int) f 
{
    _f = (_f & 0x0F) | ((f & 0x0F) << 4);
}

- (void) setLowFF: (int) f
{
    _f = (_f & 0xF0) | (f & 0x0F);
}


- (void) sysexReceived: (UInt8 *) sysexData length: (UInt32) length
{
	// Check for MTC full frames first
	if ((length == 10) && (_online))
	{
		if ( (sysexData[1] == 0x7f)
            && (sysexData[3] == 0x01)
            && (sysexData[4] == 0x01) )
		{
			_h = ((sysexData[5] & 0x1f)); 
			_tcMode = ((sysexData[5] & 0x60) >> 5);
			_m = sysexData[6];
			_s = sysexData[7];
			_f = sysexData[8];
			
			[self updateTimecodeDisplay];
			return;
		}
	}
    // Check for MMC Goto messages next
    else if ((length == 13) && (_online))
    {
		if ( (sysexData[1] == 0x7f)
            && (sysexData[2] == 0x7f)   // TODO: respond to individual device ID as well as all-call
            && (sysexData[3] == 0x06)
            && (sysexData[4] == 0x44) 
            && (sysexData[5] == 0x06)
            && (sysexData[6] == 0x01) 
            )
		{
 			_h = ((sysexData[7] & 0x1f)); 
			_tcMode = ((sysexData[7] & 0x60) >> 5);
			_m = sysexData[8];
			_s = sysexData[9];
			_f = sysexData[10];
			
			[self updateTimecodeDisplay];
			return;
        }
    }
}

- (void) refreshMIDIInputs: (NSNotification *) note
{
    self.online = YES;
}

@end
