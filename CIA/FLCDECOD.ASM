;ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
;³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
;³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

code segment public
assume cs:code

	public flcInit
        public flcDecodeFrame

.386

PlayFLC_Data		equ 0

data_SirkaObrazovky	equ PlayFLC_Data 
data_SirkaObrazovky_Sirka equ PlayFLC_Data+2
data_Sirka equ		PlayFLC_Data+4
data_Vyska equ		PlayFLC_Data+6
data_StartingOfs	equ PlayFLC_Data+8
;data_VRAMSeg		equ PlayFLC_Data+10
data_DSEG		equ PlayFLC_Data+10
data_Banka		equ PlayFLC_Data+12
data_StartingBank	equ PlayFLC_Data+13
data_LinesToBeDrawn	equ PlayFLC_Data+14
data_SetPalProc		equ PlayFLC_Data+16     ;pozor, flc.pas natvrdo zapisuje na offset 16
data_SetBankProc	equ PlayFLC_Data+20
data_ReadDataProc	equ PlayFLC_Data+24
data_ChunkSize		equ PlayFLC_Data+28
data_Flags		equ PlayFLC_Data+32
data_KonecChunku	equ PlayFLC_Data+34


flags_OneBankOnly	equ 1			;priznak, ze cely img v jedne bance
flags_SmallerThan64KB	equ 2			;priznak, ze cely snimek ma <=65520B

BlockHeadFLI        equ 0
BlockHeadFLI_Size   equ BlockHeadFLI   ;dd 0    ;hlavicka Snimku - velikost dat snimku v bytech
BlockHeadFLI_Magic  equ BlockHeadFLI+4 ;dw 0    ;Magicky indentifikator
BlockHeadFLI_Chunks equ BlockHeadFLI+6 ;dw 0    ;pocet chunku ve snimku
BlockHeadFLI_Expand equ BlockHeadFLI+8 ;dw 0,0,0,0 ;8 bajtu pro pozdejsi pouziti

HeadFLI        equ 0
HeadFLI_Size   equ HeadFLI          ;dd 0 ;hlavicka souboru - velikost souboru v bajtech
HeadFLI_Magic  equ HeadFLI_Size+4   ;dw 0 ;identifikace
HeadFLI_Frames equ HeadFLI_Magic+2  ;dw 0 ;pocet snimku-1
HeadFLI_Width  equ HeadFLI_Frames+2 ;dw 0 ;sirka (320)
HeadFLI_Height equ HeadFLI_Width+2  ;dw 0 ;vyska (200)
HeadFLI_Depth  equ HeadFLI_Height+2 ;dw 0 ;bitova hloubka
HeadFLI_Flags  equ HeadFLI_Depth+2  ;dw 0 ;? priznaky
HeadFLI_Speed  equ HeadFLI_Flags+2  ;dw 0 ;pocet prodlev mezi snimkama
HeadFLI_Reserv equ HeadFLI_Speed+4  ;dd 0 ;reserved, se to zero
HeadFLC_UnImportant equ HeadFLI_Reserv+2 ;dd 0 ;UnImportant data at the moment
HeadFLC_OFrame1 equ HeadFLC_UnImportant+4*4+2*2+38 ;Offset of the 1st Frame
HeadFLC_OFrame2 equ HeadFLC_OFrame1+4 ;Offset of the 2nd Frame
HeadFLI_Expand equ HeadFLC_OFrame2+4  ;UnUsed data, set to zeroes


NactiCoNejvice proc near
	push fs
	push es
	pusha
        mov eax,fs:[data_ChunkSize]
        mov cx,65520
	sub cx,si	;cx = kolik musime presunout
        movzx edx,si    ;dx = kolik max. muzeme nacist
        cmp eax,edx
        jae short NeCtiVsechno
        mov dx,ax       ;hornich 16 bitu vzdy nulovych
NeCtiVsechno:
	push ds
        sub word ptr fs:[data_KonecChunku],si	;chunk bude koncit o neco driv
        pop es
        sub fs:[data_ChunkSize],edx
        push ds
        xor di,di
        push dx				;pocet bajtu na nacteni
        shr cx,1
        rep movsw			;presun po slovech
        adc cx,cx		
        rep movsb			;presun pripadny zbyvajici bajt
        push ds
        push di
	mov ds,fs:[data_DSEG]
        call dword ptr fs:[data_ReadDataProc]
        pop ds
        cld
        popa
        xor si,si
        pop es
        pop fs
	retn
NactiCoNejvice endp

	sp_prvni	equ ss:[bp+12]
        sp_pocet	equ ss:[bp+10]
        sp_data		equ ss:[bp+6]

SetBank proc near			;predpoklada, ze SetBankProc nemeni FS
        pusha
        push ds
        push fs
        pushf
        mov ds,fs:[data_DSEG]
        inc byte ptr fs:[data_Banka]
        xor ax,ax
        mov al,byte ptr fs:[data_Banka]
        push ax
        call dword ptr fs:[data_SetBankProc]
        popf
        pop fs
        pop ds
	mov es,ax
        popa
        retn
SetBank endp

MoveUnCompressedScreen proc near
        mov dx,fs:[data_SirkaObrazovky_Sirka]
        mov ax,fs:[data_Vyska]
    @6: mov cx,fs:[data_Sirka]
        mov bx,di
        add bx,cx
        jnc short Nepretek12
        xor cx,cx
        sub cx,di
        rep movsb
        call SetBank
        mov cx,bx
Nepretek12:
;nejkomplikovanejsi, snad nejrychlejsi:
        mov bx,di
        neg bx
        and bx,3	;zbytek DI do nasobku 4
        sub cx,bx	;budeme presouvat zvlast
        xchg bx,cx
        rep movsb       ;zarovname DI na 4
        mov cx,bx
        shr cx,2
        and bx,3        ;zbytek po deleni 4mi
        rep movsd
        mov cx,bx       ;ted presuneme ten zbytek
        rep movsb
;nejjednodussi zpusob:
;    	rep movsb
;IMHO nejlepsi zpusob:
;        shr cx,1
;        rep movsw
;        jnc short mucs1
;    	movsb
;mucs1:	
;konec
        add di,dx
        jnc short @Nepretek13
        call SetBank
@Nepretek13:
	dec ax
        jnz short @6
        retn
MoveUnCompressedScreen endp

ClearScreen proc near
        mov dx,word ptr fs:[data_SirkaObrazovky_Sirka]
        push si
        xor ax,ax
        mov bx,fs:[data_Vyska]
   @6b: mov cx,fs:[data_Sirka]
        mov si,di
        add si,cx
        jnc short Nepretek13
        xor cx,cx
        sub cx,di
        rep stosb
        call SetBank
        mov cx,si
Nepretek13:
        shr cx,1
        rep stosw
        jnc short cs1
    	stosb
cs1:    add di,dx
        jnc short @Nepretek14
        call SetBank
@Nepretek14:
        dec bx
        jnz short @6b
        pop si
        retn
ClearScreen endp

FLI_Color proc near   ;chunk s paletou
  push fs
  cmp al,0bh
  sbb di,di
  mov dx,[si]       ;pocet paketu
  add si,2
  test dx,dx
  jz short @@3           ;nula?->konec
  xor bx,bx
@@2:
  cld
  add bl,[si]      ;na zacatku paketu 1 bajt, kolik barev se ma preskocit
  inc si
  xor ah,ah
  lodsb
  mov cx,ax
  add bl,al
  add cx,cx
  add cx,ax        ;byl-li 0, mysli se tim 256
  test al,al
  jnz short @ne256
  inc ah
  mov ch,3
 @Ne256:
  add si,cx
  push ds
  push es
  push si
  push bx
  push dx
  push di
  sub bl,al
  sub si,cx        ;uloz offset dalsiho paketu
  push bx          ;index 1. barvy
  push ax	   ;pocet barev
  push ds
  push si
  test di,1	   ;typ palety?
  jz short @Color2
 @Color1:
  shr byte ptr [si],2
  inc si
  loop short @Color1     ;posli tam (3*pocet barev) bajtu
 @Color2:
  mov ds,fs:[data_DSEG]
  call dword ptr fs:[data_SetPalProc]
  pop di
  pop dx
  pop bx
  pop si
  pop es
  pop ds
  dec dx           ;pocet paketu na zpracovani
  jnz short @@2          ;este nakej? <>0, jo
@@3:
  pop fs
  retn
FLI_Color endp

FLI_Brun proc near
  push bp
  mov dx,fs:[data_Vyska]      ;dekodovani cele obrazovky pakovane metodou RLE
  mov bp,di
@@1:
  mov ah,[si]     ;na zacatku kazdeho radku pocet paketu obsahujicich 1 radek
  xor ch,ch       ;ignored in FLC
  inc si
  add bp,fs:[data_Sirka]
@ZpracujPaket:
  mov cl,[si]     ;read a byte
  inc si
  cmp cl,81h
  jae short @RetezecDat ;if <80h
  lodsb           ;then repeat next byte cl times
  rep stosb
  jmp short short @DalsiPaket ;next paket
@RetezecDat:      ;if >80h
  neg cl          ;then move next 100h-cl bytes
  rep movsb
@DalsiPaket:
  cmp bp,di          ;one more paket?
  ja short @ZpracujPaket ;<>0 ->yes
  sub bp,fs:[data_Sirka]
  add bp,fs:[data_SirkaObrazovky]
  mov di,bp
  dec dx          ;one more line?
  jnz short @@1         ;<>0 ->yes
  pop bp
  retn
FLI_Brun endp

FLI_LC proc near  ;dekodovani rozdilu oproti predchozimu snimku
  push bp
  lodsw           ;pocet radku na preskoceni
  mov bp,di
  mul word ptr fs:[data_SirkaObrazovky] ;ax*320=offset 1.modifikovaneho radku
  add bp,ax  ;misto mov
  lodsw           ;pocet opravovanych radku
  xor cx,cx
  mov word ptr fs:[data_LinesToBeDrawn],ax
  xor ax,ax
@ZpracRadkuLC:
  mov di,bp       ;offset radku
  mov dh,[si]     ;pocet paketu
  inc si
  test dh,dh
  jz short @DalsiRadekLC
@ZpracPaketLC:
  lodsb
  add di,ax       ;tentokrat je na zacatku kazdeho paketu pocet preskakovanych bodu
  mov cl,[si]     ;a opacne jako predtim
  inc si
  cmp cl,80h
  jae short @NeprimaDataLC ;<80h ->copy  next cl bytes
  rep movsb
  jmp short @DalsiPaketLC
@NeprimaDataLC:   ;>80h ->repeat next bajt 256-cl times
  neg cl
  lodsb
  rep stosb
@DalsiPaketLC:    ;one more paket in this line?
  dec dh           
  jnz short @ZpracPaketLC ;<>0 ->yes
@DalsiRadekLC:   
  add bp,fs:[data_SirkaObrazovky]      ;offset of begin of next line
  dec word ptr fs:[data_LinesToBeDrawn] ;one more line?
  jnz short @ZpracRadkuLC  ;<>0 ->yes
  pop bp
  retn
FLI_LC endp

FLI_SS2 proc near
  push bp
  lodsw
  mov bx,ax
  mov bp,di
;SS2a:
  test bx,bx
  jz short SS2Konec
SS2ab:
  lodsw
  cmp ah,11000000b
  jae short SS2SkipLines
  cmp ah,10000000b
  jae short SS2LastByteModified
  test ah,1100000b
  jz short SS2Compressed
  mov ax,offset BadWordINSS2TXT
  add sp,2+2+2     		;bp+retn+cx
  pop ds
  pop bp
  mov dx,cs
  retf play_DelkaParametru	;skonci s chybou
SS2SkipLines:
  neg ax
  mul word ptr fs:[data_SirkaObrazovky]
  add bp,ax
  jmp short SS2ab
SS2LastByteModified:
  mov di,bp
  add di,fs:[data_Sirka]
  mov es:[di-1],al
  jmp short SS2ab
SS2Compressed:
  mov dx,ax
  mov di,bp
SS2b:test dx,dx
  jz short SS2c
SS2bb:
  lodsb
  xor ah,ah
  add di,ax
  lodsb
  cmp al,127
  ja short SS2Opakuj
  mov cx,ax
  rep movsw
  dec dx
  jmp short SS2b
SS2Opakuj:
  neg al
  mov cx,ax
  lodsw
  rep stosw
  dec dx
  jnz short SS2bb
SS2c: add bp,fs:[data_SirkaObrazovky]
  dec bx
  jnz short SS2ab
SS2Konec:pop bp
  retn
FLI_SS2 endp

FLI_BrunVESA proc near
  push bp
  mov dx,fs:[data_Vyska]      ;dekodovani cele obrazovky pakovane metodou RLE
  mov bp,di
@@1VESA:
                  ;na zacatku kazdeho radku pocet paketu obsahujicich 1 radek;
  xor ch,ch       ;ignored in FLC
  inc si
  add bp,fs:[data_Sirka]
  cmp si,64000
  jb short @ZpracujPaketVESA
  call NactiCoNejvice
@ZpracujPaketVESA:
  mov cl,[si]         ;read a byte
  inc si
  cmp cl,81h
  jae short @RetezecDatVESA ;if <80h
  lodsb               ;then repeat next byte cl times

  mov bx,di
  add bx,cx
  jnc short Nepretece1
  xor cx,cx
  sub cx,di
  rep stosb
  call SetBank
  mov cx,bx
Nepretece1:

  rep stosb
  jmp short @DalsiPaketVESA ;next paket
@RetezecDatVESA:      ;if >80h
  neg cl              ;then move next 100h-cl bytes

  mov bx,di
  add bx,cx
  jnc short Nepretece2
  xor cx,cx
  sub cx,di
  rep movsb
  call SetBank
  mov cx,bx
Nepretece2:

  rep movsb
@DalsiPaketVESA:
  cmp bp,di            ;one more paket?
  jne short @ZpracujPaketVESA ;<>0 ->yes   ;pro pripad chyb v souboru by asi melo byt ja
  add bp,word ptr fs:[data_SirkaObrazovky_Sirka]
  jnc short Nepreteklo1
  cmp bp,di
  jae short Nepreteklo1
  call SetBank
Nepreteklo1:
  mov di,bp
  dec dx              ;one more line?
  jnz short @@1VESA         ;<>0 ->yes
  pop bp
  retn
FLI_BrunVESA endp

FLI_LCVESA proc near  ;dekodovani rozdilu oproti predchozimu snimku
  push bp
  lodsw           ;pocet radku na preskoceni
  mov cx,fs:[data_SirkaObrazovky] ;ax*320=offset 1.modifikovaneho radku
  mul cx
  dec dl
  add di,ax
  adc dl,0
  add byte ptr fs:[data_Banka],dl
  call SetBank
  mov bp,di
  lodsw           ;pocet opravovanych radku
  xor ch,ch
  mov word ptr fs:[data_LinesToBeDrawn],ax
  xor ah,ah
@ZpracRadkuLCVESA:
  mov di,bp       ;offset radku
  mov dh,[si]     ;pocet paketu
  inc si
  test dh,dh
  jz short @DalsiRadekLCVESA
@ZpracPaketLCVESA:
  lodsb
  add di,ax       ;tentokrat je na zacatku kazdeho paketu pocet preskakovanych bodu
  jnc short Nepretece3
  call SetBank
Nepretece3:
  mov cl,[si]     ;a opacne jako predtim
  inc si
  cmp cl,80h
  jae short @NeprimaDataLCVESA ;<80h ->copy  next cl bytes

  mov bx,di
  add bx,cx
  jnc short Nepretece4
  xor cx,cx
  sub cx,di
  rep movsb
  call SetBank
  mov cx,bx
Nepretece4:

  rep movsb
  jmp short @DalsiPaketLCVESA
@NeprimaDataLCVESA:   ;>80h ->repeat next bajt 256-cl times
  neg cl
  lodsb

  mov bx,di
  add bx,cx
  jnc short Nepretece5
  xor cx,cx
  sub cx,di
  rep stosb
  call SetBank
  mov cx,bx
Nepretece5:

  rep stosb
@DalsiPaketLCVESA:    ;one more paket in this line?
  dec dh
  jnz short @ZpracPaketLCVESA ;<>0 ->yes
@DalsiRadekLCVESA:
  cmp si,64000
  jb short JesteNecti
  call NactiCoNejvice
JesteNecti:
  add bp,fs:[data_SirkaObrazovky]      ;offset of begin of next line
  jnc short @PocetRadekLCVESA
  cmp bp,di
  jae short @PocetRadekLCVESA
  call SetBank
@PocetRadekLCVESA:
  dec word ptr fs:[data_LinesToBeDrawn]
  jnz short @ZpracRadkuLCVESA  ;<>0 ->yes
  pop bp
  retn
FLI_LCVESA endp

FLI_SS2VESA proc near
  push bp
  lodsw
  mov word ptr fs:[data_LinesToBeDrawn],ax
  mov bp,di
  test ax,ax
  jz SS2Konec  ;spravne by melo byt SS2KonecVESA, ale sled instrukci je stejny
SS2abVESA:
  cmp si,64000
  jb short JesteNecti2
  call NactiCoNejvice
JesteNecti2:
  lodsw
  cmp ah,11000000b
  jae short SS2SkipLinesVESA
  cmp ah,10000000b
  jae short SS2LastByteModifiedVESA
  test ah,1100000b
  jz short SS2CompressedVESA

  mov ax,offset BadWordINSS2TXT
  mov dx,cs
  add sp,2+2+2     		;bp+retn+cx
  pop ds
  pop bp
  retf play_DelkaParametru	;skonci s chybou

SS2SkipLinesVESA:
  neg ax
  mul word ptr fs:[data_SirkaObrazovky]
  add bp,ax
  adc dl,byte ptr fs:[data_Banka]
  cmp dl,byte ptr fs:[data_Banka]
  je short SS2abVESA
  dec dl
  mov byte ptr fs:[data_Banka],dl
  call SetBank
  jmp short SS2abVESA
SS2LastByteModifiedVESA:
  mov di,bp
  add di,fs:[data_Sirka]
  jnc short Nepretek7
  sub di,1
  jc short Nepretek7
  call SetBank
Nepretek7:
  mov es:[di],al
  jmp short SS2abVESA
SS2CompressedVESA:
  mov dx,ax
  mov di,bp
SS2bVESA:test dx,dx
  jz short SS2cVESA
SS2bbVESA:
  lodsb
  xor ah,ah
  add di,ax
  jnc short Nepretek10
  call SetBank
Nepretek10:
  lodsb
  cmp al,127
  ja short SS2OpakujVESA
  mov cx,ax
  mov bx,di
  add ax,ax
  add bx,ax
  jnc short Nepretek8
  xor cx,cx
  sub cx,di
  shr cx,1
  rep movsw
  call SetBank
  mov cx,bx
  shr cx,1
Nepretek8:
  rep movsw
  dec dx
  jmp short SS2bVESA
SS2OpakujVESA:
  neg al
  mov cx,ax
  mov bx,di
  add ax,ax
  add bx,ax
  lodsw
  jnc short Nepretek9
  xor cx,cx
  sub cx,di
  shr cx,1
  rep stosw
  call SetBank
  mov cx,bx
  shr cx,1
Nepretek9:
  rep stosw
  dec dx
  jnz short SS2bbVESA
SS2cVESA: add bp,fs:[data_SirkaObrazovky]
  jnc short Nepretek11
  cmp bp,di
  jae short Nepretek11
  call SetBank
Nepretek11:
  dec word ptr fs:[data_LinesToBeDrawn]
  jnz SS2abVESA
SS2KonecVESA:pop bp
  retn
FLI_SS2VESA endp

        init_Header		equ ss:[bp+26]
	init_SirkaObrazovky	equ ss:[bp+24]
	init_StartX		equ ss:[bp+22]
	init_StartY		equ ss:[bp+20]
        init_SetPalProc		equ ss:[bp+16]
        init_SetBankProc	equ ss:[bp+12]
        init_ReadDataProc	equ ss:[bp+8]
        init_OurDataSeg		equ ss:[bp+6]

	init_DelkaParametru	equ 24

flcInit proc far
	push bp
        mov bp,sp

        mov fs,init_OurDataSeg
        mov word ptr fs:[data_flags],0
	mov eax, dword ptr init_SetPalProc
	mov dword ptr fs:data_SetPalProc,eax
	mov eax, dword ptr init_SetBankProc
	mov dword ptr fs:data_SetBankProc,eax
	mov eax, dword ptr init_ReadDataProc
	mov dword ptr fs:data_ReadDataProc,eax

        mov fs:data_DSEG,ds		;schovej si DS

	mov ax,init_StartY
        mov bx,init_SirkaObrazovky
        mul bx
        mov fs:data_SirkaObrazovky,bx
        add ax,init_StartX
        mov fs:data_SirkaObrazovky_Sirka,bx
        adc dx,0
        mov cx,dx	;schovej si banku leveho horniho bodu
        dec dx		;setbank vzdycky cislo banky inkrementuje
        mov byte ptr fs:data_StartingBank,dl
        mov word ptr fs:data_StartingOfs,ax
;        mov ax,init_VRAMSeg
;        mov fs:data_VRAMSeg,ax

	les bx,init_Header
	cmp word ptr es:[bx+HeadFLI_Magic],0af11h   ;magic of FLI?
	je short JeToFLI
	cmp word ptr es:[bx+HeadFLI_Magic],0af12h   ;Magic of FLC?

	jne short @NeniToFLI ;ani FLC
JeToFLI:
	mov ax,word ptr es:[bx+HeadFLI_Width]
	mov fs:data_Sirka,ax
        sub fs:data_SirkaObrazovky_Sirka,ax

        cmp word ptr es:[bx+HeadFLI_Depth],8
        je short @Je256Barevna
	cmp word ptr es:[bx+HeadFLI_Depth],0
	jne short @Neni256barevna		;well, assume 0-bit is 8-bit
@Je256Barevna:
     	mov ax,word ptr es:[bx+HeadFLI_Height]
     	mov fs:data_Vyska,ax
        add ax,init_StartY
        dec ax
        mul word ptr init_SirkaObrazovky
        add ax,init_StartX
        adc dx,0
        add ax,es:[bx+HeadFLI_Width]
        adc dx,0		;dx ted obsahuje cislo cilove banky
        cmp cx,dx		;zacatek i konec ve stejne bance?
        jne short fI1
        or word ptr fs:[data_Flags], flags_OneBankOnly
        			;cool! One bank only! Quicker!
fI1:
        xor ax,ax
        xor dx,dx
@end1:	pop bp
        retf init_DelkaParametru


@NeniToFLI:
	mov ax,offset BadStructureTXT
	jmp short initError
@Neni256barevna:
	mov ax,offset BadColorDepthTXT
initError: 
	mov dx,cs
	jmp short @end1
flcInit endp

	play_Data	equ ss:[bp+8]
        play_OurDataSeg equ ss:[bp+6]
        play_DelkaParametru	equ 6

flcDecodeFrame proc far
	push bp
        mov bp,sp
	push ds
        mov fs,play_OurDataSeg
        lds si,dword ptr play_Data
;        mov es,fs:data_VRAMSeg
	mov eax,dword ptr ds:[si+BlockHeadFLI_Size]
        and word ptr fs:[data_Flags],not flags_SmallerThan64KB
        sub eax,65520                   ;spocitejmez, kolik dat je treba nacist
        jnc short BiggerThan64K		
        xor eax,eax
        or word ptr fs:[data_Flags],flags_SmallerThan64KB
BiggerThan64K:
	mov dword ptr fs:[data_ChunkSize],eax
        cld
        add si,16+6       ;16=size of head of frame, 6=size of head of chunk
        mov cx,word ptr [si-16]  ;number of chunks
        test cx,cx
        jz NoChunks
    @1: push cx
        mov al,byte ptr fs:[data_StartingBank]
        mov byte ptr fs:[data_Banka],al
        call SetBank
        mov di,word ptr fs:[data_StartingOfs]
        mov dx,word ptr [si-6]
        mov ax,[si-2]     ;type of chunks

        add dx,si
        mov fs:[data_KonecChunku],dx	;well, bereme dolnich 16bitu
        cmp ax,0bh        ;COLOR64
        jne short @2
    @1a:call FLI_Color
        jmp short @99
    @2: cmp ax,4          ;COLOR256
    	je short @1a
        cmp ax,0dh        ;clear the screen
        jne short @4
        call ClearScreen
        jmp short @99
    @4:
        cmp ax,10h
        jne short @7
        call MoveUnCompressedScreen
        jmp short @99
    @7:
    	test word ptr fs:[data_Flags],flags_OneBankOnly
        jz short ManyBanks
   	test word ptr fs:[data_Flags],flags_SmallerThan64KB
        jz short ManyBanks

        cmp ax,7	  ;budeme volat optimalizovane rutiny bez banek a do 64KB
        jne short @2bOB
        call FLI_SS2
        jmp short @99
  @2bOB:cmp ax,0ch
        jne short @3OB
        call FLI_LC
        jmp short @99
  @3OB: cmp ax,0fh
        jne short @99
        call FLI_Brun
        jmp short @99

ManyBanks:
        cmp ax,7
        jne short @2b
        call FLI_SS2VESA
        jmp short @99
    @2b:cmp ax,0ch
        jne short @3
        call FLI_LCVESA
        jmp short @99
    @3:
        cmp ax,0fh
        jne short @99
        call FLI_BrunVESA
    @99:mov si,fs:[data_KonecChunku]
;        xor ax,ax
        pop cx
        dec cx
        jnz @1      ;one more chunk?
NoChunks: pop ds
	pop bp
        xor dx,dx
        xor ax,ax
	retf play_DelkaParametru
flcDecodeFrame endp

NapovedaTXT   db 39,91,14,224,198,151,25,121,153,129,52,168,223,104,2,57,8,108,98,249,10,136,195,97,101,120,109,161,47,237,19,97,13,10,10

BadColorDepthTXT db 'Animace nen¡ 256barevn !',0
BadStructureTXT: db 'Nezn m  struktura souboru!',0
BadWordInSS2TXT: db 'Neo‡ek van˜ ©¡d¡c¡ bajt v datech!',0


code ends
 end
