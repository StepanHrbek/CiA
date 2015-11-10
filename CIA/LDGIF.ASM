;ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
;³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
;³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

data segment public
     extrn TmpPtr,Strip,BitsLeft,WorkArray,CurMCURow,Strips,I,IC,EC,WorkSeg1
     extrn Tmp2,Tmp11,c,bb,DelUkazatele,NextRestartNum
data ends

code segment public

	extrn CteniGIF,InitLZW,PreteceniBloku
        public DeLZW

        assume cs:code, ds:data
.386

DeLZW proc near
PredRepeat:
      cld
      mov fs,WorkSeg1
      mov di,TmpPtr
      mov es,word ptr [TmpPtr+2]
@Repeat:
      mov si,Strip                ;{ ‡ten¡ nov‚ho indexu }
@@koloGIF:
      mov edx,dword ptr WorkArray[si+1]
      mov cx,BitsLeft
      shr edx,cl
      and dx,Strips
      add cl,byte ptr Tmp11       ;PocBit

      mov ax,cx
      and cl,7
      mov byte ptr BitsLeft,cl
      shr ax,3
      add Strip,ax
      add si,ax
@ZkusKonecBloku:
      add si,2
      cmp si,Tmp2
      jb short @@PredKonec
      mov si,Tmp2
      cmp si,CurMCURow     ;MaxMaxII
      je short @@MusimeCistZDisku
      mov ax,word ptr WorkArray[si+1-2]
      mov bl,byte ptr WorkArray[si+1]
      mov word ptr WorkArray[si+1-1],ax
      xor bh,bh
      inc Strip
      inc bx
      add Tmp2,bx
      jmp short @@PredKonec2
@@MusimeCistZDisku:
      mov si,Tmp2
      mov ax,word ptr WorkArray[1+si-2]
      push ax
      sub si,Strip
      push dx
      push si
      push di
      call near ptr CteniGIF
      pop di
      cld
      pop si
      mov fs,WorkSeg1
      pop dx
      mov es,word ptr [TmpPtr+2]
      pop ax
      mov word ptr [WorkArray],ax
      sub Strip,si
      cmp word ptr CurMCURow,0        ;MaxMaxII,0
;{      mov dx,I}
      je short @@Konec
@@PredKonec2:mov si,Strip
      jmp @ZkusKonecBloku

@@PredKonec:
      mov I,dx
     @@Konec:
      cmp dx,IC          ;{if i=IC then InitLZW}
      jne short @NoInit
      mov TmpPtr,di
      call near ptr InitLZW
      jmp PredRepeat     ;{inicializace bude provedena v PredRepeat}
@NoInit:
      cmp dx,EC          ;{else if i<>EC then}
      je @UplnyKonec
      cmp dx,bb          ;LZW je prece kauzalni system! Porucha, abortujeme
      jae @UplnyKonec
          mov si,dx       ;{begin}
          add si,si
          mov ax,c
          PUSH SI
;push gs
;push bx  ...neni treba
          lgs bx,dword ptr DelUkazatele
          mov cx,word ptr gs:[bx+si] ;{aa:=DelUkazatele[i];}
;pop bx
;pop gs
          sub ax,cx
          cmp ax,di ;word ptr TmpPtr
          ja short @dal                         ;{if TypPtr(TmpPtr).ofs1>c-aa then pretecenibloku}
          push cx
          mov TmpPtr,di
          call near ptr PreteceniBloku
          mov di,TmpPtr
      mov fs,WorkSeg1
      mov es,word ptr [TmpPtr+2]

          cld
          pop cx
         @dal:
	  mov bx,bb
	  add bx,bx
	  inc cx
;push gs
          lgs si,dword ptr DelUkazatele
	  mov word ptr gs:[bx+si],cx
;pop gs
          POP SI
;{$ifndef Shrinking}
	  add si,si
;{$else}
;{	  add si,si}
;	  mov word ptr VESAModeInfo[si],bx
;@1:	  add si,si
;{$endif}
	  add bx,bx
          push ds

          mov word ptr fs:[bx],di   ;Ukazatele
          mov word ptr fs:[bx+2],es ;Ukazatele
;          mov bx,si                ;pro zvyseni cache hits

          lds si,dword ptr fs:[si]  ;Ukazatele

;          mov word ptr fs:[bx],di   ;;pro zvyseni cache hits
;          mov word ptr fs:[bx+2],es ;;pro zvyseni cache hits

          dec cx
          rep movsb
          pop ds


          mov ax,NextRestartNum
          cmp ax,bb                ;{if bb=NextRestartNum then}
          jne short @NezvetsujDelkuBloku ;{begin}
          inc Tmp11                ;PocBit
          shl ax,1                 ;{NextRestartNum:=NextRestartNum*2;}
          cmp ax,4096              ;{if NextRestartNum=4096 then NextRestartNum:=4098;}
          jne short @@0
          inc ax
          inc ax
@@0:      cmp ax,8196              ;!!! necely GIF?
          je short @UplnyKonec
          shl Strips,1             ;{Strips:=(Strips shl 1)+1;}
          mov NextRestartNum,ax
          inc Strips               ;{end}
@NezvetsujDelkuBloku:
          inc bb              ;{end}
          mov ax,i
          cmp ax,EC
          jne @Repeat
@UplnyKonec:
        mov TmpPtr,di
	retn
DeLZW endp


code ends

end