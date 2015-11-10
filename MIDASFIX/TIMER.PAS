{*      TIMER.PAS
 *
 * TempoTimer, v1.20
 *
 * Copyright 1995 Petteri Kangaslampi and Jarno Paananen
 *
 * by D.Ment:
 *  automatic tmrInit and tmrClose added
 *   warning: they must not be called twice,
 *    don't use this file or remove tmrInit/Close from your code !!!
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*}

Unit      Timer;
Interface {$i define.inc}
Uses      Chyby;
Function  Init:TError;
Procedure Done;


type
    Pword = ^word;
    Pinteger = ^integer;

const
    tmrActive : word = 0;               { Running in a timer interrupt?
                                          1 if yes, 0 if not }



{****************************************************************************\
*
* Function:     tmrGetScrSync(scrSync : Pword) : integer;
*
* Description:  Calculates the screen synchronization value for timer
*
* Input:        scrSync : Pword         pointer to screen synchronization
*                                       value
*
* Returns:      MIDAS error code.
*               Screen syncronization value used with tmrSyncScr() is stored
*               in scrSync^.
*
\****************************************************************************}

function tmrGetScrSync(scrSync : Pword) : integer;




{****************************************************************************\
*
* Function:     tmrInit : integer;
*
* Description:  Initializes TempoTimer.
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function tmrInit : integer;




{****************************************************************************\
*
* Function:     tmrClose : integer
*
* Description:  Uninitializes TempoTimer. MUST be called if and ONLY if
*               tmrInit() has been called.
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function tmrClose : integer;




{****************************************************************************\
*
* Function:     tmrPlaySD(SD : pointer) : integer;
*
* Description:  Starts playing sound with a Sound Device ie. calling its
*               Play() function in the update rate, which is set to
*               50Hz.
*
* Input:        SD : pointer            Ptr to Sound Device that will be used
*
* Returns:      MIDAS error code.
*
\****************************************************************************}

function tmrPlaySD(SD : pointer) : integer;




{****************************************************************************\
*
* Function:     tmrStopSD : integer;
*
* Description:  Stops playing sound with the Sound Device.
*
* Returns:      MIDAS error code.
*
\****************************************************************************}

function tmrStopSD : integer;




{****************************************************************************\
*
* Function:     tmrPlayMusic(play : pointer; playerNum : Pinteger) : integer;
*
* Description:  Starts playing music with the timer.
*
* Input:        play : pointer          Pointer to music playing function,
*                                       must return MIDAS error codes
*               playerNum : Pinteger    Pointer to player number, used
*                                       for stopping music
*
* Returns:      MIDAS error code. Player number is written to playerNum^.
*
* Notes:        There can be a maximum of 16 music players active at the
*               same time.
*
\****************************************************************************}

function tmrPlayMusic(play : pointer; playerNum : Pinteger) : integer;




{****************************************************************************\
*
* Function:     tmrStopMusic(playerNum : integer) : integer;
*
* Description:  Stops playing music with the timer.
*
* Input:        playerNum : integer     Number of player to be stopped.
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function tmrStopMusic(playerNum : integer) : integer;




{****************************************************************************\
*
* Function:     tmrSyncScr(sync : word; preVR, immVR, inVR : pointer) :
*                   integer;
*
* Description:  Synchronizes the timer to screen refresh.
*
* Input:        sync : word             Screen synchronization value returned
*                                       by tmrGetScrSync().
*               preVR : pointer         Pointer to the routine that will be
*                                       called BEFORE Vertical Retrace
*               immVR : pointer         Pointer to the routine that will be
*                                       called immediately after Vertical
*                                       Retrace starts
*               inVR : pointer          Pointer to the routine that will be
*                                       called some time during Vertical
*                                       Retrace
*
* Returns:      MIDAS error code
*
* Notes:        preVR() and immVR() functions must be as short as possible
*               and do nothing else than update counters or set some VGA
*               registers to avoid timer synchronization problems. inVR()
*               can take a longer time and can be used for, for example,
*               setting the palette.
*
\****************************************************************************}

function tmrSyncScr(sync : word; preVR, immVR, inVR : pointer) : integer;




{****************************************************************************\
*
* Function:     tmrStopScrSync : integer;
*
* Description:  Stops synchronizing the timer to the screen.
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function tmrStopScrSync : integer;



{****************************************************************************\
*
* Function:     tmrSetUpdRate(updRate : word) : integer;
*
* Description:  Sets the timer update rate, ie. the rate at which the module
*               playing routine is called
*
* Input:        updRate : word          updating rate, in 100*Hz (5000=50Hz)
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function tmrSetUpdRate(updRate : word) : integer;



implementation

{$IFNDEF __BPREAL__}
{$DEFINE NOEMS}
{$ENDIF}

uses  Errors, mGlobals, DMA, DSM
{$IFNDEF NOEMS}
      ,EMS
{$ENDIF}
      ;



function tmrGetScrSync(scrSync : Pword) : integer; external;
function tmrInit : integer; external;
function tmrClose : integer; external;
function tmrPlaySD(SD : pointer) : integer; external;
function tmrStopSD : integer; external;
function tmrPlayMusic(play : pointer; playerNum : Pinteger) : integer;
    external;
function tmrStopMusic(playerNum : integer) : integer; external;
function tmrSyncScr(sync : word; preVR, immVR, inVR : pointer) : integer;
    external;
function tmrStopScrSync : integer; external;
function tmrSetUpdRate(updRate : word) : integer; external;
{$L TIMER.OBJ}


{같같같같같같같같같같같같같같같같INIT/DONE같같같같같같같같같같같같같같같같같�}

const unita='timer';
var result:TError;

procedure UserInit;
 begin
  result:=TError(tmrInit);
 end;

procedure UserDone;
 begin
  tmrClose;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.