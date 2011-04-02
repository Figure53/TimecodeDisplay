//
//  F53Timecode-MTCAdditions.m
//  Video Server
//
//  Created by Sean Dougall on 2/21/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "F53Timecode-MTCAdditions.h"


@implementation F53Timecode (MTCAdditions)

+ (F53Framerate) framerateForMTCIndex: (F53MTCFramerateIndex) index
{
    switch (index)
    {
        case kF53MTCFramerateIndex24fps:
            return F53Framerate24;
        case kF53MTCFramerateIndex25fps:
            return F53Framerate25;
        case kF53MTCFramerateIndex30nd:
            return F53Framerate2997nd;
        case kF53MTCFramerateIndex30df:
            return F53Framerate2997df;
    }
    NSLog(@"index %d invalid", index);
    return F53FramerateInvalid;
}

+ (F53Framerate) framerateForMTCIndex: (F53MTCFramerateIndex) index pullDown: (BOOL) pullDown
{
    switch (index)
    {
        case kF53MTCFramerateIndex24fps:
            return pullDown ? F53Framerate23976 : F53Framerate24;
        case kF53MTCFramerateIndex25fps:
            return pullDown ? F53Framerate24975 : F53Framerate25;
        case kF53MTCFramerateIndex30nd:
            return pullDown ? F53Framerate2997nd : F53Framerate30nd;
        case kF53MTCFramerateIndex30df:
            return pullDown ? F53Framerate2997df : F53Framerate30df;
    }
    return F53FramerateInvalid;
}

+ (F53MTCFramerateIndex) mtcIndexForFramerate: (F53Framerate) framerate
{
    switch (framerate.fps)
    {
        case 24: 
            return kF53MTCFramerateIndex24fps;
        case 25:
            return kF53MTCFramerateIndex25fps;
        case 30:
            return framerate.dropFrame ? kF53MTCFramerateIndex30df : kF53MTCFramerateIndex30nd;
    }
    return kF53MTCFramerateIndexInvalid;
}

+ (F53Timecode *) timecodeWithMTCFramerateIndex: (F53MTCFramerateIndex) index
                                             hh: (int) hh
                                             mm: (int) mm
                                             ss: (int) ss
                                             ff: (int) ff
{
    if (index == kF53MTCFramerateIndexInvalid)
        return [F53Timecode invalidTimecode];
    
    return [F53Timecode timecodeWithFramerate:[F53Timecode framerateForIndex:index] hh:hh mm:mm ss:ss ff:ff];
}


- (void) setHighHH: (int) h
{
    _framerate = [F53Timecode framerateForMTCIndex:((h & 0x06) >> 1)];
    _hh = (h & 0x01) << 4 | (_hh & 0x0f);
    [self addFrames:1];
}

- (void) setLowHH: (int) h
{
    _hh = (_hh & 0xf0) | (h & 0x0f);
}

- (void) setHighMM: (int) m
{
    _mm = (m & 0x0f) << 4 | (_mm & 0x0f);
}

- (void) setLowMM: (int) m
{
    _mm = (_mm & 0xf0) | (m & 0x0f);
}

- (void) setHighSS: (int) s
{
    _ss = (s & 0x0f) << 4 | (_ss & 0x0f);
}

- (void) setLowSS: (int) s
{
    _ss = (_ss & 0xf0) | (s & 0x0f);
}

- (void) setHighFF: (int) f
{
    _ff = (f & 0x0f) << 4 | (_ff & 0x0f);
}

- (void) setLowFF: (int) f
{
    [self addFrames:1];
    _ff = (_ff & 0xf0) | (f & 0x0f);
}

@end
