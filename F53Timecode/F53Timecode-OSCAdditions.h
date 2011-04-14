//
//  F53Timecode-OSCAdditions.h
//  Video Server
//
//  Created by Sean Dougall on 2/16/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "F53Timecode.h"

@interface F53Timecode (OSCAdditions)

- (UInt32) intValueForOSC;
+ (F53Timecode *) timecodeWithIntValueForOSC: (UInt32) intValue;

@end
