//
//  F53Timecode-MTCAdditions.h
//  Video Server
//
//  Created by Sean Dougall on 2/21/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "F53Timecode.h"


typedef enum 
{ 
    kF53MTCFramerateIndex24fps = 0,
    kF53MTCFramerateIndex25fps = 1,
    kF53MTCFramerateIndex30df = 2,
    kF53MTCFramerateIndex30nd = 3,
    kF53MTCFramerateIndexInvalid = -1
} F53MTCFramerateIndex;


@interface F53Timecode (MTCAdditions)

+ (F53Framerate) framerateForMTCIndex: (F53MTCFramerateIndex) index;
+ (F53Framerate) framerateForMTCIndex: (F53MTCFramerateIndex) index pullDown: (BOOL) pullDown;
+ (F53MTCFramerateIndex) mtcIndexForFramerate: (F53Framerate) framerate;

+ (F53Timecode *) timecodeWithMTCFramerateIndex: (F53MTCFramerateIndex) index
                                             hh: (int) hh
                                             mm: (int) mm
                                             ss: (int) ss
                                             ff: (int) ff;

- (void) setHighHH: (int) h;
- (void) setLowHH: (int) h;
- (void) setHighMM: (int) m;
- (void) setLowMM: (int) m;
- (void) setHighSS: (int) s;
- (void) setLowSS: (int) s;
- (void) setHighFF: (int) f;
- (void) setLowFF: (int) f;

@end
