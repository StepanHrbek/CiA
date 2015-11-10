{*      MIDAS.PAS
 *
 * Simplified MIDAS Sound System API
 *
 * Copyright 1995 Petteri Kangaslampi and Jarno Paananen
 *
 * by D.Ment:
 *  SamplePlayer added (plays IFF/WAV of unlimited length)
 *  automatic midasSetDefaults and midasClose added
 *  Uses Crt removed (it does runtime error 200 on fast computers)
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*}


unit      MIDAS;
Interface {$i define.inc}
Uses      Objects,Strings,Chyby,Memo,Sys,Fajly, MPlayer,S3M,MODP,MTM;
Function  Init:TError;
Procedure Done;


{****************************************************************************\
*      MIDAS version defines
\****************************************************************************}

const
    MVERSTR : Pchar = '0.40a';
    MVERNUM : word = $0040;



{****************************************************************************\
*      MIDAS global variables:
\****************************************************************************}

const
    NUMSDEVICES = 5;                    { total number of Sound Devices }
    NUMMPLAYERS = 3;                    { total number of Module Players }

var
    midasSD : pointer;                  { pointer to current Sound Device }
    midasMP : pointer;                  { pointer to current Module Player }

var
    midasDisableEMS : integer;          { 1 if EMS usage is disabled
                                          (default 0) }
    midasSDNumber : integer;            { Sound Device number (-1 for
                                          autodetect, default -1) }
    midasSDPort : integer;              { Sound Device I/O port number
                                          (-1 for autodetect or SD default,
                                          default -1) }
    midasSDIRQ : integer;               { Sound Device IRQ number (-1 for
                                          autodetect or SD default,
                                          default -1) }
    midasSDDMA : integer;               { Sound Device DMA channel number
                                          (-1 for autodetect or SD default,
                                          default -1) }
    midasSDCard : integer;              { Sound Device sound card type
                                          (-1 for autodetect or SD default,
                                          default -1) }
    midasMixRate : word;                { Sound Device mixing rate }
    midasOutputMode : word;             { Sound Device output mode force
                                          bits, default 0 (SD default) }
    midasAmplification : integer;       { Forced amplification level or -1
                                          for SD default (default -1) }
    midasChannels : integer;            { number of channels open or 0 if no
                                          channels have been opened using
                                          midasOpenChannels() }
    midasPlayerNum : integer;           { timer music player number }

    midasEMSInit : integer;             { is EMS heap manager initialized? }
    midasTMRPlay : integer;             { is sound being played with timer? }
    midasSDInit : integer;              { is Sound Device initialized? }
    midasSDChans : integer;             { are Sound Device channels open? }
    midasMPInit : integer;              { is Module Player initialized? }
    midasMPPlay : integer;              { is Module Player playing? }
    midasTMRMusic : integer;            { is music being player with timer? }

const
    midasExts:array[0..NUMMPLAYERS-1] of string[3]=('S3M','MOD','MTM');
    midasPlayers:array[0..NUMMPLAYERS-1] of PModulePlayer=(@mpS3M,@mpMOD,@mpMTM);




{****************************************************************************\
*      MIDAS global functions:
\****************************************************************************}


{****************************************************************************\
*
* Function:     midasError(errNum : integer);
*
* Description:  Prints a MIDAS error message to stderr, uninitializes MIDAS
*               and exits to DOS
*
* Input:        errNum : integer        MIDAS error code
*
\****************************************************************************}

procedure midasError(errNum : integer);




{****************************************************************************\
*
* Function:     midasUninitError(errNum : integer);
*
* Description:  Prints an error message to stderr and exits to DOS without
*               uninitializing MIDAS. This function should only be used
*               from midasClose();
*
* Input:        errNum : integer        MIDAS error code
*
\****************************************************************************}

procedure midasUninitError(errNum : integer);



{****************************************************************************\
*
* Function:     midasDetectSD;
*
* Description:  Attempts to detect a Sound Device. Sets the global variable
*               midasSD to point to the detected Sound Device or NIL if no
*               Sound Device was detected
*
\****************************************************************************}

procedure midasDetectSD;



{****************************************************************************\
*
* Function:     midasInit;
*
* Description:  Initializes MIDAS Sound System
*
\****************************************************************************}

procedure midasInit;



{****************************************************************************\
*
* Function:     midasClose;
*
* Description:  Uninitializes MIDAS Sound System
*
\****************************************************************************}

procedure midasClose;



{****************************************************************************\
*
* Function:     midasSetDefaults;
*
* Description:  Initializes MIDAS Sound System variables to their default
*               states. MUST be the first MIDAS function to be called.
*
\****************************************************************************}

procedure midasSetDefaults;


{$IFNDEF NOLOADERS}


{****************************************************************************\
*
* Function:     function midasLoadModule(fileName : Pchar; MPl : pointer;
*                   SaveSampleInfo : pointer) : pointer;
*
* Description:  Loads a module file into memory.
*
* Input:        fileName : Pchar        Pointer to module file name
*               MPl : pointer           Pointer to the Module Player which
*                                       will be used for loading the module
*               int (*SaveSampleInfo)() Pointer to sample information saving
*                                       function. The function must have
*                                       identical calling convention with
*                                       vuPrepare(). NIL if no such function
*                                       is used.
*
* Returns:      Pointer to the loaded module structure
*
* Notes:        The only practical use at this point for SaveSampleInfo() are
*               the real VU-meters. To load a module and add the prepare the
*               VU meter information use:
*                   module := midasLoadModule(fileName, MP, @vuPrepare);
*               Note that the definition of SaveSampleInfo matches exactly
*               the prototype of vuPrepare().
*
\****************************************************************************}

function midasLoadModule(fileName : Pchar; MPl : pointer;
    SaveSampleInfo : pointer) : pointer;




{****************************************************************************\
*
* Function:     midasFreeModule(module : pointer);
*
* Description:  Deallocates a module from memory
*
* Input:        module : pointer        Pointer to module to be deallocated
*
\****************************************************************************}

procedure midasFreeModule(module : pointer);


{$ENDIF}



{****************************************************************************\
*
* Function:     midasOpenChannels(numChans : integer);
*
* Description:  Opens Sound Device channels for sound and music output.
*
* Input:        numChans : integer      Number of channels to open
*
* Notes:        Channels opened with this function can be used for sound
*               playing, and modules played with midasPlayModule() will be
*               played through the last of these channels. This function is
*               provided so that the same number of channels can be open
*               the whole time throughout the execution of the program,
*               keeping the volume level constant. Note that you must ensure
*               that you open enough channels for all modules, otherwise
*               midasPlayModule() will fail.
*
\****************************************************************************}

procedure midasOpenChannels(numChans : integer);



{****************************************************************************\
*
* Function:     midasCloseChannels;
*
* Description:  Closes Sound Device channels opened with midasOpenChannels().
*               Do NOT call this function unless you have opened the sound
*               channels used yourself with midasOpenChannels().
*
\****************************************************************************}

procedure midasCloseChannels;



{****************************************************************************\
*
* Function:     midasPlayModule(module : pointer; numEffectChns : integer);
*
* Description:  Loads a module into memory, points midasMP to the correct
*               Module Player and starts playing it.
*
* Input:        module : pointer        Module loaded with midasLoadModule()
*               numEffectChns : integer Number of channels to open for sound
*                                       effects. Ignored if sound channels
*                                       have already been opened with
*                                       midasOpenChannels().
*
* Returns:      Pointer to module structure. This function can not fail,
*               as it will call midasError() to handle all error cases.
*
* Notes:        The Sound Device channels available for sound effects are the
*               _first_ numEffectChns channels. So, for example, if you use
*               midasPlayModule(module, 3), you can use channels 0-2 for sound
*               effects. If you already have opened channels with
*               midasOpenChannels(), the module will be played with the last
*               possible channels, so that the first channels will be
*               available for sound effects. Note that if not enough channels
*               are open this function will fail.
*
\****************************************************************************}

procedure midasPlayModule(module : pointer; numEffectChns : integer);





{****************************************************************************\
*
* Function:     midasStopModule(module : pointer);
*
* Input:        module : pointer        the module which is being played
*
* Description:  Stops playing a module and uninitializes the Module Player.
*               If sound channels were NOT opened through midasOpenChannels(),
*               but by letting midasPlayModule() open them, they will be
*               closed. Sound channels opened with midasOpenChannels() are NOT
*               closed and must be closed separately.
*
\****************************************************************************}

procedure midasStopModule(module : pointer);




{****************************************************************************\
*
* SamplePlayer by D.Ment
*
\****************************************************************************}

procedure midasMasterVolume(vol:word);
function  midasLoadSample(sam:pointer;len:word;copysample:byte):word;
procedure midasSetRate(rate,channel:word);
function  midasChannelPlays(channel:word):boolean;
function  midasGetChannelPos(channel:word):word;
procedure midasPlaySample(channel,nophandle,handle,rate,volume:word);
procedure midasStopChannel(channel:word);
procedure midasRemoveSample(handle:word);

{
 TSamplePlayer cte data ze streamu a laduje je na zvukovy vystup.
 V Midasu 0.40 jde prehravat max 64K samply, proto musi vstup
 kouskovat a prehravat po blocich.
}
var   buf:pointer;
const bufsize=65520-16;{rezerva 16 kvuli midasu, 16 kvuli getmemu}

type  PSamplePlayer=^TSamplePlayer;
      TSamplePlayer=object(TPlayer)
        constructor   Init(achannel,avolume:word;astream:PStream;looping:boolean);
        procedure     SetVolume(avolume:word);
        function      Sync:boolean;virtual;
        function      GetLength:longint;
        destructor    Done;virtual;
       private
        zbyva         :longint;
        loopsize      :longint;
        rate          :word;
        channel       :word;
        volume        :word;
        flip          :boolean;
        samplehandle1 :word;
        samplehandle2 :word;
        god           :word;
        function      LoadMore:boolean;
        function      PlayMore:boolean;
      end;


implementation


{$IFNDEF __BPREAL__}
{$DEFINE NOEMS}
{$ENDIF}


uses dos, Errors, mGlobals, mMem, mFile, SDevice, Timer, DMA, DSM, mUtils
{$IFNDEF NOEMS}
    ,EMS
{$ENDIF}
    ;



{****************************************************************************\
*      Static variables used by midasXXXX() functions:
\****************************************************************************}

{ pointers to all Sound Devices: }
const
    midasSoundDevices : array[0..(NUMSDEVICES-1)] of PSoundDevice = (
        @GUS, @PAS, @WSS, @SB, @NSND );

var
    SD : PSoundDevice;                  { current Sound Device }
    MP : PModulePlayer;                 { current Module Player }




{****************************************************************************\
*
* Function:     midasError(errNum : integer);
*
* Description:  Prints a MIDAS error message to stderr, uninitializes MIDAS
*               and exits to DOS
*
* Input:        errNum : integer        MIDAS error code
*
\****************************************************************************}

procedure midasError(errNum : integer);
begin
 midasClose;
 erMsg(_(_erMidas)+' '+StrPas(errorMsg[errNum]));
end;




{****************************************************************************\
*
* Function:     midasUninitError(errNum : integer);
*
* Description:  Prints an error message to stderr and exits to DOS without
*               uninitializing MIDAS. This function should only be used
*               from midasClose();
*
* Input:        errNum : integer        MIDAS error code
*
\****************************************************************************}

procedure midasUninitError(errNum : integer);
begin
 erMsg(_(_erMidasFatal)+' '+StrPas(errorMsg[errNum]));
end;




{****************************************************************************\
*
* Function:     midasDetectSD;
*
* Description:  Attempts to detect a Sound Device. Sets the global variable
*               midasSD to point to the detected Sound Device or NIL if no
*               Sound Device was detected
*
\****************************************************************************}

procedure midasDetectSD;
var
    dsd, dResult, error : integer;
    sdev : PSoundDevice;
begin
    midasSD := NIL;                     { nothing detected yet }
    SD := NIL;
    dsd := 0;                           { start from first Sound Device }

    { search through Sound Devices until a Sound Device is detected: }
    while (midasSD = NIL) and (dsd < NUMSDEVICES) do
    begin
        { attempt to detect current SD: }
        sdev := midasSoundDevices[dsd];
        error := sdev^.Detect(@dResult);
        if error <> OK then
            midasError(error);
        if dResult = 1 then
        begin
            midasSDNumber := dsd;       { Sound Device detected }
            { point midasSD to this Sound Device: }
            midasSD := sdev;
            SD := sdev;
        end;
        dsd := dsd + 1;                 { try next Sound Device }
    end;
end;




{****************************************************************************\
*
* Function:     midasInit;
*
* Description:  Initializes MIDAS Sound System
*
\****************************************************************************}

procedure midasInit;
var
    result, error : integer;
begin
{$IFNDEF NOEMS}
    if midasDisableEMS = 0 then         { is EMS usage disabled? }
    begin
        { Initialize EMS Heap Manager: }
        error := emsInit(@midasEMSInit);
        if error <> OK then
            midasError(error);

        { was EMS Heap Manager initialized? }
        if midasEMSInit = 1 then
        begin
            useEMS := 1;                { yes, use EMS memory }
        end
        else
        begin
            useEMS := 0;                { no, do not use EMS memory }
        end;
    end
    else
    begin
        midasEMSInit := 0;
        useEMS := 0;                    { EMS disabled - do not use it }
    end;
{$ELSE}
    midasEMSInit := 0;
    useEMS := 0;
{$ENDIF}

    if midasSDNumber = -1 then          { has a Sound Device been selected? }
    begin
        midasDetectSD;                  { attempt to detect Sound Device }
        if SD = NIL then
            midasError(errSDFailure);
    end
    else
    begin
        { Use selected Sound Device: }
        midasSD := midasSoundDevices[midasSDNumber];
        SD := midasSD;

        { Sound Device number was forced, but if no I/O port, IRQ or DMA
          number has been set, try to autodetect the values for this Sound
          Device. If detection fails, use default values: }

        if (midasSDPort = -1) and (midasSDIRQ = -1) and (midasSDDMA = -1) then
        begin
            error := SD^.Detect(@result);
            if error <> OK then
                midasError(error);
        end;
    end;

    if midasSDPort <> -1 then           { has an I/O port been selected? }
        SD^.port := midasSDPort;        { if yes, set it to Sound Device }
    if midasSDIRQ <> -1 then            { SD IRQ number? }
        SD^.IRQ := midasSDIRQ;          { if yes, set it to Sound Device }
    if midasSDDMA <> -1 then            { SD DMA channel number? }
        SD^.DMA := midasSDDMA;
    if midasSDCard <> -1 then           { sound card type? }
        SD^.cardType := midasSDCard;

    { initialize Sound Device: }
    error := SD^.Init(midasMixRate, midasOutputMode);
    if error <> OK then
        midasError(error);
    midasSDInit := 1;                   { Sound Device initialized }

{$IFNDEF NOTIMER}
    { start playing sound using the timer: }
    error := tmrPlaySD(midasSD);
    if error <> OK then
        midasError(error);
    midasTMRPlay := 1;
{$ENDIF}
end;




{****************************************************************************\
*
* Function:     midasClose;
*
* Description:  Uninitializes MIDAS Sound System
*
\****************************************************************************}

procedure midasClose;
var
    error : integer;
begin
{$IFNDEF NOTIMER}
    { if music is being played with timer, stop it: }
    if midasTMRMusic <> 0 then
    begin
        error := MP^.SetUpdRateFunct(NIL);
        if error <> OK then
            midasUninitError(error);
        error := tmrStopMusic(midasPlayerNum);
        if error <> OK then
            midasUninitError(error);

        midasTMRMusic := 0;
    end;
{$ENDIF}

    { if Module Player is playing, stop it: }
    if midasMPPlay <> 0 then
    begin
        error := MP^.StopModule;
        if error <> OK then
            midasUninitError(error);
        midasMPPlay := 0;
    end;

    { if Module Player has been initialized, uninitialize it: }
    if midasMPInit <> 0 then
    begin
        error := MP^.Close;
        if error <> OK then
            midasUninitError(error);
        midasMPInit := 0;
        MP := NIL;
        midasMP := NIL;
    end;

    { if Sound Device channels are open, close them: }
    if midasSDChans <> 0 then
    begin
        error := SD^.CloseChannels;
        if error <> OK then
            midasUninitError(error);
        midasSDChans := 0;
        midasChannels := 0;
    end;

{$IFNDEF NOTIMER}
    { if sound is being played, stop it: }
    if midasTMRPlay <> 0 then
    begin
        error := tmrStopSD;
        if error <> OK then
            midasUninitError(error);
        midasTMRPlay := 0;
    end;
{$ENDIF}

    { if Sound Device is initialized, uninitialize it: }
    if midasSDInit <> 0 then
    begin
        error := SD^.Close;
        if error <> OK then
            midasUninitError(error);
        midasSDInit := 0;
        SD := NIL;
        midasMP := NIL;
    end;

{$IFNDEF NOEMS}
    { if EMS Heap Manager is initialized, uninitialize it: }
    if midasEMSInit <> 0 then
    begin
        error := emsClose;
        if error <> OK then
            midasUninitError(error);
        midasEMSInit := 0;
    end;
{$ENDIF}
end;




{****************************************************************************\
*
* Function:     midasSetDefaults;
*
* Description:  Initializes MIDAS Sound System variables to their default
*               states. MUST be the first MIDAS function to be called.
*
\****************************************************************************}

procedure midasSetDefaults;
begin
    midasEMSInit := 0;                  { EMS heap manager is not
                                           initialized yet }
    midasTMRPlay := 0;                  { Sound is not being played }
    midasSDInit := 0;                   { Sound Device is not initialized }
    midasSDChans := 0;                  { Sound Device channels are not
                                           open }
    midasMPInit := 0;                   { Module Player is not initialized }
    midasMPPlay := 0;                   { Module Player is not playing }
    midasTMRMusic := 0;                 { Music is not being played with
                                           timer }
    midasChannels := 0;                 { No channels opened }

    ptTempo := 1;                       { enable ProTracker BPM tempos }
    usePanning := 1;                    { enable ProTracker panning cmds }
    surround := 0;                      { disable surround to save GUS mem }
    extendedOctaves := 0;               { Disable extended octaves }
    useVDS := 1;                        { use VDS if found }

    midasDisableEMS := 0;               { do not disable EMS usage }
    midasSDNumber := -1;                { no Sound Device forced }
    midasSDPort := -1;                  { no I/O port forced }
    midasSDIRQ := -1;                   { no IRQ number forced }
    midasSDDMA := -1;                   { no DMA channel number forced }
    midasSDCard := -1;                  { no sound card type forced }
    midasOutputMode := 0;               { no output mode forced }
    midasMixRate := 44100;              { attempt to use 44100Hz mixing
                                          rate }
    midasAmplification := -1;           { use default amplification level }

    SD := NIL;                          { point SD and MP to NULL for }
    midasSD := NIL;                     { safety }
    MP := NIL;
    midasMP := NIL;
end;



{$IFNDEF NOLOADERS}



{****************************************************************************\
*
* Function:     function midasLoadModule(fileName : Pchar; MPl : pointer;
*                   SaveSampleInfo : pointer) : pointer;
*
* Description:  Loads a module file into memory.
*
* Input:        fileName : Pchar        Pointer to module file name
*               MPl : pointer           Pointer to the Module Player which
*                                       will be used for loading the module
*               int (*SaveSampleInfo)() Pointer to sample information saving
*                                       function. The function must have
*                                       identical calling convention with
*                                       vuPrepare(). NIL if no such function
*                                       is used.
*
* Returns:      Pointer to the loaded module structure
*
* Notes:        The only practical use at this point for SaveSampleInfo() are
*               the real VU-meters. To load a module and add the prepare the
*               VU meter information use:
*                   module = midasLoadModule(fileName, MP, &vuPrepare);
*               Note that the definition of SaveSampleInfo matches exactly
*               the prototype of vuPrepare().
*
\****************************************************************************}

function midasLoadModule(fileName : Pchar; MPl : pointer;
    SaveSampleInfo : pointer) : pointer;
var
    module : PmpModule;
    error : integer;
    MPlayr : PModulePlayer;
begin
    { load module: }
    MPlayr := MPl;
    error := MPlayr^.LoadModule(fileName, midasSD, SaveSampleInfo, @module);
    if error <> OK then
        midasError(error);

    midasLoadModule := module
end;




{****************************************************************************\
*
* Function:     midasFreeModule(module : pointer);
*
* Description:  Deallocates a module from memory
*
* Input:        module : pointer        Pointer to module to be deallocated
*
\****************************************************************************}

procedure midasFreeModule(module : pointer);
var
    MPlayr : PModulePlayer;
    error : integer;
    mpmod : PmpModule;
begin
    mpmod := module;
    MPlayr := mpmod^.MP;

    error := MPlayr^.FreeModule(module, midasSD);
    if error <> OK then
        midasError(error);
end;


{$ENDIF}



{****************************************************************************\
*
* Function:     midasOpenChannels(numChans : integer);
*
* Description:  Opens Sound Device channels for sound and music output.
*
* Input:        numChans : integer      Number of channels to open
*
* Notes:        Channels opened with this function can be used for sound
*               playing, and modules played with midasPlayModule() will be
*               played through the last of these channels. This function is
*               provided so that the same number of channels can be open
*               the whole time throughout the execution of the program,
*               keeping the volume level constant. Note that you must ensure
*               that you open enough channels for all modules, otherwise
*               midasPlayModule() will fail.
*
\****************************************************************************}

procedure midasOpenChannels(numChans : integer);
var
    error : integer;
begin
    midasChannels := numChans;

    { open Sound Device channels: }
    error := SD^.OpenChannels(numChans);
    if error <> OK then
        midasError(error);
    midasSDChans := 1;

    { set amplification level if forced: }
    if midasAmplification <> -1 then
    begin
        error := SD^.SetAmplification(midasAmplification);
        if error <> OK then
            midasError(error);
    end;
end;




{****************************************************************************\
*
* Function:     midasCloseChannels;
*
* Description:  Closes Sound Device channels opened with midasOpenChannels().
*               Do NOT call this function unless you have opened the sound
*               channels used yourself with midasOpenChannels().
*
\****************************************************************************}

procedure midasCloseChannels;
var
    error : integer;
begin
    { Close Sound Device channels: }
    error := SD^.CloseChannels;
    if error <> OK then
        midasError(error);
    midasSDChans := 0;
    midasChannels := 0;
end;




{****************************************************************************\
*
* Function:     midasPlayModule(module : pointer; numEffectChns : integer);
*
* Description:  Loads a module into memory, points midasMP to the correct
*               Module Player and starts playing it.
*
* Input:        module : pointer        Module loaded with midasLoadModule()
*               numEffectChns : integer Number of channels to open for sound
*                                       effects. Ignored if sound channels
*                                       have already been opened with
*                                       midasOpenChannels().
*
* Returns:      Pointer to module structure. This function can not fail,
*               as it will call midasError() to handle all error cases.
*
* Notes:        The Sound Device channels available for sound effects are the
*               _first_ numEffectChns channels. So, for example, if you use
*               midasPlayModule(module, 3), you can use channels 0-2 for sound
*               effects. If you already have opened channels with
*               midasOpenChannels(), the module will be played with the last
*               possible channels, so that the first channels will be
*               available for sound effects. Note that if not enough channels
*               are open this function will fail.
*
\****************************************************************************}

procedure midasPlayModule(module : pointer; numEffectChns : integer);
var
    numChans, error, firstChannel : integer;
    mpmod : PmpModule;
begin
    mpmod := module;
    midasMP := mpmod^.MP;
    MP := midasMP;

    { initialize module player: }
    error := MP^.Init(midasSD);
    if error <> OK then
        midasError(error);
    midasMPInit := 1;

    numChans := mpmod^.numChans;

    { Open Sound Device channels if not already open: }
    if midasChannels = 0 then
    begin
        error := SD^.OpenChannels(numChans + numEffectChns);
        if error <> OK then
            midasError(error);
        midasSDChans := 1;
        firstChannel := numEffectChns;

        { set amplification level if forced: }
        if midasAmplification <> -1 then
        begin
            error := SD^.SetAmplification(midasAmplification);
            if error <> OK then
                midasError(error);
        end;
    end
    else
    begin
        if midasChannels < numChans then
            midasError(errNoChannels);
        firstChannel := midasChannels - numChans;
    end;

    { Start playing the module using the last Sound Device channels and
      looping the whole song: }
    error := MP^.PlayModule(module, firstChannel, numChans, 0, 32767);
    if error <> OK then
        midasError(error);
    midasMPPlay := 1;

{$IFNDEF NOTIMER}
    { start playing using the timer: }
    error := tmrPlayMusic(@MP^.Play, @midasPlayerNum);
    if error <> OK then
        midasError(error);
    error := MP^.SetUpdRateFunct(@tmrSetUpdRate);
    if error <> OK then
        midasError(error);

    midasTMRMusic := 1;
{$ENDIF}
end;





{****************************************************************************\
*
* Function:     midasStopModule(module : pointer);
*
* Input:        module : pointer        the module which is being played
*
* Description:  Stops playing a module and uninitializes the Module Player.
*               If sound channels were NOT opened through midasOpenChannels(),
*               but by letting midasPlayModule() open them, they will be
*               closed. Sound channels opened with midasOpenChannels() are NOT
*               closed and must be closed separately.
*
\****************************************************************************}

procedure midasStopModule(module : pointer);
var
    error, i : integer;
    mpmod : PmpModule;
begin
    mpmod := module;
    midasMP := mpmod^.MP;
    MP := mpmod^.MP;

{$IFNDEF NOTIMER}
    { Stop playing music with timer: }
    error := MP^.SetUpdRateFunct(NIL);
    if error <> OK then
        midasError(error);
    error := tmrStopMusic(midasPlayerNum);
    if error <> OK then
        midasError(error);

    midasTMRMusic := 0;
{$ENDIF}

    { stop playing the module: }
    error := MP^.StopModule;
    if error <> OK then
        midasError(error);
    midasMPPlay := 0;

    { uninitialize Module Player: }
    error := MP^.Close;
    if error <> OK then
        midasError(error);
    midasMPInit := 0;
    midasMP := NIL;                     { point midasMP to NULL for safety }

    { If Sound Device channels were not opened with midasOpenChannels(),
      close them: }
    if midasChannels = 0 then
    begin
        error := SD^.CloseChannels;
        if error <> OK then
            midasError(error);
        midasSDChans := 0;
    end
    else
    begin
        { Sound Device channels were originally opened with
          midasOpenChannels(). Now stop sounds from the channels used by
          the Module Player: }
        for i := (midasChannels - mpmod^.numChans) to (midasChannels - 1) do
        begin
            error := SD^.StopSound(i);
            if error <> OK then
                midasError(error);
            error := SD^.SetVolume(i, 0);
            if error <> OK then
                midasError(error);
        end;
    end;
end;


{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ Pridana drobotina ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

procedure check(error:integer);
begin
 if error<>0 then midasError(error);
end;

procedure midasMastervolume(vol:word);
begin
 if vol>63 then vol:=63;
 if midasMPplay<>0 then mp^.setmastervolume(vol);
end;

function midasLoadSample(sam:pointer;len:word;copysample:byte):word;
var handle:word;
begin
 if SD<>nil then begin
   check(SD^.AddInstrument(sam,smp8bit,len,0{loopstart},0{loopend},64{vol},0{loop},copysample,@handle));
   midasLoadsample:=handle;
   end
 else
   midasLoadsample:=0;
end;

procedure midasPlaySample(channel,nophandle,handle,rate,volume:word);
begin
 if SD<>nil then begin
   {tohle dela jen kvuli Gravisovi}
   if midasSDnumber=0{gus} then begin
     check(SD^.SetInstrument(channel,nopHandle));
     end;
   check(SD^.StopSound(channel));

   check(SD^.SetInstrument(channel,handle));
   check(SD^.SetVolume(channel,minW(volume,64)));
   check(SD^.PlaySound(channel,rate));
   end;
end;

procedure midasSetVolume(channel,volume:word);
begin
 if SD<>nil then check(SD^.SetVolume(channel,volume));
end;

procedure midasSetRate(rate,channel:word);
begin
 if SD<>nil then check(SD^.SetRate(channel,rate));
end;

function midasChannelPlays(channel:word):boolean;
var l:longint;
begin
 midasChannelPlays:=false;
 if SD<>nil then begin
   check(SD^.getrate(channel,@l));
   midasChannelPlays:=l<>0;
   end;
end;

{na gusovi 0=nehraje, na ostatnich po dohrani zustane pos na konci samplu}
function midasGetChannelPos(channel:word):word;
var p:word;
begin
 p:=0;
 if SD<>nil then check(SD^.getposition(channel,@p));
 midasGetChannelPos:=p;
end;

procedure midasStopChannel(channel:word);
begin
 if SD<>nil then begin
   check(SD^.StopSound(channel));
   check(SD^.SetVolume(channel,0));
   end;
end;

procedure midasRemoveSample(handle:word);
begin
 if SD<>nil then check(SD^.RemInstrument(handle));
end;


{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ SamplePlayer ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

{---------------------------------------------------------------------------
 Zacne hrat sampl ze zadaneho souboru.
 Channel musi byt v dobe inicializace volny.
 ---------------------------------------------------------------------------}
Constructor TSamplePlayer.Init(achannel,avolume:word;astream:PStream;looping:boolean);
var   iff:array[1..78] of byte;
      wavd:array[0..10] of longint absolute iff;
      wavw:array[0..21] of word absolute wavd;
begin
 if (SD=nil) or (midasSDnumber=4){nosound} then Fail;
 if not inherited Init(astream) then Fail;
 channel:=achannel;
 volume:=avolume;
 {zjisti format samplu (zbyva, rate, flip)}
 stream^.Read(wavD,4);
 if wavD[0]=MakeLong(MakeWord(ord('F'),ord('F')),MakeWord(ord('I'),ord('R'))) then begin
   stream^.Read(wavd[1],sizeof(wavd)-4);
   zbyva:=wavd[10];
   if (wavw[10]<>1) or (wavw[11]<>1) then
    if dumb then Fail
     else erMsg(_(_erNeni8bitMono));
   rate:=wavw[12];
   {if (wavw[15] and $fff0)=$abc0 then vol:=wavw[15] and $f;}
   flip:=false;
   end else
 if wavd[0]=MakeLong(MakeWord(ord('M'),ord('R')),MakeWord(ord('O'),ord('F'))) then begin
   stream^.Read(iff[5],sizeof(iff)-4);
   zbyva:=MakeLong(MakeWord(iff[75],iff[76]),MakeWord(iff[77],iff[78]));
   rate:=MakeWord(iff[63],iff[64]);
   flip:=true;
   end
 else begin
   zbyva:=1000000000;
   rate:=11000;
   flip:=false;
   end;
 zbyva:=minL(zbyva,stream^.GetSize-stream^.GetPos);
 if looping then loopsize:=zbyva else loopsize:=0;
 {natahne prvni blok, playne ho a natahne dalsi}
 if not LoadMore or not PlayMore then begin
   Done;
   Fail;
   end;
end;

{---------------------------------------------------------------------------
 Loadne dalsi blok do sample2, vraci uspesnost.
 Kdyz dojde na konec streamu, zrusi ho.
 Volat jen kdyz je sample2 prazdny.
 ---------------------------------------------------------------------------}
Function TSamplePlayer.LoadMore:boolean;
var   blocksize:word;
begin
 LoadMore:=false;
 if stream<>nil then begin
   blocksize:=minL(bufsize,zbyva);
   if blocksize>0 then begin
     stream^.Read(buf^,blocksize);
     dec(zbyva,blocksize);
     if flip then asm les si,buf;mov al,80h;mov cx,blocksize;@1:xor [es:si],al;inc si;loop @1;end;
     samplehandle2:=midasLoadSample(buf,blocksize,1{copy});
     LoadMore:=true;
     end;
   if zbyva=0 then
    if loopsize=0 then KillObj(stream) else begin
      stream^.Seek(stream^.GetPos-loopsize);
      zbyva:=loopsize;
      end;
   end;
end;

{---------------------------------------------------------------------------
 Playne sample2, presune ho do sample1, do sample2 natahne dalsi blok.
 Volat jen kdyz nic nehraje.
 Vraci jestli se podarilo zacit zas hrat (sample2 byl pripraven).
 ---------------------------------------------------------------------------}
Function TSamplePlayer.PlayMore:boolean;
var   b:boolean;
begin
 PlayMore:=samplehandle2<>0;
 if samplehandle2<>0 then midasPlaySample(channel,1,samplehandle2,rate,volume);
 if samplehandle1<>0 then midasRemoveSample(samplehandle1);
 samplehandle1:=samplehandle2;
 samplehandle2:=0;
 LoadMore;
end;

{---------------------------------------------------------------------------
 Synchronizace. Vraci jestli uz s hranim skoncil a lze zavolat Done.
 ---------------------------------------------------------------------------}
Function TSamplePlayer.Sync:boolean;
begin
 Sync:=not midasChannelPlays(channel) and not PlayMore;
end;

{---------------------------------------------------------------------------
 Vraci zhruba kolik sekund jeste bude hrat.
 ---------------------------------------------------------------------------}
Function TSamplePlayer.GetLength:longint;
begin
 if stream=nil then GetLength:=1
  else GetLength:=1+zbyva div rate;
end;

{---------------------------------------------------------------------------
 Nastavi hlasitost.
 ---------------------------------------------------------------------------}
Procedure TSamplePlayer.SetVolume(avolume:word);
begin
 volume:=avolume;
 midasSetVolume(channel,volume);
end;

{---------------------------------------------------------------------------
 Vypne kanal, uvolni samply.
 ---------------------------------------------------------------------------}
Destructor TSamplePlayer.Done;
begin
 midasStopChannel(channel);
 if samplehandle1<>0 then midasRemoveSample(samplehandle1);
 if samplehandle2<>0 then midasRemoveSample(samplehandle2);
 inherited Done;
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='midas';
var result:TError;

procedure UserInit;
 begin
  MidasSetDefaults;
  if not GetMem(buf,bufsize) then begin result:=erLowMem;exit;end;
  fileRegister('WAV',isPlayable+isSound+isSample);
  fileRegister('IFF',isPlayable+isSound+isSample);
  fileRegister('RAW',isPlayable+isSound+isSample);
  fileRegister('MOD',isPlayable+isSound+isModule);
  fileRegister('MTM',isPlayable+isSound+isModule);
  fileRegister('S3M',isPlayable+isSound+isModule);
 end;

procedure UserDone;
 begin
  FreeMem(buf,bufsize);
  MidasClose;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.