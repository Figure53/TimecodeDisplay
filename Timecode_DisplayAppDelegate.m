//
//  Timecode_DisplayAppDelegate.m
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
