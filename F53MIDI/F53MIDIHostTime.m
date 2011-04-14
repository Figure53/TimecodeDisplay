/**

 @author  Kurt Revis
 @file    F53MIDIHostTime.m

 Copyright (c) 2002-2006, Kurt Revis.  All rights reserved.
 Copyright (c) 2006-2011, Figure 53.
 
 NOTE: F53MIDI is an appropriation of Kurt Revis's SnoizeMIDI. https://github.com/krevis/MIDIApps
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Kurt Revis, nor Snoize, nor the names of other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
**/


#import "F53MIDIHostTime.h"

#include <mach/mach_time.h>


static int isInited = 0;
static Float64 nanoRatio;

static void InitHostTime()
{
    struct mach_timebase_info info;
    
    mach_timebase_info(&info);
    nanoRatio = (double)info.numer / (double)info.denom;
    
    isInited = 1;
}

MIDITimeStamp F53MIDIGetCurrentHostTime()
{
    return mach_absolute_time();
}

UInt64 F53MIDIConvertHostTimeToNanos(MIDITimeStamp hostTime)
{
    if (!isInited)
        InitHostTime();
    return (UInt64)(hostTime * nanoRatio);
}

MIDITimeStamp F53MIDIConvertNanosToHostTime(UInt64 nanos)
{
    if (!isInited)
        InitHostTime();
    return (UInt64)(nanos / nanoRatio);
}
