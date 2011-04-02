/**

 @author Sean Dougall
 @file F53Timecode.h
 @date Created on May 16, 2008. Last modified December 22, 2010.
 @brief NOTE: This is a 10.4 version, modified to remove Objective-C 2.0 entities such as @property.
 
  Copyright 2008-2011 Figure 53, LLC.

**/

#import <Foundation/Foundation.h>
#define F53TimecodeGlobalFramerateDidChangeNotification @"F53TimecodeGlobalFramerateDidChangeNotification"
#define kInvalidTimecodeString @"-:--:--"

//! Struct representing framerate
/*!
 
 */
typedef struct {
	unsigned int	fps;			/**< Base frames per second -- i.e., the number of frames per timecode "second". 24, 25, or 30, but extensible to others if necessary **/
	BOOL			videoSpeed;		/**< Pulls timecode down to video speed -- if true, 24 -> 23.976; 25 -> 24.975; 30 -> 29.97 **/
	BOOL			dropFrame;		/**< Specifies dropframe counting system; ignored if fps != 30 **/
} F53Framerate;

//! Shorthand for framerate of 23.976 frames per second
#define	F53Framerate23976	[F53Timecode framerateWithFPS:24 videoSpeed:YES dropFrame:NO]
//! Shorthand for framerate of 24 frames per second
#define	F53Framerate24		[F53Timecode framerateWithFPS:24 videoSpeed:NO dropFrame:NO]
//! Shorthand for framerate of 24.975 frames per second
#define	F53Framerate24975	[F53Timecode framerateWithFPS:25 videoSpeed:YES dropFrame:NO]
//! Shorthand for framerate of 25 frames per second
#define	F53Framerate25		[F53Timecode framerateWithFPS:25 videoSpeed:NO dropFrame:NO]
//! Shorthand for framerate of 29.97 frames per second, non-drop
#define	F53Framerate2997nd	[F53Timecode framerateWithFPS:30 videoSpeed:YES dropFrame:NO]
//! Shorthand for framerate of 29.97 frames per second, drop frame
#define	F53Framerate2997df	[F53Timecode framerateWithFPS:30 videoSpeed:YES dropFrame:YES]
//! Shorthand for framerate of 30 frames per second, non-drop
#define	F53Framerate30nd		[F53Timecode framerateWithFPS:30 videoSpeed:NO dropFrame:NO]
//! Shorthand for framerate of 30 frames per second, drop frame
#define	F53Framerate30df		[F53Timecode framerateWithFPS:30 videoSpeed:NO dropFrame:YES]
//! Shorthand for invalid framerate marker
#define F53FramerateInvalid	[F53Timecode framerateWithFPS:1  videoSpeed:NO dropFrame:NO]

//! Timecode object
/*!
 F53Timecode provides functionality for timecode math, conversion to and from real time, and 
 several variants of string representations. Also implements the NSCoding protocol,
 so F53Timecode objects may be serialized and stored.
 
 F53Timecode objects are mutable. Any changes to the timing represented by the timecode will automatically
 trigger a "rebalance", adjusting so that hours range from 0 to 23, minutes from 0 to 59, seconds from 
 0 to 59, and frames within the range permitted by the framerate. This rebalance also takes care of any
 dropframe math that may need to take place.
 
 The advantages of F53Timecode over CoreAudio's SMPTETime struct are in its object-oriented design, which 
 allows for the rebalancing described above as well as object serialization and easier timecode math. 
 For situations where SMPTETime is needed but math, string parsing, or serialization is useful, the 
 F53TimecodeCoreAudioExt category extends F53Timecode to provide conversion to/from SMPTETime structs.
 */
@interface F53Timecode : NSObject <NSCoding, NSCopying> {
	int             _hh;
	int             _mm;
	int             _ss;
	int             _ff;
	int             _bits;
	F53Framerate	_framerate;
	BOOL            _negative;
}

/*!
 \return Basic string representation, in the form @"1:02:24:15". The final colon is replaced by a semicolon if the receiver's framerate's dropFrame flag is true.
 Note: Bits are truncated, not rounded.
 \sa stringRepresentationWithBits
 \sa stringRepresentationWithBitsAndFramerate
 \sa setStringRepresentation:
 \sa timecodeWithFramerate:fromStringRepresentation:
 */
- (NSString *)stringRepresentation;

/*!
 \return String representation in the form @"1:02:24:15/64"
 \sa stringRepresentation
 \sa stringRepresentationWithBitsAndFramerate
 \sa setStringRepresentation:
 \sa timecodeWithFramerate:fromStringRepresentation:
 */
- (NSString *)stringRepresentationWithBits;

/*!
 \return String representation in the form @"1:02:24:15/64@29.97nd"
 \sa stringRepresentation
 \sa stringRepresentationWithBits
 \sa setStringRepresentation:
 \sa timecodeWithFramerate:fromStringRepresentation:
 */
- (NSString *)stringRepresentationWithBitsAndFramerate;

/*!
 \param newStringRep The string rep
 
 Sets timecode to the value represented by the given string. Parses however many components are 
 provided, starting with hours, and separated by any non-numeric character. Two consecutive separator
 characters are treated as though placed around a zero. For example, @"1.2..15" is parsed
 into a timecode representing 1:02:00:15.

 Note: A valid framerate must be set before this method is called.
 
 \sa stringRepresentation
 \sa stringRepresentationWithBits
 \sa setStringRepresentation:
 \sa timecodeWithFramerate:fromStringRepresentation:
 */
- (void)setStringRepresentation:(NSString *)newStringRep;


/*!
 \param newFramerate
 \param hh
 \param mm
 \param ss
 \param ff
 \return An autoreleased timecode object.
 
 Convenience method for creating a new timecode object. Bits are set to zero, and all other fields are rebalanced.
 
 \sa timecodeWithFramerate:hh:mm:ss:ff:bits:
 \sa timecodeWithFramerate:fromStringRepresentation:
 */
+ (F53Timecode *)timecodeWithFramerate:(F53Framerate)newFramerate hh:(int)newHH mm:(int)newMM ss:(int)newSS ff:(int)newFF;

/*!
 \param newFramerate
 \param hh
 \param mm
 \param ss
 \param ff
 \param bits
 \return An autoreleased timecode object.
 
 Convenience method for creating a new timecode object. All fields are rebalanced.
 
 \sa timecodeWithFramerate:hh:mm:ss:ff:
 \sa timecodeWithFramerate:fromStringRepresentation:
 */
+ (F53Timecode *)timecodeWithFramerate:(F53Framerate)newFramerate hh:(int)newHH mm:(int)newMM ss:(int)newSS ff:(int)newFF bits:(int)newBits;

/*!
 \param newFramerate
 \param hh
 \param mm
 \param ss
 \param ff
 \return An autoreleased timecode object.
 
 Convenience method for creating a new timecode object from a string representation. This method is rather more
 expensive than timecodeWithFramerate:hh:mm:ss:ff:, but is obviously the quickest way to get a timecode from a string.
 
 For a description of how strings are parsed, see setStringRepresentation:.
 
 \sa setStringRepresentation:
 \sa timecodeWithFramerate:hh:mm:ss:ff:bits:
 \sa timecodeWithFramerate:fromStringRepresentation:
 */
+ (F53Timecode *)timecodeWithFramerate:(F53Framerate)newFramerate fromStringRepresentation:(NSString *)newStringRep;

/*!
 \param newFPS
 \param newVideoSpeed
 \param newDropFrame
 
 One-liner convenience method for creating F53Framerate structs. See F53Framerate for a description of the
 struct's members.
 */
+ (F53Framerate)framerateWithFPS:(unsigned int)newFPS videoSpeed:(BOOL)newVideoSpeed dropFrame:(BOOL)newDropFrame;

/*!
 \param index
 
 Look up a framerate based on a preset global list of options.
 */
+ (F53Framerate) framerateForIndex: (NSInteger) index;

/*!
 \return A timecode object containing a framerate of F53FramerateInvalid.
 
 This does not return a singleton, and should not be used to determine the validity of another timecode object.
 */
+ (F53Timecode *)invalidTimecode;



/*!
 \return The receiver's framerate.
 \sa setFramerate:
 \sa convertFramerateTo:
 \sa convertFramerateFromReelStartTo:
 */
- (F53Framerate)framerate;

/*!
 \param newFramerate The new framerate to set.

 Simply resets the framerate and rebalances. In most cases, the hours, minutes, seconds, and frames members will
 be unaffected (unless they are out of range of the new framerate and get rebalanced). For example, 
 1:01:00:23 @ 29.97nd will become approximately 1:01:00:23 @ 24fps. For methods that do more sophisticated conversions, see
 convertFramerateTo: and convertFramerateFromReelStartTo:.
 
 \sa framerate
 \sa convertFramerateTo:
 \sa convertFramerateFromReelStartTo:
 */
- (void)setFramerate:(F53Framerate)newFramerate;				// doesn't recalculate; just copies over digits and rebalances

/*!
 \param newFramerate The new framerate to set.
 
 Recalculates the timecode, preserving the number of seconds from 0:00:00:00. For example, 
 1:01:00:23 @ 29.97nd will become approximately 1:01:04:11 @ 24fps (as both represent 3,664.43 seconds from 0:00:00:00 in real time).
 
 If you are converting from video speed to film speed or vice versa, and need to treat timecode seconds equally,
 you can use setFramerate: to set the framerate (without recalcluating) to pull the value up or down, then use
 this method to do the conversion. For example:
 <div><code>// Reverse telecine<br/>
	F53Timecode *tc = [F53Timecode timecodeWithFramerate:F53Framerate2997nd hh:1 mm:1 ss:0 ff:23]; // 1:01:00:23 @ 29.97nd<br/>
	[tc setFramerate:F53Framerate30]; // -> 1:01:00:23 @ 30nd<br/>
	[tc convertFramerateTo:F53Framerate24]; // -> ca. 1:01:00:29 @ 24
 </code></div>
 
 \sa framerate
 \sa convertFramerateTo:
 \sa convertFramerateFromReelStartTo:
 */
- (void)convertFramerateTo:(F53Framerate)targetFramerate;	// recalculates timing from 0:00:00:00

/*!
 \param newFramerate The new framerate to set.
 
 Recalculates the timecode, preserving the number of seconds from the most recent reel/act/hour start. For example, 
 1:01:00:23 @ 29.97nd will become approximately 1:01:00:20 @ 24fps (as both represent 60.82 seconds from 1:00:00:00 in real time).
 
 Note: This method and convertFramerateTo: will have the same effect in many cases. The differences will arise when
 pulling up or down (e.g. converting from 24 to 29.97) and when converting between drop frame and non-drop.
 
 \sa framerate
 \sa setFramerate:
 \sa convertFramerateTo:
 */
- (void)convertFramerateFromReelStartTo:(F53Framerate)targetFramerate;	// recalculates timing from hh:00:00:00

/*!
 Called by all timing-related methods. You should not need to call this method directly.
 */
- (void)rebalance;



//! \return The number of frames, at the current framerate, between 0:00:00:00 and the receiver.
- (SInt64)framesFromZero;
//! \return The number of seconds between 0:00:00:00 and the receiver.
- (double)secondsFromZero;
//! \param newFrames The number of frames, at the current framerate, between 0:00:00:00 and the receiver.
- (void)setFramesFromZero:(SInt64)newFrames;
//! \param newSeconds The number of seconds between 0:00:00:00 and the receiver.
- (void)setSecondsFromZero:(double)newSeconds;
/*! 
 \param otherTimecode The other timecode to compare against
 \return The number of frames, at the current framerate, between otherTimecode and the receiver.
 
 Note: It is up to the calling method to ensure that both timecodes are at the same framerate. The results
 will be incorrect if they are not.
 */
- (SInt64)framesFromTimecode:(F53Timecode *)otherTimecode;

//! \param otherTimecode The other timecode to compare against
//! \return The number of seconds between otherTimecode and the receiver.
- (double)secondsFromTimecode:(F53Timecode *)otherTimecode;

/*!
 \param newFrames The number of frames to be added to otherTimecode and assigned to the receiver
 \param otherTimecode The other timecode to add newFrames to and assign to the receiver
 
 Note: It is up to the calling method to ensure that both timecodes are at the same framerate. The results
 will be incorrect if they are not.
 */
- (void)setFrames:(SInt64)newFrames fromTimecode:(F53Timecode *)otherTimecode;

/*!
 \param newSeconds The number of seconds to be added to otherTimecode and assigned to the receiver
 \param otherTimecode The other timecode to add newSeconds to and assign to the receiver
 */
- (void)setSeconds:(double)newSeconds fromTimecode:(F53Timecode *)otherTimecode;



//! \param numFrames The number of frames to be added to the receiver
- (void)addFrames:(SInt64)numFrames;
//! \param numFrames The number of frames to be subtracted from the receiver
- (void)subtractFrames:(SInt64)numFrames;
//! \param seconds The number of seconds to be added to the receiver
- (void)addSeconds:(double)seconds;
//! \param seconds The number of seconds to be subtracted from the receiver
- (void)subtractSeconds:(double)seconds;

- (NSComparisonResult) compare: (F53Timecode *) otherTimecode;

- (unsigned int) hh;
- (void) setHH: (unsigned int) newHH;
- (unsigned int) mm;
- (void) setMM: (unsigned int) newMM;
- (unsigned int) ss;
- (void) setSS: (unsigned int) newSS;
- (unsigned int) ff;
- (void) setFF: (unsigned int) newFF;
- (unsigned int) bits;
- (void) setBits:(unsigned int) newBits;

@end
