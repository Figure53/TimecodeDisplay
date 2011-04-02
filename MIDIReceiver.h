//
//  MIDIReceiver.h
//  Timecode Display
//
//  Created by Sean Dougall on 3/31/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "F53MIDI.h"

@interface MIDIReceiver : NSObject <F53MIDIMessageDestination>
{
    BOOL _online;
    F53MIDIPortInputStream *_portInputStream;
    unsigned _h;
    unsigned _m;
    unsigned _s;
    unsigned _f;
    int _tcMode;
}

@property (assign) BOOL online;

@end
