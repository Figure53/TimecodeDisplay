/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIObject.m
@date    Created on Thursday March 9 2006.
@brief   

Copyright (c) 2001-2006, Kurt Revis.  All rights reserved.
Copyright (c) 2006 Christopher Ashworth. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

**/

#import "F53MIDIObject.h"
#import "F53MIDIObject-Private.h"

#import "F53MIDIUtilities.h"
#import "F53MIDIClient.h"
#import "F53MIDIEndpoint.h"
#import "F53MIDISourceEndpoint.h"
#import "F53MIDIDestinationEndpoint.h"
#import "F53MIDIDevice.h"
#import "F53MIDIExternalDevice.h"

#import <objc/objc-runtime.h>


@interface F53MIDIObject (Private)

static int midiObjectOrdinalComparator(id object1, id object2, void *context);

// Methods to be used on F53MIDIObject itself, not subclasses:

+ (void) privateInitialize;
+ (void) midiClientCreated: (NSNotification *) notification;
+ (NSSet *) leafSubclasses;
+ (Class) subclassForObjectType: (MIDIObjectType) objectType;

+ (BOOL) isUniqueIDInUse: (MIDIUniqueID) proposedUniqueID;

+ (void) midiObjectPropertyChanged: (NSNotification *) notification;
+ (void) midiObjectWasAdded: (NSNotification *) notification;
+ (void) midiObjectWasRemoved: (NSNotification *) notification;

// Methods to be used on subclasses of F53MIDIObject, not F53MIDIObject itself:

+ (NSMapTable *) midiObjectMapTable;

+ (F53MIDIObject *) addObjectWithObjectRef: (MIDIObjectRef) anObjectRef ordinal: (unsigned int) anOrdinal;
+ (void) removeObjectWithObjectRef: (MIDIObjectRef) anObjectRef;

+ (void) refreshObjectOrdinals;

+ (void) midiSetupChanged: (NSNotification *) notification;

+ (void) postObjectListChangedNotification;
+ (void) postObjectsAddedNotificationWithObjects: (NSArray*) objects;

- (void) updateUniqueID;

- (void) postRemovedNotification;
- (void) postReplacedNotificationWithReplacement: (F53MIDIObject *) replacement;

@end

@implementation F53MIDIObject (Private)

int midiObjectOrdinalComparator(id object1, id object2, void *context)
{
    unsigned int ordinal1, ordinal2;
	
    ordinal1 = [object1 ordinal];
    ordinal2 = [object2 ordinal];
	
    if (ordinal1 > ordinal2)
        return NSOrderedDescending;
    else if (ordinal1 == ordinal2)
        return NSOrderedSame;
    else
        return NSOrderedAscending;
}

///  A map table from (Class) to (NSMapTable *).
///  Keys are leaf subclasses of F53MIDIObject.
///  Objects are pointers to the subclass's NSMapTable from MIDIObjectRef to (F53MIDIObject *).
static NSMapTable *_classToObjectsMapTable = nil;

+ (void) privateInitialize
{
    F53Assert(self == [F53MIDIObject class]);
	
    _classToObjectsMapTable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 0);
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(midiClientCreated:) name:F53MIDIClientCreatedInternalNotification object:nil];
}

+ (void) midiClientCreated: (NSNotification *) notification
{
    NSSet *leafSubclasses;
    NSEnumerator *enumerator;
    NSString *aClassString;
    NSNotificationCenter *center;
    F53MIDIClient *client;
	
    F53Assert(self == [F53MIDIObject class]);
	
    // Send +initialMIDISetup to each leaf subclass of this class.    
    leafSubclasses = [self leafSubclasses];
    enumerator = [leafSubclasses objectEnumerator];
    while ((aClassString = [enumerator nextObject])) {
        Class aClass = NSClassFromString(aClassString);
        [aClass initialMIDISetup];
    }
	
    client = [F53MIDIClient sharedClient];
    center = [NSNotificationCenter defaultCenter];
	
    // Also subscribe to the object property changed notification, if it will be posted.
    // We will receive this notification and then dispatch it to the correct object.
    if ([client postsObjectPropertyChangedNotifications]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(midiObjectPropertyChanged:) name:F53MIDIClientObjectPropertyChangedNotification object:[F53MIDIClient sharedClient]];
    }
	
    // And subscribe to object added/removed notifications, if they will be posted.
    // We will dispatch these to the correct subclass.
    if ([client postsObjectAddedAndRemovedNotifications]) {
        [center addObserver:self selector:@selector(midiObjectWasAdded:) name:F53MIDIClientObjectAddedNotification object:client];
        [center addObserver:self selector:@selector(midiObjectWasRemoved:) name:F53MIDIClientObjectRemovedNotification object:client];
    } else {
        // Otherwise, make each subclass listen to the general "something changed" notification.
        enumerator = [leafSubclasses objectEnumerator];
        while ((aClassString = [enumerator nextObject])) {
            Class aClass = NSClassFromString(aClassString);
            [center addObserver:aClass selector:@selector(midiSetupChanged:) name:F53MIDIClientSetupChangedInternalNotification object:client];
        }
    }    
}

+ (NSSet *) leafSubclasses
{
    static NSMutableSet *sLeafSubclasses = nil;
    
    /*
     
     ALTERED BY SD: These are the only leaf subclasses of F53MIDIObject that I can find,
     so there's really no reason to go through this whole process (especially since it
     doesn't work when targeting Snow Leopard).
     
     */
    
    if (!sLeafSubclasses) {
        sLeafSubclasses = [[NSMutableSet setWithObjects:
                            NSStringFromClass([F53MIDIDestinationEndpoint class]),
                            NSStringFromClass([F53MIDISourceEndpoint class]),
                            NSStringFromClass([F53MIDIDevice class]),
                            NSStringFromClass([F53MIDIExternalDevice class]),
                            nil] retain];

        // This is expensive -- we need to look through over 700 classes--so we do it only once.
/*        int numClasses, newNumClasses;
        Class *classes;
        int classIndex;
        NSMutableSet *knownSubclasses;
        NSEnumerator *enumerator;
        NSValue *aClassValue;
		
        F53Assert(self == [F53MIDIObject class]);
		
        // Get the whole list of classes
        numClasses = 0;
        newNumClasses = objc_getClassList(NULL, 0);
        classes = NULL;
        while (numClasses < newNumClasses) {
            numClasses = newNumClasses;
            classes = realloc(classes, sizeof(Class) * numClasses);
            bzero(classes, numClasses * sizeof(Class));
            newNumClasses = objc_getClassList(classes, numClasses);
        }
		
        // For each class:
        //    if it is a subclass of this class, add it to knownSubclasses
        knownSubclasses = [NSMutableSet set];
        for (classIndex = 0; classIndex < numClasses; classIndex++) {
            Class aClass = classes[classIndex];
			
            if (aClass != self && [aClass isSubclassOfClass:self])// F53ClassIsSubclassOfClass(aClass, self))
                [knownSubclasses addObject:[NSValue valueWithPointer:aClass]];
        }
		
        free(classes);
		
        // copy knownSubclasses to leaves
        sLeafSubclasses = [[NSMutableSet alloc] initWithSet:knownSubclasses];
		
        // Then for each class in knownSubclasses,
        //    if its superclass is in knownSubclasses
        //       remove that superclass from leaves
        enumerator = [knownSubclasses objectEnumerator];
        while ((aClassValue = [enumerator nextObject]))
        {
            Class aClass = [aClassValue pointerValue];
            NSString *superclassValue = NSStringFromClass(aClass);
            if ([knownSubclasses containsObject:superclassValue])
                [sLeafSubclasses removeObject:superclassValue];
        }*/
        
        // End: we are left with the correct set of leaves.
    }
	
    return sLeafSubclasses;
}

+ (Class) subclassForObjectType: (MIDIObjectType) objectType
{
    // Go through each of our subclasses and find which one owns objects of this type.
    // TODO: this is kind of inefficient; a map from type to class might be better.
	
    F53Assert(self == [F53MIDIObject class]);
	
    for (NSString *subclassString in [self leafSubclasses])
    {
        Class subclass = NSClassFromString(subclassString);
		
        if ([subclass midiObjectType] == objectType)
            return subclass;
    }
	
    return Nil;
}

+ (BOOL) isUniqueIDInUse: (MIDIUniqueID) proposedUniqueID
{
    if ([[F53MIDIClient sharedClient] coreMIDICanFindObjectByUniqueID]) {
        MIDIObjectRef object = NULL;
        MIDIObjectType type;
		
        MIDIObjectFindByUniqueID(proposedUniqueID, &object, &type);
        return (object != NULL);
    } else {
        // This search is not as complete as it could be, but it'll have to do.
        // We're only going to set unique IDs on virtual endpoints, anyway.
        return ([F53MIDISourceEndpoint sourceEndpointWithUniqueID:proposedUniqueID] != nil || [F53MIDIDestinationEndpoint destinationEndpointWithUniqueID:proposedUniqueID] != nil);
    }
}

//
// Notifications that objects have changed
//

+ (void) midiObjectPropertyChanged: (NSNotification *) notification
{
    MIDIObjectRef ref;
    MIDIObjectType objectType;
    NSString *propertyName;
    Class subclass;
    F53MIDIObject *object;
	
    F53Assert(self == [F53MIDIObject class]);
	
    ref = [[[notification userInfo] objectForKey:F53MIDIClientObjectPropertyChangedObject] pointerValue];
    objectType = [[[notification userInfo] objectForKey:F53MIDIClientObjectPropertyChangedType] intValue];
    propertyName = [[notification userInfo] objectForKey:F53MIDIClientObjectPropertyChangedName];
	
    subclass = [self subclassForObjectType:objectType];
    object = [subclass objectWithObjectRef:ref];
    [object propertyDidChange:propertyName];
}

+ (void) midiObjectWasAdded: (NSNotification *) notification
{
    MIDIObjectRef ref;
    MIDIObjectType objectType;
    Class subclass;
	
    F53Assert(self == [F53MIDIObject class]);
	
    ref = [[[notification userInfo] objectForKey:F53MIDIClientObjectAddedOrRemovedChild] pointerValue];
    F53Assert(ref != NULL);
    objectType = [[[notification userInfo] objectForKey:F53MIDIClientObjectAddedOrRemovedChildType] intValue];
	
    subclass = [self subclassForObjectType:objectType];
    if (subclass) {
        // We might already have this object. Check and see.
        if (![subclass objectWithObjectRef:ref])
            [subclass immediatelyAddObjectWithObjectRef:ref];            
    }
}

+ (void) midiObjectWasRemoved: (NSNotification *) notification
{
    MIDIObjectRef ref;
    MIDIObjectType objectType;
    Class subclass;
    F53MIDIObject *object;
	
    F53Assert(self == [F53MIDIObject class]);
	
    ref = [[[notification userInfo] objectForKey:F53MIDIClientObjectAddedOrRemovedChild] pointerValue];
    F53Assert(ref != NULL);
    objectType = [[[notification userInfo] objectForKey:F53MIDIClientObjectAddedOrRemovedChildType] intValue];
	
    subclass = [self subclassForObjectType:objectType];
    if ((object = [subclass objectWithObjectRef:ref]))
        [subclass immediatelyRemoveObject:object];
}

//
// Methods to be used on subclasses of F53MIDIObject, not F53MIDIObject itself
//

+ (NSMapTable *) midiObjectMapTable
{
    F53Assert(self != [F53MIDIObject class]);
	
    return NSMapGet(_classToObjectsMapTable, self);
}

+ (F53MIDIObject *) addObjectWithObjectRef: (MIDIObjectRef) anObjectRef ordinal: (unsigned int) anOrdinal
{
    F53MIDIObject *object;
	
    F53Assert(self != [F53MIDIObject class]);
    F53Assert(anObjectRef != NULL);
	
    object = [[self alloc] initWithObjectRef:anObjectRef ordinal:anOrdinal];
    if (object) {
        NSMapTable *mapTable = [self midiObjectMapTable];
        F53Assert(mapTable != NULL);
		
        NSMapInsertKnownAbsent(mapTable, anObjectRef, object);
        [object release];
    }
	
    return object;
}

+ (void) removeObjectWithObjectRef: (MIDIObjectRef) anObjectRef
{
    NSMapTable *mapTable = [self midiObjectMapTable];
	
    F53Assert(self != [F53MIDIObject class]);
    F53Assert(mapTable != NULL);
	
    NSMapRemove(mapTable, anObjectRef);
}

+ (void) refreshObjectOrdinals
{
    ItemCount index, count;
	
    F53Assert(self != [F53MIDIObject class]);
	
    count = [self midiObjectCount];
    for (index = 0; index < count; index++) {
        MIDIObjectRef ref = [self midiObjectAtIndex:index];
        [[self objectWithObjectRef:ref] setOrdinal:index];
    }
}

+ (void) midiSetupChanged: (NSNotification *) notification
{
    F53Assert(self != [F53MIDIObject class]);
	
    [self refreshAllObjects];
}

+ (void) postObjectListChangedNotification
{
    F53Assert(self != [F53MIDIObject class]);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIObjectListChangedNotification object:self];
}

+ (void) postObjectsAddedNotificationWithObjects: (NSArray*) objects
{
    NSDictionary *userInfo;
    
    F53Assert(self != [F53MIDIObject class]);
	
    userInfo = [NSDictionary dictionaryWithObject:objects forKey:F53MIDIObjectsThatAppeared];
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIObjectsAppearedNotification object:self userInfo:userInfo];    
}

- (void) updateUniqueID
{
    if (noErr != MIDIObjectGetIntegerProperty(_objectRef, kMIDIPropertyUniqueID, &_uniqueID))
        _uniqueID = 0;
}

- (void) postRemovedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIObjectDisappearedNotification object:self];
}

- (void) postReplacedNotificationWithReplacement: (F53MIDIObject *) replacement
{
    NSDictionary *userInfo;
	
    F53Assert(replacement != NULL);
    userInfo = [NSDictionary dictionaryWithObject:replacement forKey:F53MIDIObjectReplacement];
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIObjectWasReplacedNotification object:self userInfo:userInfo];
}

@end


@implementation F53MIDIObject

NSString *F53MIDIObjectsAppearedNotification = @"F53MIDIObjectsAppearedNotification";
NSString *F53MIDIObjectsThatAppeared = @"F53MIDIObjectsThatAppeared";
NSString *F53MIDIObjectDisappearedNotification = @"F53MIDIObjectDisappearedNotification";
NSString *F53MIDIObjectWasReplacedNotification = @"F53MIDIObjectWasReplacedNotification";
NSString *F53MIDIObjectReplacement = @"F53MIDIObjectReplacement";
NSString *F53MIDIObjectListChangedNotification = @"F53MIDIObjectListChangedNotification";
NSString *F53MIDIObjectPropertyChangedNotification = @"F53MIDIObjectPropertyChangedNotification";
NSString *F53MIDIObjectChangedPropertyName = @"F53MIDIObjectChangedPropertyName";


+ (void) initialize
{
    F53Initialize;
    
    [self privateInitialize];
}

///
///  Returns the CoreMIDI MIDIObjectType corresponding to this subclass. 
///  Must be implemented by subclasses.
///
+ (MIDIObjectType) midiObjectType
{
    F53RequestConcreteImplementation(self, _cmd);
    return kMIDIObjectType_Other;
}

/// 
///  Returns the number of this kind of MIDIObjectRef that are available.
///  Must be implemented by subclasses.
///
+ (ItemCount) midiObjectCount
{
    F53RequestConcreteImplementation(self, _cmd);
    return 0;
}

/// 
///  Returns the MIDIObjectRef with this index.
///  Must be implemented by subclasses.
///
+ (MIDIObjectRef) midiObjectAtIndex: (ItemCount) index
{
    F53RequestConcreteImplementation(self, _cmd);
    return NULL;        
}

///
///  Does nothing in the base class.  Works for subclasses of F53MIDIObject only.
///
+ (NSArray *) allObjects
{
    NSMapTable *mapTable;
	
    mapTable = [self midiObjectMapTable];
    F53Assert(mapTable);
	
    if (mapTable)
        return NSAllMapTableValues(mapTable);
    else
        return nil;
}

///
///  Does nothing in the base class.  Works for subclasses of F53MIDIObject only.
///
+ (NSArray *) allObjectsInOrder
{
    return [[self allObjects] sortedArrayUsingFunction:midiObjectOrdinalComparator context:NULL];
}

///
///  Does nothing in the base class.  Works for subclasses of F53MIDIObject only.
///
+ (F53MIDIObject *) objectWithUniqueID: (MIDIUniqueID) aUniqueID
{
    // TODO:  We may want to change this to use MIDIObjectFindByUniqueID() where it is available (10.2 and greater).
    // However, I bet it's cheaper to look at the local list of unique IDs instead of making a roundtrip to the MIDIServer.
    NSArray *allObjects;
    unsigned int index;
	
    allObjects = [self allObjects];
    index = [allObjects count];
    while (index--) {
        F53MIDIObject *object;
		
        object = [allObjects objectAtIndex:index];
        if ([object uniqueID] == aUniqueID)
            return object;
    }
	
    return nil;
}

///
///  Does nothing in the base class.  Works for subclasses of F53MIDIObject only.
///
+ (F53MIDIObject *) objectWithName: (NSString *) aName
{
    NSArray *allObjects;
    unsigned int index;
	
    if (!aName) return nil;
	
    allObjects = [self allObjects];
    index = [allObjects count];
    while (index--) {
        F53MIDIObject *object;
		
        object = [allObjects objectAtIndex:index];
        if ([[object name] isEqualToString:aName])
            return object;
    }
	
    return nil;
}

///
///  Does nothing in the base class.  Works for subclasses of F53MIDIObject only.
///
+ (F53MIDIObject *) objectWithObjectRef: (MIDIObjectRef) anObjectRef
{
    NSMapTable *mapTable;
	
    if (anObjectRef == NULL) return nil;
    
    mapTable = [self midiObjectMapTable];
    F53Assert(mapTable);
	
    if (mapTable)
        return NSMapGet(mapTable, anObjectRef);
    else
        return nil;
}

///
///  Generate a new unique ID.
///
+ (MIDIUniqueID) generateNewUniqueID
{
    static MIDIUniqueID sequence = 0;
    MIDIUniqueID proposed;
    BOOL foundUnique = NO;
	
    while (!foundUnique) {
        // We could get fancy, but just using the current time is likely to work just fine.
        // Add a sequence number in case this method is called more than once within a second.
        proposed = time(NULL);
        proposed += sequence;
        sequence++;
		
        // Make sure this uniqueID is not in use, just in case.
        foundUnique = ![self isUniqueIDInUse:proposed];
    }
	
    return proposed;
}

- (id) initWithObjectRef: (MIDIObjectRef) anObjectRef ordinal: (unsigned int) anOrdinal
{
    if (!(self = [super init]))
        return nil;
	
    F53Assert(anObjectRef != NULL);
	
    _objectRef = anObjectRef;
    _ordinal = anOrdinal;
	
    // Save the object's uniqueID, since it could become inaccessible later (if the object goes away).
    [self updateUniqueID];
	
    // Nothing has been cached yet.
    _flags.hasCachedName = NO;
    
    return self;
}

- (MIDIObjectRef) objectRef
{
    return _objectRef;
}

///
///  Returns whether or not the set succeeded
///
- (BOOL) setUniqueID: (MIDIUniqueID) value
{
    if (value == _uniqueID)
        return YES;
	
    [self checkIfPropertySetIsAllowed];
	
    MIDIObjectSetIntegerProperty(_objectRef, kMIDIPropertyUniqueID, value);
    // Ignore the error code. We're going to check if our change stuck, either way.
	
    // Refresh our idea of the unique ID since it may or may not have changed
    [self updateUniqueID];
	
    return (_uniqueID == value);
}

- (MIDIUniqueID) uniqueID
{
    return _uniqueID;
}

- (void) setOrdinal: (unsigned int) value
{
    _ordinal = value;
}

- (unsigned int) ordinal;
{
    return _ordinal;
}

- (void) setName: (NSString *) value
{
    if (![value isEqualToString:[self name]]) {
        [self setString:value forProperty:kMIDIPropertyName];
        _flags.hasCachedName = NO;  // Make sure we read it back from the MIDIServer next time, just in case our change did not stick.        
    }
}

- (NSString *) name
{
    if (!_flags.hasCachedName) {
        [_cachedName release];
        _cachedName = [[self stringForProperty:kMIDIPropertyName] retain];
        _flags.hasCachedName = YES;
    }
	
    return _cachedName;
}

- (BOOL) isOnline
{
    return ![self isOffline];
}

- (BOOL) isOffline
{
    return [self integerForProperty:kMIDIPropertyOffline];
}

- (NSDictionary*) allProperties
{
    id propertyList;
	
    if (noErr != MIDIObjectGetProperties(_objectRef, (CFPropertyListRef *)&propertyList, NO /* not deep */))
        propertyList = nil;
	
    return (NSDictionary*)[propertyList autorelease];
}

- (void) setString: (NSString *) value forProperty: (CFStringRef) property
{
    OSStatus err;
	
    [self checkIfPropertySetIsAllowed];
	
    err = MIDIObjectSetStringProperty(_objectRef, property, (CFStringRef)value);
}

- (NSString *) stringForProperty: (CFStringRef) property
{
    NSString *string;
	
    if (noErr == MIDIObjectGetStringProperty(_objectRef, property, (CFStringRef *)&string))
        return [string autorelease];
    else
        return nil;
}

- (void) setInteger: (SInt32) value forProperty: (CFStringRef) property
{
    OSStatus err;
	
    [self checkIfPropertySetIsAllowed];
	
    err = MIDIObjectSetIntegerProperty(_objectRef, property, value);
}

- (SInt32) integerForProperty: (CFStringRef) property
{
    OSStatus err;
    SInt32 value;
	
    err = MIDIObjectGetIntegerProperty(_objectRef, property, &value);
	
    return value;
}

///
///  Does nothing in base class. 
///  May be overridden in subclasses to raise an exception if we shouldn't be 
///  setting values for properties of this object.
///
- (void) checkIfPropertySetIsAllowed
{
    // Do nothing in base class.
}

///
///  Call this to force this object to throw away any properties it may have cached.
///  Subclasses may want to override this.
///
- (void) invalidateCachedProperties
{
    _flags.hasCachedName = NO;
}

///
///  Called when a property of this object changes.  Subclasses may override (be sure to call super's implementation).
///  Posts the notification F53MIDIObjectPropertyChangedNotification.
///
- (void) propertyDidChange: (NSString *) propertyName
{
    NSDictionary *userInfo;
	
    if ([propertyName isEqualToString:(NSString *)kMIDIPropertyName]) {
        _flags.hasCachedName = NO;
    } else if ([propertyName isEqualToString:(NSString *)kMIDIPropertyUniqueID]) {
        [self updateUniqueID];
    }
	
    userInfo = [NSDictionary dictionaryWithObject:propertyName forKey:F53MIDIObjectChangedPropertyName];
    [[NSNotificationCenter defaultCenter] postNotificationName:F53MIDIObjectPropertyChangedNotification object:self userInfo:userInfo];
}

@end

@implementation F53MIDIObject (FrameworkPrivate)

///
///  Sent to each subclass when the first MIDI Client is created.
///
+ (void) initialMIDISetup
{
    ItemCount objectIndex, objectCount;
    NSMapTable *newMapTable;
	MIDIObjectRef anObjectRef;
	
    F53Assert(self != [F53MIDIObject class]);
	
    objectCount = [self midiObjectCount];
	
    newMapTable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, NSObjectMapValueCallBacks, objectCount);
    NSMapInsertKnownAbsent(_classToObjectsMapTable, self, newMapTable);
	
    // Iterate through the new MIDIObjectRefs and add a wrapper object for each.
    for (objectIndex = 0; objectIndex < objectCount; objectIndex++) {
        anObjectRef = [self midiObjectAtIndex:objectIndex];
        if (anObjectRef == NULL)
            continue;
		
        [self addObjectWithObjectRef:anObjectRef ordinal:objectIndex];
    }
}

///
///  Subclasses may use this method to immediately cause a new object to be created from a MIDIObjectRef
///  (instead of doing it when CoreMIDI sends a notification).
///  Should be sent only to F53MIDIObject subclasses, not to F53MIDIObject itself.
///
+ (F53MIDIObject *) immediatelyAddObjectWithObjectRef: (MIDIObjectRef) anObjectRef
{
    F53MIDIObject *theObject;
	
    // Use a default ordinal to start.
    theObject = [self addObjectWithObjectRef:anObjectRef ordinal:0];
	
    // Any of the objects' ordinals may have changed, so refresh them.
    [self refreshObjectOrdinals];
	
    // And post a notification that the object list has changed.
    [self postObjectListChangedNotification];
	
    // And post a notification that this object has been added.
    [self postObjectsAddedNotificationWithObjects:[NSArray arrayWithObject:theObject]];
    
    return theObject;
}

///
///  Similarly, subclasses may use this method to immediately cause an object to be removed from the list
///  of F53MIDIObjects of this subclass, instead of waiting for CoreMIDI to send a notification.
///  Should be sent only to F53MIDIObject subclasses, not to F53MIDIObject itself.
///
+ (void) immediatelyRemoveObject: (F53MIDIObject *) object
{
    [object retain];
    
    [self removeObjectWithObjectRef:[object objectRef]];
	
    // Any of the objects' ordinals may have changed, so refresh them.
    [self refreshObjectOrdinals];
	
    // And post a notification that the object list has changed.
    [self postObjectListChangedNotification];
	
    // And post a notification that this object has been removed.
    [object postRemovedNotification];
	
    [object release];
}

///
///  Refresh all F53MIDIObjects of this subclass.
///  Should be sent only to F53MIDIObject subclasses, not to F53MIDIObject itself.
///
+ (void) refreshAllObjects
{
    NSMapTable *oldMapTable, *newMapTable;
    ItemCount objectIndex, objectCount;
    NSMutableArray *removedObjects, *replacedObjects, *replacementObjects, *addedObjects;
	MIDIObjectRef anObjectRef;
	F53MIDIObject *object;
	
    F53Assert(self != [F53MIDIObject class]);
	
    objectCount = [self midiObjectCount];
	
    oldMapTable = [self midiObjectMapTable];
    newMapTable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, NSObjectMapValueCallBacks, objectCount);
	
    // We start out assuming all objects have been removed, none have been replaced.
    // As we find out otherwise, we remove some endpoints from removedObjects,
    // and add some to replacedObjects.
    removedObjects = [NSMutableArray arrayWithArray:[self allObjects]];
    replacedObjects = [NSMutableArray array];
    replacementObjects = [NSMutableArray array];
    addedObjects = [NSMutableArray array];
	
    // Iterate through the new objectRefs.
    for (objectIndex = 0; objectIndex < objectCount; objectIndex++) {
        anObjectRef = [self midiObjectAtIndex:objectIndex];
        if (anObjectRef == NULL)
            continue;
		
        if ((object = [self objectWithObjectRef:anObjectRef])) {
            // This objectRef existed previously.
            [removedObjects removeObjectIdenticalTo:object];
            // It's possible that its uniqueID changed, though.
            [object updateUniqueID];
            // And its ordinal may also have changed.
            [object setOrdinal:objectIndex];
        } else {
            F53MIDIObject *replacedObject;
			
            // This objectRef did not previously exist, so create a new object for it.
            // (Don't add it to the map table, though.)
            object = [[[self alloc] initWithObjectRef:anObjectRef ordinal:objectIndex] autorelease];
            if (object) {
                // If the new object has the same uniqueID as an old object, remember it.
                if ((replacedObject = [self objectWithUniqueID:[object uniqueID]])) {
                    [replacedObjects addObject:replacedObject];
                    [replacementObjects addObject:object];
                    [removedObjects removeObjectIdenticalTo:replacedObjects];
                } else {
                    [addedObjects addObject:object];
                }
            }
        }
		
        if (object)
            NSMapInsert(newMapTable, anObjectRef, object);
    }
	
    // Now replace the old set of objects with the new one.
    if (oldMapTable)
        NSFreeMapTable(oldMapTable);
    NSMapInsert(_classToObjectsMapTable, self, newMapTable);
	
    // Make the new group of objects invalidate their cached properties (names and such).
    [[self allObjects] makeObjectsPerformSelector:@selector(invalidateCachedProperties)];
	
    // Now everything is in place for the new regime.
    // First, post specific notifications for added/removed/replaced objects.
    if ([addedObjects count] > 0)
        [self postObjectsAddedNotificationWithObjects:addedObjects];
    
    [removedObjects makeObjectsPerformSelector:@selector(postRemovedNotification)];
	
    objectIndex = [replacedObjects count];
    while (objectIndex--)
        [[replacedObjects objectAtIndex:objectIndex] postReplacedNotificationWithReplacement:[replacementObjects objectAtIndex:objectIndex]];
	
    // Then, post a general notification that the list of objects for this subclass has changed (if it has).
    if ([addedObjects count] > 0 || [removedObjects count] > 0 || [replacedObjects count] > 0)
        [self postObjectListChangedNotification];
}

@end
