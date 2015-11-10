{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Timer;
Interface {$i define.inc}
Uses      Chyby;
Function  Init:TError;
Procedure Done;


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
function tmrInit : integer; far; external;
function tmrClose : integer; far; external;
function tmrSyncScr(sync : word; preVR, immVR, inVR : pointer) : integer; external;
function tmrStopScrSync : integer; external;
{$L TIMER.OBJ}


{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

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