;ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
;³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
;³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

P386
IDEAL
JUMPS
MODEL TPASCAL
LANG EQU PASCAL


GLOBAL  LANG dpmiAllocDescriptor : far
GLOBAL  LANG dpmiFreeDescriptor : far
GLOBAL  LANG dpmiSegmentDescriptor : far
GLOBAL  LANG dpmiSetSegmentBase : far
GLOBAL  LANG dpmiGetSegmentBase : far
GLOBAL  LANG dpmiSetSegmentLimit : far
GLOBAL  LANG dpmiSetSegmentAccessRights : far
GLOBAL  LANG dpmiCreateCodeAlias : far
GLOBAL  LANG dpmiAllocDOSMem : far
GLOBAL  LANG dpmiFreeDOSMem : far
GLOBAL  LANG dpmiGetRealIntVect : far
GLOBAL  LANG dpmiSetRealIntVect : far
GLOBAL  LANG dpmiGetIntVect : far
GLOBAL  LANG dpmiSetIntVect : far
GLOBAL  LANG dpmiRealModeInt : far
GLOBAL  LANG dpmiRealModeIntStack : far


;/***************************************************************************\
;*       struct dpmiRealCallRegs
;*       -----------------------
;* Description:  Real mode calling register value structure
;\***************************************************************************/

STRUC   dpmiRealCallRegs
        rEDI            DD      ?
        rESI            DD      ?
        rEBP            DD      ?
        reserved        DD      ?
        rEBX            DD      ?
        rEDX            DD      ?
        rECX            DD      ?
        rEAX            DD      ?
        flags           DW      ?
        rES             DW      ?
        rDS             DW      ?
        rFS             DW      ?
        rGS             DW      ?
        rIP             DW      ?
        rCS             DW      ?
        rSP             DW      ?       ; if SS and SP are zero, DPMI will
        rSS             DW      ?       ; provide a small (30 words) stack
ENDS



;/***************************************************************************\
;*	 enum ErrorCodes
;*	 ---------------
;* Description:  MIDAS Sound System error codes
;\***************************************************************************/

ENUM	ErrorCodes \
	OK = 0, \			; no error
	errUndefined, \ 		; undefined error
	errOutOfMemory, \		; out of (conventional) memory
	errHeapCorrupted, \		; (conventional memory) heap corrupted
	errInvalidBlock, \		; invalid memory block
	errOutOfEMS, \			; out of EMS memory
	errEMSHeapCorrupted, \		; EMS heap corrupted
	errInvalidEMSBlock, \		; invalid EMS memory block
	errEMMFailure, \		; Expanded Memory Manager failure
	errOutOfCardMemory, \		; out of soundcard memory
	errCardHeapCorrupted, \ 	; soundcard heap corrupted
	errInvalidCardBlock, \		; invalid soundcard memory block
	errNoInstHandles, \		; out of instrument handles
	errFileOpen, \			; unable to open file
	errFileRead, \			; unable to read file
	errInvalidModule, \		; invalid module file
	errInvalidInst, \		; invalid instrument in module
	errInvalidPatt, \		; invalid pattern data in module
	errInvalidChanNumber, \ 	; invalid channel number
	errInvalidInstHandle, \ 	; invalid instrument handle
	errNoChannels, \		; Sound Device channels not open
	errSDFailure, \ 		; Sound Device hardware failure
	errInvalidArguments, \		; invalid function arguments
	errFileNotFound, \		; file does not exist
	errInvalidFileHandle, \ 	; invalid file handle
	errAccessDenied, \		; access denied
	errFileExists, \		; file exists
	errTooManyFiles, \		; too many open files
	errDiskFull, \			; disk full
	errEndOfFile, \ 		; unexpected end of file
        errInvalidPath, \               ; invalid path
        errFileWrite, \                 ; unable to write file
        errVDSLock, \                   ; unable to lock VDS DMA buffer
        errVDSUsage, \                  ; unable to use Virtual DMA
        errBadVDS, \                    ; invalid VDS version
        errDPMIFailure, \               ; DPMI failure
        errInvalidDescriptor, \         ; invalid segment descriptor
        errOutOfResources               ; out of system resources


CODESEG



;/***************************************************************************\
;*
;* Function:    int dpmiAllocDescriptor(ushort *descriptor);
;*
;* Description: Allocate LDT descriptor. Use dpmiFreeDescriptor to deallocate.
;*
;* Input:       ushort *descriptor      pointer to descriptor number
;*
;* Returns:     MIDAS error code. Descriptor number is written to *descriptor.
;*
;\***************************************************************************/

PROC    dpmiAllocDescriptor     FAR     descriptor : dword

        xor     ax,ax                   ; DPMI function 0 - alloc LDT descr.
        mov     cx,1                    ; allocate one descriptor
        int     31h
        jc      @@err

        les     bx,[descriptor]         ; write allocated descriptor to
        mov     [es:bx],ax              ; *descriptor

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiFreeDescriptor(ushort descriptor);
;*
;* Description: Deallocates an LDT descriptor.
;*
;* Input:       ushort descriptor       descriptor to deallocate
;*
;* Returns:     MIDAS error code
;*
;\***************************************************************************/

PROC    dpmiFreeDescriptor      FAR     descriptor : word

        mov     ax,0001h                ; DPMI function 1 - free LDT descr.
        mov     bx,[descriptor]
        int     31h
        jc      @@err

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errInvalidDescriptor

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiSegmentDescriptor(ushort segment, ushort *descriptor);
;*
;* Description: Creates a descriptor to a real mode segment. Subsequent
;*              calls will return the same descriptor. Note that the
;*              DESCRIPTOR CANNOT BE DEALLOCATED.
;*
;* Input:       ushort segment          real mode segment
;*              ushort *descriptor      pointer to descriptor number
;*
;* Returns:     MIDAS error code. Descriptor number is written to *descriptor.
;*
;\***************************************************************************/

PROC    dpmiSegmentDescriptor   FAR     realSeg : word, descriptor : dword

        mov     ax,0002h                ; DPMI function 2 - segment to descr.
        mov     bx,[realSeg]
        int     31h
        jc      @@err

        les     bx,[descriptor]         ; write descriptor number to
        mov     [es:bx],ax              ; *descriptor

        xor     ax,ax			; bugfix
        jmp     @@done			; bugfix

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiSetSegmentBase(ushort selector, ulong baseAddr);
;*
;* Description: Changes the 32-bit linear base address of a selector.
;*
;* Input:       ushort selector         selector number
;*              ulong baseAddr          32-bit linear base address for
;*                                       selector
;*
;* Returns:     MIDAS error code.
;*
;\***************************************************************************/

PROC    dpmiSetSegmentBase      FAR     selector : word, baseAddr : dword

        mov     ax,0007h                ; DPMI function 7 - set segment base
        mov     bx,[selector]
        mov     cx,[word baseAddr+2]    ; cx:dx = new base address
        mov     dx,[word baseAddr]
        int     31h
        jc      @@err

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errInvalidDescriptor

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiGetSegmentBase(ushort selector, ulong *baseAddr);
;*
;* Description: Reads the 32-bit linear base address of a selector.
;*
;* Input:       ushort selector         selector number
;*              ulong *baseAddr         pointer to the 32-bit linear base
;*                                      address of the selector
;*
;* Returns:     MIDAS error code. Selector base address is written to
;*              *baseAddr.
;*
;\***************************************************************************/

PROC    dpmiGetSegmentBase      FAR     selector : word, baseAddr : dword

        mov     ax,0006h                ; DPMI function 7 - get segment base
        mov     bx,[selector]
        int     31h
        jc      @@err

        les     bx,[baseAddr]
        mov     [word es:bx],dx         ; write segment base address to
        mov     [word es:bx+2],cx       ; *baseAddr

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errInvalidDescriptor

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiSetSegmentLimit(ushort selector, ulong limit);
;*
;* Description: Changes the limit of a segment selector.
;*
;* Input:       ushort selector         selector number
;*              ulong limit             32-bit segment limit
;*
;* Returns:     MIDAS error code.
;*
;\***************************************************************************/

PROC    dpmiSetSegmentLimit     FAR     selector : word, limit : dword

        mov     ax,0008h                ; DPMI function 8 - set segment limit
        mov     bx,[selector]
        mov     cx,[word limit+2]       ; cx:dx = new segment limit
        mov     dx,[word limit]
        int     31h
        jc      @@err

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiSetSegmentAccessRights(ushort selector,
;*                  ushort accessRights);
;*
;* Description: Changes the access rights of a selector
;*
;* Input:       ushort selector         selector
;*              ushort accessRights     new access rights for the segment
;*
;* Returns:     MIDAS error code.
;*
;\***************************************************************************/

PROC    dpmiSetSegmentAccessRights      FAR     selector : word, \
                                                accessRights : word

        mov     ax,0009h                ; DPMI function 9 - set access rights
        mov     bx,[selector]
        mov     cx,[accessRights]
        int     31h
        jc      @@err

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiCreateCodeAlias(ushort codeSelector,
;*                  ushort *selector);
;*
;* Description: Creates a data descriptor that has the same base and limit
;*              as a code segment descriptor. Use dpmiFreeDescriptor() to
;*              deallocate data descriptor.
;*
;* Input:       ushort codeSelector     code segment selector
;*              ushort *selector        pointer to data segment selector
;*
;* Returns:     MIDAS error code. New data selector is written to *selector.
;*
;\***************************************************************************/

PROC    dpmiCreateCodeAlias     FAR     codeSelector : word, selector : dword

        mov     ax,000Ah                ; 000Ah - create code alias descr.
        mov     bx,[codeSelector]
        int     31h
        jc      @@err

        les     bx,[selector]           ; write selector to *selector
        mov     [es:bx],ax

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiAllocDOSMem(ushort numParagraphs, ushort *segment,
;*                  ushort *selector);
;*
;* Description: Allocates memory from DOS free memory pool, below 1MB. Use
;*              dpmiFreeDOSMem() to deallocate.
;*
;* Input:       ushort numParagraphs    number of paragraphs to allocate
;*              ushort *segment         pointer to real mode segment
;*              ushort *selector        pointer to selector
;*
;* Returns:     MIDAS error code. Real mode segment of allocated block is
;*              written to *segment. Protected mode selector for block is
;*              written to *selector.
;*
;\***************************************************************************/

PROC    dpmiAllocDOSMem         FAR     numParagraphs : word, \
                                        realSeg : dword, selector : dword

        mov     ax,0100h                ; 0100h - alloc DOS memory block
        mov     bx,[numParagraphs]
        int     31h
        jnc     @@ok

        cmp     ax,07h                  ; memory control blocks damaged?
        je      @@mcbDamaged
        cmp     ax,08h                  ; insufficient memory?
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
        les     bx,[realSeg]            ; write real mode segment to *segment
        mov     [es:bx],ax
        les     bx,[selector]           ; write selector to *selector
        mov     [es:bx],dx

        xor     ax,ax

@@err:

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    dpmiFreeDOSMem(ushort selector);
;*
;* Description: Deallocates memory allocated with dpmiAllocDOSMem().
;*
;* Input:       ushort selector     selector for allocated block
;*
;* Returns:     MIDAS error code
;*
;\***************************************************************************/

PROC    dpmiFreeDOSMem          FAR     selector : word

        mov     ax,0101h                ; 0101h - free DOS memory block
        mov     dx,[selector]
        int     31h
        jc      @@error

        xor     ax,ax
        jmp     @@done

@@error:
        cmp     ax,07h                  ; memory control blocks damaged?
        je      @@mcbDamaged
        cmp     ax,09h                  ; incorrect segment?
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
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiGetRealIntVect(uchar intNum, ushort *segment,
;*                  ushort *offset);
;*
;* Description: Gets a real mode interrupt vector
;*
;* Input:       uchar intNum            interrupt number
;*              ushort *segment         pointer to interrupt vector segment
;*              ushort *offset          pointer to interrupt vector offset
;*
;* Returns:     MIDAS error code. Interrupt vector is written to
;*              *segment and *offset.
;*
;\***************************************************************************/

PROC    dpmiGetRealIntVect      FAR     intNum : byte, intSeg : dword, \
                                        intOffs : dword

        mov     ax,0200h                ; 0200h - get real mode int vector
        mov     bl,[intNum]
        int     31h
        jc      @@err

        les     bx,[intSeg]             ; write interrupt vector segment to
        mov     [es:bx],cx              ; *segment
        les     bx,[intOffs]            ; write interrupt vector offset to
        mov     [es:bx],dx              ; *offset

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiSetRealIntVect(uchar intNum, ushort segment,
;*                  ushort offset);
;*
;* Description: Sets a real mode interrupt vector
;*
;* Input:       uchar intNum            interrupt number
;*              ushort segment          interrupt vector segment
;*              ushort offset           interrupt vector offset
;*
;* Returns:     MIDAS error code
;*
;\***************************************************************************/

PROC    dpmiSetRealIntVect      FAR     intNum : byte, intSeg : word, \
                                        intOffset : word

        mov     ax,0201h                ; 0201h - set real mode int vector
        mov     bl,[intNum]
        mov     cx,[intSeg]
        mov     dx,[intOffset]
        int     31h
        jc      @@err

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiGetIntVect(uchar intNum, void **intVector);
;*
;* Description: Gets a protected mode interrupt vector.
;*
;* Input:       uchar intNum            interrupt number
;*              void **intVector        pointer to interrupt vector pointer
;*
;* Returns:     MIDAS error code. Interrupt vector is written to *intVector.
;*
;\***************************************************************************/

PROC    dpmiGetIntVect          FAR     intNum : byte, intVector : dword

        mov     ax,0204h                ; 0204h - get prot. mode int vector
        mov     bl,[intNum]
        int     31h
        jc      @@err

        les     bx,[intVector]          ; write interrupt vector to *intVector
        mov     [es:bx],dx
        mov     [es:bx+2],cx

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:     int dpmiSetIntVect(uchar intNum, void *intVector);
;*
;* Description:  Sets a protected mode interrupt vector.
;*
;* Input:        uchar intNum            interrupt number
;*               void *intVector         interrupt vector
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC    dpmiSetIntVect          FAR     intNum : byte, intVector : dword

        mov     ax,0205h                ; 0205h - set prot. mode int vect
        mov     bl,[intNum]
        mov     dx,[word intVector]     ; cx:dx = new interrupt vector
        mov     cx,[word intVector+2]
        int     31h
        jc      @@err

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dpmiRealModeInt(uchar intNum,
;*                  dpmiRealCallRegs *registers);
;*
;* Description: Simulates a real mode interrupt using DPMI service 0x0300.
;*              *register MUST contain appropriate register values for
;*              interrupt (CS:IP is ignored).
;*
;* Input:       uchar intNum                    interrupt number
;*              dpmiRealCallRegs *registers     DPMI real mode calling struct
;*
;* Returns:     MIDAS error code. Register values returned by the interrupt
;*              are written to *registers.
;*
;\***************************************************************************/

PROC    dpmiRealModeInt         FAR     intNum : byte, registers : dword
USES    di

	mov	al,[intNum]
	call	dpmiRealModeIntStack LANG, ax, [registers], 0

        ret
ENDP



PROC    dpmiRealModeIntStack    FAR     intNum : byte, registers : dword, \
                                         stacksize : word
USES    di

        mov     ax,0300h                ; 0300h - simulate real mode interrupt
        mov     bl,[intNum]
        mov     bh,1                    ; reset PIC and A20 line
        les     di,[registers]
	mov	cx,[stacksize]		; bugfix
        int     31h
        jc      @@err

        ; es:di now contains pointer to modified real mode call structure.
        ; The DPMI specs do not clearly state that this is necessarily the
        ; same as the original structure, so for safety we check the pointers
        ; and if they differ copy the data to the original structure:

        mov     ax,es
        cmp     ax,[word registers+2]
        jne     @@copyregs
        cmp     di,[word registers]
        jne     @@copyregs

        ; es:di points to the original structure - the new register values
        ; are at their place.

        xor     ax,ax
        jmp     @@done

@@copyregs:
        ; es:di has changed - copy the new register structure to the old
        ; place:
        push    ds si

        mov     si,di
        mov     ax,es                   ; ds:si = es:di
        mov     ds,ax

        les     di,[registers]
        mov     cx,SIZE dpmiRealCallRegs
        cld
        rep     movsb

        pop     si ds

        xor     ax,ax
        jmp     @@done

@@err:
        mov     ax,errDPMIFailure

@@done:
        ret
ENDP



END
