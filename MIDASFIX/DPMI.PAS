{*      DPMI.PAS
 *
 * DPMI functions for protected mode MIDAS
 *
 * Copyright 1995 Petteri Kangaslampi and Jarno Paananen
 *
 * by D.Ment:
 *  dpmiRealCallRegs.clr added
 *  dpmiRealModeIntStack added
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*}


 {$ifdef dpmi}
  {$define __BPPROT__}
 {$else}
  {$define __BPREAL__}
 {$endif}

unit DPMI;


interface



{****************************************************************************\
*       struct dpmiRealCallRegs
*       -----------------------
* Description:  Real mode calling register value structure
\****************************************************************************}

type
    dpmiRealCallRegs = Object
        rEDI : longint;
        rESI : longint;
        rEBP : longint;
        reserved : longint;
        rEBX : longint;
        rEDX : longint;
        rECX : longint;
        rEAX : longint;
        flags : word;
        rES : word;
        rDS : word;
        rFS : word;
        rGS : word;
        rIP : word;
        rCS : word;
        rSP : word;                     { if SS and SP are zero, DPMI will }
        rSS : word;                     { provide a small (30 words) stack }
        procedure clr;
    end;

    PdpmiRealCallRegs = ^dpmiRealCallRegs;



type
    Pword = ^word;
    Plongint = ^longint;
    Ppointer = ^pointer;


{****************************************************************************\
*
* Function:     dpmiAllocDescriptor(descriptor : Pword) : integer;
*
* Description:  Allocate LDT descriptor. Use dpmiFreeDescriptor to deallocate.
*
* Input:        descriptor : Pword      pointer to descriptor number
*
* Returns:      MIDAS error code. Descriptor number is written to descriptor^.
*
\****************************************************************************}

function dpmiAllocDescriptor(descriptor : Pword) : integer;




{****************************************************************************\
*
* Function:     dpmiFreeDescriptor(descriptor : word) : integer;
*
* Description:  Deallocates an LDT descriptor.
*
* Input:        descriptor : word       descriptor to deallocate
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function dpmiFreeDescriptor(descriptor : word) : integer;




{****************************************************************************\
*
* Function:     dpmiSegmentDescriptor(segment : word; descriptor : Pword) :
*                   integer;
*
* Description:  Creates a descriptor to a real mode segment. Subsequent
*               calls will return the same descriptor. Note that the
*               DESCRIPTOR CANNOT BE DEALLOCATED.
*
* Input:        segment : word          real mode segment
*               descriptor : Pword      pointer to descriptor number
*
* Returns:      MIDAS error code. Descriptor number is written to descriptor^.
*
\****************************************************************************}

function dpmiSegmentDescriptor(segment : word; descriptor : Pword) : integer;




{****************************************************************************\
*
* Function:     dpmiSetSegmentBase(selector : word; baseAddr : longint) :
*                   integer;
*
* Description:  Changes the 32-bit linear base address of a selector.
*
* Input:        selector : word         selector number
*               baseAddr : longint      32-bit linear base address for
*                                       selector
*
* Returns:      MIDAS error code.
*
\****************************************************************************}

function dpmiSetSegmentBase(selector : word; baseAddr : longint) : integer;




{****************************************************************************\
*
* Function:     dpmiGetSegmentBase(selector : word; baseAddr : Plongint) :
*                   integer;
*
* Description:  Reads the 32-bit linear base address of a selector.
*
* Input:        selector : word         selector number
*               baseAddr : Plongint     pointer to the 32-bit linear base
*                                       address of the selector
*
* Returns:      MIDAS error code. Selector base address is written to
*               baseAddr^.
*
\****************************************************************************}

function dpmiGetSegmentBase(selector : word; baseAddr : Plongint) : integer;




{****************************************************************************\
*
* Function:     dpmiSetSegmentLimit(selector : word; limit : longint) :
*                   integer;
*
* Description:  Changes the limit of a segment selector.
*
* Input:        selector : word         selector number
*               limit : longint         32-bit segment limit
*
* Returns:      MIDAS error code.
*
\****************************************************************************}

function dpmiSetSegmentLimit(selector : word; limit : longint) : integer;




{****************************************************************************\
*
* Function:     dpmiSetSegmentAccessRights(selector, accessRights : word) :
*                   integer;
*
* Description:  Changes the access rights of a selector
*
* Input:        selector : word         selector
*               accessRights : word     new access rights for the segment
*
* Returns:      MIDAS error code.
*
\****************************************************************************}

function dpmiSetSegmentAccessRights(selector, accessRights : word) : integer;




{****************************************************************************\
*
* Function:     dpmiCreateCodeAlias(codeSelector : word; selector : Pword) :
*                   integer;
*
* Description:  Creates a data descriptor that has the same base and limit
*               as a code segment descriptor. Use dpmiFreeDescriptor() to
*               deallocate data descriptor.
*
* Input:        codeSelector : word     code segment selector
*               selector : Pword        pointer to data segment selector
*
* Returns:      MIDAS error code. New data selector is written to selector^.
*
\****************************************************************************}

function dpmiCreateCodeAlias(codeSelector : word; selector : Pword) : integer;




{****************************************************************************\
*
* Function:     function dpmiAllocDOSMem(numParagraphs : word; segment,
*                   selector : Pword) : integer;
*
* Description:  Allocates memory from DOS free memory pool, below 1MB. Use
*               dpmiFreeDOSMem() to deallocate.
*
* Input:        numParagraphs : word    number of paragraphs to allocate
*               segment : Pword         pointer to real mode segment
*               selector : Pword        pointer to selector
*
* Returns:      MIDAS error code. Real mode segment of allocated block is
*               written to segment^. Protected mode selector for block is
*               written to selector^.
*
\****************************************************************************}

function dpmiAllocDOSMem(numParagraphs : word; segment, selector : Pword) :
    integer;




{****************************************************************************\
*
* Function:     dpmiFreeDOSMem(selector : word) : integer;
*
* Description:  Deallocates memory allocated with dpmiAllocDOSMem().
*
* Input:        selector : word     selector for allocated block
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function dpmiFreeDOSMem(selector : word) : integer;




{****************************************************************************\
*
* Function:     dpmiGetRealIntVect(intNum : byte; segment, offset : Pword) :
*                   integer;
*
* Description:  Gets a real mode interrupt vector
*
* Input:        intNum : byte           interrupt number
*               segment : Pword         pointer to interrupt vector segment
*               offset : Pword          pointer to interrupt vector offset
*
* Returns:      MIDAS error code. Interrupt vector is written to
*               segment^ and offset^.
*
\****************************************************************************}

function dpmiGetRealIntVect(intNum : byte; segment, offset : Pword) : integer;




{****************************************************************************\
*
* Function:     dpmiSetRealIntVect(intNum : byte; segment, offset : word) :
*                   integer;
*
* Description:  Sets a real mode interrupt vector
*
* Input:        intNum : byte           interrupt number
*               segment : word          interrupt vector segment
*               offset : word           interrupt vector offset
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function dpmiSetRealIntVect(intNum : byte; segment, offset : word) : integer;




{****************************************************************************\
*
* Function:     dpmiGetIntVect(intNum : byte; intVector : Ppointer) : integer;
*
* Description:  Gets a protected mode interrupt vector.
*
* Input:        intNum : byte           interrupt number
*               intVector : Ppointer    pointer to interrupt vector pointer
*
* Returns:      MIDAS error code. Interrupt vector is written to intVector^.
*
\****************************************************************************}

function dpmiGetIntVect(intNum : byte; intVector : Ppointer) : integer;




{****************************************************************************\
*
* Function:     dpmiSetIntVect(intNum : byte; intVector : pointer) : integer;
*
* Description:  Sets a protected mode interrupt vector.
*
* Input:        intNum : byte           interrupt number
*               intVector : pointer     interrupt vector
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function dpmiSetIntVect(intNum : byte; intVector : pointer) : integer;




{****************************************************************************\
*
* Function:     dpmiRealModeInt(intNum : byte; registers : PdpmiRealCallRegs)
*                   : integer;
*
* Description:  Simulates a real mode interrupt using DPMI service 0x0300.
*               *register MUST contain appropriate register values for
*               interrupt (CS:IP is ignored).
*
* Input:        intNum : byte                   interrupt number
*               registers : PdpmiRealCallRegs   DPMI real mode calling struct
*
* Returns:      MIDAS error code. Register values returned by the interrupt
*               are written to registers^.
*
\****************************************************************************}

function dpmiRealModeInt(intNum : byte; registers : PdpmiRealCallRegs) :
    integer;
function dpmiRealModeIntStack(intNum : byte; registers : PdpmiRealCallRegs;
    stacksize : word) : integer;



implementation

{$ifdef DEBUG}
uses Errors;
{$endif}


{---------------------------------------------------------------------------
 Vynuluje sadu realmodovych registru pro volani dpmi.
 ---------------------------------------------------------------------------}
procedure dpmiRealCallRegs.clr;
begin
 fillchar(self,sizeof(dpmiRealCallRegs),0);
end;


function dpmiAllocDescriptor(descriptor : Pword) : integer; external;
function dpmiFreeDescriptor(descriptor : word) : integer; external;
function dpmiSegmentDescriptor(segment : word; descriptor : Pword) : integer; external;
function dpmiSetSegmentBase(selector : word; baseAddr : longint) : integer; external;
function dpmiGetSegmentBase(selector : word; baseAddr : Plongint) : integer; external;
function dpmiSetSegmentLimit(selector : word; limit : longint) : integer; external;
function dpmiSetSegmentAccessRights(selector, accessRights : word) : integer; external;
function dpmiCreateCodeAlias(codeSelector : word; selector : Pword) : integer; external;
function dpmiAllocDOSMem(numParagraphs : word; segment, selector : Pword) : integer; external;
function dpmiFreeDOSMem(selector : word) : integer; external;
function dpmiGetRealIntVect(intNum : byte; segment, offset : Pword) : integer; external;
function dpmiSetRealIntVect(intNum : byte; segment, offset : word) : integer; external;
function dpmiGetIntVect(intNum : byte; intVector : Ppointer) : integer; external;
function dpmiSetIntVect(intNum : byte; intVector : pointer) : integer; external;
function dpmiRealModeInt(intNum : byte; registers : PdpmiRealCallRegs) : integer; external;
function dpmiRealModeIntStack(intNum : byte; registers : PdpmiRealCallRegs; stacksize : word) : integer; external;
{$L DPMI.OBJ}


END.
