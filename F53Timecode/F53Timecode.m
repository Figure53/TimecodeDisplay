/**
 
  @author Sean Dougall
  @file F53Timecode.m
  @date Created on May 16, 2008.
 
  Copyright (c) 2008-2011 Figure 53 LLC, http://figure53.com
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
 
**/

#import "F53Timecode.h"


@implementation F53Timecode

#pragma mark housekeeping & accessors

- (NSString *) description
{
    return [self stringRepresentationWithBitsAndFramerate];
}

- (id)init 
{
    if (self = [super init])
    {
        _framerate = F53Framerate2997nd;
        _hh = _mm = _ss = _ff = _bits = 0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    F53Timecode *newTC = [F53Timecode new];
    [newTC setFramerate:_framerate];
    [newTC setHH:_hh];
    [newTC setMM:_mm];
    [newTC setSS:_ss];
    [newTC setFF:_ff];
    [newTC setBits:_bits];
    return newTC;
}

- (NSUInteger) hash
{
    return _bits + 80 * (_ff + 30 * (_ss + 60 * (_mm + 60 * (_hh + 24 * (_framerate.fps + 30 * (_framerate.dropFrame ? (_framerate.videoSpeed ? 0 : 1) : (_framerate.videoSpeed ? 2 : 3)))))));
}

- (BOOL) isEqual: (id) otherObject
{
    if (![otherObject isKindOfClass:[F53Timecode class]])
        return NO;
    
    if ([otherObject hash] != [self hash])
        return NO;
    
    return YES;
}

// +timecodeWithFramerate:hh:mm:ss:ff:
// convenience method for new F53Timecode object with all digits in place
// does not retain return value
+ (F53Timecode *)timecodeWithFramerate:(F53Framerate)newFramerate hh:(int)newHH mm:(int)newMM ss:(int)newSS ff:(int)newFF
{
    F53Timecode *result = [F53Timecode new];
    [result setFramerate:newFramerate];
    [result setHH:newHH];
    [result setMM:newMM];
    [result setSS:newSS];
    [result setFF:newFF];
    return [result autorelease];
}

// +timecodeWithFramerate:hh:mm:ss:ff:bits:
// convenience method for new F53Timecode object with all digits in place
// does not retain return value
+ (F53Timecode *)timecodeWithFramerate:(F53Framerate)newFramerate hh:(int)newHH mm:(int)newMM ss:(int)newSS ff:(int)newFF bits:(int)newBits
{
    F53Timecode *result = [F53Timecode new];
    [result setFramerate:newFramerate];
    [result setHH:newHH];
    [result setMM:newMM];
    [result setSS:newSS];
    [result setFF:newFF];
    [result setBits:newBits];
    return [result autorelease];
}

// +timecodeWithFramerate:newStringRep
// convenience method for enw F53Timecode object with digits from string
// leading zeros optional; any non-numeric digit treated as separator
// does not retain return value
+ (F53Timecode *)timecodeWithFramerate:(F53Framerate)newFramerate fromStringRepresentation:(NSString *)newStringRep
{
    F53Timecode *result = [F53Timecode new];
    [result setFramerate:newFramerate];
    [result setStringRepresentation:newStringRep];
    return [result autorelease];
}

// +framerateWithFPS:videoSpeed:dropFrame:
// useful for inline F53Framerate declarations
// return value is a struct; nothing dynamically allocated
+ (F53Framerate)framerateWithFPS:(unsigned int)newFPS videoSpeed:(BOOL)newVideoSpeed dropFrame:(BOOL)newDropFrame
{
    F53Framerate result;
    result.fps = newFPS;
    result.videoSpeed = newVideoSpeed;
    result.dropFrame = (newFPS == 30 ? newDropFrame : NO);
    return result;
}

+ (F53Framerate) framerateForIndex: (NSInteger) index
{
    // Note: This order must remain unchanged. More options can potentially be added in the future, but
    // these existing values need to stay as they are.
    switch (index)
    {
        case 0: return F53Framerate23976;
        case 1: return F53Framerate24;
        case 2: return F53Framerate24975;
        case 3: return F53Framerate25;
        case 4: return F53Framerate2997nd;
        case 5: return F53Framerate2997df;
        case 6: return F53Framerate30nd;
        case 7: return F53Framerate30df;
    }
    return F53Framerate2997nd;
}

+ (F53Timecode *)invalidTimecode 
{
    F53Timecode *result = [F53Timecode new];
    [result setFramerate:F53FramerateInvalid];
    return result;
}

// single-component accessors
// setters "rebalance" digits to maintain validity
- (unsigned int)hh { return _hh; }
- (void)setHH:(unsigned int)newHH { 
    @synchronized(self)
    {
        _hh = newHH; 
        [self rebalance]; 
    }
}
- (unsigned int)mm { return _mm; }
- (void)setMM:(unsigned int)newMM { 
    @synchronized(self)
    {
        _mm = newMM; 
        [self rebalance]; 
    }
}
- (unsigned int)ss { return _ss; }
- (void)setSS:(unsigned int)newSS { 
    @synchronized(self)
    {
        _ss = newSS; 
        [self rebalance]; 
    }
}
- (unsigned int)ff { return _ff; }
- (void)setFF:(unsigned int)newFF {
    @synchronized(self)
    {
        _ff = newFF; 
        [self rebalance]; 
    }
}
- (unsigned int)bits { return _bits; }
- (void)setBits:(unsigned int)newBits { _bits = newBits; [self rebalance]; }
- (F53Framerate)framerate { return _framerate; }
- (void)setFramerate:(F53Framerate)newFramerate { 
    @synchronized(self)
    {
        _framerate = newFramerate; 
        [self rebalance]; 
    }
}    // doesn't recalculate; just copies over digits and rebalances

// timing management

// -convertFramerateTo:
// changes framerate, recalculating timing from 0:00:00:00
- (void)convertFramerateTo:(F53Framerate)targetFramerate
{
    @synchronized(self)
    {
        double timeFromZero = [self secondsFromZero];
        _framerate = targetFramerate;
        [self setSecondsFromZero:timeFromZero];
    }
}

// -convertFramerateFromReelStartTo:
// changes framerate, recalculating timing from hh:00:00:00
- (void)convertFramerateFromReelStartTo:(F53Framerate)targetFramerate
{
    // reset hours to 0 ...
    int tempHH = _hh;
    _hh = 0;
    
    // convert 0:xx:xx:xx/xx ...
    double timeFromReelStart = [self secondsFromZero];
    _framerate = targetFramerate;
    [self setSecondsFromZero:timeFromReelStart];
    
    // and restore hours
    _hh = tempHH;
}

// -rebalance
// makes sure all digits are in valid ranges (e.g. 1:61:xx:xx -> 2:01:xx:xx)
- (void)rebalance
{
    if (_framerate.fps <= 1) return;
    while (_bits < 0) { 
        _bits += 80; 
        _ff--; 
    }            
    while (_bits >= 80) { 
        _bits -= 80; 
        _ff++; 
    }
    while (_ff < 0) { _ff += _framerate.fps; _ss--; }    while (_ff >= _framerate.fps) { _ff -= _framerate.fps; _ss++; }
    while (_ss < 0) { _ss += 60; _mm--; }                while (_ss >= 60) { _ss -= 60; _mm++; }
    while (_mm < 0) { _mm += 60; _hh--; }                while (_mm >= 60) { _mm -= 60; _hh++; }
    
    if ((_framerate.dropFrame) && (_framerate.fps == 30) && (_ff < 2) && (_ss == 0) && (_mm%10 > 0)) _ff+=2;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
//    [super encodeWithCoder:coder];
    [coder encodeInt:_hh forKey:@"F53TimecodeHH"];
    [coder encodeInt:_mm forKey:@"F53TimecodeMM"];
    [coder encodeInt:_ss forKey:@"F53TimecodeSS"];
    [coder encodeInt:_ff forKey:@"F53TimecodeFF"];
    [coder encodeInt:_bits forKey:@"F53TimecodeBits"];
    [coder encodeInt:_framerate.fps forKey:@"F53TimecodeFramerate.fps"];
    [coder encodeBool:_framerate.videoSpeed forKey:@"F53TimecodeFramerate.videoSpeed"];
    [coder encodeBool:_framerate.dropFrame forKey:@"F53TimecodeFramerate.dropFrame"];
}

- (id)initWithCoder:(NSCoder *)coder {
//    self = [super initWithCoder:coder];
    self = [super init];
    _hh = [coder decodeIntForKey:@"F53TimecodeHH"];
    _mm = [coder decodeIntForKey:@"F53TimecodeMM"];
    _ss = [coder decodeIntForKey:@"F53TimecodeSS"];
    _ff = [coder decodeIntForKey:@"F53TimecodeFF"];
    _bits = [coder decodeIntForKey:@"F53TimecodeBits"];
    _framerate.fps = [coder decodeIntForKey:@"F53TimecodeFramerate.fps"];
    _framerate.videoSpeed = [coder decodeBoolForKey:@"F53TimecodeFramerate.videoSpeed"];
    _framerate.dropFrame = [coder decodeBoolForKey:@"F53TimecodeFramerate.dropFrame"];
    return self;
}

#pragma mark string representations

- (NSString *)stringRepresentation
{
    return [NSString stringWithFormat:@"%d:%02d:%02d%@%02d",
                                      _hh,
                                      _mm,
                                      _ss,
                                      (_framerate.dropFrame ? @";" : @":"),
                                      _ff];
}

- (NSString *)stringRepresentationWithBits
{
    return [NSString stringWithFormat:@"%d:%02d:%02d%@%02d/%02d",
            _hh,
            _mm,
            _ss,
            (_framerate.dropFrame ? @";" : @":"),
            _ff,
            _bits];
}

- (NSString *)stringRepresentationWithBitsAndFramerate
{
    NSString *framerateString;
    switch(_framerate.fps) {
        case 24:
            framerateString = _framerate.videoSpeed ? @"23.976 fps" : @"24fps";
            break;
        case 25:
            framerateString = _framerate.videoSpeed ? @"24.975 fps" : @"25fps";
            break;
        case 30:
            framerateString = _framerate.videoSpeed ? _framerate.dropFrame ? @"29.97df" : @"29.97nd" : _framerate.dropFrame ? @"30df" : @"30fps";
            break;
        default:
            framerateString = @"[invalid]";
    }
    return [NSString stringWithFormat:@"%d:%02d:%02d%@%02d/%02d@%@",
            _hh,
            _mm,
            _ss,
            (_framerate.dropFrame ? @";" : @":"),
            _ff,
            _bits,
            framerateString];
}

// -setStringRepresentation:
// parses string to get digits into existing F53Timecode
- (void)setStringRepresentation:(NSString *)newStringRep
{
    NSScanner *s = [NSScanner scannerWithString:newStringRep];
    [s setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]]; if ([s isAtEnd]) return;
    
    _hh = _mm = _ss = _ff = _bits = 0;
    
    if (![s scanInt:&_hh]) _hh = 0;
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    [s setScanLocation:[s scanLocation]+1]; 
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    if (![s scanInt:&_mm]) _mm = 0; 
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    [s setScanLocation:[s scanLocation]+1]; 
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    if (![s scanInt:&_ss]) _ss = 0; 
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    [s setScanLocation:[s scanLocation]+1]; 
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    if (![s scanInt:&_ff]) _ff = 0;
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    [s setScanLocation:[s scanLocation]+1]; 
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    if (![s scanInt:&_bits]) _bits = 0;
    if ([s isAtEnd]) { [self rebalance]; return; }
    
    [self rebalance];
}

#pragma mark timing calculations

- (SInt64)framesFromZero
{
    SInt64 result = _ff + _framerate.fps * (_ss + 60 * (_mm + 60 * _hh));
    if ((_framerate.dropFrame) && (_framerate.fps == 30))
        return result - 2 * (result / 1800) + 2 * (result / 18000);    // do dropframe math if necessary
    return _negative ? -result : result;
}

- (double)secondsFromZero
{
    double result = [self framesFromZero] + [self bits]/80.;
    result /= _framerate.fps;
    if (_framerate.videoSpeed) result *= 1.001;
    return result;
}

- (void)setFramesFromZero:(SInt64)newFrames
{
    if (newFrames < 0)
    {
        _negative = YES;
        newFrames = -newFrames;
    }
    else
        _negative = NO;
    
    if ((_framerate.dropFrame) && (_framerate.fps == 30)) 
        newFrames = newFrames + 2 * ((newFrames - 2 - 2 * (newFrames-2) / 17982) / 1798) - 2 * newFrames / 17982;    //do dropframe math if necessary
    if (_framerate.fps == 0) return;
    _ff = newFrames % _framerate.fps;    newFrames /= _framerate.fps;
    _ss = newFrames % 60;                newFrames /= 60;
    _mm = newFrames % 60;                newFrames /= 60;
    _hh = newFrames;
    [self rebalance];
}

- (void)setSecondsFromZero:(double)newSeconds
{
    double frames = newSeconds * _framerate.fps / (_framerate.videoSpeed ? 1.001 : 1.);
    SInt64 intFrames = (SInt64)frames;
    [self setFramesFromZero:intFrames];
    [self setBits:80*(frames-intFrames)];
}

- (SInt64)framesFromTimecode:(F53Timecode *)otherTimecode
{
    return [self framesFromZero] - [otherTimecode framesFromZero];
}


- (double)secondsFromTimecode:(F53Timecode *)otherTimecode
{
    return [self secondsFromZero] - [otherTimecode secondsFromZero];
}

- (void)setFrames:(SInt64)newFrames fromTimecode:(F53Timecode *)otherTimecode
{
    [self setFramesFromZero:[otherTimecode framesFromZero] + newFrames];
    [self setBits:[otherTimecode bits]];
}

- (void)setSeconds:(double)newSeconds fromTimecode:(F53Timecode *)otherTimecode
{
    [self setSecondsFromZero:[otherTimecode secondsFromZero] + newSeconds];
}

- (NSComparisonResult) compare: (F53Timecode *) otherTimecode
{
    double selfSecondsFromZero = [self secondsFromZero];
    double otherSecondsFromZero = [otherTimecode secondsFromZero];
    if (selfSecondsFromZero > otherSecondsFromZero)
        return NSOrderedDescending;
    if (selfSecondsFromZero < otherSecondsFromZero)
        return NSOrderedAscending;
    return NSOrderedSame;
}

#pragma mark timecode math

- (void)addFrames:(SInt64)numFrames {
    [self setFramesFromZero:[self framesFromZero]+numFrames];
}

- (void)subtractFrames:(SInt64)numFrames {
    [self setFramesFromZero:[self framesFromZero]-numFrames];
}

- (void)addSeconds:(double)seconds {
    [self setSecondsFromZero:[self secondsFromZero] + seconds];
}

- (void)subtractSeconds:(double)seconds {
    [self setSecondsFromZero:[self secondsFromZero] - seconds];
}

@end
