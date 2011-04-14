/**

 @author  Kurt Revis
 @file    F53MIDIDestinationEndpoint.m

 Copyright (c) 2002-2006, Kurt Revis. All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/

#import "F53MIDIDestinationEndpoint.h"

#import "F53MIDIClient.h"
#import "F53MIDIObject-Private.h"


@implementation F53MIDIDestinationEndpoint

static EndpointUniqueNamesFlags _destinationEndpointUniqueNamesFlags = { YES, YES };

#pragma mark -
#pragma mark F53MIDIObject required overrides

+ (MIDIObjectType) midiObjectType
{
    return kMIDIObjectType_Destination;
}

+ (ItemCount) midiObjectCount
{
    return MIDIGetNumberOfDestinations();
}

+ (MIDIObjectRef) midiObjectAtIndex: (ItemCount) index
{
    return MIDIGetDestination(index);
}

#pragma mark -
#pragma mark F53MIDIEndpoint required overrides

+ (EndpointUniqueNamesFlags *) endpointUniqueNamesFlagsPtr
{
    return &_destinationEndpointUniqueNamesFlags;
}

+ (ItemCount) endpointCountForEntity: (MIDIEntityRef) entity
{
    return MIDIEntityGetNumberOfDestinations(entity);
}

+ (MIDIEndpointRef) endpointRefAtIndex: (ItemCount) index forEntity: (MIDIEntityRef) entity
{
    return MIDIEntityGetDestination(entity, index);
}

#pragma mark -
#pragma mark New methods

+ (NSArray *) destinationEndpoints
{
    return [self allObjectsInOrder];
}

+ (F53MIDIDestinationEndpoint *) destinationEndpointWithUniqueID: (MIDIUniqueID) aUniqueID
{
    return (F53MIDIDestinationEndpoint *)[self objectWithUniqueID:aUniqueID];
}

+ (F53MIDIDestinationEndpoint *) destinationEndpointWithName: (NSString *) aName
{
    return (F53MIDIDestinationEndpoint *)[self objectWithName:aName];
}

+ (F53MIDIDestinationEndpoint *) destinationEndpointWithEndpointRef: (MIDIEndpointRef) anEndpointRef
{
    return (F53MIDIDestinationEndpoint *)[self objectWithObjectRef:(MIDIObjectRef)anEndpointRef];
}

///
///  If newUniqueID is 0, we'll use the unique ID that CoreMIDI generates for us.
///
+ (F53MIDIDestinationEndpoint *) createVirtualDestinationEndpointWithName: (NSString *) endpointName readProc: (MIDIReadProc) readProc readProcRefCon: (void *) readProcRefCon uniqueID: (MIDIUniqueID) newUniqueID
{
    F53MIDIClient *client = [F53MIDIClient sharedClient];
    OSStatus status;
    MIDIEndpointRef newEndpointRef;
    BOOL wasPostingExternalNotification;
    F53MIDIDestinationEndpoint *endpoint;
    
    // We are going to be making a lot of changes, so turn off external notifications
    // for a while (until we're done).  Internal notifications are still necessary and aren't very slow.
    wasPostingExternalNotification = [client postsExternalSetupChangeNotification];
    [client setPostsExternalSetupChangeNotification:NO];
    
    status = MIDIDestinationCreate([client midiClient], (CFStringRef)endpointName, readProc, readProcRefCon, &newEndpointRef);
    if (status)
        return nil;
    
    // We want to get at the new F53MIDIEndpoint immediately.
    // CoreMIDI will send us a notification that something was added, and then we will create an F53MIDISourceEndpoint.
    // However, the notification from CoreMIDI is posted in the run loop's main mode, and we don't want to wait for it to be run.
    // So we need to manually add the new endpoint, now.
    endpoint = (F53MIDIDestinationEndpoint *)[self immediatelyAddObjectWithObjectRef:newEndpointRef];    
    if (!endpoint) {
        NSLog(@"%@ couldn't find its virtual endpoint after it was created", NSStringFromClass(self));
        return nil;
    }
    
    [endpoint setIsOwnedByThisProcess];
    
    if (newUniqueID != 0) 
        [endpoint setUniqueID:newUniqueID];
    if ([endpoint uniqueID] == 0) {
        // CoreMIDI didn't assign a unique ID to this endpoint, so we should generate one ourself
        BOOL success = NO;
        
        while (!success) 
            success = [endpoint setUniqueID:[F53MIDIObject generateNewUniqueID]];
    }
    
    [endpoint setManufacturerName:@"Figure 53"];
    
    // Do this before the last modification, so one setup change notification will still happen
    [client setPostsExternalSetupChangeNotification:wasPostingExternalNotification];
    
    [endpoint setModelName:[client name]];
    
    return endpoint;
}

+ (void) flushOutputForAllDestinationEndpoints
{
    MIDIFlushOutput(NULL);
}

- (void) flushOutput
{
    MIDIFlushOutput((MIDIEndpointRef)_objectRef);
}

@end
