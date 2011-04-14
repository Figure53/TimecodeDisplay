/**

 @author  Kurt Revis
 @file    F53MIDIDevice.m

 Copyright (c) 2002-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#import "F53MIDIDevice.h"

#import "F53MIDISourceEndpoint.h"
#import "F53MIDIDestinationEndpoint.h"

@interface F53MIDIDevice (Private)

- (F53MIDIEndpoint *) singleRealtimeEndpointOfClass: (Class) endpointSubclass;

@end

@implementation F53MIDIDevice (Private)

- (F53MIDIEndpoint *) singleRealtimeEndpointOfClass: (Class) endpointSubclass
{
    SInt32 entityIndex;
    F53MIDIEndpoint *endpoint = nil;
    
    entityIndex = [self singleRealtimeEntityIndex];
    if (entityIndex >= 0) {
        MIDIEntityRef entityRef;
        
        entityRef = MIDIDeviceGetEntity(_objectRef, entityIndex);
        if (entityRef) {
            // Find the first endpoint in this entity.
            // (There is probably only one... I'm not sure what it would mean if there were more than one.)
            MIDIEndpointRef endpointRef;
            
            endpointRef = [endpointSubclass endpointRefAtIndex:0 forEntity:entityRef];
            if (endpointRef)
                endpoint = (F53MIDIEndpoint *)[endpointSubclass objectWithObjectRef:endpointRef];
        }
    }
    
    return endpoint;
}

@end


@implementation F53MIDIDevice

+ (MIDIObjectType) midiObjectType
{
    return kMIDIObjectType_Device;
}

+ (ItemCount) midiObjectCount
{
    return MIDIGetNumberOfDevices();
}

+ (MIDIObjectRef) midiObjectAtIndex: (ItemCount) index
{
    return (MIDIObjectRef)MIDIGetDevice(index);
}

+ (NSArray *) devices
{
    return [self allObjectsInOrder];
}

+ (F53MIDIDevice *) deviceWithUniqueID: (MIDIUniqueID) aUniqueID
{
    return (F53MIDIDevice *)[self objectWithUniqueID:aUniqueID];
}

+ (F53MIDIDevice *) deviceWithDeviceRef: (MIDIDeviceRef) aDeviceRef
{
    return (F53MIDIDevice *)[self objectWithObjectRef:(MIDIObjectRef)aDeviceRef];
}

- (MIDIDeviceRef) deviceRef
{
    return (MIDIDeviceRef)_objectRef;
}

- (NSString *) manufacturerName
{
    return [self stringForProperty:kMIDIPropertyManufacturer];
}

- (NSString *) modelName
{
    return [self stringForProperty:kMIDIPropertyModel];
}

- (NSString *) pathToImageFile
{
    return [self stringForProperty:kMIDIPropertyImage];
}

///
///  Returns -1 if this property does not exist on the device.
///
- (SInt32) singleRealtimeEntityIndex
{
    OSStatus status;
    SInt32 value;
    
    status = MIDIObjectGetIntegerProperty(_objectRef, kMIDIPropertySingleRealtimeEntity, &value);
    if (status == noErr)
        return value;
    else
        return -1;    
}

- (F53MIDISourceEndpoint *) singleRealtimeSourceEndpoint
{
    return (F53MIDISourceEndpoint *)[self singleRealtimeEndpointOfClass:[F53MIDISourceEndpoint class]];
}

///
///  Return nil if the device supports separate realtime messages for any entity.
///
- (F53MIDIDestinationEndpoint *) singleRealtimeDestinationEndpoint
{
    return (F53MIDIDestinationEndpoint *)[self singleRealtimeEndpointOfClass:[F53MIDIDestinationEndpoint class]];
}

@end
