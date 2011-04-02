//
//  Timecode_DisplayAppDelegate.m
//  Timecode Display
//
//  Created by Sean Dougall on 3/31/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "Timecode_DisplayAppDelegate.h"
#import "MIDIReceiver.h"


@implementation Timecode_DisplayAppDelegate

@synthesize displayWindow = _displayWindow;
@synthesize timecodeDisplay = _timecodeDisplay;

- (id) init
{
    if (self = [super init])
    {
        _midiReceiver = [MIDIReceiver new];
    }
    return self;
}

- (void) dealloc
{
    [_midiReceiver release];
    _midiReceiver = nil;
    
    [super dealloc];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
    _midiReceiver.online = YES;
}

- (void) setTimecodeString: (NSString *) newString
{
    if (newString == nil)
    {
        NSLog(@"ERROR: App delegate tried to set nil timecode string.");
        return;
    }
    
    [_timecodeDisplay setStringValue:newString];
}

- (void) setFramerateString: (NSString *) newString
{
    if (newString == nil)
    {
        NSLog(@"ERROR: App delegate tried to set nil framerate string.");
        return;
    }
    
    [_displayWindow setTitle:newString];
}

- (void) windowDidResize: (NSNotification *) notification
{
    NSAttributedString *as = [_timecodeDisplay attributedStringValue];
    NSAttributedString *newAS = [[[NSAttributedString alloc] initWithString:@"00:00:00:00" attributes:[as attributesAtIndex:0 effectiveRange:NULL]] autorelease];
    NSSize stringSize = [newAS size];
    NSSize boundsSize = _displayWindow.frame.size;
    boundsSize.width -= 10;
    boundsSize.height -= 20;
    
    NSFont *displayFont = [_timecodeDisplay font];
    _fontSize = [displayFont pointSize];
    
    if (stringSize.width / stringSize.height > boundsSize.width / boundsSize.height)
    {
        _fontSize *= boundsSize.width / stringSize.width;
    }
    else
    {
        _fontSize *= boundsSize.height / stringSize.height;
    }
    
    [_timecodeDisplay setFont:[NSFont fontWithName:[displayFont fontName] size:_fontSize]];
    
    // Center vertically
    float newHeight = [[_timecodeDisplay attributedStringValue] size].height;
    float windowHeight = _displayWindow.frame.size.height;
    NSRect frameRect = _timecodeDisplay.frame;
    frameRect.origin.y = MAX((windowHeight - newHeight - 30), 0) * 0.6;
    frameRect.size.height = newHeight;
    [_timecodeDisplay setFrame:frameRect];
}



@end
