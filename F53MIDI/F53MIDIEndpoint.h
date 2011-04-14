/**

 @author  Kurt Revis
 @file    F53MIDIEndpoint.h

 Copyright (c) 2002-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#ifndef __F53MIDIENDPOINT_H__
#define __F53MIDIENDPOINT_H__

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreMIDI/CoreMIDI.h>

#import "F53MIDIObject.h"

@class F53MIDIDevice;

@interface F53MIDIEndpoint : F53MIDIObject
{
    MIDIDeviceRef _deviceRef;        ///< Device of this endpoint; nil if it's a virtual endpoint.
    
    struct {
        unsigned int hasLookedForDevice:1;
        unsigned int hasCachedManufacturerName:1;
        unsigned int hasCachedModelName:1;
    } _endpointFlags;
    
    NSString *_cachedManufacturerName;
    NSString *_cachedModelName;
}

// Class methods:

// Implemented only on subclasses of F53MIDIEndpoint:
+ (ItemCount) endpointCountForEntity: (MIDIEntityRef) entity;
+ (MIDIEndpointRef) endpointRefAtIndex: (ItemCount) index forEntity: (MIDIEntityRef) entity;

// Instance methods:

- (MIDIEndpointRef) endpointRef;

- (BOOL) isVirtual;
- (BOOL) isOwnedByThisProcess;
- (void) setIsOwnedByThisProcess;
- (void) remove;

- (void) setManufacturerName: (NSString *) value;
- (NSString *) manufacturerName;

- (void) setModelName: (NSString *) value;
- (NSString *) modelName;

- (NSString *) uniqueName;
- (NSString *) alwaysUniqueName;
- (NSString *) longName;

- (void) setAdvanceScheduleTime: (SInt32) newValue;
- (SInt32) advanceScheduleTime;

- (NSString *) pathToImageFile;

- (NSArray *) uniqueIDsOfConnectedThings;
- (NSArray *) connectedExternalDevices;

- (F53MIDIDevice *) device;

@end


// MIDI property keys

extern NSString *F53MIDIEndpointPropertyOwnerPID;    // We set this on the virtual endpoints that we create, so we can query them to see if they're ours.

typedef struct EndpointUniqueNamesFlags {        // TODO: make this private
    unsigned int areNamesUnique:1;
    unsigned int haveNamesAlwaysBeenUnique:1;
} EndpointUniqueNamesFlags;

#endif