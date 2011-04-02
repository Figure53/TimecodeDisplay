/**

@author  Kurt Revis, Christopher Ashworth
@file    F53MIDIEndpoint.m
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

#import "F53MIDIEndpoint.h"

#import "F53MIDIUtilities.h"
#import "F53MIDIClient.h"
#import "F53MIDIObject-Private.h"
#import "F53MIDIDevice.h"
#import "F53MIDIExternalDevice.h"
#import "NSArray-F53MIDIExtensions.h"

#import <CoreFoundation/CoreFoundation.h>
#import <AvailabilityMacros.h>
#import <unistd.h>


@interface F53MIDIEndpoint (Private)

+ (EndpointUniqueNamesFlags *) endpointUniqueNamesFlagsPtr;

+ (BOOL) doEndpointsHaveUniqueNames;
+ (BOOL) haveEndpointsAlwaysHadUniqueNames;
+ (void) checkForUniqueNames;

- (MIDIDeviceRef) findDevice;
- (MIDIDeviceRef) deviceRef;

- (SInt32) ownerPID;
- (void) setOwnerPID: (SInt32) value;

- (MIDIDeviceRef) getDeviceRefFromConnectedUniqueID: (MIDIUniqueID) connectedUniqueID;

@end

#pragma mark -

@implementation F53MIDIEndpoint (Private)

// Methods to be implemented in subclasses

+ (EndpointUniqueNamesFlags *) endpointUniqueNamesFlagsPtr
{
    F53RequestConcreteImplementation(self, _cmd);
    return NULL;
}

#pragma mark -
#pragma mark New methods

+ (BOOL) doEndpointsHaveUniqueNames
{
    return [self endpointUniqueNamesFlagsPtr]->areNamesUnique;
}

+ (BOOL) haveEndpointsAlwaysHadUniqueNames
{
    return [self endpointUniqueNamesFlagsPtr]->haveNamesAlwaysBeenUnique;
}

+ (void) checkForUniqueNames
{
    NSArray *endpoints;
    NSArray *nameArray, *nameSet;
    BOOL areNamesUnique;
    struct EndpointUniqueNamesFlags *flagsPtr;
	
    endpoints = [self allObjects];
    nameArray = [endpoints F53_arrayByMakingObjectsPerformSelector:@selector(name)];
    nameSet = [NSSet setWithArray:nameArray];
	
    areNamesUnique = ([nameArray count] == [nameSet count]);
	
    flagsPtr = [self endpointUniqueNamesFlagsPtr];
    flagsPtr->areNamesUnique = areNamesUnique;
    flagsPtr->haveNamesAlwaysBeenUnique = flagsPtr->haveNamesAlwaysBeenUnique && areNamesUnique;
}

- (MIDIDeviceRef) findDevice
{
    if ([[F53MIDIClient sharedClient] coreMIDICanGetDeviceFromEntity]) {
        OSStatus status;
        MIDIEntityRef entity;
        MIDIDeviceRef device;
		
        status = MIDIEndpointGetEntity((MIDIEndpointRef)_objectRef, &entity);
        if (noErr == status) {
            status = MIDIEntityGetDevice(entity, &device);
            if (noErr == status)
                return device;
        }
    } else {
        // This must be 10.1. Do it the hard way.
        // Walk the device/entity/endpoint tree, looking for the device which has our endpointRef.
        // Note that if this endpoint is virtual, no device will be found.
		
        ItemCount deviceCount, deviceIndex;
		
        deviceCount = MIDIGetNumberOfDevices();
        for (deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++) {
            MIDIDeviceRef device;
            ItemCount entityCount, entityIndex;
			
            device = MIDIGetDevice(deviceIndex);
            entityCount = MIDIDeviceGetNumberOfEntities(device);
			
            for (entityIndex = 0; entityIndex < entityCount; entityIndex++) {
                MIDIEntityRef entity;
                ItemCount endpointCount, endpointIndex;
				
                entity = MIDIDeviceGetEntity(device, entityIndex);
                endpointCount = [[self class] endpointCountForEntity:entity];
                for (endpointIndex = 0; endpointIndex < endpointCount; endpointIndex++) {
                    MIDIEndpointRef thisEndpoint;
					
                    thisEndpoint = [[self class] endpointRefAtIndex:endpointIndex forEntity:entity];
                    if (thisEndpoint == (MIDIEndpointRef)_objectRef) {
                        // Found it!
                        return device;
                    }
                }
            }
        }
    }
	
    // Nothing was found
    return NULL;
}

- (MIDIDeviceRef) deviceRef
{
    if (!_endpointFlags.hasLookedForDevice) {
        _deviceRef = [self findDevice];
        _endpointFlags.hasLookedForDevice = YES;
    }
	
    return _deviceRef;
}

- (SInt32) ownerPID
{
    SInt32 value;
    
    NS_DURING {
        value = [self integerForProperty:(CFStringRef)F53MIDIEndpointPropertyOwnerPID];
    } NS_HANDLER {
        value = 0;
    } NS_ENDHANDLER;
	
    return value;
}

- (void) setOwnerPID: (SInt32) value
{
    OSStatus err;
    
    err = MIDIObjectSetIntegerProperty(_objectRef, (CFStringRef)F53MIDIEndpointPropertyOwnerPID, value);
}

- (MIDIDeviceRef) getDeviceRefFromConnectedUniqueID: (MIDIUniqueID) connectedUniqueID
{
    MIDIDeviceRef returnDeviceRef = NULL;
	
    if ([[F53MIDIClient sharedClient] coreMIDICanFindObjectByUniqueID]) {
        // 10.2 and later
        MIDIObjectRef connectedObjectRef;
        MIDIObjectType connectedObjectType;
        OSStatus err;
        BOOL done = NO;
        
        err = MIDIObjectFindByUniqueID(connectedUniqueID, &connectedObjectRef, &connectedObjectType);
        connectedObjectType &= ~kMIDIObjectType_ExternalMask;
        
        while (err == noErr && !done)
        {
            switch (connectedObjectType) {
                case kMIDIObjectType_Device:
                    // we've got the device already
                    returnDeviceRef = (MIDIDeviceRef)connectedObjectRef;
                    done = YES;
                    break;
					
                case kMIDIObjectType_Entity:
                    // get the entity's device
                    connectedObjectType = kMIDIObjectType_Device;
                    err = MIDIEntityGetDevice((MIDIEntityRef)connectedObjectRef, (MIDIDeviceRef*)&connectedObjectRef);
                    break;
                    
                case kMIDIObjectType_Destination:
                case kMIDIObjectType_Source:
                    // Get the endpoint's entity
                    connectedObjectType = kMIDIObjectType_Entity;
                    err = MIDIEndpointGetEntity((MIDIEndpointRef)connectedObjectRef, (MIDIEntityRef*)&connectedObjectRef);                
                    break;
                    
                default:
                    // give up
                    done = YES;
                    break;
            }        
        }
    } else {
        // 10.1 fallback.  Assume the unique ID is for an external device.
        //returnDeviceRef = [[SMExternalDevice externalDeviceWithUniqueID: connectedUniqueID] deviceRef];
    }
    
    return returnDeviceRef;
}

@end

#pragma mark -

@implementation F53MIDIEndpoint

NSString *F53MIDIEndpointPropertyOwnerPID = @"F53MIDIEndpointPropertyOwnerPID";


+ (ItemCount) endpointCountForEntity: (MIDIEntityRef) entity
{
    F53RequestConcreteImplementation(self, _cmd);
    return 0;
}

+ (MIDIEndpointRef) endpointRefAtIndex: (ItemCount) index forEntity: (MIDIEntityRef) entity
{
    F53RequestConcreteImplementation(self, _cmd);
    return nil;
}

- (id) initWithObjectRef: (MIDIObjectRef) anObjectRef ordinal: (unsigned int) anOrdinal
{
    if (!(self = [super initWithObjectRef:anObjectRef ordinal:anOrdinal]))
        return nil;
	
    // We start out not knowing the endpoint's device (if it has one). We'll look it up on demand.
    _deviceRef = nil;
    _endpointFlags.hasLookedForDevice = NO;
	
    // Nothing has been cached yet 
    _endpointFlags.hasCachedManufacturerName = NO;
    _endpointFlags.hasCachedModelName = NO;
    
    return self;
}

- (void) dealloc
{
    [self remove];
    
    [_cachedManufacturerName release];
    _cachedManufacturerName = nil;
    [_cachedModelName release];
    _cachedModelName = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark F53MIDIObject overrides

- (void) checkIfPropertySetIsAllowed
{
    if (![self isOwnedByThisProcess])
	{
        [NSException raise:NSGenericException format:NSLocalizedStringFromTableInBundle(@"Can't set a property on an endpoint we don't own", @"F53MIDI", F53BundleForObject(self), "exception if someone tries to set a property on an endpoint we don't own"), nil];
    }
}

- (void) invalidateCachedProperties
{
    [super invalidateCachedProperties];
	
    _endpointFlags.hasLookedForDevice = NO;
    _endpointFlags.hasCachedManufacturerName = NO;
    _endpointFlags.hasCachedModelName = NO;
}

- (void) propertyDidChange: (NSString *) propertyName
{
    if ([propertyName isEqualToString:(NSString *)kMIDIPropertyManufacturer])
        _endpointFlags.hasCachedManufacturerName = NO;
    else if ([propertyName isEqualToString:(NSString *)kMIDIPropertyModel])
        _endpointFlags.hasCachedModelName = NO;
    else if ([propertyName isEqualToString:(NSString *)kMIDIPropertyModel])
        _endpointFlags.hasCachedModelName = NO;
	
    [super propertyDidChange:propertyName];
}

#pragma mark -
#pragma mark New methods

- (MIDIEndpointRef) endpointRef
{
    return (MIDIEndpointRef)_objectRef;
}

- (BOOL) isVirtual
{
    // We are virtual if we have no device
    return ([self deviceRef] == NULL);
}

- (BOOL) isOwnedByThisProcess
{
    return ([self isVirtual] && ([self ownerPID] == getpid()));
}

- (void) setIsOwnedByThisProcess
{
    // We have sort of a chicken-egg problem here. When setting values of properties, we want
    // to make sure that the endpoint is owned by this process. However, there's no way to
    // tell if the endpoint is owned by this process until it gets a property set on it.
    // So we'll say that this method should be called first, before any other setters are called.
    
	/*
    if (![self isVirtual]) {
        [NSException raise:NSGenericException format:NSLocalizedStringFromTableInBundle(@"Endpoint is not virtual, so it can't be owned by this process", @"F53MIDI", F53BundleForObject(self), "exception if someone calls -setIsOwnedByThisProcess on a non-virtual endpoint")];
    }
	 */
    
    [self setOwnerPID:getpid()];
}

///
///  Only works on virtual endpoints owned by this process.
///
- (void) remove
{
    if (_objectRef && [self isOwnedByThisProcess]) {        
        MIDIEndpointDispose((MIDIEndpointRef)_objectRef);
		
        // This object still hangs around in the endpoint lists until CoreMIDI gets around to posting a notification.
        // We should remove it immediately.
        [[self class] immediatelyRemoveObject:self];
		
        // Now we can forget the _objectRef (not earlier!)
        _objectRef = NULL;
    }
}

- (NSString *) manufacturerName
{
    if (!_endpointFlags.hasCachedManufacturerName) {
        [_cachedManufacturerName release];
		
        _cachedManufacturerName = [self stringForProperty:kMIDIPropertyManufacturer];
		
        // NOTE This fails sometimes on 10.1.3 and earlier (see bug #2865704),
        // so we fall back to asking for the device's manufacturer name if necessary.
        // (This bug is fixed in 10.1.5, with CoreMIDI framework version 15.5.)
        if ([[F53MIDIClient sharedClient] coreMIDIFrameworkVersion] < 0x15508000) {
            if (!_cachedManufacturerName)
                _cachedManufacturerName = [[self device] manufacturerName];
        }
		
        [_cachedManufacturerName retain];
        _endpointFlags.hasCachedManufacturerName = YES;        
    }
	
    return _cachedManufacturerName;
}

- (void) setManufacturerName: (NSString *) value
{
    if (![value isEqualToString:[self manufacturerName]]) {
        [self setString:value forProperty:kMIDIPropertyManufacturer];
        _endpointFlags.hasCachedManufacturerName = NO;
    }
}

- (void) setModelName: (NSString *) value
{
    if (![value isEqualToString:[self modelName]]) {
        [self setString:value forProperty:kMIDIPropertyModel];
        _endpointFlags.hasCachedModelName = NO;
    }
}

- (NSString *) modelName
{
    if (!_endpointFlags.hasCachedModelName) {
        [_cachedModelName release];
        _cachedModelName = [[self stringForProperty:kMIDIPropertyModel] retain];
		
        _endpointFlags.hasCachedModelName = YES;
    }
	
    return _cachedModelName;
}

///
///  If all endpoints of the same kind (source or destination) have unique names,
///  returns -name. Otherwise, returns -longName.
///
- (NSString *) uniqueName
{
    if ([[self class] doEndpointsHaveUniqueNames])
        return [self name];
    else
        return [self longName];
}

///
///  If all endpoints of the same kind (source or destination) have ALWAYS had unique names,
///  returns -name. Otherwise, returns -longName.
///
- (NSString *) alwaysUniqueName
{
    if ([[self class] haveEndpointsAlwaysHadUniqueNames])
        return [self name];
    else
        return [self longName];    
}

///
///  Returns "<device name> <endpoint name>". If there is no device for this endpoint
///  (that is, if it's virtual) return "<model name> <endpoint name>".
///  If the model/device name and endpoint name are the same, we return just the endpoint name.
///
- (NSString *) longName
{
    NSString *endpointName, *modelOrDeviceName;
	
    endpointName = [self name];
	
    if ([self isVirtual]) {
        modelOrDeviceName = [self modelName];		
    } else {
        modelOrDeviceName = [[self device] name];
    }
    
	if (modelOrDeviceName && [modelOrDeviceName isEqual:endpointName])
		return endpointName;
    else if (modelOrDeviceName && [modelOrDeviceName length] > 0)
        return [[modelOrDeviceName stringByAppendingString:@" "] stringByAppendingString:endpointName];
    else
        return endpointName;
}

///
///  Value is in milliseconds.
///
- (void) setAdvanceScheduleTime: (SInt32) newValue
{
    [self setInteger:newValue forProperty:kMIDIPropertyAdvanceScheduleTimeMuSec];
}

- (SInt32) advanceScheduleTime
{
    return [self integerForProperty:kMIDIPropertyAdvanceScheduleTimeMuSec];
}

///
///  Returns a POSIX path to the image for this endpoint's device, or nil if there is no image.
///
- (NSString *) pathToImageFile
{
    return [self stringForProperty:kMIDIPropertyImage];
}

///
///  May be external devices, endpoints, or who knows what.
///
- (NSArray *) uniqueIDsOfConnectedThings
{
    MIDIUniqueID oneUniqueID;
    NSData *data;
	
    // The property for kMIDIPropertyConnectionUniqueID may be an integer or a data object.
    // Try getting it as data first.  (The data is an array of big-endian MIDIUniqueIDs, aka SInt32s.)
    if (noErr == MIDIObjectGetDataProperty(_objectRef, kMIDIPropertyConnectionUniqueID, (CFDataRef *)&data)) {
        unsigned int dataLength = [data length];
        unsigned int count;
        const MIDIUniqueID *p, *end;
        NSMutableArray *array;
        
        // Make sure the data length makes sense
        if (dataLength % sizeof(SInt32) != 0)
            return [NSArray array];
		
        count = dataLength / sizeof(MIDIUniqueID);
        array = [NSMutableArray arrayWithCapacity:count];
        p = [data bytes];
        for (end = p + count ; p < end; p++) {
            oneUniqueID = ntohl(*p);
            if (oneUniqueID != 0)
                [array addObject:[NSNumber numberWithLong:oneUniqueID]];
        }
		
        return array;
    }
    
    // Now try getting the property as an integer. (It is only valid if nonzero.)
    if (noErr == MIDIObjectGetIntegerProperty(_objectRef, kMIDIPropertyConnectionUniqueID, &oneUniqueID)) {
        if (oneUniqueID != 0)
            return [NSArray arrayWithObject:[NSNumber numberWithLong:oneUniqueID]];
    }
	
    // Give up
    return [NSArray array];
}

- (NSArray *) connectedExternalDevices
{
    NSArray *uniqueIDs;
    unsigned int uniqueIDIndex, uniqueIDCount;
    NSMutableArray *externalDevices;
	
    uniqueIDs = [self uniqueIDsOfConnectedThings];
    uniqueIDCount = [uniqueIDs count];
    externalDevices = [NSMutableArray arrayWithCapacity:uniqueIDCount];
    
    for (uniqueIDIndex = 0; uniqueIDIndex < uniqueIDCount; uniqueIDIndex++) {
        MIDIUniqueID aUniqueID = [[uniqueIDs objectAtIndex:uniqueIDIndex] intValue];
        MIDIDeviceRef aDeviceRef = [self getDeviceRefFromConnectedUniqueID:aUniqueID];
        if (aDeviceRef) {
            F53MIDIExternalDevice *extDevice = [F53MIDIExternalDevice externalDeviceWithDeviceRef:aDeviceRef];
            if (extDevice)
                [externalDevices addObject:extDevice];
        }
    }    
	
    return externalDevices;
}

///
///  May return nil if this endpoint is virtual.
///
- (F53MIDIDevice *) device
{
    return [F53MIDIDevice deviceWithDeviceRef:[self deviceRef]];
}

//
// Overrides of SMMIDIObject private methods
//

+ (void) initialMIDISetup
{
    [super initialMIDISetup];
    [self checkForUniqueNames];
}

+ (void) refreshAllObjects
{
    [super refreshAllObjects];
    [self checkForUniqueNames];
}

+ (F53MIDIObject *) immediatelyAddObjectWithObjectRef: (MIDIObjectRef) anObjectRef
{
    F53MIDIObject *object;
	
    object = [super immediatelyAddObjectWithObjectRef:anObjectRef];
    [self checkForUniqueNames];
    return object;
}

@end

