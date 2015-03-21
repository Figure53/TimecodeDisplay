//
//  Timecode_DisplayAppDelegate.h
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

#import <Cocoa/Cocoa.h>

@class MIDIReceiver;

@interface Timecode_DisplayAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow *_displayWindow;
    NSTextField *_timecodeDisplay;
    NSPanel *_logWindow;
    NSTextView *_eventLog;
    NSString *_eventLogContent;
    MIDIReceiver *_midiReceiver;
    float _fontSize;
    NSTimeInterval _lastFlaggedLoopbackTime;    ///< Keep track of when we were last flagged as receiving multiple sources or a loopback.
    NSTimer *_loopbackExpireTimer;
    NSDateFormatter *_logDateFormatter;
}

@property (assign) IBOutlet NSWindow *displayWindow;
@property (assign) IBOutlet NSTextField *timecodeDisplay;
@property (assign) IBOutlet NSPanel *logWindow;
@property (assign) IBOutlet NSTextView *eventLog;
@property (readonly) NSDateFormatter *logDateFormatter;

- (IBAction) showTimecodeDisplayWindow:(id)sender;
- (IBAction) showEventLogWindow:(id)sender;
- (IBAction) clearLog:(id)sender;

- (void) setTimecodeString:(NSString *)newString;
- (void) setFramerateString:(NSString *)newString;
- (void) flagLoopback;
- (void) appendLogEntry:(NSString *)entry;

@end
