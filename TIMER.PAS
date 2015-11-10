{* Subset of TIMER unit form MIDAS Sound System 0.40
 *
 * TempoTimer, originally v1.20
 *
 * Copyright 1995 Petteri Kangaslampi and Jarno Paananen
 *}

unit Timer;


interface


type
    Pword = ^word;

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
* Description:  Uninitializes TempoTimer.
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function tmrClose : integer;




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




implementation



function tmrGetScrSync(scrSync : Pword) : integer; external;
function tmrInit : integer; external;
function tmrClose : integer; external;
function tmrSyncScr(sync : word; preVR, immVR, inVR : pointer) : integer; external;
function tmrStopScrSync : integer; external;
{$L TIMER.OBJ}


END.
