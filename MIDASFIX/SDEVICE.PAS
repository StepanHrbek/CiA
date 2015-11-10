{*      SDEVICE.PAS
 *
 * Sound Device definitions
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

unit    SDevice;

{$ifdef dpmi}
 {$define __BPPROT__}
{$else}
 {$define __BPREAL__}
{$endif}

interface


const
    SMPMAX = 65519;                     { max sample length (65536-16 - 1) }
    MAXINSTS = 256;                     { maximum number of instruments }



{****************************************************************************\
*       enum smpTypes
*       -------------
* Description:  Sample types
\****************************************************************************}

const
    smpNone = 0;                        { no sample }
    smp8bit = 1;                        { 8-bit unsigned sample }



{****************************************************************************\
*       enum sdPanning
*       --------------
* Description:  Sound Device panning values. Legal values range from
*               panLeft to panRight, in steps of 1, plus panSurround.
*               Surround sound is played from middle if surround is not
*               enabled.
\****************************************************************************}

const
    panLeft = -64;                      { left speaker }
    panMiddle = 0;                      { middle (both speakers) }
    panRight = 64;                      { right speaker }
    panSurround = $80;                  { surround sound }




{****************************************************************************\
*       enum sdSmpPos
*       -------------
* Description:  Sample positions in memory
\****************************************************************************}

const
    sdSmpNone = 0;                  { no sample }
    sdSmpConv = 1;                  { conventional memory }
    sdSmpEMS = 2;                   { EMS }



{****************************************************************************\
*       enum sdStatus
*       -------------
* Description:  SoundDevice status
\****************************************************************************}

const
    sdUnInitialized = 0;
    sdOK = 1;



{****************************************************************************\
*       enum sdMode
*       -----------
* Description:  Possible SoundDevice output modes
\****************************************************************************}

const
    sdMono = 1;                         { mono }
    sdStereo = 2;                       { stereo }

    sd8bit = 4;                         { 8-bit output }
    sd16bit = 8;                        { 16-bit output }



{****************************************************************************\
*       enum sdConfigBits
*       -----------------
* Description:  Sound Device configuration information bits
\****************************************************************************}

const
    sdUsePort = 1;                      { SD uses an I/O port }
    sdUseIRQ = 2;                       { SD uses an IRQ }
    sdUseDMA = 4;                       { SD uses a DMA channel }
    sdUseMixRate = 8;                   { SD uses the set mixing rate }
    sdUseOutputMode = 16;               { SD uses the set output mode }
    sdUseDSM = 32;                      { SD uses software mixing (DSM) }


{****************************************************************************\
*       struct SoundDevice
*       ------------------
* Description:  SoundDevice structure. See SDEVICE.TXT for documentation
\****************************************************************************}

    { Sound Device function pointer types: }
type
    Pinteger = ^integer;
    Pbyte = ^byte;
    Pword = ^word;
    Plongint = ^longint;

    sdDetect = function(result : Pinteger) : integer;
    sdInit = function(mixRate, mode : word) : integer;
    sdClose = function : integer;
    sdGetMixRate = function(mixRate : Pword) : integer;
    sdGetMode = function(mode : Pword) : integer;
    sdOpenChannels = function(channels : word) : integer;
    sdCloseChannels = function : integer;
    sdClearChannels = function : integer;
    sdMute = function(mute : integer) : integer;
    sdPause = function(pause : integer) : integer;
    sdSetMasterVolume = function(masterVolume : byte) : integer;
    sdGetMasterVolume = function(masterVolume : Pbyte) : integer;
    sdSetAmplification = function(amplification : word) : integer;
    sdGetAmplification = function(amplification : Pword) : integer;
    sdPlaySound = function(channel : word; rate : longint) : integer;
    sdStopSound = function(channel : word) : integer;
    sdSetRate = function(channel : word; rate : longint) : integer;
    sdGetRate = function(channel : word; rate : Plongint) : integer;
    sdSetVolume = function(channel : word; volume : byte) : integer;
    sdGetVolume = function(channel : word; volume : Pbyte) : integer;
    sdSetInstrument = function(channel : word; inst : word) : integer;
    sdGetInstrument = function(channel : word; inst : Pword) : integer;
    sdSetPosition = function(channel : word; pos : word) : integer;
    sdGetPosition = function(channel : word; pos : Pword) : integer;
    sdSetPanning = function(channel : word; panning : integer) : integer;
    sdGetPanning = function(channel : word; panning : Pinteger) : integer;
    sdMuteChannel = function(channel : word; mute : integer) : integer;
    sdAddInstrument = function(sample : pointer; smpType : integer;
        length, loopStart, loopEnd : word; volume : byte; loop : integer;
        copySample : integer; instHandle : Pword) : integer;
    sdRemInstrument = function(inst : word) : integer;
    sdSetUpdRate = function(updRate : word) : integer;
    sdStartPlay = function : integer;
    sdPlay = function(callMP : Pinteger) : integer;

    PcharArray = array[0..1023] of Pchar;
    PPcharArray = ^PcharArray;


    { actual Sound Device structure: }

    SoundDevice = Record
        tempoPoll : word;
        configBits : word;              { Configuration info bits. See enum
                                          sdConfigBits. }
        port : word;                    { Sound Device I/O port address }
        IRQ : byte;                     { Sound Device IRQ number }
        DMA : byte;                     { Sound Device DMA channel number }
        cardType : word;                { Sound Device sound card type.
                                          Starting from 1, 0 means
                                          autodetect }
        numCardTypes : word;            { number of different sound card
                                          types for this Sound Device }
        status : word;                  { Sound Device status }
        modes : word;                   { Possible modes for this SD,
                                          see enum sdMode }
        ID : Pchar;                     { pointer Sound Device ID string }
        cardNames : PPcharArray;        { pointer to an array of pointers to
                                          sound card name strings }
        numPortAddresses : word;        { number of possible port
                                          addresses in table }
        portAddresses : Pword;          { pointer to an array of possible
                                          I/O port addresses }

        Detect : sdDetect;
        Init : sdInit;
        Close : sdClose;
        GetMixRate : sdGetMixRate;
        GetMode : sdGetMode;
        OpenChannels : sdOpenChannels;
        CloseChannels : sdCloseChannels;
        ClearChannels : sdClearChannels;
        Mute : sdMute;
        Pause : sdPause;
        SetMasterVolume : sdSetMasterVolume;
        GetMasterVolume : sdGetMasterVolume;
        SetAmplification : sdSetAmplification;
        GetAmplification : sdGetAmplification;
        PlaySound : sdPlaySound;
        StopSound : sdStopSound;
        SetRate : sdSetRate;
        GetRate : sdGetRate;
        SetVolume : sdSetVolume;
        GetVolume : sdGetVolume;
        SetInstrument : sdSetInstrument;
        GetInstrument : sdGetInstrument;
        SetPosition : sdSetPosition;
        GetPosition : sdGetPosition;
        SetPanning : sdSetPanning;
        GetPanning : sdGetPanning;
        MuteChannel : sdMuteChannel;
        AddInstrument : sdAddInstrument;
        RemInstrument : sdRemInstrument;
        SetUpdRate : sdSetUpdRate;
        StartPlay : sdStartPlay;
        Play : sdPlay;
    end;

    PSoundDevice = ^SoundDevice;




{****************************************************************************\
*       SoundDevice structures for all Sound Devices:
\****************************************************************************}

{* Note! This SHOULD NOT be here, but Borland Pascal does not allow
 * external variables in data segment. Sheesh. Can a language really
 * be this stupid?
*}

var
    GUS : SoundDevice;
    PAS : SoundDevice;
    WSS : SoundDevice;
    SB : SoundDevice;
    NSND : SoundDevice;


implementation


USES  Errors, mMem, mUtils, mGlobals, DMA, DSM
{$IFDEF __BPPROT__}
     ,DPMI
{$ENDIF}
     ;


procedure gusSD; external;
{$L GUS.OBJ}
procedure pasSD; external;
{$L PAS.OBJ}
procedure wssSD; external;
{$L WSS.OBJ}
procedure sbSD; external;
{$L SB.OBJ}
procedure nsndSD; external;
{$L NSND.OBJ}


BEGIN
    mMemCopy(@GUS, @gusSD, SizeOf(SoundDevice));
    mMemCopy(@PAS, @pasSD, SizeOf(SoundDevice));
    mMemCopy(@WSS, @wssSD, SizeOf(SoundDevice));
    mMemCopy(@SB, @sbSD, SizeOf(SoundDevice));
    mMemCopy(@NSND, @nsndSD, SizeOf(SoundDevice))
END.
