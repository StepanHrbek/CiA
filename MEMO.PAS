{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.10ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Memo;
Interface {$i define.inc}
Uses      Chyby, Objects,Memory{$ifdef dpmi},WinApi,DPMI{$endif};
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                        Sprava pameti
---------------------------------------------------------------------------

Snaha byla umoznit psat programy nezavisle na zpusobu spravy pameti.
Budes-li tedy alokovat pamet s pouzitim zdejsich rutin, bude tvuj program
prenositelny mezi temito pametovymi modely (nastavuje se v DEFINE.INC):

 PROTPAS
  - protected mod
  - alokace pameti se interne provadi pomoci: GetMem, WinApi, INT 31

 REALPAS
  - real mod
  - alokace pameti se interne provadi pomoci: GetMem, INT 21
  - na zacatku programu by melo byt neco jako ($M stack,hodne,hodne)

 REALDOS
  - real mod
  - alokace pameti se interne provadi pomoci: INT 21
  - na zacatku programu by tedy melo byt neco jako ($M stack,malo,malo)
  - pozor: New a Dispose zustavaji nepretizene, berou pamet z ^^^ ^^^^
  - tento model se hodi v pripade, ze tvuj program vola jine
    dosove programy a potrebuje pro ne hodne dosove pameti



---------------------------------------------------------------------------
                        Operace s bloky pameti
---------------------------------------------------------------------------
Klasicke blokove presuny typu REP MOVSB lze az ctyrnasobne zrychlit pouzitim
zdejsich rutin zacinajicich na REP_.
K nazvoslovi:
 - Zacatek nazvu tvori prepis instrukce (instrukci), kde mezery nahrazuje
   podtrzitko, napr REP_STOSB.
 - Nasledovat muze _SI nebo _DI pro odliseni verzi zarovnavajicich adresy
   podle SI (zdroj) nebo DI (cil). Pokud je na jedne strane videopamet,
   zarovnavani podle ni muze presun znacne urychlit.
 - Nasledovat muze _NZ (NoZero) coz znamena, ze CX nesmi byt nula.
 - Nasledovat muze _W (Word) pro odliseni verzi nezarovnavajicich adresy
   na doublewordy, nybrz na wordy. Zarovnavani na wordy ma nizsi rezii,
   a je tedy rychlejsi u kratkych presunu.
 - Nasledovat muze _O (Overflow) nebo _NO (NoOverflow) coz znamena,
   ze offset smi/nesmi behem presunu pretect 64KB. Toto omezeni vede
   ke zjednoduseni a tudiz zvyseni rychlosti.

}



{---------------------------------------------------------------------------
 Verejne typy a promenne.
 ---------------------------------------------------------------------------}

TYPE  PByte     = ^byte;
      PWord     = ^word;
      PInt      = ^integer;
      PLong     = ^longint;
      TProc     = procedure;
      FBool     = function:boolean;
      PtrRec    = record
                   Ofs, Seg: Word;
                  end;
      Fuzzy     = (Bad,Unsure,Okay);

VAR   freeofs:word;                    {64KB pameti komukoliv k dispozici}
      freeseg:word;                    {pro docasne vyuziti}
      freeptr:pointer absolute freeofs;

      free:array[0..1027] of byte;     {1KB pameti komukoliv k dispozici}
      freeW:array[0..513] of word absolute free;{pro docasne vyuziti}
      freeL:array[0..256] of longint absolute free;

      debugmem:boolean;                {debugovaci rezim: vypis hlasek o pameti}

{---------------------------------------------------------------------------
 Nahrada systemovych zdroju pameti.
 ---------------------------------------------------------------------------}
FUNCTION  MemAvail:longint;
FUNCTION  MaxAvail:longint;
FUNCTION  GetMem(var p:pointer;bytes:longint):boolean;
PROCEDURE FreeMem(var p:pointer;bytes:longint);
FUNCTION  GetMemDos(var segment:word;var p:pointer;bytes:longint):boolean;
PROCEDURE FreeMemDos(var p:pointer;bytes:longint);
PROCEDURE Seg2Desc(var w:word);

{---------------------------------------------------------------------------
 Zakladni operace s bloky pameti.
 ---------------------------------------------------------------------------}
PROCEDURE REP_STOSB;
PROCEDURE REP_STOSW_o;
PROCEDURE REP_STOSW_no;
PROCEDURE REP_MOVSB_si;
PROCEDURE REP_MOVSB_di;
PROCEDURE REP_MOVSB_si_nz_w;
PROCEDURE REP_MOVSB_di_nz_w;
PROCEDURE REP_MOVSB_back;
PROCEDURE REP_MOVSB_ADD_SI_3;
PROCEDURE REP_MOVSB_ADD_DI_3;
PROCEDURE REP_TransparentMOVSB_nz;
PROCEDURE MapBytesCX2DX_nz;
PROCEDURE TransparentMapBytesCX2DX_nz;
PROCEDURE MoveBack(src,dest:pointer;bytes:word{*predelat na long});
PROCEDURE MoveForw(src,dest:pointer;bytes:word);
PROCEDURE FillByte(blok:pointer;bytes:longint;value:byte);
PROCEDURE FillWord(blok:pointer;words:longint;value:word);
FUNCTION  CmpBlock(blok1,blok2:pointer;bytes:word):boolean;
FUNCTION  CmpByte(blok:pointer;val:byte;bytes:word):boolean;
FUNCTION  CmpWord(blok:pointer;val:word;words:word):boolean;

{---------------------------------------------------------------------------
 Ostatni
 ---------------------------------------------------------------------------}
PROCEDURE KillObj(var p:PObject);


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

Const
 UserBufsSize=4;{tolik kilobajtu muzes v realmodu alokovat do bufferu
                 - viz unita memory: newbuffer}

{---------------------------------------------------------------------------
 Nekolik kousku zkopirovanych z jinych unit za ucelem snizeni poctu
 unit v uses.
 ---------------------------------------------------------------------------}
  FUNCTION  Stri(n:longint):string;
  var st:string[10];
  begin
   str(n,st);
   stri:=st;
  end;
  PROCEDURE BiosWriteln(st:string);assembler;
   var p:pointer absolute st;
   asm
       push bp
       mov ax,300h;xor bx,bx;int 10h
       mov ax,1301h;mov bx,7;xor cx,cx
       les bp,p;mov cl,[es:bp];inc bp
       int 10h
        mov ax,1301h;mov bx,7;mov cx,2
        push cs;pop es;lea bp,@newline
        int 10h
       pop bp
        jmp @end
        @newline:
        db 13,10
        @end:
   end;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ GETMEM... ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}


{---------------------------------------------------------------------------
 Alokuje konvencni pamet. Jednotkou je 16B chunk.
 Vraci segment, pri neuspechu 0.
 ---------------------------------------------------------------------------}
FUNCTION GetConv16(bytes16:word):word;assembler;
 asm
     mov ah,48h;mov bx,bytes16;int 21h;
     jnc @ok;xor ax,ax;@ok:
 end;

{---------------------------------------------------------------------------
 Uvolnuje konvencni pamet a vynuluje ukazatel na ni.
 ---------------------------------------------------------------------------}
PROCEDURE FreeConv(var segment:word);assembler;
 asm
     les di,segment
     xor ax,ax
     xchg ax,[es:di]
     or ax,ax;jz @end
     mov es,ax;mov ah,49h;int 21h;
     @end:
 end;

{---------------------------------------------------------------------------
 Vraci maximalni naalokovatelne mnozstvi konvencni pameti v bajtech.
 ---------------------------------------------------------------------------}
FUNCTION GetMaxConv:longint;assembler;
 asm
     mov ah,48h;mov bx,0ffffh;int 21h;
     mov dx,bx;shr dx,12
     mov ax,bx;shl ax,4
 end;

{---------------------------------------------------------------------------
 Nahrada MemAvail.
 ---------------------------------------------------------------------------}
FUNCTION  MemAvail:longint;
begin
 {$ifdef realdos}
  MemAvail:=GetMaxConv;
 {$endif}
 {$ifdef realpas}
  MemAvail:=GetMaxConv+system.MemAvail;
 {$endif}
 {$ifdef protpas}
  MemAvail:=system.MemAvail;
 {$endif}
end;

{---------------------------------------------------------------------------
 Nahrada MaxAvail.
 ---------------------------------------------------------------------------}
FUNCTION  MaxAvail:longint;
begin
 {$ifdef realdos}
  MaxAvail:=GetMaxConv;
 {$endif}
 {$ifdef realpas}
  MaxAvail:=maxL(GetMaxConv,system.MaxAvail);
 {$endif}
 {$ifdef protpas}
  MaxAvail:=system.MaxAvail;
 {$endif}
end;

{---------------------------------------------------------------------------
 Alokace dosove pameti.
 Vraci uspesnost.
 ---------------------------------------------------------------------------}
FUNCTION  GetMemDos(var segment:word;var p:pointer;bytes:longint):boolean;
var   l:longint;
      selector:word;
begin
 {$ifdef dpmi}
 if midasDumbError(dpmiAllocDosMem((bytes+15) div 16,@segment,@selector))<>0
  then begin segment:=0;selector:=0;end;
 p:=ptr(selector,0);
 {$else}
 GetMem(p,bytes);
 segment:=PtrRec(p).Seg;
 {$endif}
 GetMemDos:=p<>nil;
end;

{---------------------------------------------------------------------------
 Uvolneni dosove pameti.
 ---------------------------------------------------------------------------}
PROCEDURE FreeMemDos(var p:pointer;bytes:longint);
var   selector:word;
begin
 if p<>nil then begin
   {$ifdef dpmi}
   selector:=PtrRec(p).Seg;
   midasDumbError(dpmiFreeDosMem(selector));
   {$else}
   FreeMem(p,bytes);
   {$endif}
   p:=nil;
   end;
end;

{---------------------------------------------------------------------------
 Prevede realmodovy segment na protektovy descriptor.
 Zkratka za dpmiSegmentDescriptor se dvema parametry.
 ---------------------------------------------------------------------------}
PROCEDURE Seg2Desc(var w:word);
var   i:integer;
begin
 {$ifdef dpmi}
 i:=dpmiSegmentDescriptor(w,@w);
 if i<>0 then midasError(i);
 {$endif}
end;



{---------------------------------------------------------------------------
 Nahrada za systemovy GetMem.
 Lisi se timto:
  - pri neuspechu vzdy nastavi nil a vrati false
  - parametr p musi byt typu pointer
  - pokus o alokaci 0 bajtu je chyba (hlasi ji pouze betaverze)
 Alokovat vic jak 65520 se nedoporucuje, ale jde to.
 ---------------------------------------------------------------------------}
FUNCTION GetMem(var p:pointer;bytes:longint):Boolean;
begin
 if debugmem then BiosWriteln(' Alloc '+stri(bytes)+'.');
 p:=nil;

 {$ifdef beta}
 if (bytes<1) then erBetaMsg('getmem 1');
 {$endif}

 {$ifdef realdos}
   p:=ptr(GetConv16((bytes+15) div 16),0);
 {$endif}

 {$ifdef realpas}
   if bytes<65536
    then p:=MemAlloc(bytes)                     {standardni alokace s pripadnym uvolnenim cache}
    else p:=ptr(GetConv16((bytes+15) div 16),0);{pouze pro vyjmecne situace, bez uvolnovani cache}
 {$endif}

 {$ifdef protpas}
   if bytes<65536
    then p:=MemAlloc(bytes)                     {standardni alokace s pripadnym uvolnenim cache}
    else p:=GlobalAllocPtr(gmem_fixed,bytes);   {pouze pro vyjmecne situace, bez uvolnovani cache}
 {$endif}

 getmem:=p<>nil;
end;

{---------------------------------------------------------------------------
 Nahrada za systemovy FreeMem. Vynuluje pointer.
 ---------------------------------------------------------------------------}
PROCEDURE FreeMem(var p:pointer;bytes:longint);
begin
 if p<>nil then begin
   if debugmem then BiosWriteln(' Free '+stri(bytes)+'.');

   {$ifdef realdos}
     FreeConv(PtrRec(p).Seg);
   {$endif}

   {$ifdef realpas}
     if bytes<65536
      then system.FreeMem(p,bytes)
      else FreeConv(PtrRec(p).Seg);
   {$endif}

   {$ifdef protpas}
     if bytes<65536
      then system.FreeMem(p,bytes)
      else GlobalFreePtr(p);
   {$endif}

   p:=nil;
   end;
end;





{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ ASM RUTINY ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}


{---------------------------------------------------------------------------
 Optimalizovanej REP STOSB
 CX libovolne.
 DI smi pretect 64KB.
 Meni hornich 24 bitu EAX.
 ---------------------------------------------------------------------------}
PROCEDURE REP_STOSB;assembler;
 asm
       cmp cx,16;jc @simple
       {fill eax}
       mov ah,al;push ax;push ax;db 66h;pop ax
       {zarovna DI na sudou}
       test di,1;jz @s1ok;stosb;dec cx;@s1ok:
       {zarovna DI na dablsudou}
       test di,2;jz @s2ok;stosw;sub cx,2;@s2ok:
       {dodela zbytek}
       push cx;shr cx,2;db 66h;rep stosw;pop cx;and cx,3
       @simple:
       rep stosb
       @end:
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP STOSW.
 CX libovolne.
 DI smi pretect 64KB.
 Meni hornich 16 bitu EAX.
 ---------------------------------------------------------------------------}
PROCEDURE REP_STOSW_o;assembler;
 asm
       test di,1;jnz @licha

      @suda:
       {zarovna DI na dablsudou}
       test di,2;jz @s1ok
       jcxz @end{osetri pripad cx=0}
       stosw
       dec cx
       jz @end{osetri pripad cx=1}
       @s1ok:
       {fill eax}
       push ax;push ax;db 66h;pop ax
       {dodela zbytek}
       shr cx,1;db 66h;rep stosw;adc cx,cx;rep stosw
       ret

      @licha:
       {zarovna na sudou = ulozi pul wordu na lichou adresu}
       jcxz @end{osetri pripad cx=0}
       stosb
       xchg al,ah
       dec cx
       jz @last{osetri pripad cx=1}
       {fill eax}
       push ax;push ax;db 66h;pop ax
       {zarovna DI na dablsudou}
       test di,2;jz @s2ok;stosw;dec cx;jz @last;@s2ok:
       {dodela zbytek}
       shr cx,1;db 66h;rep stosw;adc cx,cx;rep stosw
       {ulozi posledni pulword na sudou adresu}
       @last:
       stosb

      @end:
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP STOSW.
 CX libovolne.
 DI nesmi pretect 64KB -> toto omezeni vede ke zvyseni rychlosti.
 Meni hornich 16 bitu EAX.
 ---------------------------------------------------------------------------}
PROCEDURE REP_STOSW_no;assembler;
 asm
       cmp cx,16;jc @simple

       test di,1;jnz @licha

      @suda:
       {zarovna DI na dablsudou}
       test di,2;jz @s1ok;stosw;dec cx;@s1ok:
       {fill eax}
       push ax;push ax;db 66h;pop ax
       {dodela zbytek}
       shr cx,1;db 66h;rep stosw;adc cx,cx
      @simple:
       rep stosw
       ret

      @licha:
       {zarovna na sudou = ulozi pul wordu na lichou adresu}
       stosb
       xchg al,ah
       dec cx
       {fill eax}
       push ax;push ax;db 66h;pop ax
       {zarovna DI na dablsudou}
       test di,2;jz @s2ok;stosw;dec cx;@s2ok:
       {dodela zbytek}
       shr cx,1;db 66h;rep stosw;adc cx,cx;rep stosw
       {ulozi posledni pulword na sudou adresu}
       stosb

      @end:
 end;


{---------------------------------------------------------------------------
 Optimalizovanej REP MOVSB.
 CX libovolne.
 Zarovnava podle SI na doublewordy -> vhodnejsi pro delsi trate.
 SI smi pretect 64KB, DI nesmi.
 ---------------------------------------------------------------------------}
PROCEDURE REP_MOVSB_si;assembler;
 asm
       cmp cx,16;jc @4
       test si,3
       jz @6
       @5:
       movsb
       test si,3
       loopnz @5
       @6:
       push cx
       shr cx,2
       db 66h;rep movsw
       pop cx
       and cx,3
       @4:
       rep movsb
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP MOVSB.
 CX libovolne.
 Zarovnava podle DI na doublewordy -> vhodnejsi pro delsi trate.
 DI smi pretect 64KB, SI nesmi.
 ---------------------------------------------------------------------------}
PROCEDURE REP_MOVSB_di;assembler;
 asm
       cmp cx,16;jc @4
       test di,3
       jz @6
       @5:
       movsb
       test di,3
       loopnz @5
       @6:
       push cx
       shr cx,2
       db 66h;rep movsw
       pop cx
       and cx,3
       @4:
       rep movsb
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP MOVSB.
 CX musi byt vetsi nez 0.
 Zarovnava podle SI na wordy -> vhodnejsi pro kratsi trate.
 SI smi pretect 64KB, DI nesmi.
 ---------------------------------------------------------------------------}
PROCEDURE REP_MOVSB_si_nz_w;assembler;
 asm
      test si,1
      jz @5
      movsb
      dec cx
      @5:
      shr cx,1
      rep movsw
      adc cx,cx
      rep movsb
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP MOVSB.
 CX musi byt vetsi nez 0.
 Zarovnava podle DI na wordy -> vhodnejsi pro kratsi trate.
 DI smi pretect 64KB, SI nesmi.
 ---------------------------------------------------------------------------}
PROCEDURE REP_MOVSB_di_nz_w;assembler;
 asm
      test di,1
      jz @5
      movsb
      dec cx
      @5:
      shr cx,1
      rep movsw
      adc cx,cx
      rep movsb
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP MOVSB pri nastavenem DF (si,di se pri presunu snizuji).
 CX libovolne.
 {* optimalizovat
 ---------------------------------------------------------------------------}
PROCEDURE REP_MOVSB_back;assembler;
 asm
       shr cx,1;jnc @nomovsb;movsb;@nomovsb:jz @end;dec si;dec di
       shr cx,1;jnc @nomovsw;movsw;jz @end;@nomovsw:sub si,2;sub di,2
       db 66h;rep movsw
       @end:
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP (MOVSB;ADD SI,3).
 Zarovnava podle DI na wordy.
 SI i DI smi pretect 64KB.
 Pouziti: kopirovani z packed bitmapy do unchained videopameti.
 Meni AX,CX.
 ---------------------------------------------------------------------------}
PROCEDURE REP_MOVSB_ADD_SI_3;assembler;
 asm
       cmp cx,20;jc @3
       test di,1
       jz @1
       movsb
       add si,3
       dec cx
       @1:
       push cx
       shr cx,4
       @2:
       mov al,[si   ];mov ah,[si+ 4];stosw{16x}
       mov al,[si+ 8];mov ah,[si+12];stosw
       mov al,[si+16];mov ah,[si+20];stosw
       mov al,[si+24];mov ah,[si+28];stosw
       mov al,[si+32];mov ah,[si+36];stosw
       mov al,[si+40];mov ah,[si+44];stosw
       mov al,[si+48];mov ah,[si+52];stosw
       mov al,[si+56];mov ah,[si+60];stosw
       add si,64
       loop @2
       pop cx
       and cx,15
       @3:
       shl cx,2
       neg cx
       add cx,offset @rep_done
       jmp cx
       movsb;add si,3;movsb;add si,3{20x}
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       @rep_done:
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP (MOVSB;ADD DI,3).
 Zarovnava podle SI na wordy.
 SI i DI smi pretect 64KB.
 Pouziti: kopirovani z unchained videopameti do packed bitmapy.
 Meni AX,CX.
 ---------------------------------------------------------------------------}
PROCEDURE REP_MOVSB_ADD_DI_3;assembler;
 asm
       cmp cx,20;jc @3
       test si,1
       jz @1
       movsb
       add di,3
       dec cx
       @1:
       push cx
       shr cx,4
       @2:
       lodsw;mov [es:di   ],al;mov [es:di+ 4],ah{16x}
       lodsw;mov [es:di+ 8],al;mov [es:di+12],ah
       lodsw;mov [es:di+16],al;mov [es:di+20],ah
       lodsw;mov [es:di+24],al;mov [es:di+28],ah
       lodsw;mov [es:di+32],al;mov [es:di+36],ah
       lodsw;mov [es:di+40],al;mov [es:di+44],ah
       lodsw;mov [es:di+48],al;mov [es:di+52],ah
       lodsw;mov [es:di+56],al;mov [es:di+60],ah
       add di,64
       loop @2
       pop cx
       and cx,15
       @3:
       shl cx,2
       neg cx
       add cx,offset @rep_done
       jmp cx
       movsb;add di,3;movsb;add di,3{20x}
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       @rep_done:
 end;

{---------------------------------------------------------------------------
 Optimalizovanej REP (if [si]>0 then MOVSB else INC DI).
 Zarovnava na wordy, volitelne podle SI nebo DI
  - pred volanim udelej TEST SI,1 nebo TEST DI,1.
 Pouziti: pokladani transparentni packed bitmapy.
 Predpokladam, ze transparentnich pixelu je vetsina.
 Meni AX.
 ---------------------------------------------------------------------------}
PROCEDURE REP_TransparentMOVSB_nz;assembler;
 asm
      jz @5
      lodsb
      or al,al
      jz @3
      stosb
      dec di
      @3:
      inc di
      dec cx
      @5:
      shr cx,1
      jz @last
      PUSHF
   @1:
      lodsw
      or ax,ax
      jnz @2
 @nic:inc di
      inc di
      loop @1
      jmp @outro
      @2:
      or al,al
      jz @AH
      or ah,ah
      jz @AL
  @AX:stosw
      loop @1
      jmp @outro
  @AL:stosb
      inc di
      loop @1
      jmp @outro
  @AH:inc di
      stosb
      loop @1
  @outro:
      POPF
  @last:
      jnc @9
      lodsb
      or al,al
      jz @4
      stosb
      dec di
      @4:
      inc di
      @9:
 end;

{---------------------------------------------------------------------------
 CX bajtu z DS:SI namapuje do DX bajtu v ES:DI.
 CX ani DX nesmi byt 0.
 Pouziti: zoomovani textur.
 Meni AX,BX,CX,DX,SI,DI.
 Pozn: Zatim jsem nepocital, jestli nedochazi u okraju k chybam, takze
  za 100% funkcnost nerucim.
 ---------------------------------------------------------------------------}
PROCEDURE MapBytesCX2DX_nz;assembler;
 asm
      cmp cx,dx
      ja @smrskni   {cx>dx => smrskni}
      jz @nech      {cx=dx => nech}
      mov ax,cx
      add ax,ax
      cmp ax,dx
      jb @roztahni  {2*cx<dx => roztahni}

   @smrskni:{pouzitelne pro vse, vhodne pro dx<2*cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      dec dx
      {*bx=? ..jsem linej pocitat co by sem sedlo}
      @3:
      movsb
      add bx,ax
      adc si,dx
      loop @3
      retf

   @nech:
      jmp REP_MOVSB_di

   @roztahni:{pouzitelne pro dx>cx, vhodne pro dx>2*cx}
      PUSH BP
      mov bp,cx
      mov bx,cx
      shr bx,1
      @1:
      sub bx,dx
      lodsb
      @2:
      stosb
      add bx,bp
      jnc @2
      loop @1
      POP BP
 end;

PROCEDURE TransparentMapBytesCX2DX_nz;assembler;
 asm
      cmp cx,dx
      ja @smrskni
      jb @roztahni

   @nech:
      jmp REP_TransparentMOVSB_nz

   @smrskni:{pouzitelne pro vse, vhodne pro dx<cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      dec dx
      {*bx=? ..jsem linej pocitat co by sem sedlo}
      jmp @5
      @3:
      add bx,ax
      adc si,dx
      @5:
      lodsb
      or al,al
      jz @4
      stosb
      loop @3
      retf
      @4:
      inc di
      loop @3
      retf

   @roztahni:{pouzitelne a vhodne pro dx>cx}
      PUSH BP
      mov bp,cx
      mov bx,cx
      shr bx,1
     @1:
      sub bx,dx
      lodsb
      or al,al
      jz @0
     @2:
      stosb
      add bx,bp
      jnc @2
      loop @1
      POP BP
      retf
     @0:
      inc di
      add bx,bp
      jnc @0
      loop @1
      POP BP
 end;



{---------------------------------------------------------------------------
 Rychlejsi nahrada Move.
 Pokud se zdroj a cil prekryvaji, musi jit o posun zpet (na nizsi adresu).
 ---------------------------------------------------------------------------}
PROCEDURE MoveBack(src,dest:pointer;bytes:word);assembler;
 asm
     mov cx,bytes;jcxz @end{nic kdyz se ma presunout 0 bajtu dlouhej kus}
     PUSH DS
     lds si,src
     les di,dest
     cmp si,di;jnz @doit{src<>dest (pravdepodobne)}
     mov ax,ds;mov bx,es;cmp ax,bx;jz @endds{nic, kdyz src=dest}
     @doit:
     call REP_MOVSB_di
     @endds:
     POP DS
     @end:
 end;

{---------------------------------------------------------------------------
 Rychlejsi nahrada Move.
 Pokud se zdroj a cil prekryvaji, musi jit o posun dopredu (na vyssi adresu).
 ---------------------------------------------------------------------------}
PROCEDURE MoveForw(src,dest:pointer;bytes:word);assembler;
 asm
     mov cx,bytes;jcxz @end{nic kdyz se ma presunout 0 bajtu dlouhej kus}
     PUSH DS
     lds si,src
     les di,dest
     cmp si,di;jnz @doit{src<>dest (pravdepodobne)}
     mov ax,ds;mov bx,es;cmp ax,bx;jz @endds{nic, kdyz src=dest}
     @doit:
     std
     call REP_MOVSB_back
     cld
     @endds:
     POP DS
     @end:
 end;


{---------------------------------------------------------------------
 Vyplni blok zadanym bajtem. Pri preteceni segmentu se vrati na zacatek
 tehoz segmentu, tedy nelze vyplnit vice nez 64K.
 ---------------------------------------------------------------------}
PROCEDURE FillByte(blok:pointer;bytes:longint;value:byte);assembler;
 asm
      les di,blok
      mov al,value
      mov cx,word ptr bytes

      {osetreni delky nad 65535}
      mov bx,word ptr bytes+2
      cmp bx,0
      jz @doit
      test bx,8000h
      jnz @done{zaporny pocet}
      stosb
      mov cx,65535
      @doit:

      call REP_STOSB
      @done:
 end;

{---------------------------------------------------------------------
 Vyplni blok zadanym wordem. Pri preteceni segmentu se vrati na zacatek
 tehoz segmentu, tedy nelze vyplnit vice nez 64K.
 ---------------------------------------------------------------------}
PROCEDURE FillWord(blok:pointer;words:longint;value:word);assembler;
 asm
      les di,blok
      mov ax,value
      mov cx,word ptr words

      {osetreni bloku nad 65535 bajtu}
      cmp cx,32768
      jnb @full
      mov bx,word ptr words+2
      cmp bx,0
      jz @doit
      test bx,8000h
      jnz @done{zaporny pocet}
      @full:
      mov cx,32768
      @doit:

      call REP_STOSW_o
      @done:
 end;



{---------------------------------------------------------------------
 Maji dva bloky delky max 65535 bajtu shodny obsah ?
 ---------------------------------------------------------------------}
FUNCTION  CmpBlock(blok1,blok2:pointer;bytes:word):boolean;assembler;
 asm
      push ds
      lds si,blok1
      les di,blok2
      mov cx,bytes
      repe cmpsb
      mov al,1
      jz @same
      mov al,0
      @same:
      pop ds
 end;

{---------------------------------------------------------------------
 Je blok delky max 65535 bajtu vyplnen zadanym bajtem ?
 ---------------------------------------------------------------------}
FUNCTION  CmpByte(blok:pointer;val:byte;bytes:word):boolean;assembler;
 asm
      push ds
      les di,blok
      mov al,val
      mov cx,bytes
      repe scasb
      mov al,1
      jz @same
      mov al,0
      @same:
      pop ds
 end;

{---------------------------------------------------------------------
 Je blok delky max 32768 wordu vyplnen zadanym wordem ?
 ---------------------------------------------------------------------}
FUNCTION  CmpWord(blok:pointer;val:word;words:word):boolean;assembler;
 asm
      push ds
      les di,blok
      mov ax,val
      mov cx,words
      repe scasw
      mov al,1
      jz @same
      mov al,0
      @same:
      pop ds
 end;


PROCEDURE KillObj(var p:PObject);
begin
 if p<>nil then begin
   Dispose(p,Done);
   p:=nil;
   end;
end;


Var   oldmem :longint;

{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const
 inited:boolean=false;

function Init:word;
 begin
  Init:=erOk;
  if not inited then begin
   oldmem       :=system.memavail;
   {$ifndef dpmi}
   if UserBufsSize<>0 then begin
     MaxHeapSize:=PtrRec(HeapEnd).Seg-PtrRec(HeapOrg).Seg;
     if MaxHeapSize>64*UserBufsSize then dec(MaxHeapSize,64*UserBufsSize);
     dec(oldmem,1024*UserBufsSize);
     end;
   {$endif}
   debugmem     :=false;
   InitMemory;
   InitDosMem;
   if not GetMem(freeptr,65536) then begin Init:=erLowMem;exit;end;
   inited       :=true;
   end;
 end;

procedure Done;
 begin
  if inited then begin
   if freeptr<>nil then FreeMem(freeptr,65536);
   DoneDosMem;
   DoneMemory;
   if debug then begin
     writeln('memstart=',oldmem);
     writeln('memend  =',system.memavail);
     writeln('rozdil  =',oldmem-system.memavail);
     end;
   inited       :=false;
   end;
 end;

{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.