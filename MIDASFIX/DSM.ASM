;*      DSM.ASM
;*
;* Digital Sound Mixer, v1.24
;*
;* Copyright 1995 Petteri Kangaslampi and Jarno Paananen
;*
;* by D.Ment:
;*  cmp bl,panLeft fixed to cmp bl,256+panLeft
;*
;* This file is part of the MIDAS Sound System, and may only be
;* used, modified and distributed under the terms of the MIDAS
;* Sound System license, LICENSE.TXT. By continuing to use,
;* modify or distribute this file you indicate that you have
;* read the license and understand and accept it fully.
;*


IDEAL
P386
JUMPS

INCLUDE "lang.inc"
INCLUDE "errors.inc"
INCLUDE "mglobals.inc"
INCLUDE "dsm.inc"
INCLUDE "mmem.inc"
IFNDEF NOEMS
INCLUDE "ems.inc"
ENDIF
IFDEF __DPMI__
INCLUDE "dpmi.inc"
ENDIF
INCLUDE "sdevice.inc"



TBUF_MAX = 4096                         ; maximum size of temporary buffer
MIX8BITS = 12                           ; number of bits of accuracy in 8-bit
                                        ; mixing
PP8SIZE = 1 SHL MIX8BITS                ; 8-bit mixing post-processing table
                                        ; size



DATASEG

dsmMixRate	DW	?		; mixing rate in Hz
dsmMode 	DW	?		; output mode (see enum sdMode)
dsmVolTableMem	DD	?		; pointer to volume table returned
					; by memAlloc(). Used for deallocating
dsmVolTableSeg	DW	?		; volume table segment
dsmTempBuffer   DD      ?               ; temporary mixing buffer
dsmTBufSize	DW	?		; temp. buffer size in bytes
dsmChannels	DD	?		; pointer to channel datas
dsmChOpen	DW	?		; number of open channels
dsmChPlay       DW      ?               ; 1 if data on channels may be played
dsmMasterVolume DB      ?               ; master volume
dsmInstruments	DD	?		; instrument structures
dsmUpdateMix	DW	?		; amount of data to mix between two
					; updates
dsmMixLeft	DW	?		; amount of data to be mixed before
					; the next update
dsmMixPos	DW	?		; mixing position in buffer
dsmTBufPos      DW      ?               ; mixing position in temporary buffer
dsmSamplePtr    DD      ?               ; conventional memory sample pointer,
                                        ; used internally by some functions
dsmMuted        DW      ?               ; 1 if muted, 0 if not
dsmPaused       DW      ?               ; 1 if paused, 0 if not
dsmLastMixStart DW      ?               ; most recent mixing start
dsmLastMixLen   DW      ?               ; most recent mixing length
dsmTBufElemSize DW      ?               ; temporary buffer element size
                                        ; (2 for mono, 4 for stereo)
dsmMixElemSize  DW      ?               ; mixing buffer element size
                                        ; (1 for 8-bit mono, 2 for 16-bit mono
                                        ; or 8-bit stereo, 4 for 16-bit
                                        ; stereo)
dsmTBufClearValue DD    ?               ; dword used for temporary buffer
                                        ; clearing
mixCount        DW      ?               ; mixing loop counter for some mixing
                                        ; routines
mixRout         DW      ?               ; mixing routine pointer
mixLVol         DB      ?               ; mixing left channel volume
mixRVol         DB      ?               ; mixing right channel volume
mixLoop         DW      ?               ; pointer to mixing loop start
dsmChanNum      DW      ?               ; current channel number
pp8Table        DD      ?               ; pointer to 8-bit mixing post-
                                        ; processing table
dsmAmplification  DW    ?               ; amplification level
dsmMemPtr       DD      ?               ; temporary memory pointer

dsmBuffer       DD      ?               ; mixing buffer pointer
dsmBufferLen    DW      ?               ; mixing buffer length, in bytes
dsmBufferEnd    DW      ?               ; mixing buffer end offset
dsmPlayPos      DW      ?               ; mixing buffer playing position




CODESEG




;/***************************************************************************\
;*
;* Macro:	ChnPtr	segreg, indexreg, channum
;*
;* Description: Points a segment:index register pair to the channel structure
;*		of a channel. Also jumps to @@err if channel number is too
;*		big.
;*
;* Input:	segreg		segment register to be used
;*		indexreg	index register to be used
;*		channum 	number of the channel
;*
;* Destroys:	ax, dx
;*
;\***************************************************************************/

MACRO	ChanPtr segreg, indexreg, channum
LOCAL   chok

	mov	ax,channum
	cmp	ax,[dsmChOpen]		; channel number too big?
        jb      chok
        mov     ax,errInvalidChanNumber
        jmp     @@err

chok:
	mov	indexreg,SIZE dsmChannel
	mul	indexreg			; segreg:indexreg points to
	mov	indexreg,[word dsmChannels]	; the channel structure
	add	indexreg,ax
	mov	segreg,[word dsmChannels+2]
ENDM



;/***************************************************************************\
;*
;* Macro:	InstPtr segreg, indexreg, instnum
;*
;* Description: Points a segment:index register pair to the instrument
;*		structure for instrument instnum.
;*
;* Input:	segreg		segment register to be used
;*		indexreg	index register to be used
;*		instnum 	number of the instrument
;*
;* Destroys:	ax, dx
;*
;\***************************************************************************/

MACRO	InstPtr segreg, indexreg, instnum

	; point segreg:indexreg to beginning of instrument structures:
	mov	segreg,[word dsmInstruments + 2]
	mov	indexreg,[word dsmInstruments]

	mov	ax,instnum
	mov	dx,SIZE dsmInstrument	; segreg:indexreg points to instrument
	mul	dx			; data structure
	add	indexreg,ax
ENDM



;/***************************************************************************\
;*
;* Macro:	NumLabel lblname, lblnum
;*
;* Description: Creates a numbered label in the source, format _namenum
;*		(ie. _table1)
;*
;* Input:	lblname 	name for the label
;*		lblnum		number for the label
;*
;\***************************************************************************/

MACRO	NumLabel lblname, lblnum
_&lblname&lblnum:
ENDM



;/***************************************************************************\
;*
;* Macro:	JmpTable lblname, lblcount
;*
;* Description: Creates a jump offset table in the source. The table consists
;*		of near offsets of labels _lblname0 - _lblnameX
;*
;* Input:	lblname 	name of labels to be used for the table
;*		lblcount	number of labels
;*
;\***************************************************************************/

MACRO	dwoffs lblname, lblnum
	DW	offset _&lblname&lblnum
ENDM

MACRO	JmpTable lblname, lblcount
;LOCAL	 numb
numb = 0
REPT	lblcount
	dwoffs lblname, %numb
numb = numb + 1
ENDM
ENDM


;/***************************************************************************\
;*
;* Macro:       MixLoop         mname, mixLp, DIinc, counter
;*
;* Description: Generates code for inner mixing loop
;*
;* Input:	mname		mixing loop name (ie. m8mna)
;*		mixLp		macro that contains code for mixing loop
;*              DIinc           DI increment after each loop (16 times)
;*		counter 	loop counter (ie. cx)
;*
;\***************************************************************************/

MACRO   MixLoop         mname, mixLp, DIinc, counter
LOCAL	lp

LABEL	&mname	WORD
JmpTable	&mname, 17


lp:
num = 0
REPT	16
	NumLabel &mname, %num
	&mixLp %num
	num = num + 1
ENDM
	NumLabel &mname, %num

IF DIinc NE 0
	add	di,DIinc		; mix next 32 bytes
ENDIF
	dec	counter
	jnz	lp
	retn

ENDM	MixLoop



;/***************************************************************************\
;*
;* Function:    dsmClearBuffer
;*
;* Description: Clears the DMA buffer
;*
;* Returns:     MIDAS error code
;*
;\***************************************************************************/

PROC    dsmClearBuffer  FAR

        test    [dsmMode],sd16bit       ; check if output mode is 16-bit
	jnz	@@16

        push    di                              ; no, the buffer is unsigned
        les     di,[dsmBuffer]                  ; 8-bit - clear with 80h
        mov     al,80h                          ; bytes
        mov     cx,[dsmBufferLen]
	cld
	rep	stosb
	pop	di
	jmp	@@ok

@@16:
	push	di
        les     di,[dsmBuffer]                  ; 16-bit signed buffer
        xor     ax,ax                           ; - clear with zero words
        mov     cx,[dsmBufferLen]
	shr	cx,1
	cld
	rep	stosw
	pop	di

@@ok:
        xor     ax,ax
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dsmInit(unsigned mixRate, unsigned mode,
;*                  uchar *mixBuffer, unsigned mixBufferSize);
;*
;* Description: Initializes DSM
;*
;* Input:       unsigned mixRate        mixing rate
;*              unsigned mode           mixing mode (see enum sdMode)
;*              uchar *mixBuffer        pointer to mixing buffer
;*              unsigned mixBufferSize  mixing buffer length, in bytes
;*
;* Returns:     MIDAS error code
;*
;\***************************************************************************/

PROC    dsmInit         FAR     mixRate : word, mode : word, \
                                mixBuffer : dword, mixBufferSize : word
        cld

        mov     eax,[mixBuffer]         ; eax = mixing buffer pointer
        mov     [dsmBuffer],eax         ; store it in dsmBuffer
        mov     bx,[mixBufferSize]      ; bx = mixing buffer length
        mov     [dsmBufferLen],bx
        add     ax,bx                   ; ax = mixing buffer end offset
        mov     [dsmBufferEnd],ax

        mov     ax,[mixRate]
        mov     [dsmMixRate],ax

	mov	[dsmChOpen],0		; no open channels
        mov     [dsmChPlay],0           ; do not play data in channels
	mov	[dsmChannels],0 	; point channel structures to NULL
        mov     [dsmMuted],0            ; not muted
        mov     [dsmPaused],0           ; not paused

	mov	ax,[mode]
	mov	[dsmMode],ax

        mov     [dsmTBufElemSize],2     ; initialize temporary buffer element
                                        ; size to 2 (16-bit)
        mov     [dsmMixElemSize],1      ; initialize mixing buffer element
                                        ; size to 1

	test	[dsmMode],sd16bit	; 16-bit mixing?
        jz      @@b8                    ; if yes, multiply mixing buffer
        shl     [dsmMixElemSize],1      ; element size by two
        mov     [dsmTBufClearValue],0   ; buffer clearing value is zero
        jmp     @@b16

@@b8:   ; 8-bit mixing - buffer clearing value is 8000h:
        mov     [dsmTBufClearValue],80008000h

@@b16:
IFNDEF NOSTEREO
        test    [dsmMode],sdStereo      ; stereo?
        jz      @@bst
        shl     [dsmTBufElemSize],1     ; if yes, multiply both temporary and
        shl     [dsmMixElemSize],1      ; mixing buffer element size by 2
ENDIF

@@bst:
	mov	ax,VOLLEVELS * 256 * 2 + 16	; volume table size in bytes

        mov     bx,[dsmBufferLen]       ; size of temporary mixing buffer
        test    [dsmMode],sd8bit        ; 8-bit output mode?
        jz      @@not8                  ; if yes, temporary buffer should be
        shl     bx,1                    ; 2 times larger (16-bit)
@@not8:
        cmp     bx,TBUF_MAX             ; maximum size is TBUF_MAX, as in
	jbe	@@tbok			; the real mode we have to save
	mov	bx,TBUF_MAX		; memory...

@@tbok: mov	[dsmTBufSize],bx	; save temporary buffer size
	add	ax,bx			; temporary buffer and volume table
					; are in the same segment, with the
					; buffer following the volume table

        test    [dsmMode],sd8bit        ; If using a 8-bit mixing mode,
        jz      @@avt                   ; allocate memory for post-processing
        add     ax,PP8SIZE              ; table also in the volume table
                                        ; segment, after the temporary buffer
@@avt:
        ; Allocate memory for volume table, temporary mixing buffer and
        ; possible post-processing table:
        call    memAlloc LANG, ax, seg dsmVolTableMem offset dsmVolTableMem
        test    ax,ax
        jnz     @@err

IFDEF __REALMODE__
        mov     dx,[word dsmVolTableMem+2]      ; point dx:ax to allocated
        mov     ax,[word dsmVolTableMem]        ; block

        add     ax,15
	shr	ax,4			; calculate volume table segment
	add	dx,ax			; ( (off+15)/16 + seg )
	mov	[dsmVolTableSeg],dx
ELSE
IFDEF __DPMI__
        ; Protected mode under DPMI - allocate descriptor for volume table
        ; segment:
        call    dpmiAllocDescriptor LANG, seg dsmVolTableSeg \
                offset dsmVolTableSeg
        test    ax,ax
        jnz     @@err

        ; Get allocated memory area segment base address to dsmMemPtr:
        call    dpmiGetSegmentBase LANG, [word dsmVolTableMem+2], \
                seg dsmMemPtr offset dsmMemPtr
        test    ax,ax
        jnz     @@err

        xor     ebx,ebx
        mov     eax,[dsmMemPtr]                 ; eax = volume table memory
        mov     bx,[word dsmVolTableMem]        ; start address
        add     eax,ebx

        add     eax,0Fh                 ; align to paragraph boundary
        and     eax,not 0Fh

        ; Set volume table segment base address:
        call    dpmiSetSegmentBase LANG, [dsmVolTableSeg], eax
        test    ax,ax
        jnz     @@err

        ; Calculate correct segment limit:
        mov     eax,256*2*VOLLEVELS     ; volume table
        add     ax,[dsmTBufSize]        ; temporary mixing buffer
        test    [dsmMode],sd8bit
        jz      @@n8
        add     ax,PP8SIZE              ; post-processing table in 8-bit modes
@@n8:
        ; Set volume table segment limit:
        call    dpmiSetSegmentLimit LANG, [dsmVolTableSeg], eax
        test    ax,ax
        jnz     @@err

        mov     dx,[dsmVolTableSeg]
ENDIF
ENDIF

	mov	[word dsmTempBuffer],256*2*VOLLEVELS	; temp buffer offset
	mov	[word dsmTempBuffer+2],dx		; and segment

        test    [dsmMode],sd8bit        ; calculate post-processing table
        jz      @@noppt                 ; address if in 8-bit mode

        mov     ax,256*2*VOLLEVELS
        add     ax,[dsmTBufSize]        ; ax = table start offset
        mov     [word pp8Table],ax      ; store table pointer in pp8Table
        mov     [word pp8Table+2],dx

@@noppt:
	mov	[dsmMasterVolume],64	; set master volume to maximum
	mov	[dsmMixPos],0		; start mixing from the beginning
					; of the buffer
	call	dsmSetUpdRate LANG, 5000 ; set the update rate to 50Hz
        test    ax,ax
        jnz     @@err

	; Allocate memory for instrument structures:
        call    memAlloc LANG, MAXINSTS * SIZE dsmInstrument, \
                        seg dsmInstruments offset dsmInstruments
        test    ax,ax
        jnz     @@err

        les     di,[dsmInstruments]     ; point es:di to instrument structures
	mov	cx,MAXINSTS

        ; initialize all instruments to reasonable states:
@@instlp:
	mov	[es:di+dsmInstrument.inuse],0	; instrument not in use
	mov	[es:di+dsmInstrument.sample],0	; point sample to NULL
	add	di,SIZE dsmInstrument		; point es:di to next inst
	loop	@@instlp


	; now clear the DMA playing buffer, as it may contain garbage
        call    dsmClearBuffer

        jmp     @@done


@@err:
        ERROR   ID_dsmInit

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmClose(void);
;*
;* Description:  Uninitializes DSM
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmClose	FAR

IFDEF __DPMI__
        ; Deallocate volume table segment descriptor:
        call    dpmiFreeDescriptor LANG, [dsmVolTableSeg]
        test    ax,ax
        jnz     @@err
ENDIF
	; Deallocate volume table and possible temporary buffer:
	call	memFree LANG, [dsmVolTableMem]
        test    ax,ax
        jnz     @@err

	; Deallocate instrument structures:
	call	memFree LANG, [dsmInstruments]
        test    ax,ax
        jnz     @@err

        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmClose

@@done:
	ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dsmGetMixRate(ushort *mixRate);
;*
;* Description: Reads the actual mixing rate
;*
;* Returns:     Midas error code.
;*              Mixing rate, in Hz, is stored in *mixRate
;*
;\***************************************************************************/

PROC    dsmGetMixRate   FAR     mixRate : dword

	mov	ax,[dsmMixRate]
        les     bx,[mixRate]
        mov     [es:bx],ax              ; store mixing rate to *mixRate

        xor     ax,ax                   ; always successful

	ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dsmGetMode(ushort *mode);
;*
;* Description: Reads the actual output mode
;*
;* Returns:     MIDAS error code.
;*              Output mode is stored in *mode.
;*
;\***************************************************************************/

PROC    dsmGetMode      FAR     mode : dword

	mov	ax,[dsmMode]
        les     bx,[mode]
        mov     [es:bx],ax              ; store output mode in *mode

        xor     ax,ax                   ; always successful

	ret
ENDP




;/***************************************************************************\
;*
;* Function:     int dsmOpenChannels(unsigned channels);
;*
;* Description:  Opens channels for output
;*
;* Input:        unsigned channels      number of channels to open
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmOpenChannels FAR	channels : word
USES	di

        mov     [dsmMuted],0            ; not muted
        mov     [dsmPaused],0           ; not paused

        ; calculate channel structure table size:
	mov	ax,SIZE dsmChannel
	mul	[channels]

        ; allocate memory for channel structures:
        call    memAlloc LANG, ax, seg dsmChannels offset dsmChannels
        test    ax,ax
        jnz     @@err

        mov     [dsmChPlay],0           ; do not play data on channels
        mov     ax,[channels]           ; save number of channels
        mov     [dsmChOpen],ax

        mov     bx,64                   ; default amplification level is 64
        test    [dsmMode],sd8bit        ; if the output mode is 16-bit
        jz      @@not8b                 ; (no clipping)

        cmp     ax,4                    ; use amplification 64 for four
        jbe     @@not8b                 ; channels or less

        mov     cx,14                   ; for five channels or more the
        mul     cx                      ; amplification level is
        mov     bx,ax                   ; 14 * number of channels

@@not8b:
        ; Calculate the volume table and set amplification level:
        call    dsmSetAmplification LANG, bx


	call	dsmClearChannels LANG	; clear all channels
        test    ax,ax
        jnz     @@err

        mov     [dsmChPlay],1           ; play data on channels

        xor     ax,ax                   ; successful
        jmp     @@done


@@err:
        ERROR   ID_dsmOpenChannels

@@done:
	ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dsmCalcVolTable(ushort amplification);
;*
;* Description: Calculates a new volume table
;*
;* Input:       ushort amplification    Amplification level. 64 = normal
;*                                      (100%), 32 = 50%, 128 = 200% etc.
;*
;* Returns:     MIDAS error code.
;*
;\***************************************************************************/

PROC    dsmCalcVolTable FAR     amplification : word
USES    di,si

        ; All mixing modes use a 16-bit signed volume table

        mov     es,[dsmVolTableSeg]
	xor	edi,edi 		; index in table
	mov	cx,256*VOLLEVELS	; number of volume table entries

        movsx   esi,[amplification]

@@vtlp: mov	ax,di

        and     ax,0FFh                 ; ax = signed volume table entry
        sub     ax,128                  ; at full volume (volume table is
        shl     ax,8                    ; 16-bit signed)

        test    [dsmMode],sd8bit        ; 8-bit mixing?
        jz      @@not8                  ; if yes, scale maximum value
        sar     ax,16-MIX8BITS          ; according to number of bits used

@@not8:
	mov	bx,di
	shr	bx,8			; bx = volume
        imul    bx                      ; multiply with volume
	mov	bx,VOLLEVELS - 1
        idiv    bx                      ; divide with maximum volume

        cwd
        idiv    [dsmChOpen]             ; divide with number of channels

        cwde                            ; eax = volume table value

        test    [dsmMode],sd16bit       ; do not take amplification into
        jz      @@noamp                 ; account here if not in 16-bit mode
        imul    esi                     ; multiply with amplification
        sar     eax,6                   ; and divide by 64

@@noamp:
        mov     [es:edi+edi],ax         ; store value in volume table

@@vtlb: inc	edi			; next value
	loop	@@vtlp


        test    [dsmMode],sd8bit
        jz      @@noppt

        ; Now build post-processing table for 8-bit mixing:

        les     di,[pp8Table]           ; point es:di to table
        mov     cx,PP8SIZE
        xor     bx,bx
        movsx   esi,[amplification]     ; esi = amplification level

@@pptlp:
        mov     ax,bx
        sub     ax,PP8SIZE / 2          ; eax = current table value
        cwde

        imul    esi                     ; multiply by amplification level
        sar     eax,6                   ; and divide by 64

        sar     eax,MIX8BITS - 8        ; convert eax to an unsigned 8-bit
        add     eax,128                 ; value

        test    eax,eax                 ; is eax negative?
        jns     @@noc1
        xor     eax,eax                 ; if is, clip it to 0
        jmp     @@vok

@@noc1:
        cmp     eax,255                 ; is eax > 255?
        jbe     @@vok
        mov     eax,255                 ; if is, clip it to 255

@@vok:
        mov     [es:di],al              ; store value in table
        inc     di
        inc     bx
        dec     cx
        jnz     @@pptlp

@@noppt:
        xor     ax,ax
        ret
ENDP



IFNDEF CUTDOWN


;/***************************************************************************\
;*
;* Function:    int dsmGetMainVU(ushort *leftVU, ushort *rightVU);
;*
;* Description: Gets the main output VU-meter values
;*
;* Input:       ushort *leftVU          Pointer to left channel VU-meter
;*                                      value (0-63)
;*              ushort *rightVU         Pointer to right channel VU-meter
;*                                      value (0-63)
;*
;* Returns:     MIDAS error code. Left channel VU-meter value is stored in
;*              *leftVU, and right channel value in *rightVU
;*
;\***************************************************************************/

PROC    dsmGetMainVU    FAR     leftVU : dword, rightVU : dword
USES    si,di
LOCAL   start : word, bleft : word, chanNum : word, leftVal : word

        mov     ax,[dsmLastMixStart]
        mov     [start],ax              ; start = buffer start position
        mov     ax,[dsmLastMixLen]
        mov     [bleft],ax              ; bleft = number of bytes to calculate

        cmp     [dsmMode],sd8bit or sdMono
        je      @@8mono
        cmp     [dsmMode],sd8bit or sdStereo
        je      @@8stereo
        cmp     [dsmMode],sd16bit or sdMono
        je      @@16mono
        cmp     [dsmMode],sd16bit or sdStereo
        je      @@16stereo

        mov     ax,errUndefined         ; unknown output mode - return
        jmp     @@err                   ; undefined error


@@8stereo:
        mov     [chanNum],0             ; left channel

@@8schan:
        mov     ax,[dsmLastMixLen]
        mov     [bleft],ax              ; bleft = number of bytes to calculate

        ; do for one channel
        mov     dl,255                  ; dl = smallest value found
        xor     dh,dh                   ; dh = largest value found

        les     si,[dsmBuffer]          ; point es:si to mixing buffer
        add     si,[dsmLastMixStart]

@@do8s:
        mov     cx,[bleft]              ; cx = number of bytes left
        mov     ax,[dsmBufferEnd]       ; ax = number of bytes before
        sub     ax,si                   ; buffer end
        cmp     cx,ax
        jb      @@8sok1                 ; do not calculate past buffer end
        mov     cx,ax
@@8sok1:
        sub     [bleft],cx              ; decrease number of bytes left

        shr     cx,1                    ; number of bytes left for current
                                        ; channel

        cmp     [chanNum],0             ; left channel?
        je      @@8s1                   ; if not, process right channel data
        inc     si                      ; instead

@@8s1:
@@8slp:
        mov     al,[es:si]              ; get byte from buffer
        add     si,2                    ; next byte for current channel
        cmp     al,dl                   ; is value below the smallest value
        jb      @@8ssm                  ; found?
        cmp     al,dh                   ; is value above the largest value
        ja      @@8ssl                  ; found?
        dec     cx                      ; decrease number of bytes
        jnz     @@8slp                  ; more data left?
        jmp     @@8slpd

@@8ssm:
        mov     dl,al                   ; new smallest value
        dec     cx                      ; decrease number of bytes
        jnz     @@8slp                  ; more data left?
        jmp     @@8slpd

@@8ssl:
        mov     dh,al                   ; new largest value
        dec     cx                      ; decrease number of bytes
        jnz     @@8slp                  ; more data left?

@@8slpd:
        cmp     [bleft],0               ; more bytes left?
        je      @@8sd
        mov     si,[word dsmBuffer]     ; yes - move to buffer beginning
        jmp     @@do8s                  ; and continue processing

@@8sd:  xor     ax,ax
        mov     al,dh                   ; ax = largest - smallest value
        sub     al,dl                   ; (range 0-255)
        shr     ax,2                    ; ax = ax / 4 (range 0-63)

        cmp     [chanNum],1             ; was this the right channel?
        je      @@8sbcd                 ; if yes, we are done

        mov     [leftVal],ax            ; no, store left channel value
        inc     [chanNum]               ; and process right channel
        jmp     @@8schan

@@8sbcd:
        mov     cx,ax                   ; cx = ax = right channel VU value
        mov     bx,[leftVal]            ; bx = left channel VU value
        jmp     @@vudone


@@8mono:
        mov     dl,255                  ; dl = smallest value found
        mov     dh,0                    ; dh = largest value found

        les     si,[dsmBuffer]          ; point es:si to mixing buffer
        add     si,[start]

@@do8m:
        mov     cx,[bleft]              ; cx = number of bytes left
        mov     ax,[dsmBufferEnd]       ; ax = number of bytes before
        sub     ax,si                   ; buffer end
        cmp     cx,ax
        jb      @@8mok1                 ; do not calculate past buffer end
        mov     cx,ax
@@8mok1:
        sub     [bleft],cx              ; decrease number of bytes left

@@8mlp:
        mov     al,[es:si]              ; get byte from buffer
        inc     si                      ; next byte
        cmp     al,dl                   ; is value below the smallest value
        jb      @@8msm                  ; found?
        cmp     al,dh                   ; is value above the largest value
        ja      @@8msl                  ; found?
        dec     cx                      ; decrease number of bytes
        jnz     @@8mlp                  ; more bytes left?
        jmp     @@8mlpd

@@8msm:
        mov     dl,al                   ; new smallest value
        dec     cx                      ; decrease number of bytes
        jnz     @@8mlp                  ; more bytes left?
        jmp     @@8mlpd

@@8msl:
        mov     dh,al                   ; new largest value
        dec     cx                      ; decrease number of bytes
        jnz     @@8mlp                  ; more bytes left?

@@8mlpd:
        cmp     [bleft],0               ; more bytes left?
        je      @@8md
        mov     si,[word dsmBuffer]     ; yes - move to buffer beginning
        jmp     @@do8m                  ; and continue processing

@@8md:  mov     al,dh                   ; al = largest - smallest value
        sub     al,dl                   ; (range 0-255)
        xor     ah,ah
        shr     ax,2                    ; ax = ax / 4 (range 0-63)
        mov     bx,ax                   ; bx = ax = left channel VU value
        mov     cx,ax                   ; cx = ax = right channel VU value
        jmp     @@vudone



@@16stereo:
        mov     [chanNum],0             ; left channel

@@16schan:
        mov     ax,[dsmLastMixLen]
        mov     [bleft],ax              ; bleft = number of bytes to calculate

        ; do for one channel
        mov     bx,32767                ; bx = smallest value found
        mov     dx,-32767               ; dx = largest value found

        les     si,[dsmBuffer]          ; point es:si to mixing buffer
        add     si,[dsmLastMixStart]

@@do16s:
        mov     cx,[bleft]              ; cx = number of bytes left
        mov     ax,[dsmBufferEnd]       ; ax = number of bytes before
        sub     ax,si                   ; buffer end
        cmp     cx,ax
        jb      @@16sok1                ; do not calculate past buffer end
        mov     cx,ax
@@16sok1:
        sub     [bleft],cx              ; decrease number of bytes left

        shr     cx,2                    ; number of words left for current
                                        ; channel

        cmp     [chanNum],0             ; left channel?
        je      @@16s1                  ; if not, process right channel data
        add     si,2                    ; instead

@@16s1:
@@16slp:
        mov     ax,[es:si]              ; get word from buffer
        add     si,4                    ; next word
        cmp     ax,bx                   ; is value below the smallest value
        jl      @@16ssm                 ; found?
        cmp     ax,dx                   ; is value above the largest value
        jg      @@16ssl                 ; found?
        dec     cx                      ; decrease number of words
        jnz     @@16slp                 ; more words left?
        jmp     @@16slpd

@@16ssm:
        mov     bx,ax                   ; new smallest value
        dec     cx                      ; decrease number of words
        jnz     @@16slp                 ; more words left?
        jmp     @@16slpd

@@16ssl:
        mov     dx,ax                   ; new largest value
        dec     cx                      ; decrease number of words
        jnz     @@16slp                 ; more words left?

@@16slpd:
        cmp     [bleft],0               ; more bytes left?
        je      @@16sd
        mov     si,[word dsmBuffer]     ; yes - move to buffer beginning
        jmp     @@do16s                 ; and continue processing

@@16sd: mov     ax,dx                   ; ax = largest - smallest value
        sub     ax,bx                   ; (range 0-65535)
        shr     ax,10                   ; ax = ax / 1024 (range 0-63)

        cmp     [chanNum],1             ; was this the right channel?
        je      @@16sbcd                ; if yes, we are done

        mov     [leftVal],ax            ; no, store left channel value
        inc     [chanNum]               ; and process right channel
        jmp     @@16schan

@@16sbcd:
        mov     cx,ax                   ; cx = ax = right channel VU value
        mov     bx,[leftVal]            ; bx = left channel VU value
        jmp     @@vudone


@@16mono:
        mov     bx,32767                ; bx = smallest value found
        mov     dx,-32767               ; dx = largest value found

        les     si,[dsmBuffer]          ; point es:si to mixing buffer
        add     si,[start]

@@do16m:
        mov     cx,[bleft]              ; cx = number of bytes left
        mov     ax,[dsmBufferEnd]       ; ax = number of bytes before
        sub     ax,si                   ; buffer end
        cmp     cx,ax
        jb      @@16mok1                ; do not calculate past buffer end
        mov     cx,ax
@@16mok1:
        sub     [bleft],cx              ; decrease number of bytes left

        shr     cx,1                    ; number of words to go

@@16mlp:
        mov     ax,[es:si]              ; get word from buffer
        add     si,2                    ; next word
        cmp     ax,bx                   ; is value below the smallest value
        jl      @@16msm                 ; found?
        cmp     ax,dx                   ; is value above the largest value
        jg      @@16msl                 ; found?
        dec     cx                      ; decrease number of words
        jnz     @@16mlp                 ; more words left?
        jmp     @@16mlpd

@@16msm:
        mov     bx,ax                   ; new smallest value
        dec     cx                      ; decrease number of words
        jnz     @@16mlp                 ; more words left?
        jmp     @@16mlpd

@@16msl:
        mov     dx,ax                   ; new largest value
        dec     cx                      ; decrease number of words
        jnz     @@16mlp                 ; more words left?
        jmp     @@16mlpd

@@16mlpd:
        cmp     [bleft],0               ; more bytes left?
        je      @@16md
        mov     si,[word dsmBuffer]     ; yes - move to buffer beginning
        jmp     @@do16m                 ; and continue processing

@@16md: mov     ax,dx                   ; ax = largest - smallest value
        sub     ax,bx                   ; (range 0-65535)
        shr     ax,10                   ; ax = ax / 1024 (range 0-63)
        mov     bx,ax                   ; bx = ax = left channel VU value
        mov     cx,ax                   ; cx = ax = right channel VU value
        jmp     @@vudone

@@vudone:
        les     di,[leftVU]             ; left channel VU-meter value = bx
        mov     [es:di],bx

        les     di,[rightVU]            ; right channel VU-meter value = cx
        mov     [es:di],cx

@@ok:   xor     ax,ax
        jmp     @@done

@@err:
        ERROR   ID_dsmGetMainVU

@@done:
        ret
ENDP


ENDIF



;/***************************************************************************\
;*
;* Function:     int dsmCloseChannels(void);
;*
;* Description:  Closes open channels
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC    dsmCloseChannels FAR

        ; Check that channels have been opened
        cmp     [dsmChOpen],0
        jne     @@chok
        mov     ax,errNoChannels
        jmp     @@err

@@chok:
        mov     [dsmChPlay],0           ; do not play data on channels

        ; deallocate channel structures:
        call    memFree LANG, [dsmChannels]
        test    ax,ax
        jnz     @@err

	mov	[dsmChOpen],0		; no open channels

        call    dsmClearBuffer          ; clear DMA buffer
        jmp     @@done

@@err:
        ERROR   ID_dsmCloseChannels

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmClearChannels(void);
;*
;* Description:  Clears open channels (removes all sounds)
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmClearChannels  FAR

	mov	cx,[dsmChOpen]		; number of open channels
	test	cx,cx			; if none open, error
        jnz     @@chok
        mov     ax,errNoChannels
        jmp     @@err

@@chok:
        les     bx,[dsmChannels]        ; point es:bx to channel structures

@@chlp:
	mov	[es:bx+dsmChannel.hasData],0	; no data to be played
	mov	[es:bx+dsmChannel.muted],0	; not muted
	mov	[es:bx+dsmChannel.inst],0	; no instrument selected
        mov     [es:bx+dsmChannel.instChanged],0     ; instrument not changed
        mov     [es:bx+dsmChannel.smpPos],smpNone    ; no sample
        mov     [es:bx+dsmChannel.rate],0       ; no rate set
	mov	[es:bx+dsmChannel.panning],panMiddle

        add     bx,SIZE dsmChannel      ; next channel
	loop	@@chlp

        xor     ax,ax                   ; success
        jmp     @@done


@@err:
        ERROR   ID_dsmClearChannels

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmMute(int mute);
;*
;* Description:  Mutes all channels
;*
;* Input:        int mute               1 = mute, 0 = un-mute
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmMute 	FAR		mute : word

        mov     ax,[mute]
        mov     [dsmMuted],ax

	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmPause(int pause);
;*
;* Description:  Pauses or resumes the playing
;*
;* Input:        int pause              1 = pause, 0 = resume
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmPause	FAR		pause : word

        mov     ax,[pause]              ; copy paused flag
        mov     [dsmPaused],ax

        call    dsmClearBuffer LANG     ; clear playing buffer

        ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmSetMasterVolume(uchar masterVolume);
;*
;* Description:  Sets the master volume
;*
;* Input:        uchar masterVolume     master volume (0 - 64)
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC    dsmSetMasterVolume FAR  masterVolume : byte

        mov     al,[masterVolume]
        mov     [dsmMasterVolume],al

        xor     ax,ax                   ; always successful

        ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmGetMasterVolume(uchar *masterVolume);
;*
;* Description:  Gets the master volume
;*
;* Input:        uchar *masterVolume    pointer to master volume (0-64)
;*
;* Returns:      MIDAS error code. Master volume is placed in *masterVolume.
;*
;\***************************************************************************/

PROC    dsmGetMasterVolume FAR  masterVolume : dword

        mov     al,[dsmMasterVolume]
        les     bx,[masterVolume]
        mov     [es:bx],al

        xor     ax,ax                   ; always successful

        ret
ENDP





;/***************************************************************************\
;*
;* Function:    int dsmSetAmplification(unsigned amplification);
;*
;* Description: Sets amplification level and calculates new volume table.
;*
;* Input:       unsigned amplification  amplification level, 64 = normal
;*
;* Returns:     MIDAS error code.
;*
;\***************************************************************************/

PROC    dsmSetAmplification     FAR     amplification : word

        mov     ax,[amplification]
        mov     [dsmAmplification],ax

        call    dsmCalcVolTable LANG, ax

        xor     ax,ax
        ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dsmGetAmplification(unsigned *amplification);
;*
;* Description: Gets amplification level.
;*
;* Input:       unsigned *amplification   pointer to amplification level
;*
;* Returns:     MIDAS error code. Amplification level is written to
;*              *amplification.
;*
;\***************************************************************************/

PROC    dsmGetAmplification     FAR     amplification : dword

        mov     ax,[dsmAmplification]
        les     bx,[amplification]
        mov     [es:bx],ax

        xor     ax,ax
        ret
ENDP




;/***************************************************************************\
;*
;* Function:     int dsmPlaySound(unsigned channel, ulong rate);
;*
;* Description:  Plays a sound
;*
;* Input:        unsigned channel       channel number
;*               ulong rate             playing rate in Hz
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmPlaySound	FAR	channel : word, rate : dword

	call	dsmSetPosition LANG, [channel], 0	; start from the
	test	ax,ax					; beg. of the sample
        jnz     @@err
	call	dsmSetRate LANG, [channel], [rate]	; set playing rate
	test	ax,ax
        jnz     @@err

        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmPlaySound

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmStopSound(unsigned channel);
;*
;* Description:  Stops playing a sound
;*
;* Input:        unsigned channel       channel number
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmStopSound	FAR	channel : word

	ChanPtr es, bx, [channel]	; point es:bx to channel structure
	mov	[es:bx+dsmChannel.hasData],0	; channel has no data to
						; be played
        xor     ax,ax
        jmp     @@done

@@err:
        ERROR   ID_dsmStopSound

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmSetRate(unsigned channel, ulong rate);
;*
;* Description:  Sets the playing rate
;*
;* Input:        unsigned channel        channel number
;*		 ulong rate		 playing rate in Hz
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmSetRate	FAR	channel : word, rate : dword

	ChanPtr es, bx, [channel]	; point es:bx to channel structure

	mov	eax,[rate]
	mov	[es:bx+dsmChannel.rate],eax	; set playing rate on channel

        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmSetRate
@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmGetRate(unsigned channel, ulong *rate);
;*
;* Description:  Returns the playing rate or zero if nothing is being
;*		 played
;*
;* Input:        unsigned channel       channel number
;*               ulong *rate            pointer to playing rate
;*
;* Returns:      MIDAS error code.
;*               Playing rate, in Hz, or zero, if nothing is being
;*               played, is stored in *rate
;*
;\***************************************************************************/

PROC    dsmGetRate      FAR     channel : word, rate : dword
USES    si

        lgs     si,[rate]               ; point gs:si to rate variable

	ChanPtr es, bx, [channel]	; point es:bx to channel structure

	cmp	[es:bx+dsmChannel.hasData],0	; data on channel?
	je	@@nodata

        ; get playing rate:
        mov     eax,[es:bx+dsmChannel.rate]
        jmp     @@ok

@@nodata:
        ; no data - return 0 in *rate:
        xor     eax,eax
@@ok:
        mov     [gs:si],eax             ; store playing rate in *rate
        xor     ax,ax                   ; success
        jz      @@done

@@err:
        ERROR   ID_dsmGetRate
@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmSetVolume(unsigned channel, uchar volume);
;*
;* Description:  Sets the volume
;*
;* Input:        unsigned channel       channel number
;*               uchar volume           volume (0 - 64)
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC    dsmSetVolume    FAR     channel : word, volume : byte

	ChanPtr es, bx, [channel]	; point es:bx to channel structure

        mov     al,[volume]             ; ax = new volume
        cmp     al,64                   ; is volume > 64?
	jbe	@@ok
        mov     al,64                   ; volume limit is 64

@@ok:	mov	[es:bx+dsmChannel.volume],al	; set new volume

        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmSetVolume

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmGetVolume(unsigned channel, uchar *volume);
;*
;* Description:  Gets the volume
;*
;* Input:        unsigned channel       channel number
;*               uchar *volume          pointer to volume (0 - 64)
;*
;* Returns:      MIDAS error code. Volume is written to *volume.
;*
;\***************************************************************************/

PROC    dsmGetVolume    FAR     channel : word, volume : dword

	ChanPtr es, bx, [channel]	; point es:bx to channel structure

        mov     al,[es:bx+dsmChannel.volume]
        les     bx,[volume]
        mov     [es:bx],al

        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmGetVolume

@@done:
	ret
ENDP




;/***************************************************************************\
;*
;* Function:     int dsmSetInstrument(unsigned channel, ushort inst);
;*
;* Description:  Sets instrument number
;*
;* Input:        unsigned channel       channel number
;*               ushort inst            instrument number
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmSetInstrument FAR	channel : word, inst : word
USES	si

        ChanPtr es, bx, [channel]       ; point es:bx to channel structure

	mov	ax,[inst]

        test    ax,ax
        jz      @@badinst               ; check that the instrument number
        js      @@badinst               ; is valid - 0 < inst <= MAXINSTS
        cmp     ax,MAXINSTS
        jbe     @@1

@@badinst:
        mov     ax,errInvalidInstHandle ; invalid instrument handle
        jmp     @@err

@@1:
	dec	ax			; instrument numbers start from 1
	InstPtr gs, si, ax		; point gs:si to instrument structure
	cmp	[gs:si+dsmInstrument.inuse],1	; is instrument in use?
        je      @@2

        mov     ax,errInvalidInstHandle ; invalid instrument handle
        jmp     @@err

@@2:
        mov     ax,[inst]
        mov     [es:bx+dsmChannel.inst],ax      ; set new instrument number

        mov     al,[gs:si+dsmInstrument.volume] ; set instrument default
        mov     [es:bx+dsmChannel.volume],al    ; volume as the playing volume

        cmp     [ALE],1
        je      @@ale


        ; no Amiga Loop Emulation - copy instrument data (sample pointer etc.
        ; to channel structure so that instrument will be used now):

        call    dsmUseInstrument

        cmp     [es:bx+dsmChannel.hasData],1
	jne	@@nodata

        ; Data is being played on the channel - reset the playing position
        ; to make sure playing does not continue past the end of the
        ; instrument
        call    dsmSetPosition LANG, [channel], [es:bx+dsmChannel.pos]
        test    ax,ax
        jnz     @@err

@@nodata:
        xor     ax,ax                   ; success
        jmp     @@done


@@ale:
        ; Amiga Loop Emulation is active - do not set instrument values to
        ; channel structure. Just flag that the instrument has been changed.
        ; The values will be set when the current sample or sample loop ends
        ; or the playing position is set.
        mov     [es:bx+dsmChannel.instChanged],1        ; instrument has been
                                                        ; changed

        ; If data is being played, we are done.
        cmp     [es:bx+dsmChannel.hasData],1
        je      @@aledone

        ; Data is not being played - if the new sample is looping and a
        ; sampling rate has been set, start playing from the loop
        ; beginning
        cmp     [gs:si+dsmInstrument.looping],1
        jne     @@aledone

        ; Check if a playing rate has been set to the channel. If not, don't
        ; start playing.
        cmp     [es:bx+dsmChannel.rate],0
        je      @@aledone

        ; Start playing from loop start: (dsmSetPosition() sets the
        ; instrument values to channel structure)
        call    dsmSetPosition LANG, [channel], \
                [gs:si+dsmInstrument.loopStart]
        test    ax,ax
        jnz     @@err


@@aledone:
        xor     ax,ax
        jmp     @@done

@@err:
        ERROR   ID_dsmSetInstrument

@@done:
	ret
ENDP




;/***************************************************************************\
;*
;* Function:     int dsmGetInstrument(unsigned channel, ushort *inst);
;*
;* Description:  Gets instrument number
;*
;* Input:        unsigned channel       channel number
;*               ushort *inst           pointer to instrument number
;*
;* Returns:      MIDAS error code. Instrument number is written to *inst.
;*
;\***************************************************************************/

PROC    dsmGetInstrument FAR    channel : word, inst : dword
USES	si

	ChanPtr es, bx, [channel]	; point es:bx to channel structure

        mov     ax,[es:bx+dsmChannel.inst]
        les     bx,[inst]
        mov     [es:bx],ax

        xor     ax,ax
        jmp     @@done

@@err:
        ERROR   ID_dsmGetInstrument

@@done:
	ret
ENDP




;/***************************************************************************\
;*
;* Function:    dsmUseInstrument
;*
;* Description: Sets the instrument values on a channel to the channel
;*              structure so that the instrument specified by
;*              dsmChannel.inst will be used for playing.
;*
;* Input:       es:bx                   pointer to channel structure
;*
;* Destroys:    eax, dx
;*
;\***************************************************************************/

PROC NOLANGUAGE dsmUseInstrument        NEAR

        push    gs si

        mov     ax,[es:bx+dsmChannel.inst]      ; ax = instrument number
        dec     ax                              ; (table starts from 0)
        InstPtr gs, si, ax                      ; point ds:si to inst struct

        mov     eax,[gs:si+dsmInstrument.sample]        ; copy sample
        mov     [es:bx+dsmChannel.sample],eax           ; pointer

        mov     al,[gs:si+dsmInstrument.smpType]        ; copy sample type
        mov     [es:bx+dsmChannel.smpType],al

        mov     al,[gs:si+dsmInstrument.smpPos]         ; copy sample position
        mov     [es:bx+dsmChannel.smpPos],al

        mov     ax,[gs:si+dsmInstrument.slength]        ; copy sample length
        mov     [es:bx+dsmChannel.slength],ax

        mov     ax,[gs:si+dsmInstrument.loopStart]      ; copy sample loop
        mov     [es:bx+dsmChannel.loopStart],ax         ; start

        mov     ax,[gs:si+dsmInstrument.loopEnd]        ; copy sample loop
        mov     [es:bx+dsmChannel.loopEnd],ax           ; end

        mov     al,[gs:si+dsmInstrument.looping]        ; copy inst looping
        mov     [es:bx+dsmChannel.looping],al           ; flag

        mov     [es:bx+dsmChannel.instChanged],0

        pop     si gs

        ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmSetPosition(unsigned channel, ushort pos);
;*
;* Description:  Sets the playing position from the beginning of instrument
;*
;* Input:        unsigned channel        channel number
;*		 ushort pos		 new position
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmSetPosition	FAR	channel : word, pos : word
USES	si

	ChanPtr es, bx, [channel]	; point es:bx to channel structure

        cmp     [es:bx+dsmChannel.instChanged],1        ; has instrument been
        jne     @@noinstch                              ; changed?
        call    dsmUseInstrument                        ; use new instrument

@@noinstch:
	mov	cx,[pos]		; cx = new position

        mov     ax,[es:bx+dsmChannel.inst]      ; current instrument
        test    ax,ax                   ; is there a instrument selected?
	jz	@@noset 		; if not, then don't play

        cmp     [es:bx+dsmChannel.smpType],smpNone      ; is there a sample?
	je	@@noset

        cmp     [es:bx+dsmChannel.looping],1    ; is instrument looping?
	je	@@looping

        ; instrument is not looping - stop playing if new position is past
        ; sample length:
        cmp     cx,[es:bx+dsmChannel.slength]
        jb      @@set
        call    dsmStopSound LANG, [channel]
        test    ax,ax
        jnz     @@err
	jmp	@@noset

@@looping:
        ; instrument is looping - if new position is past loop end, set it to
        ; loop start:
        cmp     cx,[es:bx+dsmChannel.loopEnd]
        jb      @@set
        mov     cx,[es:bx+dsmChannel.loopStart]

@@set:
	mov	[es:bx+dsmChannel.pos],cx	; set position
	mov	[es:bx+dsmChannel.posl],0	; set position fraction to 0
	mov	[es:bx+dsmChannel.hasData],1	; channel has data

@@noset:
        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmSetPosition

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmGetPosition(unsigned channel, ushort *pos);
;*
;* Description:  Gets the playing position
;*
;* Input:        unsigned channel       channel number
;*               ushort *pos            pointer to the position variable
;*
;* Returns:      MIDAS error code.
;*               Playing position from the beginning of instrument is stored
;*               in *pos.
;*
;\***************************************************************************/

PROC    dsmGetPosition  FAR     channel : word, pos : dword

	ChanPtr es, bx, [channel]	; point es:bx to channel structure
	mov	ax,[es:bx+dsmChannel.pos]

        les     bx,[pos]
        mov     [es:bx],ax              ; store playing position in *pos

        xor     ax,ax
        jmp     @@done

@@err:
        ERROR   ID_dsmGetPosition

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:    int dsmSetPanning(unsigned channel, short panning);
;*
;* Description: Sets the panning status of a channel
;*
;* Input:       unsigned channel      channel number
;*              short panning         panning information (see enum sdPanning)
;*
;* Returns:     MIDAS error code
;*
;\***************************************************************************/

PROC	dsmSetPanning	FAR	channel : word, panning : word

	ChanPtr es, bx, [channel]	; point es:bx to channel structure
	mov	ax,[panning]
        mov     [es:bx+dsmChannel.panning],al

        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmSetPanning

@@done:
	ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dsmGetPanning(unsigned channel, short *panning);
;*
;* Description: Returns the panning status of a channel
;*
;* Input:       unsigned channel        channel number
;*              short *panning          pointer to panning variable
;*
;* Returns:     MIDAS error code.
;*              Panning information is stored in *panning
;*
;\***************************************************************************/

PROC    dsmGetPanning   FAR     channel : word, panning : dword

	ChanPtr es, bx, [channel]	; point es:bx to channel structure
        movsx   ax,[es:bx+dsmChannel.panning]   ; ax = panning value

        cmp     al,panSurround          ; if panning is panSurround, clear
        jne     @@panok                 ; upper nybble, as panSurround is a
        mov     ax,panSurround          ; positive value even if bit 7 is 1

@@panok:
        les     bx,[panning]
        mov     [es:bx],ax              ; store panning info in *panning

        xor     ax,ax                   ; success
	jmp	@@done

@@err:
        ERROR   ID_dsmGetPanning

@@done:
	ret
ENDP




;/***************************************************************************\
;*
;* Function:     int dsmMuteChannel(unsigned channel, int mute);
;*
;* Description:  Mutes/un-mutes a channel
;*
;* Input:	 ushort channel 	 channel number
;*		 ushort mute		 1 = mute, 0 = un-mute
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmMuteChannel	FAR	channel : word, mute : word

	ChanPtr es, bx, [channel]	; point es:bx to channel structure
	mov	ax,[mute]
	mov	[es:bx+dsmChannel.muted],al

        xor     ax,ax                   ; success
	jmp	@@done

@@err:
        ERROR   ID_dsmMuteChannel

@@done:
	ret
ENDP




;/***************************************************************************\
;*
;* Function:    int dsmAddInstrument(void far *sample, int smpType,
;*                      ushort length, ushort loopStart, ushort loopEnd,
;*                      uchar volume, int loop, int copySample,
;*                      ushort *instHandle);
;*
;* Description:  Adds a new instrument to the instrument list
;*
;* Input:        void far *sample       Pointer to sample data. MUST be
;*                                      in conventional memory. Sample
;*                                      data is copied into another memory
;*                                      location and so sample should be
;*                                      deallocated after this function
;*                                      call.
;*               int smpType            sample type (see enum smpTypes)
;*               ushort length          sample length
;*               ushort loopStart       sample loop start
;*               ushort loopEnd         sample loop end
;*               uchar volume           sample default volume (0 - 64)
;*               int loop               looping (1 = looping sample, 0 = not)
;*               int copySample         copy another place in memory? (1=yes)
;*               ushort *instHandle     pointer to variable to store the SD
;*                                      instrument handle
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC    dsmAddInstrument FAR    sample : dword, smpType : word, \
		slength : word, loopStart : word, loopEnd : word,\
                volume : byte, sloop : word, copySample : word, \
                instHandle : dword
USES	si
LOCAL	instNum : word

	les	si,[dsmInstruments]	; point es:si to instrument structures
	xor	bx,bx			; bx = instrument number
	mov	cx,MAXINSTS

	; Attempt to find first unused instrument:
@@ilp:	cmp	[es:si+dsmInstrument.inuse],0
	je	@@inst
	add	si,SIZE dsmInstrument	; point es:si to next inst struct
	inc	bx			; next instrument
	loop	@@ilp

        mov     ax,errNoInstHandles     ; no free instrument handles
        jmp     @@err


@@inst:
	; Unused instrument found. bx contains the instrument number and
	; es:si points to the instrument structure

	mov	[instNum],bx

	mov	[es:si+dsmInstrument.inuse],1	; instrument is in use

	cmp	[smpType],smpNone	; is there a sample?
	je	@@nosmp
	cmp	[slength],0
	je	@@nosmp

        cmp     [copySample],0          ; should sample be copied?
        je      @@nocopy                ; skip allocation etc. if not

        mov     [es:si+dsmInstrument.copied],1  ; copied sample - deallocate
                                                ; when removing instrument

IFNDEF NOEMS
	cmp	[useEMS],0		; should EMS memory be used?
	je	@@conv

        lea     ax,[si+dsmInstrument.sample]    ; point es:ax to current
                                                ; dsmInstrument.sample
	push	es
        call    emsAlloc LANG, [slength], es ax ; allocate EMS for sample
	pop	es
        test    ax,ax
        jnz     @@err

@@emsok:
        ; map EMS block to conventional memory:
        push    es
        call    emsMap LANG, [es:si+dsmInstrument.sample], \
                seg dsmSamplePtr offset dsmSamplePtr
        pop     es
        test    ax,ax
        jnz     @@err

        push    ds es si di
        les     di,[dsmSamplePtr]       ; point es:di to EMS block in memory
        lds     si,[sample]             ; point ds:si to sample data
	mov	cx,[slength]
	cld
        rep     movsb                   ; copy sample data to EMS memory block
	pop	di si es ds

	mov	[es:si+dsmInstrument.smpPos],sdSmpEMS	; sample is in EMS
        jmp     @@smpok


@@conv:
ENDIF
        ; allocate conventional memory for sample:
        lea     ax,[si+dsmInstrument.sample]    ; point es:ax to current
                                                ; dsmInstrument.sample
        push    es
        call    memAlloc LANG, [slength], es ax
	pop	es
        test    ax,ax
        jnz     @@err

	push	si di ds es
        les     di,[es:si+dsmInstrument.sample] ; point es:di to memory
                                                ; allocated for sample
        lds     si,[sample]             ; point ds:si to sample data
        mov     cx,[slength]
	cld
        rep     movsb                   ; copy sample data to new memory area
	pop	es ds di si

        ; sample is in conventional memory:
        mov     [es:si+dsmInstrument.smpPos],sdSmpConv

	jmp	@@smpok

@@nosmp:
        ; no sample:
        mov     [es:si+dsmInstrument.sample],0
	mov	[es:si+dsmInstrument.smpType],smpNone
	mov	[es:si+dsmInstrument.smpPos],sdSmpNone
        jmp     @@smpdone

@@nocopy:
        ; do not copy sample
        mov     eax,[sample]                            ; copy sample pointer
        mov     [es:si+dsmInstrument.sample],eax
        mov     [es:si+dsmInstrument.smpPos],sdSmpConv  ; in conventional mem.
        mov     [es:si+dsmInstrument.copied],0          ; not copied

@@smpok:
        mov     ax,[smpType]
	mov	[es:si+dsmInstrument.smpType],al	; copy sample type

@@smpdone:
        ; copy instrument data: length, loop and volume:
        mov     ax,[slength]
	mov	[es:si+dsmInstrument.slength],ax
	mov	ax,[loopStart]
	mov	[es:si+dsmInstrument.loopStart],ax
	mov	ax,[loopEnd]
	mov	[es:si+dsmInstrument.loopEnd],ax
        mov     al,[volume]
	mov	[es:si+dsmInstrument.volume],al
	mov	ax,[sloop]
	mov	[es:si+dsmInstrument.looping],al

	mov	ax,[instNum]
        inc     ax                      ; instrument handle numbers start at 1
        les     bx,[instHandle]         ; store instrument handle in
        mov     [es:bx],ax              ; *instHandle

        xor     ax,ax                   ; success
	jmp	@@done


@@err:
        ERROR   ID_dsmAddInstrument

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:    int dsmRemInstrument(ushort inst);
;*
;* Description: Removes an instrument from the instrument list, and
;*              deallocates sample memory
;*
;* Input:	ushort inst		instrument number
;*
;* Returns:     MIDAS error code
;*
;\***************************************************************************/

PROC	dsmRemInstrument FAR	inst : word

        mov     ax,[inst]

        test    ax,ax
        jnz     @@1                     ; check that the instrument number
        cmp     ax,MAXINSTS             ; is valid - 0 < inst <= MAXINSTS
        jbe     @@1

        mov     ax,errInvalidInstHandle ; invalid instrument handle
        jmp     @@err

@@1:
	dec	ax
	InstPtr es, bx, ax		; point es:bx to inst data structure

        cmp     [es:bx+dsmInstrument.inuse],1   ; is instrument in use?
        je      @@2

        mov     ax,errInvalidInstHandle ; invalid instrument handle
        jmp     @@err

@@2:
        cmp     [es:bx+dsmInstrument.copied],0  ; do not deallocate sample if
        je      @@dealloc                       ; not copied

        cmp     [es:bx+dsmInstrument.smpPos],sdSmpConv
        je      @@conv

        cmp     [es:bx+dsmInstrument.smpPos],sdSmpNone
        je      @@dealloc

IFNDEF NOEMS
        ; sample is in EMS - deallocate
        push    es bx
        call    emsFree LANG, [es:bx+dsmInstrument.sample]
        pop     bx es
        test    ax,ax
        jnz     @@err
ENDIF

        jmp     @@dealloc

@@conv:
        ; sample is in conventional memory - deallocate
        push    es bx
	call	memFree LANG, [es:bx+dsmInstrument.sample]
        pop     bx es
        test    ax,ax
        jnz     @@err


@@dealloc:
	mov	[es:bx+dsmInstrument.inuse],0	; instrument not in use

        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmRemInstrument

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmSetUpdRate(ushort updRate);
;*
;* Description:  Set channel updating rate (depends on song tempo)
;*
;* Input:	 ushort updRate 	 updating rate in 100*Hz
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	dsmSetUpdRate	FAR	updRate : word

	mov	ax,100
	mul	[dsmMixRate]		; ax = amount of data between two
	div	[updRate]		; updates

        inc     ax                      ; make number of elements even
        and     ax,not 1

	test	[dsmMode],sd16bit
        jz      @@no16                  ; multiply amount by 2 if 16-bit
	shl	ax,1

@@no16:
IFNDEF NOSTEREO
        test    [dsmMode],sdStereo
        jz      @@nostereo              ; multiply amount by 2 if stereo
	shl	ax,1
ENDIF

@@nostereo:
	mov	[dsmUpdateMix],ax
	mov	[dsmMixLeft],ax

        xor     ax,ax                   ; always successful

	ret
ENDP





;/***************************************************************************\
;*
;* Function:    int dsmSetPlayPos(unsigned playPosition);
;*
;* Description: Sets the mixing buffer Sound Device playing position. Called
;*              before calling dsmPlay() and music player, only ONCE for
;*              each MIDAS polling loop. Usually called by
;*              SoundDevice.StartPlay().
;*
;* Returns:     MIDAS error code.
;*
;\***************************************************************************/

PROC    dsmSetPlayPos   FAR     playPosition : word

        mov     ax,[playPosition]       ; copy playing position
        mov     [dsmPlayPos],ax

        xor     ax,ax                   ; success
        ret
ENDP





;/***************************************************************************\
;*
;* Function:     int dsmPlay(int *callMP);
;*
;* Description:  Updates sound device registers or mixes data
;*
;* Returns:      MIDAS error code.
;*               *callMP contains 1 if registers were updated or data mixed
;*               so that new values can be set by, for example, calling the
;*               music player.
;*
;\***************************************************************************/

PROC    dsmPlay         FAR     callMP : dword
LOCAL   mixBytes : word
USES	si,di

	cld

        cmp     [dsmPaused],1           ; is playing paused?
        je      @@paused                ; if yes, skip mixing

        mov     ax,[dsmPlayPos]

	mov	bx,[dsmMixPos]		; mixing position
	cmp	bx,ax			; is dsmMixPos < dmaGetPos()?
	jae	@@1

	mov	cx,ax			; cx = maximum amout to mix
	sub	cx,bx			; = dmaGetPos() - dsmMixPos
	jmp	@@2

@@1:    mov     cx,[dsmBufferLen]       ; cx = maximum amount to mix
        sub     cx,bx                   ; = (dsmBufferLen - dsmMixPos)
        add     cx,ax                   ;   + dsmPlayPos

@@2:	sub	cx,16			; keep 16 bytes of safety distance
					; between mixing pos and DMA pos
	cmp	cx,16
	jl	@@stopmix		; skip if < 16 bytes space in buffer

	cmp	cx,[dsmMixLeft] 	; don't mix more data than there is
	jbe	@@3			; to mix before the next update
	mov	cx,[dsmMixLeft]

@@3:    test    [dsmMode],sd16bit       ; 16-bit?
        jz      @@no16                  ; if yes, mix only an even number
        and     cx,not 3                ; of words
	jmp	@@cok

@@no16:
        and     cx,not 1                ; mix only an even number of bytes

@@cok:
        mov     [mixBytes],cx           ; store number of bytes to mix
	or	cx,cx
	jz	@@endmix

        mov     ax,[dsmMixPos]          ; copy mixing start position to
        mov     [dsmLastMixStart],ax    ; dsmLastMixStart
        mov     [dsmLastMixLen],cx      ; store mixing length to
                                        ; dsmLastMixLength

	test	[dsmMode],sd8bit
	jnz	@@8norm
	jmp	@@16norm


@@8norm:
IFNDEF NOSTEREO
        test    [dsmMode],sdStereo
	jz	@@8nmono

@@8nstereo:
        ; 8-bit stereo output - mix the data using stereo mixing routine and
        ; 8-bit stereo post-processing:
        call    dsmMixData LANG, [mixBytes], offset dsmMixStereo, \
                        offset dsmPProc8Stereo
        test    ax,ax
        jnz     @@err
	jmp	@@endmix
ENDIF

@@8nmono:
        ; 8-bit mono output - mix the data using mono mixing routine and
        ; 8-bit mono post-processing:
        call    dsmMixData LANG, [mixBytes], offset dsmMixMono, \
                        offset dsmPProc8Mono
        test    ax,ax
        jnz     @@err
        jmp     @@endmix


@@16norm:
IFNDEF NOSTEREO
        test    [dsmMode],sdStereo
        jz      @@16nmono

        ; 16-bit stereo output - mix the data using stereo mixing routine and
        ; 16-bit stereo post-processing:
        call    dsmMixData LANG, [mixBytes], offset dsmMixStereo, \
                        offset dsmPProc16Stereo
        test    ax,ax
        jnz     @@err
	jmp	@@endmix
ENDIF

@@16nmono:
        ; 16-bit mono output - mix the data using mono mixing routine and
        ; 16-bit mono post-processing:
        call    dsmMixData LANG, [mixBytes], offset dsmMixMono, \
                        offset dsmPProc16Mono
        test    ax,ax
        jnz     @@err


@@endmix:
	mov	ax,[mixBytes]		; mixBytes bytes were mixed

	sub	[dsmMixLeft],ax 	; is the next update due?
	jz	@@update

	jmp	@@stopmix

@@update:
	mov	ax,[dsmUpdateMix]
	mov	[dsmMixLeft],ax 	; set bytes to mix before next update

        les     bx,[callMP]
        mov     [word es:bx],1          ; music-player should be called now
        xor     ax,ax                   ; success
        jmp     @@done

@@stopmix:
@@paused:
        les     bx,[callMP]
        mov     [word es:bx],0          ; do not call music player

        xor     ax,ax                   ; success
        jmp     @@done


@@err:
        ERROR   ID_dsmPlay

@@done:
	ret
ENDP





;/***************************************************************************\
;*
;* Function:    int dsmMixData(ushort mixBytes, void (near mixRoutine)(void),
;*                      void (near postProcRoutine)(void));
;*
;* Description: Mixes data from all channels
;*
;* Input:       ushort mixBytes         number of bytes to be mixed
;*		void (near mixRoutine)(void)	pointer to actual data mixing
;*                                      function
;*              void (near postProcRoutine)(void)       pointer to mixed data
;*                                      post-processing routine
;*
;* Returns:     MIDAS error code
;*
;* Destroys:    eax, ebx, ecx, edx, es, fs, gs
;*
;* Note:	DSM internal use only, do not call from outside!
;*
;\***************************************************************************/

PROC    dsmMixData      FAR     mixBytes : word, mixRoutine : word, \
                                postProcRoutine : word
USES	si,di
LOCAL   mlen : word, incr : dword, mixPtr : dword, \
        mixLength : word, mixLeft : word, smp : dword, numElems : word, \
        vol : byte, panning : byte

        mov     ax,[mixRoutine]         ; move mixing routine pointer to
        mov     [mixRout],ax            ; mixRout

        mov     ax,[mixBytes]           ; number of bytes to mix in total
        mov     [mixLeft],ax            ; store in mixLeft

@@tbufmix:
        mov     ax,[mixLeft]            ; number of bytes left to mix
        xor     dx,dx
        div     [dsmMixElemSize]        ; ax = number of elements to mix
        mul     [dsmTBufElemSize]       ; ax = number of temporary buffer
                                        ; bytes needed
        cmp     ax,[dsmTBufSize]        ; do not mix more than there is space
        jb      @@lok                   ; for in the temporary buffer
        mov     ax,[dsmTBufSize]
@@lok:
        div     [dsmTBufElemSize]       ; ax = number of elements that can
                                        ; fit in the temporary buffer
        mov     [numElems],ax           ; store number of elements to mix


        mov     [dsmChanNum],0          ; channel number to be mixed


@@chnlp:
        mov     ax,[numElems]           ; mlen = number of elements left to
        mov     [mlen],ax               ; to mix for this channel

        mov     di,[word dsmTempBuffer] ; point di to mixing position

        cmp     [dsmChPlay],1           ; may data in channels be played?
        jne     @@cdone                 ; if not, skip
        cmp     [dsmChOpen],0           ; are any channels open?
        je      @@cdone                 ; if not, we are finished

@@contmix:
        ChanPtr es, bx, [dsmChanNum]    ; point es:bx to channel struct
        cmp     [es:bx+dsmChannel.hasData],0    ; data to be mixed?
	je	@@cdone

        mov     al,[es:bx+dsmChannel.panning]
	mov	[panning],al		; save panning information

        cmp     [dsmMuted],1            ; is DSM muted?
        je      @@muted
        cmp     [es:bx+dsmChannel.muted],0      ; is channel muted?
	je	@@nom
@@muted:
	xor	al,al			; if is, play at zero volume
	jmp	@@vok
@@nom:
        movzx   ax,[es:bx+dsmChannel.volume]
	mul	[dsmMasterVolume]	; calculate actual playing volume
	shr	ax,6			; (volume * masterVolume) / 64
@@vok:
	mov	[vol],al

        mov     ax,[es:bx+dsmChannel.inst]
        test    ax,ax                   ; no mixing if no instrument set on
	jz	@@cdone 		; channel
	dec	ax			; instrument numbers start from 1
	InstPtr gs, si, ax		; point gs:si to instrument struct

	cmp	[gs:si+dsmInstrument.inuse],0
	je	@@cdone 		; skip if no legal instrument
        cmp     [es:bx+dsmChannel.smpType],smp8bit
	jne	@@cdone 		; or sample not of supported type

IFNDEF NOEMS
        cmp     [es:bx+dsmChannel.smpPos],sdSmpEMS      ; is sample in EMS?
	jne	@@smpconv

        push    es bx                   ; map sample into conventional memory
        call    emsMap LANG, [es:bx+dsmChannel.sample], \
                seg dsmSamplePtr offset dsmSamplePtr
        pop     bx es
        test    ax,ax
        jnz     @@err

        mov     eax,[dsmSamplePtr]      ; save sample pointer in conventional
        mov     [smp],eax               ; memory to smp
	jmp	@@smpok

@@smpconv:
ENDIF
        ; sample in conventional memory - point smp to sample data
        mov     eax,[es:bx+dsmChannel.sample]
	mov	[smp],eax
	jmp	@@smpok

@@smpok:
        mov     gs,[word smp+2]         ; point gs to sample segment

        mov     eax,[es:bx+dsmChannel.rate]     ; playing rate
	xor	edx,edx
	shld	edx,eax,16		; eax = sample pos increment =
	shl	eax,16			; rate / dsmMixRate
        movzx   esi,[dsmMixRate]        ; (16.16 bit fixed point number)
        div     esi
	mov	[incr],eax		; store position increment

        cmp     [es:bx+dsmChannel.looping],1    ; looping instrument?
	je	@@cloop


        ; non-looping instrument:

        mov     dx,[es:bx+dsmChannel.pos]
	shl	edx,16			; edx = playing position in channel
        mov     dx,[es:bx+dsmChannel.posl]      ; (16.16 fixed point)
        mov     ax,[es:bx+dsmChannel.slength]
	shl	eax,16			; eax = sample length
	sub	eax,edx 		; eax = amount of data before sample
					; end
        xor     edx,edx                 ; eax = number of destination elements
	div	[incr]			; before sample end

        movzx   ecx,[mlen]              ; amount of data to be mixed
	cmp	ecx,eax 		; will sample end be reached
	jbe	@@cnl1			; before the end of mixing?
	mov	ecx,eax 		; if so, don't mix past sample end

@@cnl1:
        cmp     [vol],0                 ; is volume zero?
        jne     @@nvn0v


        ; Volume is zero - no need to mix, just update the position:

        mov     si,[es:bx+dsmChannel.pos]
        shl     esi,16                          ; esi = mixing position
        mov     si,[es:bx+dsmChannel.posl]

        mov     eax,[incr]              ; eax = position increment
        imul    ecx                     ; eax = number of sample bytes mixed

        add     esi,eax                 ; update position

        mov     [es:bx+dsmChannel.posl],si
        shr     esi,16
        mov     [es:bx+dsmChannel.pos],si

        cmp     [es:bx+dsmChannel.slength],si   ; did we reach sample end?
        jbe     @@cnsend
        jmp     @@cdone

@@nvn0v:
        sub     [mlen],cx
        test    cx,cx                   ; if zero elements do not mix - we
        jz      @@cnsend                ; are at the end of the sample

        push    bx

        mov     si,[word smp]           ; point gs:si to sample start
        add     si,[es:bx+dsmChannel.pos]       ; esi = sample mixing position
        mov     ax,[es:bx+dsmChannel.posl]      ; ax = pos fractional part

        mov     bh,[vol]                ; mixing volume
	mov	edx,[incr]		; mixing position increment
        mov     bl,[panning]            ; panning information
        push    bp
        mov     bp,ax                   ; bp = mixing position fractional part
        call    [word mixRout]          ; mix the sound!
        mov     dx,bp                   ; dx = new position fractional part
        pop     bp

        pop     bx

        mov     [es:bx+dsmChannel.posl],dx      ; new position fraction
        sub     si,[word smp]                   ; substract sample start from
        mov     [es:bx+dsmChannel.pos],si       ; whole part to get new pos

        cmp     si,[es:bx+dsmChannel.slength]   ; past sample end?
	jae	@@cnsend
	jmp	@@cdone

@@cnsend:
        ; sample end has been reached
        cmp     [ALE],1                 ; is Amiga Loop Emulation active?
        je      @@nlale

        ; no Amiga Loop emulation - no data to be mixed:
        mov     [es:bx+dsmChannel.hasData],0
	jmp	@@cdone

@@nlale:
        ; Sample end was reached and Amiga Loop Emulation is active. If
        ; instrument has been changed, set new instrument values to channel
        ; structure and check if playing should be continued with new
        ; instrument. If instrument has not been changed, stop playing
        cmp     [es:bx+dsmChannel.instChanged],1
        je      @@alenewinst
        mov     [es:bx+dsmChannel.hasData],0
	jmp	@@cdone


@@cloop:	; looping instrument
        mov     dx,[es:bx+dsmChannel.pos]
	shl	edx,16			; edx = playing position in channel
        mov     dx,[es:bx+dsmChannel.posl]      ; (16.16 fixed point)
        mov     ax,[es:bx+dsmChannel.loopEnd]
	shl	eax,16			; eax = sample loop end
	sub	eax,edx 		; eax = amount of data before sample
					; loop end
	xor	edx,edx 		; eax = number of destination bytes
	div	[incr]			; before sample loop end
	or	edx,edx 		; if modulus is not zero, one more
	jz	@@cl2			; byte must be mixed in order to
	inc	eax			; actually reach loop end

@@cl2:
        cmp     [vol],0                 ; is volume zero?
        jne     @@ln0v


        ; Volume is zero - no need to mix, only update position:

        mov     edx,eax                 ; edx = number of bytes before
                                        ; loop end
        movzx   ecx,[mlen]              ; ecx = number of bytes to go

@@l0vl:
        mov     eax,ecx
        cmp     eax,edx                 ; do not go past loop end
        jb      @@l0vl1
        mov     eax,edx

@@l0vl1:
        sub     ecx,eax

        mov     si,[es:bx+dsmChannel.pos]
        shl     esi,16                          ; esi = mixing position
        mov     si,[es:bx+dsmChannel.posl]

        imul    [incr]                  ; eax = number of sample bytes mixed

        add     esi,eax                 ; update position

        mov     [es:bx+dsmChannel.posl],si
        shr     esi,16
        mov     [es:bx+dsmChannel.pos],si

        cmp     [es:bx+dsmChannel.loopEnd],si   ; did we reach loop end?
        ja      @@cdone                         ; if not, all is fine

        mov     ax,[es:bx+dsmChannel.loopStart] ; go to loop beginning
        mov     [es:bx+dsmChannel.pos],ax

        test    cx,cx
        jz      @@cdone

        xor     eax,eax
        mov     ax,[es:bx+dsmChannel.loopEnd]           ; eax = loop length
        sub     ax,[es:bx+dsmChannel.loopStart]

        shl     eax,16
	xor	edx,edx 		; eax = number of destination bytes
        div     [incr]                  ; in whole before sample loop
        test    edx,edx                 ; if modulus is not zero, one more
        jz      @@l0v2                  ; byte must be mixed in order to
	inc	eax			; actually reach loop end

@@l0v2:
        ; Divide the number of bytes left (ecx) with the loop length in
        ; destination bytes (eax). The modulus of the division is the number
        ; of bytes to go. This ensures that the loop will not be repeated
        ; more than once again.

        mov     esi,eax
        mov     eax,ecx
        xor     edx,edx
        idiv    esi
        mov     ecx,edx
        mov     edx,esi                 ; number of bytes before loop end
        jmp     @@l0vl


@@ln0v:
	movzx	ecx,[mlen]		; amount of data to be mixed
	cmp	ecx,eax 		; will sample loop end be reached
	jbe	@@cl1			; before the end of mixing?
	mov	ecx,eax 		; if so, don't mix past loop end

@@cl1:	sub	[mlen],cx		; decrease amount of data to be mixed
	or	cx,cx			; if zero bytes do mix, we are at
	jz	@@cnsend		; end of sample loop

        push    bx

        mov     si,[word smp]                   ; point gs:si to sample
        add     si,[es:bx+dsmChannel.pos]       ; esi = sample mixing position
        mov     ax,[es:bx+dsmChannel.posl]      ; ax = pos fractional part

        mov     bh,[vol]                ; mixing volume
	mov	edx,[incr]		; mixing position increment
        mov     bl,[panning]            ; panning information
        push    bp
        mov     bp,ax                   ; bp = mixing position fractional part
        call    [word mixRout]          ; mix the sound!
        mov     dx,bp                   ; dx = new position fractional part
        pop     bp

        pop     bx

        mov     [es:bx+dsmChannel.posl],dx      ; new position fraction
        sub     si,[word smp]                   ; substract sample start from
        mov     [es:bx+dsmChannel.pos],si       ; whole part to get new pos

        cmp     si,[es:bx+dsmChannel.loopEnd]   ; did we reach loop end?
	jb	@@clne


        ; loop end has been reached.
        cmp     [ALE],1                 ; is Amiga Loop Emulation active?
        je      @@lale

        ; Amiga Loop Emulation not active - just substract loop length from
        ; position to get to loop start
@@loopcurrent:
        mov     ax,[es:bx+dsmChannel.loopEnd]
        sub     ax,[es:bx+dsmChannel.loopStart]
        sub     [es:bx+dsmChannel.pos],ax
        jmp     @@clne

@@lale:
        ; Sample loop end has been reached and Amiga Loop Emulation is
        ; active. If instrument has been changed, set new instrument values
        ; to channel structure and check if playing should be continued
        ; with new instrument. If instrument has not been changed, just loop
        ; as usual
        cmp     [es:bx+dsmChannel.instChanged],1
        je      @@alenewinst
        jmp     @@loopcurrent

@@clne:
	cmp	[mlen],0		; more data to be mixed?
	je	@@cdone 		; skip if not
	jmp	@@cloop


@@alenewinst:
        ; Sample loop end or sample end has been reached, Amiga Loop
        ; Emulation is active and instrument has been changed. Set new
        ; instrument values to channel structure:
        call    dsmUseInstrument

        ; if new instrument is not looping, playing should be stopped:
        cmp     [es:bx+dsmChannel.looping],1
        je      @@alelp
        mov     [es:bx+dsmChannel.hasData],0
        jmp     @@cdone

@@alelp:
        ; looping instrument - continue playing from new instrument loop
        ; start:
        mov     ax,[es:bx+dsmChannel.loopStart]
        mov     [es:bx+dsmChannel.pos],ax
        mov     [es:bx+dsmChannel.posl],0

        cmp     [mlen],0                ; more data to be mixed?
        jne     @@contmix               ; if yes, continue mixing

@@cdone:
        cmp     [dsmChanNum],0          ; first channel?
        jne     @@notfirst

        cmp     [mlen],0                ; first channel - if not all data was
        je      @@notfirst              ; mixed, clear the rest of the buffer

        push    es

        mov     es,[word dsmTempBuffer+2]
        mov     ax,[mlen]
        mul     [dsmTBufElemSize]       ; ax = number of bytes left
        mov     cx,ax
        xor     eax,eax

        test    di,10b                  ; is di mod 4 nonzero?
        jz      @@nofix                 ; if is, write one word to align
        mov     [es:di],ax              ; to dword boundary
        add     di,2

@@nofix:
        add     cx,3
        shr     cx,2                    ; clear the rest one dword at a time
        rep     stosd
        mov     [mlen],0                ; all data mixed

        pop     es

@@notfirst:
        mov     ax,[dsmChanNum]
	inc	ax			; next channel
	cmp	ax,[dsmChOpen]		; are there more channels?
	jae	@@chdn
        mov     [dsmChanNum],ax
	jmp	@@chnlp

@@chdn:
        ; All channels mixed to the temporary buffer. Now do the post
        ; processing and move the data to mixing buffer:
        mov     cx,[numElems]           ; number of elements mixed
        call    [word postProcRoutine]
        test    ax,ax
        jnz     @@err

        mov     ax,[numElems]
        mul     [dsmMixElemSize]        ; ax = number of bytes mixed
        sub     [mixLeft],ax            ; substract number of bytes left
        jnz     @@tbufmix               ; continue if more bytes left

        xor     ax,ax                   ; success
        jmp     @@done

@@err:
        ERROR   ID_dsmMixData

@@done:
	ret
ENDP






; 16-bit mono mixing routine:
MACRO   _m16m   num
	mov	bl,[gs:si]		; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        add     [di+2*num],ax           ; add word into buffer
ENDM

MixLoop m16m, _m16m, 32, [fs:mixCount]


; 16-bit mono mixing routine, first channel:
MACRO   _m16mm  num
	mov	bl,[gs:si]		; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        mov     [di+2*num],ax           ; write word into buffer
ENDM

MixLoop m16mm, _m16mm, 32, [fs:mixCount]



;/***************************************************************************\
;*
;* Function:    dsmMixMono
;*
;* Description: The actual mono mixing routine
;*
;* Input:	gs		sample data segment
;*              si              sample mixing position whole part, from the
;*                              beginning of the sample segment
;*              bp              sample position fractional part
;*		edx		sample mixing position increment for each
;*				destination byte, 16.16 fixed point format
;*              di              pointer to mixing buffer (assumed to be in
;*                              the volume table segment)
;*		cx		number of bytes to mix
;*              bh              volume to be used
;*              [dsmChanNum]    current channel number
;*
;* Returns:     si.bp           new mixing position
;*		di		new destination position
;*
;* Destroys:    eax, ebx, ecx, edx, esi, edi, fs
;*
;\***************************************************************************/

PROC    dsmMixMono      NEAR

        test    cx,cx                   ; don't mix zero bytes
	jz	@@done

        cmp     [dsmChanNum],0          ; first channel?
        jne     @@notfirst
        mov     [mixLoop],offset m16mm  ; first channel - move to buffer
        jmp     @@mlok

@@notfirst:
        mov     [mixLoop],offset m16m   ; not the first channel - add to buf.

@@mlok:
        add     bh,VOLADD               ; convert volume rounding up
        shr     bh,VOLSHIFT
        mov     al,bh
	xor	ebx,ebx 		; bh contains volume, bl sample and
        mov     bh,al                   ; upper word of ebx is zero in mixing

        mov     ax,ds                   ; point fs to data segment
        mov     fs,ax

	push	ds
	mov	ds,[dsmVolTableSeg]	; point ds to volume table

        push    bp

	mov	ax,cx			; ax = number of words to mix
	and	ax,15			; in the first loop
	shl	ax,1
	mov	bp,32			; bp = jump table offset
	sub	bp,ax

	sub	di,bp			; undo di incrementing in loop
        add     bp,[fs:mixLoop]
        mov     ax,[cs:bp]              ; ax = correct mixing routine start
        pop     bp

	shr	cx,4			; cx = number of loops to mix
	inc	cx
        mov     [fs:mixCount],cx        ; store loop counter in mixCount

        mov     cx,dx                   ; cx = mixing position increment
                                        ; fractional part
        shr     edx,16                  ; dx = increment whole part

        call    ax                      ; call the mixing routine

	pop	ds

@@done:
	ret
ENDP



IFNDEF NOSTEREO


; 16-bit stereo mixing routine, middle panning:
MACRO   _m16sm  num
        mov     bl,[gs:si]              ; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        add     [di+4*num],ax           ; add word into dest left channel
        add     [di+4*num+2],ax         ; add word into dest right channel
ENDM

MixLoop m16sm, _m16sm, 64, [fs:mixCount]



; 16-bit stereo mixing routine, middle panning, first channel:
MACRO   _m16smm num
        mov     bl,[gs:si]              ; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        mov     [di+4*num],ax           ; write word into dest left channel
        mov     [di+4*num+2],ax         ; write word into dest right channel
ENDM

MixLoop m16smm, _m16smm, 64, [fs:mixCount]



; 16-bit stereo mixing routine, surround panning:
MACRO   _m16ss  num
        mov     bl,[gs:si]              ; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        add     [di+4*num],ax           ; add word into dest left channel
        sub     [di+4*num+2],ax         ; add with 180 degrees phase shift
                                        ; (or something like that...)
ENDM

MixLoop m16ss, _m16ss, 64, [fs:mixCount]



; 16-bit stereo mixing routine, surround panning, first channel:
MACRO   _m16ssm num
        mov     bl,[gs:si]              ; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        mov     [di+4*num],ax           ; write word into dest left channel
        neg     ax                      ; phase shift 180 degrees
        mov     [di+4*num+2],ax         ; write word to dest right channel
ENDM

MixLoop m16ssm, _m16ssm, 64, [fs:mixCount]



; 16-bit stereo mixing routine, left panning:
MACRO   _m16sl  num
        mov     bl,[gs:si]              ; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        add     [di+4*num],ax           ; add word into dest left channel
ENDM

MixLoop m16sl, _m16sl, 64, [fs:mixCount]



; 16-bit stereo mixing routine, left panning, first channel:
MACRO   _m16slm num
        mov     bl,[gs:si]              ; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        mov     [di+4*num],ax           ; write word into dest left channel
        mov     [word di+4*num+2],0     ; clear dest right channel
ENDM

MixLoop m16slm, _m16slm, 64, [fs:mixCount]



; 16-bit stereo mixing routine, right panning:
MACRO   _m16sr  num
        mov     bl,[gs:si]              ; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        add     [di+4*num+2],ax         ; add word into dest right channel
ENDM

MixLoop m16sr, _m16sr, 64, [fs:mixCount]



; 16-bit stereo mixing routine, right panning, first channel:
MACRO   _m16srm num
        mov     bl,[gs:si]              ; take byte from source
        add     bp,cx                   ; increment sample position fraction
	mov	ax,[ebx+ebx]		; take correct value from volume tbl
        adc     si,dx                   ; increment sample position whole part
        mov     [word di+4*num],0       ; clear dest left channel
        mov     [di+4*num+2],ax         ; write word into dest right channel
ENDM

MixLoop m16srm, _m16srm, 64, [fs:mixCount]



; 16-bit stereo mixing routine, smooth panning:
MACRO   _m16sp  num
        add     eax,ebp                 ; increment position fractional part
        mov     bl,[gs:si]              ; take byte from source
        adc     si,dx                   ; increment position whole part
        mov     ax,[ebx+ebx]            ; take left channel value from vol tbl
        add     [di+4*num],ax           ; add word to destination left channel
        mov     cl,bl
        mov     ax,[ecx+ecx]            ; take right ch value from volume tbl
        add     [di+4*num+2],ax         ; add word to dest right channel
ENDM

MixLoop m16sp, _m16sp, 64, [fs:mixCount]



; 16-bit stereo mixing routine, smooth panning, first channel:
MACRO   _m16spm num
        add     eax,ebp                 ; increment position fractional part
        mov     bl,[gs:si]              ; take byte from source
        adc     si,dx                   ; increment position whole part
        mov     ax,[ebx+ebx]            ; take left channel value from vol tbl
        mov     [di+4*num],ax           ; write word to dest left channel
        mov     cl,bl
        mov     ax,[ecx+ecx]            ; take right ch value from volume tbl
        mov     [di+4*num+2],ax         ; write word to dest right channel
ENDM

MixLoop m16spm, _m16spm, 64, [fs:mixCount]



;/***************************************************************************\
;*
;* Function:    dsmMixStereo
;*
;* Description: The actual stereo mixing routine
;*
;* Input:	gs		sample data segment
;*              si              sample mixing position whole part, from the
;*                              beginning of the sample segment
;*              bp              sample position fractional part
;*		edx		sample mixing position increment for each
;*				destination byte, 16.16 fixed point format
;*              di              pointer to mixing buffer (assumed to be in
;*                              the volume table segment)
;*              cx              number of bytes to mix
;*              bh              volume to be used
;*              bl              channel panning value
;*              [dsmChanNum]    current channel number
;*
;* Returns:     si.bp           new mixing position
;*		di		new destination position
;*
;* Destroys:    eax, ebx, ecx, edx, esi, edi, fs
;*
;\***************************************************************************/

PROC    dsmMixStereo    NEAR

        test    cx,cx                   ; don't mix zero bytes
	jz	@@done

        add     bh,VOLADD               ; convert volume rounding up
        shr     bh,VOLSHIFT
        mov     al,bh                   ; al = volume

        cmp     bl,256+panLeft          ; left panning?
        je      @@panleft
        cmp     bl,panRight             ; right panning?
        je      @@panright
        cmp     bl,panMiddle            ; middle panning?
        je      @@panmiddle
        cmp     bl,panSurround          ; surround panning?
        je      @@pansurround

        ; Smooth panning - if panning < 0 (left), set left channel volume to
        ; full value and right to volume*(64+panning)/64:
        test    bl,bl
        jns     @@psright

        mov     [mixLVol],al            ; full volume to left channel
        add     bl,64
        mul     bl
        shr     ax,6
        mov     [mixRVol],al            ; right channel volume
        jmp     @@sp_mix

@@psright:
        ; Smooth panning, panning > 64 (right) - set right channel volume to
        ; full value and left to volume*(64-panning)/64:
        mov     [mixRVol],al            ; full volume to right channel
        neg     bl
        add     bl,64
        mul     bl
        shr     ax,6
        mov     [mixLVol],al            ; left channel volume
        jmp     @@sp_mix


@@panleft:
        ; left panning - point mixLoop to left mixing routine:
        cmp     [dsmChanNum],0          ; first channel?
        jne     @@nfl
        mov     [mixLoop],offset m16slm ; first channel - move to buffer
        jmp     @@mix
@@nfl:
        mov     [mixLoop],offset m16sl  ; not the first channel - add to buf.
        jmp     @@mix


@@panright:
        ; right panning - point mixLoop to right mixing routine:
        cmp     [dsmChanNum],0          ; first channel?
        jne     @@nfr
        mov     [mixLoop],offset m16srm ; first channel - move to buffer
        jmp     @@mix
@@nfr:
        mov     [mixLoop],offset m16sr  ; not the first channel - add to buf.
        jmp     @@mix


@@panmiddle:
        ; middle panning - point mixLoop to middle mixing routine:
        cmp     [dsmChanNum],0          ; first channel?
        jne     @@nfm
        mov     [mixLoop],offset m16smm ; first channel - move to buffer
        jmp     @@mix
@@nfm:
        mov     [mixLoop],offset m16sm  ; not the first channel - add to buf.
        jmp     @@mix                   ; routine


@@pansurround:
        ; surround panning - point mixLoop to surround mixing routine:
        cmp     [dsmChanNum],0          ; first channel?
        jne     @@nfs
        mov     [mixLoop],offset m16ssm ; first channel - move to buffer
        jmp     @@mix
@@nfs:
        mov     [mixLoop],offset m16ss  ; not the first channel - add to buf.
        jmp     @@mix                   ; routine



@@sp_mix:
        ; now do the mixing for smooth panning:

        cmp     [dsmChanNum],0          ; first channel?
        jne     @@notfirst
        mov     [mixLoop],offset m16spm ; first channel - move to buffer
        jmp     @@mlok

@@notfirst:
        mov     [mixLoop],offset m16sp  ; not the first channel - add to buf.

@@mlok:
        mov     ax,ds                   ; point fs to data segment
        mov     fs,ax

	push	ds
	mov	ds,[dsmVolTableSeg]	; point ds to volume table

        push    bp

	mov	ax,cx			; ax = number of words to mix
	and	ax,15			; in the first loop
	shl	ax,1
	mov	bp,32			; bp = jump table offset
	sub	bp,ax

        push    bp
        add     bp,[fs:mixLoop]
        mov     ax,[cs:bp]              ; ax = correct mixing routine start
        mov     [fs:mixLoop],ax         ; store mixing routine pointer
        pop     bp

        shl     bp,1
        sub     di,bp                   ; undo di incrementing in loop
        pop     bp

	shr	cx,4			; cx = number of loops to mix
	inc	cx
        mov     [fs:mixCount],cx        ; store loop counter in mixCount

        shl     ebp,16                  ; store mixing position fractional
        mov     eax,ebp                 ; part in upper word of eax

        mov     bp,dx                   ; put mixing position increment
        shl     ebp,16                  ; fractional part to ebp upper word
        shr     edx,16                  ; dx = increment whole part

        xor     ebx,ebx                 ; bh = left channel volume (bl
        mov     bh,[fs:mixLVol]         ; contains sample in mixing)
        xor     ecx,ecx                 ; ch = right channel volume (bl
        mov     ch,[fs:mixRVol]         ; contains sample in mixing)

        call    [word fs:mixLoop]       ; call the mixing routine

	pop	ds

        mov     ebp,eax                 ; put mixing position fractional
        shr     ebp,16                  ; part back to ebp
        jmp     @@done


@@mix:
        ; do the mixing for non-smooth panning:

        xor     ebx,ebx                 ; bh contains volume, bl sample and
        mov     bh,al                   ; upper word of ebx is zero in mixing

        mov     ax,ds                   ; point es to data segment
        mov     fs,ax

	push	ds
	mov	ds,[dsmVolTableSeg]	; point ds to volume table

        push    bp

	mov	ax,cx			; ax = number of words to mix
	and	ax,15			; in the first loop
	shl	ax,1
	mov	bp,32			; bp = jump table offset
	sub	bp,ax

        shl     bp,1
	sub	di,bp			; undo di incrementing in loop
        shr     bp,1
        add     bp,[fs:mixLoop]
        mov     ax,[cs:bp]              ; ax = correct mixing routine start

        pop     bp

	shr	cx,4			; cx = number of loops to mix
	inc	cx
        mov     [fs:mixCount],cx        ; store loop counter in mixCount

        mov     cx,dx                   ; cx = mixing position increment
                                        ; fractional part
        shr     edx,16                  ; dx = increment whole part

        call    ax                      ; call the mixing routine

	pop	ds

@@done:
	ret
ENDP



ENDIF




LABEL   pp8mjump        WORD            ; jump table for 8-bit mono post-proc
        JmpTable pp8m, 17

;/***************************************************************************\
;*
;* Function:    dsmPProc8Mono
;*
;* Description: 8-bit mono mixing post-processing routine
;*
;* Input:       cx                      number of elements mixed
;*
;* Returns:     MIDAS error code in ax. Updates the mixing position.
;*
;* Destroys:    ax, bx, cx, dx, si, di, es
;*
;\***************************************************************************/

PROC    dsmPProc8Mono   NEAR

        test    cx,cx
        jz      @@done

        push    bp

        mov     dx,cx                   ; dx = number of elements to copy
        mov     si,[word dsmTempBuffer] ; si = temporary buffer pointer
        les     bp,[dsmBuffer]          ; point es:bp to mixing position
        add     bp,[dsmMixPos]

@@blp:
        mov     cx,dx
        mov     ax,[dsmBufferEnd]       ; ax = number of bytes of space left
        sub     ax,bp                   ; in mixing buffer before end
        cmp     cx,ax
        jb      @@ok
        mov     cx,ax                   ; do not copy past buffer end
@@ok:   sub     dx,cx                   ; decrease number of elements left

        push    ds
        shr     cx,1                    ; cx = number of destination words -
                                        ; number of elements is always even

        mov     ax,cx                   ; ax = number of words to process
	and	ax,15			; in the first loop
	shl	ax,1
        mov     di,32                   ; di = jump table offset
        sub     di,ax

        shl     di,1
        sub     si,di                   ; undo si incrementing in loop
        shr     di,1
        sub     bp,di                   ; undo di incrementing in loop
        mov     ax,[pp8mjump+di]        ; ax = processing start address

        mov     di,[word pp8Table]      ; point di to post-processing table
        mov     ds,[dsmVolTableSeg]     ; point ds to buffer segment

        shr     cx,4                    ; cx = number of loops to do
	inc	cx

        jmp     ax                      ; do the post-processing

@@pplp:
num = 0
REPT    16
        NumLabel pp8m, %num
        mov     bx,[si+4*num]           ; get word from source
        add     bx,PP8SIZE/2            ; convert it to unsigned
        mov     al,[di+bx]              ; process first byte
        mov     bx,[si+4*num+2]         ; get next word from source
        add     bx,PP8SIZE/2            ; convert it to unsigned
        mov     ah,[di+bx]              ; and process it
        mov     [es:bp+2*num],ax        ; store two bytes into destination
num = num + 1
ENDM
        NumLabel pp8m, %num
        add     si,64                   ; increment source pointer
        add     bp,32                   ; increment destination pointer
        dec     cx
        jnz     @@pplp

        pop     ds


        cmp     bp,[dsmBufferEnd]       ; have we reached mixing buffer end?
        jb      @@bpok
        mov     bp,[word dsmBuffer]     ; if yes, move to buffer beginning

@@bpok:
        test    dx,dx                   ; still elements left to do?
        jnz     @@blp                   ; if yes, continue

        sub     bp,[word dsmBuffer]
        mov     [dsmMixPos],bp          ; store mixing position

        pop     bp

@@done:
        xor     ax,ax
        ret
ENDP



IFNDEF NOSTEREO




;/***************************************************************************\
;*
;* Function:    dsmPProc8Stereo
;*
;* Description: 8-bit stereo mixing post-processing routine
;*
;* Input:       cx                      number of elements mixed
;*
;* Returns:     MIDAS error code in ax. Updates the mixing position.
;*
;* Destroys:    ax, bx, cx, dx, si, di, es
;*
;\***************************************************************************/

PROC    dsmPProc8Stereo NEAR

        shl     cx,1                    ; cx = number of bytes
        call    dsmPProc8Mono           ; use the mono post-processing routine
        ret
ENDP


ENDIF




;/***************************************************************************\
;*
;* Function:    dsmPProc16Mono
;*
;* Description: 16-bit mono mixing post-processing routine
;*
;* Input:       cx                      number of elements mixed
;*
;* Returns:     MIDAS error code in ax. Updates the mixing position.
;*
;* Destroys:    ax, bx, cx, dx, si, di, es
;*
;\***************************************************************************/

PROC    dsmPProc16Mono  NEAR

        test    cx,cx
        jz      @@done

        mov     dx,cx                   ; dx = number of elements to copy
        mov     si,[word dsmTempBuffer] ; si = temporary buffer pointer
        les     di,[dsmBuffer]
        add     di,[dsmMixPos]          ; point es:di to mixing position

@@blp:
        mov     cx,dx
        mov     ax,[dsmBufferEnd]       ; ax = number of bytes of space left
        sub     ax,di                   ; in mixing buffer before end
        shr     ax,1                    ; ax = number of elements [...]
        cmp     cx,ax
        jb      @@ok
        mov     cx,ax                   ; do not copy past buffer end
@@ok:   sub     dx,cx                   ; decrease number of elements left

        push    ds
        mov     ds,[dsmVolTableSeg]     ; point ds to buffer segment
        cld
        shr     cx,1                    ; number of elements is always even
        rep     movsd                   ; move data to mixing buffer
        pop     ds

        cmp     di,[dsmBufferEnd]       ; have we reached mixing buffer end?
        jb      @@bpok
        mov     di,[word dsmBuffer]     ; if yes, move to buffer beginning

@@bpok:
        test    dx,dx                   ; still elements left to do?
        jnz     @@blp                   ; if yes, continue

        sub     di,[word dsmBuffer]
        mov     [dsmMixPos],di          ; store mixing position

@@done:
        xor     ax,ax
        ret
ENDP



IFNDEF NOSTEREO



;/***************************************************************************\
;*
;* Function:    dsmPProc16Stereo
;*
;* Description: 16-bit stereo mixing post-processing routine
;*
;* Input:       cx                      number of elements mixed
;*
;* Returns:     MIDAS error code in ax. Updates the mixing position.
;*
;* Destroys:    ax, bx, cx, dx, si, di, es
;*
;\***************************************************************************/

PROC    dsmPProc16Stereo        NEAR

        test    cx,cx
        jz      @@done

        mov     dx,cx                   ; dx = number of elements to copy
        mov     si,[word dsmTempBuffer] ; si = temporary buffer pointer
        les     di,[dsmBuffer]
        add     di,[dsmMixPos]          ; point es:di to mixing position

@@blp:
        mov     cx,dx
        mov     ax,[dsmBufferEnd]       ; ax = number of bytes of space left
        sub     ax,di                   ; in mixing buffer before end
        shr     ax,2                    ; ax = number of elements [...]
        cmp     cx,ax
        jb      @@ok
        mov     cx,ax                   ; do not copy past buffer end
@@ok:   sub     dx,cx                   ; decrease number of elements left

        push    ds
        mov     ds,[dsmVolTableSeg]     ; point ds to buffer segment
        cld
        rep     movsd                   ; move data to mixing buffer
        pop     ds

        cmp     di,[dsmBufferEnd]       ; have we reached mixing buffer end?
        jb      @@bpok
        mov     di,[word dsmBuffer]     ; if yes, move to buffer beginning

@@bpok:
        test    dx,dx                   ; still elements left to do?
        jnz     @@blp                   ; if yes, continue

        sub     di,[word dsmBuffer]
        mov     [dsmMixPos],di          ; store mixing position

@@done:
        xor     ax,ax
        ret
ENDP



ENDIF




END
