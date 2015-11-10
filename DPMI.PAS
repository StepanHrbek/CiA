{*
 * Subset of DPMI unit from MIDAS Sound System 0.40c
 *  + some fixes
 *  + method dpmiRealCallRegs.clr
 *
 * Copyright 1995 Petteri Kangaslampi and Jarno Paananen
 *
 *}


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
        procedure clr;                  { clr clears all regs }
    end;

    PdpmiRealCallRegs = ^dpmiRealCallRegs;



type
    Pword = ^word;



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



implementation

const
    errOutOfMemory = 02;                { out of (conventional) memory }
    errHeapCorrupted = 03;              { (conventional memory) heap
                                           corrupted }
    errDPMIFailure = 35;                { DPMI failure }
    errInvalidDescriptor = 36;          { invalid segment descriptor }

procedure dpmiRealCallRegs.clr;
begin
 fillchar(self,sizeof(dpmiRealCallRegs),0);
end;

function dpmiSegmentDescriptor(segment : word; descriptor : Pword) : integer;
assembler;
asm
        mov     ax,0002h                ;{ DPMI function 2 - segment to descr.}
        mov     bx,[segment]
        int     31h
        jc      @@err

        les     bx,[descriptor]         ;{ write descriptor number to}
        mov     [es:bx],ax              ;{ *descriptor}

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
end;

function dpmiAllocDOSMem(numParagraphs : word; segment, selector : Pword) : integer;
assembler;
asm
        mov     ax,0100h                ;{0100h - alloc DOS memory block}
        mov     bx,[numParagraphs]
        int     31h
        jnc     @@ok

        cmp     ax,07h                  ;{memory control blocks damaged?}
        je      @@mcbDamaged
        cmp     ax,08h                  ;{insufficient memory?}
        je      @@nomemory

        mov     ax,errDPMIFailure
        jmp     @@err

@@mcbDamaged:
        mov     ax,errHeapCorrupted
        jmp     @@err

@@nomemory:
        mov     ax,errOutOfMemory
        jmp     @@err

@@ok:
        les     bx,[segment]            ;{write real mode segment to *segment}
        mov     [es:bx],ax
        les     bx,[selector]           ;{write selector to *selector}
        mov     [es:bx],dx

        xor     ax,ax
        jmp     @@done

@@err:

@@done:
end;

function dpmiFreeDOSMem(selector : word) : integer;
assembler;
asm
        mov     ax,0101h                ;{0101h - free DOS memory block}
        mov     dx,[selector]
        int     31h
        jc      @@error

        xor     ax,ax
        jmp     @@done

@@error:
        cmp     ax,07h                  ;{memory control blocks damaged?}
        je      @@mcbDamaged
        cmp     ax,09h                  ;{incorrect segment?}
        je      @@badSegment

        mov     ax,errDPMIFailure
        jmp     @@err

@@mcbDamaged:
        mov     ax,errHeapCorrupted
        jmp     @@err

@@badSegment:
        mov     ax,errInvalidDescriptor

@@err:

@@done:
end;

function dpmiRealModeInt(intNum : byte; registers : PdpmiRealCallRegs) : integer;
assembler;
asm
        mov     ax,0300h                ;{0300h - simulate real mode interrupt}
        mov     bl,[intNum]
        mov     bh,1                    ;{reset PIC and A20 line}
        les     di,[registers]
	xor	cx,cx
        int     31h
        jc      @@err
        {
        ; es:di now contains pointer to modified real mode call structure.
        ; The DPMI specs do not clearly state that this is necessarily the
        ; same as the original structure, so for safety we check the pointers
        ; and if they differ copy the data to the original structure:
        }
        mov     ax,es
        cmp     ax,[word ptr registers+2]
        jne     @@copyregs
        cmp     di,[word ptr registers]
        jne     @@copyregs
        {
        ; es:di points to the original structure - the new register values
        ; are at their place.
        }
        xor     ax,ax
        jmp     @@done

@@copyregs:{
        ; es:di has changed - copy the new register structure to the old
        ; place:}
        push    ds
        push    si

        mov     si,di
        mov     ax,es                   ;{ds:si = es:di}
        mov     ds,ax

        les     di,[registers]
        mov     cx,type dpmiRealCallRegs
        cld
        rep     movsb

        pop     si
        pop     ds

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
end;

END.
