/**

 @author  Kurt Revis
 @file    F53MIDIClient.m

 Copyright (c) 2002-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#import "F53MIDIClient.h"
#import "F53MIDIObject.h"

@interface F53MIDIClient (Private)

- (NSString *) processName;

static void getMIDINotification(const MIDINotification *message, void *refCon);

- (void) midiSetupChanged;
- (void) midiObjectAddedOrRemoved: (const MIDIObjectAddRemoveNotification *) message;
- (void) midiObjectPropertyChanged: (const MIDIObjectPropertyChangeNotification *) message;
- (void) midiThruConnectionsChanged: (const MIDINotification *) message;
- (void) serialPortOwnerChanged: (const MIDINotification *) message;
- (void) broadcastUnknownMIDINotification: (const MIDINotification *) message;
- (void) broadcastGenericMIDINotification: (const MIDINotification *) message withName: (NSString *) notificationName;

@end

@implementation F53MIDIClient (Private)

- (NSString *) processName;
{
    NSString *processName;
    
    processName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    if (!processName)
        processName = [[NSProcessInfo processInfo] processName];
    
    return processName;
}

static void getMIDINotification(const MIDINotification *message, void *refCon)
{
    F53MIDIClient *client = (F53MIDIClient *)refCon;
    
    switch (message->messageID) {
        case kMIDIMsgSetupChanged:    // The only notification in 10.1 and earlier
#if DEBUG
            NSLog(@"setup changed");
#endif
            [client midiSetupChanged];
            break;
            
        case kMIDIMsgObjectAdded:    // Added in 10.2
#if DEBUG
            NSLog(@"object added");
#endif
            [client midiObjectAddedOrRemoved:(const MIDIObjectAddRemoveNotification *)message];
            break;
            
        case kMIDIMsgObjectRemoved:    // Added in 10.2
#if DEBUG
            NSLog(@"object removed");
#endif
            [client midiObjectAddedOrRemoved:(const MIDIObjectAddRemoveNotification *)message];
            break;
            
        case kMIDIMsgPropertyChanged:    // Added in 10.2
#if DEBUG
            NSLog(@"property changed");
#endif
            [client midiObjectPropertyChanged:(const MIDIObjectPropertyChangeNotification *)message];
            break;
            
        case kMIDIMsgThruConnectionsChanged:    // Added in 10.2
#if DEBUG
            NSLog(@"thru connections changed");
#endif
            [client midiThruConnectionsChanged:message];
            break;
            
        case kMIDIMsgSerialPortOwnerChanged:    // Added in 10.2
#if DEBUG
            NSLog(@"serial port owner changed");
#endif
            [client serialPortOwnerChanged:message];
            break;
            
        default:
#if DEBUG
            NSLog(@"unknown notification: %d", message->messageID);
#endif
            [client broadcastUnknownMIDINotification:message];
            break;
    }
}

- (void) midiSetupChanged
{
    // Unfortunately, CoreMIDI in 10.1.x and earlier has a bug: CoreMIDI calls will run the thread's run loop
    // in its default mode (instead of a special private mode). Since CoreMIDI also delivers notifications when
    // this mode runs, we can get notifications inside any CoreMIDI call that we make. It may even deliver another
    // notification while we are in the middle of reacting to the first one!
    //
    // So this method needs to be reentrant. If someone calls us while we are processing, just remember that fact,
    // and call ourself again after we're done.  (If we get multiple notifications while we're processing, they
    // will be coalesced into one update at the end.)
    //
    // Fortunately the bug has been fixed in 10.2. This code isn't really expensive, so it doesn't hurt to leave it in.
    
    static BOOL retryAfterDone = NO;
    
    if (_isHandlingSetupChange) {
        retryAfterDone = YES;
        return;
    }
    
    do {
        _isHandlingSetupChange = YES;
        retryAfterDone = NO;
        
        // Notify the objects internal to this framework about the change first, 
        // and then let other objects know about it.
        [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIClientSetupChangedInternalNotification object:self];
        if (_postsExternalSetupChangeNotification)
            [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIClientSetupChangedNotification object:self];
        
        _isHandlingSetupChange = NO;
    } while (retryAfterDone);
}

- (void) midiObjectAddedOrRemoved: (const MIDIObjectAddRemoveNotification *) message
{
    NSString *notificationName;
    NSDictionary *userInfo;
    
    if (message->messageID == kMIDIMsgObjectAdded)
        notificationName = F53MIDIClientObjectAddedNotification;
    else
        notificationName = F53MIDIClientObjectRemovedNotification;
    
    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSValue valueWithPointer:message->parent], F53MIDIClientObjectAddedOrRemovedParent,
        [NSNumber numberWithInt:message->parentType], F53MIDIClientObjectAddedOrRemovedParentType,
        [NSValue valueWithPointer:message->child], F53MIDIClientObjectAddedOrRemovedChild,
        [NSNumber numberWithInt:message->childType], F53MIDIClientObjectAddedOrRemovedChildType,
        nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];    
}

- (void) midiObjectPropertyChanged: (const MIDIObjectPropertyChangeNotification *) message
{
    NSDictionary *userInfo;
    
    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSValue valueWithPointer:message->object], F53MIDIClientObjectPropertyChangedObject,
                [NSNumber numberWithInt:message->objectType], F53MIDIClientObjectPropertyChangedType,
                (NSString *)message->propertyName, F53MIDIClientObjectPropertyChangedName,
                nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIClientObjectPropertyChangedNotification object:self userInfo:userInfo];    
}

- (void) midiThruConnectionsChanged: (const MIDINotification *) message
{
    [self broadcastGenericMIDINotification:message withName:F53MIDIClientThruConnectionsChangedNotification];
}

- (void) serialPortOwnerChanged: (const MIDINotification *) message
{
    [self broadcastGenericMIDINotification:message withName:F53MIDIClientSerialPortOwnerChangedNotification];
}

- (void) broadcastUnknownMIDINotification: (const MIDINotification *) message
{
    [self broadcastGenericMIDINotification:message withName:F53MIDIClientMIDINotification];
}

- (void) broadcastGenericMIDINotification: (const MIDINotification *) message withName: (NSString *) notificationName
{
    NSDictionary *userInfo;
    
    userInfo = [NSDictionary dictionaryWithObject:[NSValue valueWithPointer:message] forKey:F53MIDIClientMIDINotificationStruct];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
}

@end


@implementation F53MIDIClient

NSString *F53MIDIClientCreatedInternalNotification = @"F53MIDIClientCreatedInternalNotification";
NSString *F53MIDIClientSetupChangedInternalNotification = @"F53MIDIClientSetupChangedInternalNotification";
NSString *F53MIDIClientSetupChangedNotification = @"F53MIDIClientSetupChangedNotification";
NSString *F53MIDIClientObjectAddedNotification = @"F53MIDIClientObjectAddedNotification";
NSString *F53MIDIClientObjectAddedOrRemovedParent = @"F53MIDIClientObjectAddedOrRemovedParent";
NSString *F53MIDIClientObjectAddedOrRemovedParentType = @"F53MIDIClientObjectAddedOrRemovedParentType";
NSString *F53MIDIClientObjectAddedOrRemovedChild = @"F53MIDIClientObjectAddedOrRemovedChild";
NSString *F53MIDIClientObjectAddedOrRemovedChildType = @"F53MIDIClientObjectAddedOrRemovedChildType";
NSString *F53MIDIClientObjectRemovedNotification = @"F53MIDIClientObjectRemovedNotification";
NSString *F53MIDIClientObjectPropertyChangedNotification = @"F53MIDIClientObjectPropertyChangedNotification";
NSString *F53MIDIClientObjectPropertyChangedObject = @"F53MIDIClientObjectPropertyChangedObject";
NSString *F53MIDIClientObjectPropertyChangedType = @"F53MIDIClientObjectPropertyChangedType";
NSString *F53MIDIClientObjectPropertyChangedName = @"F53MIDIClientObjectPropertyChangedName";
NSString *F53MIDIClientMIDINotification = @"F53MIDIClientMIDINotification";
NSString *F53MIDIClientMIDINotificationStruct = @"F53MIDIClientMIDINotificationStruct";
NSString *F53MIDIClientThruConnectionsChangedNotification =  @"F53MIDIClientThruConnectionsChangedNotification";
NSString *F53MIDIClientSerialPortOwnerChangedNotification = @"F53MIDIClientSerialPortOwnerChangedNotification";

static F53MIDIClient *_sharedClient = nil;

+ (F53MIDIClient *) sharedClient
{
    @synchronized(self) {
        if (!_sharedClient) {
            _sharedClient = [[self alloc] init];
            
            // make sure F53MIDIObject is listening for the notification below
            [F53MIDIObject class];   // provokes +[F53MIDIObject initialize] if necessary
            
            if (_sharedClient)
                [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIClientCreatedInternalNotification object:_sharedClient];
        }
    }
    
    return _sharedClient;
}

- (id) init
{
    OSStatus status;
    
    if (!(self = [super init]))
        return nil;
    
    // Don't let anyone create more than one client.
    if (_sharedClient) {
        [self release];
        return nil;
    }
    
    _name = [[self processName] retain];
    _postsExternalSetupChangeNotification = YES;
    _isHandlingSetupChange = NO;
    _coreMIDIFrameworkBundle = CFBundleGetBundleWithIdentifier(CFSTR("com.apple.audio.midi.CoreMIDI"));
    _coreMIDIPropertyNameDictionary = [[NSMutableDictionary alloc] init];
    
    status = MIDIClientCreate((CFStringRef)_name, getMIDINotification, self, &_midiClient);
    if (status != noErr) {
        NSLog(@"Couldn't create a MIDI client (error %ld)", status);
        [self release];
        return nil;
    }
    
    return self;
}

- (void) dealloc
{
    if (_midiClient) MIDIClientDispose(_midiClient);
    
    [_name release];
    _name = nil;
    [_coreMIDIPropertyNameDictionary release];
    _coreMIDIPropertyNameDictionary = nil;
    
    [super dealloc];
}

- (MIDIClientRef) midiClient
{
    return _midiClient;
}

- (NSString *) name
{
    return _name;
}

- (void) setPostsExternalSetupChangeNotification: (BOOL) value
{
    _postsExternalSetupChangeNotification = value;
}

- (BOOL) postsExternalSetupChangeNotification
{
    return _postsExternalSetupChangeNotification;
}

- (BOOL) isHandlingSetupChange
{
    return _isHandlingSetupChange;    
}

- (CFStringRef) coreMIDIPropertyNameConstantNamed: (NSString *) constantName
{
    // This method is used to look up CoreMIDI property names which may or may not exist.
    // (For example, kMIDIPropertyImage, which is present in 10.2 but not 10.1.)
    // If we used the value kMIDIPropertyImage directly, we could no longer run on 10.1 since dyld
    // would be unable to find that symbol. So we look it up at runtime instead.
    // We keep these values cached in a dictionary so we don't do a lot of potentially slow lookups
    // through CFBundle.
    
    id coreMIDIPropertyNameConstant;
    
    // Look for this name in the cache
    coreMIDIPropertyNameConstant = [_coreMIDIPropertyNameDictionary objectForKey:constantName];
    
    if (!coreMIDIPropertyNameConstant) {
        // Try looking up a symbol with this name in the CoreMIDI bundle.
        if (_coreMIDIFrameworkBundle) {
            CFStringRef *propertyNamePtr;
            
            propertyNamePtr = CFBundleGetDataPointerForName(_coreMIDIFrameworkBundle, (CFStringRef)constantName);
            if (propertyNamePtr)
                coreMIDIPropertyNameConstant = *(id *)propertyNamePtr;
        }
        
        // If we didn't find it, put an NSNull in the dict instead (so we don't try again to look it up later)
        if (!coreMIDIPropertyNameConstant)
            coreMIDIPropertyNameConstant = [NSNull null];
        [_coreMIDIPropertyNameDictionary setObject:coreMIDIPropertyNameConstant forKey:_name];
    }
    
    if (coreMIDIPropertyNameConstant == [NSNull null])
        return NULL;
    else
        return (CFStringRef)coreMIDIPropertyNameConstant;
}

- (UInt32) coreMIDIFrameworkVersion
{
    if (_coreMIDIFrameworkBundle)
        return CFBundleGetVersionNumber(_coreMIDIFrameworkBundle);
    else
        return 0;
}

// NOTE: CoreMIDI.framework has CFBundleVersion "20" as of 10.2. This translates to 0x20008000.
const UInt32 kCoreMIDIFrameworkVersionIn10_2 = 0x20008000;
// CFBundleVersion is "26" as of 10.3 (WWDC build 7A179), which is 0x26008000.
const UInt32 kCoreMIDIFrameworkVersionIn10_3 = 0x26008000;    // TODO find out what this in in 10.3 GM

- (BOOL) postsObjectAddedAndRemovedNotifications
{
    // CoreMIDI in 10.2 posts specific notifications when objects are added and removed.
    return [self coreMIDIFrameworkVersion] >= kCoreMIDIFrameworkVersionIn10_2;
}

- (BOOL) postsObjectPropertyChangedNotifications
{
    // CoreMIDI in 10.2 posts a specific notification when an object's property changes.
    return [self coreMIDIFrameworkVersion] >= kCoreMIDIFrameworkVersionIn10_2;
}

- (BOOL) coreMIDIUsesWrongRunLoop
{
    // Under 10.1 CoreMIDI calls can run the thread's run loop in the default run loop mode,
    // which causes no end of mischief.  Fortunately this was fixed in 10.2 to use a private mode.
    return [self coreMIDIFrameworkVersion] < kCoreMIDIFrameworkVersionIn10_2;    
}

- (BOOL) coreMIDICanFindObjectByUniqueID
{
    return [self coreMIDIFrameworkVersion] >= kCoreMIDIFrameworkVersionIn10_2;        
}

- (BOOL) coreMIDICanGetDeviceFromEntity
{
    return [self coreMIDIFrameworkVersion] >= kCoreMIDIFrameworkVersionIn10_2;        
}

- (BOOL) doesSendSysExRespectExternalDeviceSpeed
{
    return [self coreMIDIFrameworkVersion] >= kCoreMIDIFrameworkVersionIn10_3;
}

@end
