//
//  Timecode_DisplayAppDelegate.h
//  Timecode Display
//
//  Created by Sean Dougall on 3/31/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIDIReceiver;

@interface Timecode_DisplayAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow *_displayWindow;
    NSTextField *_timecodeDisplay;
    MIDIReceiver *_midiReceiver;
    float _fontSize;
}

@property (assign) IBOutlet NSWindow *displayWindow;
@property (assign) IBOutlet NSTextField *timecodeDisplay;

- (void) setTimecodeString: (NSString *) newString;
- (void) setFramerateString: (NSString *) newString;

@end
