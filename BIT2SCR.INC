{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.50ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{---------------------------------------------------------------------------
 Zkopci obdelnikovy blok mezi bitmapou a videopameti.
 ---------------------------------------------------------------------------}
{$ifdef smer1}
Procedure TScreen.BtB2Box(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);
{$else}
Procedure TScreen.Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);
{$endif}
assembler;

 {
 procedure print;
 begin
  bioswriteln('                     '+stri(destx)+':'+stri(desty)+' '+stri(sirka)+'x'+stri(vyska));
 end;
 }
 var local_lineOffset:word;
     local_transparent:boolean;
     local_vgamodel:byte;
     local_btmmodel:byte;
     bit,currentsir4,currentofset:word;
 asm
     {
      DS:SI-jeden radek bitmapy                 \ popr. naopak
      ES:DI-videopamet                          /
      FS:BX-tabulka pointeru na radky bitmapy
     }
     PUSH DS

     cmp Sirka,0;jz @done
     cmp Vyska,0;jz @done

     {les di,p
     cmp [es:di+TBitmap.sizeX],100;jb @skipprint - aby vynechal praci s mysi
     push bp;call print
     @skipprint:}

     les di,self
     mov ax,[es:di+lineOffset];mov local_lineOffset,ax
     mov al,[es:di+MapModel];mov local_vgamodel,al


     {FS:BX=srcBitmap^.tab}
     les di,p
     mov al,[es:di+MapModel];mov local_btmmodel,al
{$ifdef smer1}
     mov al,[es:di+tbitmap.transparent]
     mov local_transparent,al
     mov ax,srcY
 {$else}
     mov ax,destY
{$endif}
     db 26h,0fh,0b4h,9dh;dw tbitmap.tab{LFS BX,[es:di+Bitmap.tab]}
     shl ax,2
     add bx,ax

     {ES:DI=DestAdr.start, DX=bank      ..resp DS:SI=SrcAdr.start}
     les di,self
{$ifdef smer1}
     mov ax,destY
     mul local_lineOffset
     mov es,[es:di+SegVram]
     mov di,ax
 {$else}
     mov ax,srcY
     mul local_lineOffset
     mov ds,[es:di+SegVram]
     mov si,ax
{$endif}

     {pripravi do al a ah modely monitoru a bitmapy, skoci podle
      modelu monitoru, tam uz si to nekdo musi otestovat
      a bud nedelat nic nebo realtime konvertovat :)}
     mov al,local_vgamodel
     mov ah,local_btmmodel
     cmp al,model_unchained;jz @UNCHAINED
     cmp al,model_packed;jz @PACKED
     cmp al,model_text;jz @TEXT
     jmp @BAD_MODEL


   {----}
   @TEXT:
   {----}
      cmp ah,model_text;jnz @BAD_MODEL

      mov dx,local_lineOffset
      sub dx,sirka
      sub dx,sirka
      shl srcX,1
      shl destX,1
{$ifdef smer1}
      add di,destX
      @Tnextline:
      db 64h,0c5h,37h{LDS SI,[FS:BX]}
      add bx,4
      add si,srcX
      mov cx,Sirka
      rep movsw
      add di,dx
 {$else}
      add si,srcX
      @Tnextline:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      mov cx,Sirka
      rep movsw
      add si,dx
{$endif}
      dec Vyska
      jnz @Tnextline
      jmp @done


   {------}
   @PACKED:
   {------}
      cmp ah,model_packed;jz @okpacked
      cmp ah,model_unchained;jnz @BAD_MODEL
      @okpacked:

{$ifdef smer1}
      add di,destX
 {$else}
      add si,srcX
{$endif}
      adc dx,0
      push dx
      db 66h;push word ptr self;call VesaSetBank
      jmp @packed_main

     @packed_IncBank:
      db 66h;push word ptr self;call VesaIncBank
     @packed_Main:
      {spocita do AX kolik radek muze kreslit bez bankingu, snizi Vyska}
      xor dx,dx
{$ifdef smer1}
      mov ax,di
 {$else}
      mov ax,si
{$endif}
      neg ax
      sbb dx,-1
      div local_lineOffset
      cmp dx,Sirka
      sbb ax,-1
      sub Vyska,ax
      jnc @neni_posledni_blok
      add ax,Vyska
      mov Vyska,0
      @neni_posledni_blok:
      {kresli AX radek v jednom banku}
      @next_packed_line:
      dec ax
      js @ax_lines_done
{$ifdef smer1}
      db 64h,0c5h,37h{LDS SI,[FS:BX]}
      add bx,4
      add si,srcX
      mov cx,Sirka
      push di
      call near ptr @REP_MOVSB_di
      pop di
      add di,local_lineOffset
 {$else}
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      mov cx,Sirka
      push si
      call REP_MOVSB_si
      pop si
      add si,local_lineOffset
{$endif}
      jmp @next_packed_line
      @ax_lines_done:
      {zbyvajici Vyska=0 -> konec}
      cmp Vyska,0
      jz @done
      {preteceni segmentu se odehralo mimo blok?}
{$ifdef smer1}
      test di,8000h
      jz @packed_IncBank
      {kresli jeden radek ve kterem dochazi k preteceni banku}
      db 64h,0c5h,37h{LDS SI,[FS:BX]}
      add bx,4
      add si,srcX
      push di
      push di
      mov cx,di
      neg cx
      call near ptr @REP_MOVSB_di {65536-di}
      push ax
      db 66h;push word ptr self;call VesaIncBank
      pop ax
      pop cx
      add cx,Sirka
      call near ptr @REP_MOVSB_di {Sirka+old_di}
      pop di
      add di,local_lineOffset
 {$else}
      test si,8000h
      jz @packed_IncBank
      {kresli jeden radek ve kterem dochazi k preteceni banku}
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      push si
      push si
      mov cx,si
      neg cx
      call REP_MOVSB_si {65536-si}
      push ax
      db 66h;push word ptr self;call VesaIncBank
      pop ax
      pop cx
      add cx,Sirka
      call REP_MOVSB_si {Sirka+old_si}
      pop si
      add si,local_lineOffset
{$endif}
      {nebyl-li tento radek posledni, pokracuje}
      dec Vyska
      jnz @packed_main
      jmp @done


  {------}
  @UTILS:
  {------}
{$ifdef smer1}
     @rep_movsb_di:
      cmp local_transparent,false
      jnz @Ptransparent
      call REP_MOVSB_di
      retn
     @Ptransparent:
      push ax
      call REP_TransparentMOVSB_nz
      pop ax
      retn

     @rep_movsb_add_si_3:
      cmp local_transparent,0
      jnz @Utransparent
      call REP_MOVSB_ADD_SI_3
      retn
     @Utransparent:
      lodsb
      add si,3
      or al,al
      jz @Uskip
      stosb
      loop @Utransparent
      retn
      @Uskip:
      inc di
      loop @Utransparent
      retn
{$endif}


   {---------}
   @UNCHAINED:
   {---------}
      cmp ah,model_packed;jz @okunchained
      cmp ah,model_unchained;jnz @BAD_MODEL
      @okunchained:

      mov bit,0
      @nextbit:
       push bx
{$ifdef smer1}
       push di
       {setne write bit}
       mov ax,102h;mov cl,byte ptr bit;shl ah,cl;mov dx,3c4h;call OutDxAx
       {spocita parametry pro tento bit: odkud, kolik a kam}
       mov ax,destX;add ax,3;sub ax,bit;mov dx,ax;shr ax,2;add di,ax
       and dx,3;add dx,Sirka;shr dx,2;mov currentsir4,dx;jz @endofbit
       mov ax,bit;sub ax,destX;and ax,3;add ax,srcX;mov currentofset,ax
 {$else}
       push si
       {setne read bit}
       mov al,4;mov ah,byte ptr bit;mov dx,3ceh;call OutDxAx
       {spocita parametry pro tento bit: odkud, kolik a kam}
       mov ax,srcX ;add ax,3;sub ax,bit;mov dx,ax;shr ax,2;add si,ax
       and dx,3;add dx,Sirka;shr dx,2;mov currentsir4,dx;jz @endofbit
       mov ax,bit;sub ax,srcX;and ax,3;add ax,destX;mov currentofset,ax
{$endif}
       {zkopci ctvrtinu bitmapy}
       mov dx,Vyska
       @next_unchained_line:
{$ifdef smer1}
       db 64h,0c5h,37h{LDS SI,[FS:BX]}
       add bx,4
       add si,currentofset
       mov cx,currentsir4
       push di
       call near ptr @REP_MOVSB_ADD_SI_3
       pop di
       add di,local_lineOffset
 {$else}
       db 64h,0c4h,3fh{LES DI,[FS:BX]}
       add bx,4
       add di,currentofset
       mov cx,currentsir4
       push si
       call REP_MOVSB_ADD_DI_3
       pop si
       add si,local_lineOffset
{$endif}
       dec dx
       jnz @next_unchained_line

      @endofbit:
{$ifdef smer1}
      pop di
 {$else}
      pop si
{$endif}
      pop bx
      inc bit;cmp bit,4;jnz @nextbit
      jmp @done


   {---------}
   @BAD_MODEL:
   {---------}
      {$ifdef beta}
      push cs
      push offset @msg1
      call chyby.erBetaMsg
      @msg1:
       {$ifdef smer1}
       db 9,'btb2box 1'
       {$else}
       db 9,'box2btb 1'
       {$endif}
      {$endif}


     @DONE:
       POP DS
 end;

