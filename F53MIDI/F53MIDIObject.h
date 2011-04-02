/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIObject.h
@date    Created on Thursday March 9 2006.
@brief   Base class for devices, entities, and endpoints.

Copyright (c) 2001-2004, Kurt Revis.  All rights reserved.
Copyright (c) 2006 Christopher Ashworth. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

**/

#ifndef __F53MIDIOBJECT_H__
#define __F53MIDIOBJECT_H__

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreMIDI/CoreMIDI.h>

@interface F53MIDIObject : NSObject
{
    MIDIObjectRef _objectRef;
    MIDIUniqueID _uniqueID;		///< An integer which uniquely identifies a MIDIObjectRef (devices, entities, or endpoints).
    unsigned int _ordinal;
	
	NSString	*_cachedName;
	
    struct {
        unsigned int hasCachedName:1;
    } _flags;    
}

// Class methods:

+ (MIDIObjectType) midiObjectType;
+ (ItemCount) midiObjectCount;
+ (MIDIObjectRef) midiObjectAtIndex: (ItemCount) index;

+ (NSArray *) allObjects;
+ (NSArray *) allObjectsInOrder;
+ (F53MIDIObject *) objectWithUniqueID: (MIDIUniqueID) aUniqueID;
+ (F53MIDIObject *) objectWithName: (NSString *) aName;
+ (F53MIDIObject *) objectWithObjectRef: (MIDIObjectRef) anObjectRef;

+ (MIDIUniqueID) generateNewUniqueID;

// Instance methods:

- (id) initWithObjectRef: (MIDIObjectRef) anObjectRef ordinal: (unsigned int) anOrdinal;
- (MIDIObjectRef) objectRef;

- (BOOL) setUniqueID: (MIDIUniqueID) value;
- (MIDIUniqueID) uniqueID;

- (void) setOrdinal: (unsigned int) value;
- (unsigned int) ordinal;

- (void) setName: (NSString *) value;
- (NSString *) name;

- (BOOL) isOnline;
- (BOOL) isOffline;

- (NSDictionary *) allProperties;

- (void) setString: (NSString *) value forProperty: (CFStringRef) property;
- (NSString *) stringForProperty: (CFStringRef) property;

- (void) setInteger: (SInt32) value forProperty: (CFStringRef) property;
- (SInt32) integerForProperty: (CFStringRef) property;

- (void) checkIfPropertySetIsAllowed;
- (void) invalidateCachedProperties;
- (void) propertyDidChange: (NSString *) propertyName;

@end

// Notifications

extern NSString *F53MIDIObjectsAppearedNotification;			// object is the class that has new objects
															// userInfo has an array of the new objects under key SMMIDIObjectsThatAppeared
extern NSString *F53MIDIObjectsThatAppeared;

extern NSString *F53MIDIObjectDisappearedNotification;		// object is the object that disappeared

extern NSString *F53MIDIObjectWasReplacedNotification;		// object is the object that was replaced
															// userInfo contains new object under key SMMIDIObjectReplacement
extern NSString *F53MIDIObjectReplacement;

extern NSString *F53MIDIObjectListChangedNotification;		// object is the class that has either gained new objects or lost old ones
															// This notification is sent last, after the appeared/disappeared/wasReplaced notifications.

extern NSString *F53MIDIObjectPropertyChangedNotification;	// object is the object whose property changed
															// userInfo contains changed property's name under key SMMIDIObjectChangedPropertyName
extern NSString *F53MIDIObjectChangedPropertyName;

#endif
