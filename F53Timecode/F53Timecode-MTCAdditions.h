//
//  F53Timecode-MTCAdditions.h
//
//  Created by Sean Dougall on 2/21/11.
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
