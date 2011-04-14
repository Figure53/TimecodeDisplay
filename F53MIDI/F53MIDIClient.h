/**

 @author  Kurt Revis
 @file    F53MIDIClient.h

 Copyright (c) 2002-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#import <Cocoa/Cocoa.h>
#import <CoreMIDI/CoreMIDI.h>


@interface F53MIDIClient : NSObject 
{
    MIDIClientRef        _midiClient;
    NSString            *_name;
    
    BOOL                 _postsExternalSetupChangeNotification;
    BOOL                 _isHandlingSetupChange;
    
    CFBundleRef          _coreMIDIFrameworkBundle;
    NSMutableDictionary *_coreMIDIPropertyNameDictionary;
}

+ (F53MIDIClient *) sharedClient;

- (MIDIClientRef) midiClient;
- (NSString *) name;

- (void) setPostsExternalSetupChangeNotification: (BOOL) value;
- (BOOL) postsExternalSetupChangeNotification;

- (BOOL) isHandlingSetupChange;

- (CFStringRef) coreMIDIPropertyNameConstantNamed: (NSString *) name;
- (UInt32) coreMIDIFrameworkVersion;

- (BOOL) postsObjectAddedAndRemovedNotifications;
- (BOOL) postsObjectPropertyChangedNotifications;
- (BOOL) coreMIDIUsesWrongRunLoop;
- (BOOL) coreMIDICanFindObjectByUniqueID;
- (BOOL) coreMIDICanGetDeviceFromEntity;
- (BOOL) doesSendSysExRespectExternalDeviceSpeed;

@end

// Notifications

extern NSString *F53MIDIClientCreatedInternalNotification;          // Sent when the client is created. Meant only for use by F53MIDI classes. No userInfo.

// Notifications sent as a result of CoreMIDI notifications

// The default "something changed" kMIDIMsgSetupChanged notification from CoreMIDI:
extern NSString *F53MIDIClientSetupChangedInternalNotification;     // Meant only for use by F53MIDI classes. No userInfo.
extern NSString *F53MIDIClientSetupChangedNotification;             // No userInfo

// An object was added:
extern NSString *F53MIDIClientObjectAddedNotification;              // userInfo contains:
                                                                    //   F53MIDIClientObjectAddedOrRemovedParent        NSValue (MIDIObjectRef as pointer)
                                                                    //   F53MIDIClientObjectAddedOrRemovedParentType    NSNumber (MIDIObjectType as SInt32)
                                                                    //   F53MIDIClientObjectAddedOrRemovedChild        NSValue (MIDIObjectRef as pointer)
                                                                    //   F53MIDIClientObjectAddedOrRemovedChildType    NSNumber (MIDIObjectType as SInt32)
extern NSString *F53MIDIClientObjectAddedOrRemovedParent;
extern NSString *F53MIDIClientObjectAddedOrRemovedParentType;
extern NSString *F53MIDIClientObjectAddedOrRemovedChild;
extern NSString *F53MIDIClientObjectAddedOrRemovedChildType;

// An object was removed:
extern NSString *F53MIDIClientObjectRemovedNotification;            // userInfo is the same as for F53MIDIClientObjectAddedNotification above

// A property of an object changed:
extern NSString *F53MIDIClientObjectPropertyChangedNotification;    // userInfo contains:
                                                                    //   F53MIDIClientObjectPropertyChangedObject    NSValue (MIDIObjectRef as pointer)
                                                                    //   F53MIDIClientObjectPropertyChangedType        NSNumber (MIDIObjectType as SInt32)
                                                                    //   F53MIDIClientObjectPropertyChangedName        NSString
extern NSString *F53MIDIClientObjectPropertyChangedObject;
extern NSString *F53MIDIClientObjectPropertyChangedType;
extern NSString *F53MIDIClientObjectPropertyChangedName;

// A MIDI Thru connection changed:
extern NSString *F53MIDIClientThruConnectionsChangedNotification;    // userInfo is same as for F53MIDIClientMIDINotification (above).

// An owner of a serial port changed:
extern NSString *F53MIDIClientSerialPortOwnerChangedNotification;    // userInfo is same as for F53MIDIClientMIDINotification (above).

// Sent for unknown notifications from CoreMIDI:
extern NSString *F53MIDIClientMIDINotification;                      // userInfo contains these keys and values:
                                                                     //   F53MIDIClientMIDINotificationStruct    NSValue (a pointer to a struct MIDINotification)
extern NSString *F53MIDIClientMIDINotificationStruct;
