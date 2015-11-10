;ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
;³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
;³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; Compile "tasm -ut310 timer"

IDEAL
P386
JUMPS
MODEL TPASCAL
LANG EQU PASCAL


GLOBAL  LANG tmrInited : word
GLOBAL  LANG tmrActive : word
GLOBAL  LANG tmrGetScrSync : far
GLOBAL  LANG tmrInit : far
GLOBAL  LANG tmrClose : far
GLOBAL  LANG tmrSyncScr : far
GLOBAL  LANG tmrStopScrSync : far


FRAMETIME = 965 		; Time between two interrupts is 96.5%
				; of total frame time - the interrupt comes
				; somewhat _before_ the Vertical Retrace
				; actually starts.

ENUM    tmrStates \                     ; timer state
        tmrSystem, \                    ; system timer
        tmrScreen                       ; Vertical Retrace timer



;/***************************************************************************\
;*
;* Macro:       SetBorder color
;*
;* Description: Sets the border color if TIMERBORDERS is defined
;*
;* Input:       color           border color
;*
;* Destroys:    none
;*
;\***************************************************************************/

MACRO   SetBorder       color
IFDEF TIMERBORDERS
	push	dx ax
	mov	dx,03DAh
	in	al,dx
	mov	dx,03C0h
	mov	al,31h
	out	dx,al
	mov	al,color
	out	dx,al
	pop	ax dx
ENDIF
ENDM




;/***************************************************************************\
;*
;* Macro:       WaitNextVR
;*
;* Description: Waits for next Vertical Retrace
;*
;\***************************************************************************/

MACRO   WaitNextVR
LOCAL	w1, w2

	mov	dx,03DAh
w1:	in	al,dx		; wait for a non-retrace period
	test	al,8
	jnz	w1

w2:	in	al,dx
	test	al,8		; wait for retrace
	jz	w2
ENDM




DATASEG


systemTimer	DD	?		; pointer to system timer routine
sysTmrCount	DD	?		; system timer counter

scrCount	DD	?		; Retrace timer counter
scrTmrCount	DD	?		; initial value for VR timer counter
scrPVCount	DD	?		; timer count for time before Retrace
preVR		DD	?		; pre-VR function
immVR           DD      ?               ; immVR()
inVR            DD      ?               ; inVR()
scrSync 	DW	?		; 1 if timer is synchronized to screen
scrTimer	DW	?		; 1 if screen-timer is active

tmrState	DW	?		; timer state

sysTimer	DW	?		; system timer active?




CODESEG




;/***************************************************************************\
;*
;* Function:	setCount
;*
;* Description: Set timer count and restart timer
;*
;* Input:	bx		timer count
;*
;* Destroys:	al
;*
;\***************************************************************************/

PROC NOLANGUAGE setCount     NEAR	; set timer counter and restart

	mov	al,30h			; counter mode 0 - interrupt on
	out	43h,al			; terminal count
	mov	al,bl
	out	40h,al			; set timer count and restart timer
	mov	al,bh
	out	40h,al

	ret
ENDP




;/***************************************************************************\
;*
;* Function:	nextTimer
;*
;* Description: Prepare for next timer interrupt
;*
;* Destroys:    eax, ebx
;*
;\***************************************************************************/

PROC NOLANGUAGE nextTimer    NEAR

	cmp	[scrSync],1		; is timer synchronized to screen?
	jne	@@noscr

@@scr:	mov	ebx,[scrCount]		; screen timer count
	or	ebx,ebx 		; negative?
	jns	@@nos2
	mov	ebx,10			; make sure count is not negative
	mov	[scrCount],10
@@nos2:
	mov	[tmrState],tmrScreen	; next interrupt will be screen timer
	call	setCount		; set count and restart timer
	jmp	@@done


@@noscr:
@@sys:					; system timer only
	mov	[tmrState],tmrSystem	; next int is system timer
	xor	bx,bx
	call	setCount		; set system timer count

@@done:
	ret
ENDP






;/***************************************************************************\
;*
;* Function:    timer
;*
;* Description: timer interrupt handler
;*
;\***************************************************************************/

PROC NOLANGUAGE timer			; timer interrupt

	pushad
	push	ds es fs gs

        SetBorder 15

	mov	ax,@data
	mov	ds,ax			; set valid values to segment
        mov     es,ax                   ; registers

        mov     [tmrActive],1           ; in timer interrupt

	cmp	[tmrState],tmrScreen	; screen timer interrupt?
	je	@@scrtmr
	cmp	[tmrState],tmrSystem	; system timer only?
	je	@@systmr
	jmp	@@systmr		; do _something_


@@scrtmr:
	cli				; no interrupts here!

	SetBorder 14

	cmp	[scrTimer],1		; is screen timer already active?
	jne	@@scrnot

	; screen timer already active - PANIC!

	mov	eax,[scrCount]
	add	eax,[scrPVCount]
	add	[sysTmrCount],eax	; update system timer counter

	mov	eax,[scrTmrCount]	; reset screen timer counter
	mov	[scrCount],eax

	call	nextTimer		; next timer interrupt

	mov	al,20h			; send End Of Interrupt
	out	20h,al
	sti				; enable interrupts
	jmp	@@done			; stop processing this interrupt


@@scrnot:
	cmp	[scrSync],1		; should timer be synchronized to
	jne	@@chksys		; screen?

	mov	[scrTimer],1		; screen-timer is now active

	mov	dx,03DAh
@@wnvr: in	al,dx			; wait until we are _not_ in a
	test	al,8			; retrace (just to make sure...)
	jnz	@@wnvr

	cmp	[preVR],0
        je      @@npvr                  ; call preVR() if pointer is not
        call    [dword preVR] LANG      ; NULL
@@npvr:

	SetBorder 1
	mov	eax,[scrCount]
	add	eax,[scrPVCount]	; update timer counters
	add	[sysTmrCount],eax
	mov	eax,[scrTmrCount]	; reset screen-interrupt count
	mov	[scrCount],eax

	mov	dx,03DAh
@@wvr:	in	al,dx			; wait for the retrace
	test	al,8
	jz	@@wvr

        cmp     [immVR],0
        je      @@nivr                  ; call immVR() if pointer is not
        call    [dword immVR] LANG      ; NULL

@@nivr:
	SetBorder 2

	call	nextTimer		; next timer iterrupt

	mov	[scrTimer],0		; screen-timer (almost) finished

	SetBorder 4

	sti				; enable interrupts now

	mov	al,20h			; send End Of Interrupt to Interrupt
	out	20h,al			; Controller


        cmp     [inVR],0
        je      @@nvr                   ; call inVR() if pointer is not NULL
        call    [dword inVR] LANG

@@nvr:
	SetBorder 0
	mov	[scrTimer],0
	jmp	@@chksys		; check if system timer should be
					; called






@@chksys:				; check system timer
	sti
	cmp	[sysTmrCount],10000h	; should system timer be called?
	jb	@@done

	mov	eax,[sysTmrCount]
	sub	eax,10000h		; substract 65536 from system timer
	or	eax,eax 		; count. Is the result negative?
	jns	@@stcok 		; (SHOULD not be)
	xor	eax,eax 		; negative - set to zero
@@stcok:
	mov	[sysTmrCount],eax	; new timer count
	pushf
	call	[dword systemTimer]	; call system timer
	jmp	@@chksys



@@systmr:				; system timer only
	sti
	xor	bx,bx			; set new timer count and restart
	call	setCount
	pushf
	call	[dword systemTimer]	; call system timer


@@done:
        mov     [tmrActive],0           ; not in timer interrupt
        SetBorder 0
        pop     gs fs es ds             ; restore registers
	popad
        nop                             ; avoid the popad-bug...
	iret
ENDP




;/***************************************************************************\
;*
;* Function:     int tmrGetScrSync(ushort *scrSync);
;*
;* Description:  Calculates the screen synchronization value for timer
;*
;* Input:        ushort *scrSync         pointer to screen synchronization
;*                                       value
;*
;* Returns:      MIDAS error code.
;*               Screen syncronization value used with tmrSyncScr() is stored
;*               in *scrSync.
;*
;\***************************************************************************/

PROC    tmrGetScrSync   FAR     PscrSync : dword
LOCAL	tmrVal : word

	cli				; disable interrupts for maximum
					; accuracy
	mov cx,10			; try to read max 10x
@@read:
	dec	cx
	jz	@@badtimer		; 10x bad -> timer is not precise

	WaitNextVR			; wait for next Vertical Retrace

	mov	al,36h
	out	43h,al
	xor	al,al			; reset the timer
	out	40h,al
	out	40h,al


	WaitNextVR			; wait for next Vertical Retrace

	xor	al,al
	out	43h,al
	in	al,40h
	mov	ah,al
	in	al,40h			; read timer count - time between
	xchg	al,ah			; two Vertical Retraces
	neg	ax
	mov	[tmrVal],ax


	WaitNextVR			; wait for next Vertical Retrace

	mov	al,36h
	out	43h,al
	xor	al,al			; reset timer again
	out	40h,al
	out	40h,al


	WaitNextVR			; wait...

	xor	al,al
	out	43h,al
	in	al,40h
	mov	ah,al			; and read the timer count again
	in	al,40h
	xchg	al,ah
	neg	ax

	mov	dx,ax

	sub	dx,[tmrVal]
	cmp	dx,2			; If the difference between the two
	jg	@@read			; values read was >2, read again.
	cmp	dx,-2
	jl	@@read
@@badtimer:

        sti                             ; enable interrupts

        les     bx,[PscrSync]           ; store time in *scrSync
        mov     [es:bx],ax

        xor     ax,ax                   ; success

	or	cx,cx
	jnz	@@succ
	mov	ax,1			; or failure, timer is not precise
@@succ:

	ret
ENDP




;/***************************************************************************\
;*
;* Function:     int tmrInit(void);
;*
;* Description:  Initializes TempoTimer.
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	tmrInit 	FAR

	mov	[tmrState],tmrSystem	; only system timer now
	mov	[scrSync],0
	mov	[scrTimer],0
	mov	[sysTmrCount],0
	mov	[sysTimer],0

	mov	ax,3508h
	int	21h
	mov	[word systemTimer],bx	; save system timer interrupt
	mov	[word systemTimer+2],es

	push	ds
	mov	ax,seg timer
	mov	ds,ax			; set new timer interrupt
	mov	dx,offset timer
	mov	ax,2508h
	int	21h
	pop	ds

	xor	bx,bx			; set timer count and restart
	call	setCount

        SetBorder 2

        xor     ax,ax                   ; success
	ret
ENDP




;/***************************************************************************\
;*
;* Function:     int tmrClose(void);
;*
;* Description:  Uninitializes TempoTimer. MUST be called if and ONLY if
;*               tmrInit() has been called.
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	tmrClose	FAR

	mov	al,36h			; DOS default timer mode
	out	43h,al
	xor	al,al			; set timer count to 65536 - 18.2Hz
	out	40h,al			; (DOS default)
	out	40h,al

	push	ds
	mov	ax,2508h
	mov	dx,[word systemTimer]	; restore system timer interrupt
	mov	ds,[word systemTimer+2]
	int	21h
	pop	ds

	mov	al,36h			; DOS default timer mode
	out	43h,al
	xor	al,al			; set timer again for safety
	out	40h,al
	out	40h,al

@@done:
        xor     ax,ax                   ; success
	ret
ENDP




;/***************************************************************************\
;*
;* Function:     int tmrSyncScr(ushort sync, void (*preVR)(), void (*immVR)(),
;*               void (*inVR)());
;*
;* Description:  Synchronizes the timer to screen refresh.
;*
;* Input:        ushort sync             Screen synchronization value returned
;*                                       by tmrGetScrSync().
;*               void (*preVR)()         Pointer to the routine that will be
;*                                       called BEFORE Vertical Retrace
;*               void (*immVR)()         Pointer to the routine that will be
;*                                       called immediately after Vertical
;*                                       Retrace starts
;*               void (*inVR)()          Pointer to the routine that will be
;*                                       called some time during Vertical
;*                                       Retrace
;*
;* Returns:      MIDAS error code
;*
;* Notes:        preVR() and immVR() functions must be as short as possible
;*               and do nothing else than update counters or set some VGA
;*               registers to avoid timer synchronization problems. inVR()
;*               can take a longer time and can be used for, for example,
;*               setting the palette.
;*
;\***************************************************************************/

PROC    tmrSyncScr      FAR     sync : word, PpreVR : dword, PimmVR : dword, \
                                PinVR : dword
USES	si

	cli				; make sure we won't be disturbed...

        mov     eax,[PpreVR]
	mov	[preVR],eax
        mov     eax,[PimmVR]            ; store function pointers
        mov     [immVR],eax
        mov     eax,[PinVR]
        mov     [inVR],eax

	mov	[scrSync],1		; synchronize to screen
	mov	[scrTimer],0		; screen timer is not active

	mov	ax,FRAMETIME
	mul	[sync]			; time between two screen interrupts
	mov	bx,1000 		; is FRAMETIMER/10 % of total frame
	div	bx			; time
	movzx	eax,ax

	shr	eax,1
	mov	[scrCount],eax		; screen timer counter
	mov	[scrTmrCount],eax
	mov	ebx,eax

	movzx	eax,[sync]
	shr	eax,1			; scrPVCount = timer count between
	sub	eax,ebx 		; interrupt and start of Vertical
	mov	[scrPVCount],eax	; Retrace

	mov	[tmrState],tmrScreen	; next timer interrupt is screen timer
	WaitNextVR			; wait for next retrace
	call	setCount		; set count and restart timer

	sti

        xor     ax,ax                   ; success
	ret
ENDP




;/***************************************************************************\
;*
;* Function:     int tmrStopScrSync(void);
;*
;* Description:  Stops synchronizing the timer to the screen.
;*
;* Returns:      MIDAS error code
;*
;\***************************************************************************/

PROC	tmrStopScrSync	FAR

	cli

	mov	[scrSync],0		; no screen synchronization
	mov	[scrTimer],0		; screen timer is not active
	call	nextTimer		; set timer count and restart

	sti

        xor     ax,ax                   ; success
	ret
ENDP



END
