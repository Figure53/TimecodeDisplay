//
//  MIDIReceiver.h
//  Timecode Display
//
//  Created by Sean Dougall on 3/31/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SnoizeMIDI/SnoizeMIDI.h>

@interface MIDIReceiver : NSObject <SMMessageDestination>
{
    BOOL _online;
    SMPortInputStream *_portInputStream;
    unsigned _h;
    unsigned _m;
    unsigned _s;
    unsigned _f;
    int _tcMode;
}

@property (assign) BOOL online;

@end
