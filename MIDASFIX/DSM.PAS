{*      DSM.PAS
 *
 * Digital Sound Mixer, v1.24
 *
 * Copyright 1995 Petteri Kangaslampi and Jarno Paananen
 *
 * by D.Ment:
 *  $ifdef dpmi... added to allow compilation in IDE
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*}


unit DSM;

{$ifdef dpmi}
 {$define __BPPROT__}
{$else}
 {$define __BPREAL__}
{$endif}

interface


const
    VOLLEVELS = 33;
    VOLSHIFT = 1;



{****************************************************************************\
*       struct dsmChannel
*       -----------------
* Description:  DSM channel data
\****************************************************************************}

type
    dsmChannel = Record
        pos : word;                     { mixing position }
        posl : word;                    { mixing position fraction }
        rate : longint;                 { playing rate in Hz }
        inst : word;                    { instrument number }
        sample : pointer;               { current sample data }
        smpType : byte;                 { current sample type }
        smpPos : byte;                  { current sample position }
        slength : word;                 { current sample length }
        loopStart : word;               { current sample loop start }
        loopEnd : word;                 { current sample loop end }
        looping : byte;                 { 1 if current sample is looping }
        instChanged : byte;             { 1 if instrument has been changed
                                          (Amiga Loop Emulation) }
        panning : byte;                 { panning information }
        volume : byte;                  { playing volume (0-64) }
        muted : byte;                   { 1 if channel muted, 0 if not }
        hasData : byte;                 { 1 if channel has data to be played,
                                          0 if not }
    end;



{****************************************************************************\
*       struct dsmInstrument
*       --------------------
* Description:  DSM internal instrument structure
\****************************************************************************}

type
    dsmInstrument = Record
        sample : pointer;                   { pointer to sample data }
        smpType : byte;                     { sample type }
        smpPos : byte;                      { sample position. see enum
                                              dsmSmpPos }
        slength : word;                     { sample length }
        loopStart : word;                   { sample loop start }
        loopEnd : word;                     { sample loop end }
        volume : byte;                      { default playing volume }
        looping : byte;                     { 1 if looping sample, 0 if not }
        inuse : byte;                       { 1 if sample is in use, 0 if not
                                            (removed using dsmRemInstrument) }
        copied : byte;                      { 1 if a copied sample (should be
                                              deallocated), 0 if not }
    end;


{****************************************************************************\
*      DSM functions. See documentation on Sound Device member functions
\****************************************************************************}

type
    Pinteger = ^integer;
    Pword = ^word;
    Pbyte = ^byte;
    Plongint = ^longint;

function dsmInit(mixRate, mode : word; mixBuffer : pointer;
    mixBufferSize : word) : integer;
function dsmClose : integer;
function dsmGetMixRate(mixRate : Pword) : integer;
function dsmGetMode(mode : Pword) : integer;
function dsmOpenChannels(channels : word) : integer;
function dsmCloseChannels : integer;
function dsmClearChannels : integer;
function dsmMute(mute : integer) : integer;
function dsmPause(pause : integer) : integer;
function dsmSetMasterVolume(masterVolume : byte) : integer;
function dsmGetMasterVolume(masterVolume : Pbyte) : integer;
function dsmSetAmplification(amplification : word) : integer;
function dsmGetAmplification(amplification : Pword) : integer;
function dsmPlaySound(channel : word; rate : longint) : integer;
function dsmStopSound(channel : word) : integer;
function dsmSetRate(channel : word; rate : longint) : integer;
function dsmGetRate(channel : word; rate : Plongint) : integer;
function dsmSetVolume(channel : word; volume : byte) : integer;
function dsmGetVolume(channel : word; volume : Pbyte) : integer;
function dsmSetInstrument(channel : word; inst : word) : integer;
function dsmGetInstrument(channel : word; inst : Pword) : integer;
function dsmSetPosition(channel : word; pos : word) : integer;
function dsmGetPosition(channel : word; pos : Pword) : integer;
function dsmSetPanning(channel : word; panning : integer) : integer;
function dsmGetPanning(channel : word; panning : Pinteger) : integer;
function dsmMuteChannel(channel : word; mute : integer) : integer;
function dsmAddInstrument(sample : pointer; smpType : integer;
    length, loopStart, loopEnd : word; volume : byte; loop : integer;
    instHandle : Pword) : integer;
function dsmRemInstrument(inst : word) : integer;
function dsmSetUpdRate(updRate : word) : integer;
function dsmSetPlayPos(playPosition : word) : integer;
function dsmPlay(callMP : Pinteger) : integer;
function dsmCalcVolTable(amplification : word) : integer;
{$IFNDEF CUTDOWN}
function dsmGetMainVU(leftVU : Pword; rightVU : Pword) : integer;
{$ENDIF}




implementation

{$IFNDEF __BPREAL__}
{$DEFINE NOEMS}
{$ENDIF}


uses Errors, mGlobals, mMem
{$IFNDEF NOEMS}
     ,EMS
{$ENDIF}
{$IFDEF __BPPROT__}
     ,DPMI
{$ENDIF}
     ;


function dsmInit(mixRate, mode : word; mixBuffer : pointer;
    mixBufferSize : word) : integer; external;
function dsmClose : integer; external;
function dsmGetMixRate(mixRate : Pword) : integer; external;
function dsmGetMode(mode : Pword) : integer; external;
function dsmOpenChannels(channels : word) : integer; external;
function dsmCloseChannels : integer; external;
function dsmClearChannels : integer; external;
function dsmMute(mute : integer) : integer; external;
function dsmPause(pause : integer) : integer; external;
function dsmSetMasterVolume(masterVolume : byte) : integer; external;
function dsmGetMasterVolume(masterVolume : Pbyte) : integer; external;
function dsmSetAmplification(amplification : word) : integer; external;
function dsmGetAmplification(amplification : Pword) : integer; external;
function dsmPlaySound(channel : word; rate : longint) : integer; external;
function dsmStopSound(channel : word) : integer; external;
function dsmSetRate(channel : word; rate : longint) : integer; external;
function dsmGetRate(channel : word; rate : Plongint) : integer; external;
function dsmSetVolume(channel : word; volume : byte) : integer; external;
function dsmGetVolume(channel : word; volume : Pbyte) : integer; external;
function dsmSetInstrument(channel : word; inst : word) : integer; external;
function dsmGetInstrument(channel : word; inst : Pword) : integer; external;
function dsmSetPosition(channel : word; pos : word) : integer; external;
function dsmGetPosition(channel : word; pos : Pword) : integer; external;
function dsmSetPanning(channel : word; panning : integer) : integer; external;
function dsmGetPanning(channel : word; panning : Pinteger) : integer;
    external;
function dsmMuteChannel(channel : word; mute : integer) : integer; external;
function dsmAddInstrument(sample : pointer; smpType : integer;
    length, loopStart, loopEnd : word; volume : byte; loop : integer;
    instHandle : Pword) : integer; external;
function dsmRemInstrument(inst : word) : integer; external;
function dsmSetUpdRate(updRate : word) : integer; external;
function dsmSetPlayPos(playPosition : word) : integer; external;
function dsmPlay(callMP : Pinteger) : integer; external;
function dsmCalcVolTable(amplification : word) : integer; external;
{$IFNDEF CUTDOWN}
function dsmGetMainVU(leftVU : Pword; rightVU : Pword) : integer; external;
{$ENDIF}

{$L DSM.OBJ}


END.
