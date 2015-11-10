{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.32ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Fonty;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Objects, Cache,Fajly,Vga;
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                            Uvod k fontum
---------------------------------------------------------------------------

Unita obsahuje podporu pro bitmapove fonty ukladane ve formatu FN,
cachovany seznam fontu a zaklady psani temito fonty do bitmap.
Pozn: primo na obrazovku psat nelze.


---------------------------------------------------------------------------
                     Vypocty polohy pri psani textu
---------------------------------------------------------------------------

Jako pocatecni souradnice jsou pozadovany X=levy kraj prvniho pismene,
Y=uroven linky, na ktere pismena sedi. Po vykresleni jednoho pismene
se ukazatel X posune o sirku pismene (nemusi byt presne rovna sirce bitmapy
pismene). Mezi dvema pismeny se navic posune o addspace (mezi vzdelanci
se tomu tusim rika rozpal), u malych fontu obvykle 1 pixel. Vsechny tyto
udaje jsou soucasti fontu. Proporcionalitu lze vypnout, pak se misto
sirky pismene a addspace zapocitava jen jedna konstanta.

Lze vyuzit (lze i ignorovat) podporu pro psani zarovnanych textu.
Staci rict vystupni rutine kolik je v textu mezer a kolik pixelu
zbyva za textem k okraji, vystup bude natazeny az ke kraji.

}




{---------------------------------------------------------------------------
 Jednotlive fonty.
 ---------------------------------------------------------------------------}

TYPE
      PCharInfo = ^TCharInfo;
      TCharInfo =  record
                     relx,rely   :shortint;{relativni souradnice vzhledem ke kurzoru}
                     sirb,vysb   :byte;{sirka a vyska bitmapy}
                     shift       :byte;{posun kurzoru doprava}
                     ofsb        :word;{offset bitmapy od zacatku souboru}
                   end;

      PFontTable = ^TFontTable;
      TFontTable = array[#0..#255] of TCharInfo;

      PFont = ^TFont;{pointer na font, nil = prazdny font}
      TFont = object(TObject)
                     all         :PLine;     {pointer na naloadovany cely soubor}
                     allsize     :word;      {velikost souboru}
                     fontname    :pchar;     {nazev fontu}
                     firstchar   :char;      {prvni definovany znak}
                     lastchar    :char;      {posledni definovany znak}
                     sizeOver    :byte;      {+kolik pixelu nad carou by melo byt misto}
                     sizeUnder   :byte;      {+kolik pixelu pod carou by melo byt misto}
                     addspace    :byte;      {doporucena mezera mezi pismeny}
                     maxpred     :shortint;  {-o kolik nejvic pixelu couha PRED vizualni levy kraj pismene (viz "J")}
                     maxza       :shortint;  {+o kolik nejvic pixelu dosahuje ZA -"-}
                     maxnad      :shortint;  {-o kolik nejvic pixelu vystupuje NAD caru, na ktere pismena "sedi"}
                     maxpod      :shortint;  {+o kolik nejvic pixelu leze POD caru}
                     future      :byte;      {future enhancements :-)}
                     tablo       :PFontTable;{pointer na tabulku informaci o definovanych znacich}
                     function    LoadFromMem(p:pointer;siz:word):TError;
                     function    LoadFromDisk(hledamfilename:string):TError;
                     destructor  Done;virtual;
                   end;

const fnmagic:pchar='Îm’onÁ ';
      fnmagiclen   =7;

      fnDefault    ='modern.fn';{nejaky font, ktery urcite bude po ruce}

      erBadFont    = 84;


{---------------------------------------------------------------------------
 Cache.
 ---------------------------------------------------------------------------}

const     prior_font=10;{priorita jakou dostanou fonty v cache}

function  caFontGet(hledamfilename:PathStr):PFont;



{---------------------------------------------------------------------------
 Prime psani textu do bitmapy.
 ---------------------------------------------------------------------------}

FUNCTION  OutText({co }delka:word;src:Pchar;var mezer,sirmez:word;
                  {kam}map:PBitmap;x,y:word;
                  {jak}font:PFont;proporc:byte;barva:longint):word;



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ FONTY ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

{---------------------------------------------------------------------------
 Naloaduje do objektu font z adresy p.
 Na p je ocekavan kompletni soubor *.FN.
 Vraci uspesnost.
 Po uspechu muzes na blok pameti s *.FN zapomenout, nekdo uz se postara,
  odalokuje... Po neuspechu ti zustane, musis odalokovat sam.
 ---------------------------------------------------------------------------}
Function TFont.LoadFromMem(p:pointer;siz:word):TError;
var   b:^char;
      c:char;
label neuspech;
begin
 loadfrommem :=erBadFont;
 {je format ok?}
 if not CmpBlock(fnmagic,p,fnmagiclen) then exit;
 {prijme blok pameti za svuj}
 all         :=p;
 allsize     :=siz;
 {nastavi pointer na name}
 b:=p;
 inc(b,fnmagiclen);
 fontname    :=pchar(b);  while b^<>#0 do inc(b);inc(b);
 {nastavi firstchar,lastchar atd..}
 firstchar   :=b^;        inc(b);
 lastchar    :=b^;        inc(b);
 sizeOver    :=ord(b^);   inc(b);
 sizeUnder   :=ord(b^);   inc(b);
 addspace    :=ord(b^);   inc(b);
 future      :=ord(b^);   inc(b);
 case future of 0:;{standardni format}
                else goto neuspech;{neznamy format}
                end;
 {nastavi pointer na tablo}
 dec(pcharinfo(b),ord(firstchar));
 tablo       :=pfonttable(b);
 {opravi offsety v tablu}
 for c:=firstchar to lastchar do inc(tablo^[c].ofsb,ofs(all^));
 {zjisti extremni polohy bitmap (vzhledem ke kurzoru)}
 maxpred     :=127;
 maxza       :=-128;
 maxnad      :=127;
 maxpod      :=-128;
 for c:=firstchar to lastchar do
  with tablo^[c] do begin
    if relX<maxpred       then maxpred :=relX;
    if relY<maxnad        then maxnad  :=relY;
    if relX+sirb-1>maxza  then maxza   :=relX+sirb-1;
    if relY+vysb-1>maxpod then maxpod  :=relY+vysb-1;
    end;
 {hotovo}
 loadfrommem :=erOk;
 exit;

 {vynuluje promenne pri neuspechu}
 neuspech:
 all:=nil;
 allsize:=0;
end;

{---------------------------------------------------------------------------
 Naloaduje do objektu font ze zadaneho souboru.
 Vraci uspesnost.
 ---------------------------------------------------------------------------}
Function TFont.LoadFromDisk(hledamfilename:string):TError;
var   p:pointer;
      datasize,freesize:longint;
      result:TError;
begin
 p:=nil;
 datasize:=0;
 freesize:=0;
 result:=LoadFile(hledamfilename,p,datasize,freesize);
 if result=erOk then begin
   result:=LoadFromMem(p,datasize);
   if result<>erOk then FreeMem(p,datasize+freesize);
   end;
 LoadFromDisk:=result;
end;

{---------------------------------------------------------------------------
 Uvolni pamet po fontu.
 ---------------------------------------------------------------------------}
Destructor TFont.Done;
begin
 if all<>nil then FreeMem(pointer(all),allsize);
 inherited Done;
end;





{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ CACHOVANY SEZNAM FONTU ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

Type
 PFontIdentif = ^TFontIdentif;
 TFontIdentif = object(TCacheIdentif)
   filename:PathStr;
   constructor Init(name:PathStr);
   function Compare(id:PCacheIdentif):boolean;virtual;
   function Load:PObject;virtual;
 end;

Constructor TFontIdentif.Init(name:PathStr);
begin
 inherited Init;
 filename:=name;
end;

Function TFontIdentif.Compare(id:PCacheIdentif):boolean;
begin
 Compare:=filename=PFontIdentif(id)^.filename;
end;

Function TFontIdentif.Load:PObject;
var   f:PFont;
begin
 New(f,Init);
 if f<>nil then
  if f^.LoadFromDisk(filename)<>erOk then KillObj(f);
 Load:=f;
end;

{---------------------------------------------------------------------------
 Zadany font nahraje a vrati na nej pointer.
 Pozor: Ziskany font neuvolnuj pres TFont.Free, ale pres caLeave.
 ---------------------------------------------------------------------------}
Function caFontGet(hledamfilename:PathStr):PFont;
begin
 caFontGet:=PFont(caGet(New(PFontIdentif,Init(hledamfilename)),prior_font));
end;




{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ PSANI TEXTU DO BITMAP ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
{$ifdef dement}
const freemap=32768;
PROCEDURE totalnialefaktuplnetotalnibagr(p:pointer;sirka,vyska:word);assembler;
const obtahbase=8;
      fillbase=8;
      b1=65536-4000;
      b2=65536-2000;
var   j,cil:byte;
      obtahu:word;
asm  PUSH DS

     mov es,freeseg;mov di,freemap{ES=freeseg}
     lds si,p                     {DS=p}

     {---expand form mono (p^) to 256color (freeptr+8000^)---}
     mov al,0;mov cx,sirka;inc cx;rep stosb{fill -1th line}
     mov bx,obtahbase
     mov dh,byte ptr vyska
     @11:
     mov dl,byte ptr sirka
     @22:
     lodsb
     mov ah,al
     sub dl,8
     jbe @part
     call ExpandAH_BX
     jmp @22
     @part:
     mov cl,dl;add cl,9;mov ch,0
     call ExpandAH_BX+3
     mov al,0{fill -1th=nth colmn}
     stosb
     dec dh
     jnz @11
     mov al,0;mov cx,sirka;inc cx;rep stosb{fill nth line}

     {---obrysova cara---}
     push es;pop ds{DS=ES=freeseg}
     mov bx,sirka;inc bx{BX=sirka mapy}
     mov di,freemap;add di,bx
     mov si,b1
     mov al,bl;mul byte ptr vyska;mov cx,ax
     mov ax,obtahbase
    @loop:
     repne scasb
     jcxz @end
     cmp [di],ah;jz @okraj
     cmp [di-2],ah;jz @okraj
     cmp [di+bx-1],ah;jz @okraj
     push di;sub di,bx;cmp [di-1],ah;pop di;jnz @loop
    @okraj:
     dec di
     mov byte ptr [di],1
     mov [si],di;inc si;inc si
     inc di
     jmp @loop
    @end:

     sub si,b1
     shr si,1
     mov obtahu,si

     {---dalsich 7 obtahu dovnitr---}
     mov cil,2
    @obtah2:
     mov cx,obtahu;jcxz @99;
     mov si,b1;mov di,b2;mov al,fillbase;mov ah,cil;mov dx,0
  @1:mov bx,[si];inc si;inc si
  @5:dec bx;  cmp [bx],al;jnz @6;mov [bx],ah;mov [di],bx;inc di;inc di;inc dx
  @6:add bx,2;cmp [bx],al;jnz @7;mov [bx],ah;mov [di],bx;inc di;inc di;inc dx
  @7:sub bx,sirka;sub bx,2;
              cmp [bx],al;jnz @8;mov [bx],ah;mov [di],bx;inc di;inc di;inc dx
  @8:add bx,sirka;add bx,sirka;add bx,2;
              cmp [bx],al;jnz @9;mov [bx],ah;mov [di],bx;inc di;inc di;inc dx
  @9:loop @1;mov obtahu,dx;mov di,b1;mov si,b2;mov cx,dx
     rep movsw
     @99:
     inc cil
     cmp cil,8
     jne @obtah2

     POP DS
end;
{$endif}

{---------------------------------------------------------------------------
 Pise zadany text do zadane bitmapy zadanym fontem.
 Roztahne vsechny mezery dohromady o sirmez pixelu.
 Mezer a sirmez snizi o spotrebovane mnozstvi.
 Vraci souradnici X za prave vypsanym textem (=zadane X + sirka textu).
 ---------------------------------------------------------------------------}
FUNCTION  OutText({co }delka:word;src:Pchar;var mezer,sirmez:word;
                  {kam}map:PBitmap;x,y:word;
                  {jak}font:PFont;proporc:byte;barva:longint):word;
assembler;

var   UseModel      :byte;
      sirka_pismene :byte;
      shift         :integer;
      local_addspace:word;
      local_mezer   :word;
      local_sirmez  :word;
      pom1          :byte;
      oldds         :word;
      oldX          :word;
asm
     {
      DS:SI-src text
      DS:SI-font
      ES:DI-jeden radek bitmapy
      FS:BX-tabulka pointeru na radky bitmapy
     }

     mov oldds,ds

     {checks}
     cmp delka,0;jz @farend
     {$ifdef beta}
     db 66h;cmp word ptr src,0;jz @bad1
     db 66h;cmp word ptr map,0;jz @bad1
     jmp @oke
     @bad1:
      push cs
      push offset @msg1
      call chyby.erBetaMsg
      @msg1:
      db 29,'outtext se ®patnòmi parametry'
     @bad2:
      push cs
      push offset @msg2
      call chyby.erBetaMsg
      @msg2:
      db 38,'pokus ps†t neproporcion†lnà v textm¢du'
     @oke:
     {$endif}

     {prevede nektere parametry do lokalnich promennych}
     les di,mezer;mov ax,[es:di];mov local_mezer,ax
     les di,sirmez;mov ax,[es:di];mov local_sirmez,ax

     {pouzije model podle bitmapy, za unchained dosadi packed}
     les di,map
     mov al,[es:di+tbitmap.MapModel]
     cmp al,model_unchained;jnz @notunch;mov al,model_packed;@notunch:
     mov UseModel,al

     {map:=map.tab+4*y}
     db 66h;mov bx,word ptr [es:di+tbitmap.tab]
     mov cx,y
     shl cx,2
     add bx,cx
     db 66h;mov word ptr map,bx{pozor: do MAP si ulozi MAP.TAB, MAP uz nebude ptrebovat}

     mov al,UseModel
     cmp al,model_text;jz @TEXT
     cmp al,model_packed;jz @GRAPHIX
     {*dalsi modely}
     jmp @END


 {==========}
    @TEXT:
 {==========}

     {$ifdef beta}
     {kontrola zda do model_text pise neproporcionalne}
     cmp proporc,1
     jnz @bad2
     {$endif}
     db 0fh,0b4h,5eh,offset map{LFS BX,tab}
     lds si,src
     db 64h,0c4h,3fh{LES DI,[FS:BX]}
     add di,X
     add di,X
     mov cx,delka
     add X,cx
     mov ah,byte ptr barva
     cmp local_mezer,0
     jnz @zarovnavej
      @nexttextchar1:
      lodsb
      stosw
      loop @nexttextchar1
      jmp @END
     @zarovnavej:
      @nexttextchar2:
      lodsb
      cmp al,' '
      jnz @nemezera
       push ax
       call near ptr @DistribuujMezeryDoX
       add di,ax
       add di,ax
       pop ax
      @nemezera:
      stosw
      loop @nexttextchar2
      jmp @END


     @DistribuujMezeryDoX:
      mov ax,local_sirmez
      cmp ax,0
      jz @ret
      xor dx,dx
      div local_mezer
      add X,ax
      sub local_sirmez,ax
      dec local_mezer
      @ret:
      retn


 {==========}
   @GRAPHIX:
 {==========}

     {
     CL=firstchar
     CH=lastchar
     }
     db 66h;cmp word ptr font,0;jz @end
     lds si,font
     mov cl,[si+TFont.firstchar]
     mov ch,[si+TFont.lastchar]

     {proporcionalni >then> nacte l_addspace >else> l_addspace=0}
     cmp proporc,0;jz @real1
      xor ax,ax
      jmp @real1done
     @real1:
      mov al,[si+TFont.addspace]
      cbw
     @real1done:
      mov local_addspace,ax

     db 66h;mov ax,word ptr [si+TFont.tablo]
     db 66h;mov word ptr font,ax{POZOR: do font si ulozi font^.tablo}

     jmp @first_char

 @NEXT_CHAR:
     mov ax,local_addspace
     add X,ax

 @FIRST_CHAR:
     lds si,src
     lodsb
     inc word ptr src
     cmp al,cl ;jb @CHAR_DONE{znak neni obsazen ve fontu}
     cmp al,ch ;ja @CHAR_DONE{znak neni obsazen ve fontu}
     cmp al,' ';jnz @nenimezera

    @mezera:
     {ax=sirka mezery}
     mov ah,proporc
     cmp ah,0
     jz @real3
      mov al,ah
      jmp @real3done
     @real3:
      mov ah,type TCharInfo
      mul ah
      lds si,font
      add si,ax
      mov al,byte ptr [si+TCharInfo.shift]{pricte shift pismene}
     @real3done:
      mov ah,0
     {atd}
     add X,ax
     call near ptr @DistribuujMezeryDoX
     jmp @char_done

    @nenimezera:
     db 0fh,0b4h,5eh,offset map{LFS BX,tab}

     lds si,font
     mov ah,type TCharInfo
     mul ah
     add si,ax{ds:si ukazuje na CharInfo tohoto znaku}

     {zapamatuje si vychozi X pred kreslenim znaku}
     mov ax,X
     mov oldX,ax

     {vetveni podle modelu}
     mov al,UseModel
     cmp al,model_packed;jz @PACKED
     jmp @DONE

 {----------}
   @PACKED:
 {----------}

     lodsb
     cbw
     {mov relX,ax}
     add X,ax{zapocita relX}

     lodsb
     cbw
     shl ax,2
     add bx,ax{zapocita relY}

     lodsb
     mov sirka_pismene,al{loadne sirb}

     lodsb
     mov dh,al{loadne dh=vysb}

     lodsb
     cbw
     mov shift,ax{loadne shift}

     (*
     mov al,proporc
     cbw
     jz @prop
     sub al,sirka_pismene
     sbb ah,0
     sar ax,1
     add X,ax{vycentruje neproporc znak - posune se o (shift-sirb)/2}
     @prop:
     *)

     mov si,[si]{loadne si=ofsb}

     cmp sirka_pismene,0
     jz @skipOUTCHAR{nekresli nic kdyz je znak sirokej 0}

   {$IFDEF DEMENT} {ruzne modifikace vystupu, kvuli zpetne kompatibilite P.}
     mov dl,byte ptr barva+3
     dec dl
     js @normal
     jz @bardak

   {vystup odstinovany podle vzdalenosti od okraje bitmapy}
   @bumpos:
     push ds
     db 0fh,0a0h{push fs}
     pusha
      push ds{push adresa monobitmapy}
      push si
      mov al,sirka_pismene;mov ah,0;push ax{push sirka}
      shr dx,8;push dx{push vyska}
      mov ds,oldds
      call totalnialefaktuplnetotalnibagr{vygeneruje ve freesegu 256color znak}
     popa
     db 0fh,0a1h{pop fs}

     mov ds,oldds
     mov ds,freeseg
     mov si,freemap
     mov al,sirka_pismene;mov ah,0;add si,ax;inc si

     push cx
     mov pom1,0{pom1=cislolajny}
    @8x_NEXT_LINE:
     inc pom1
     db 64h,0c4h,3fh{LES DI,[FS:BX]}
     add di,X
     mov cl,sirka_pismene
     mov ch,0
       mov al,dl{method}
       dec al;jz @method1
       dec al;jz @method8
       dec al;jz @method7
       dec al;jz @method6
       dec al;jz @method3
       dec al;jz @method2
       dec al;jz @method4{skoro totez co 6}
       @method1:
        call REP_TransparentMOVSB_nz
        jmp @linedone
       @method2:
        lodsb;or al,al;jz @vynech2
        sub al,5;add al,[es:di];cmp al,40;jc @ok2;mov al,40;@ok2:mov [es:di],al;@vynech2:inc di;loop @method2
        jmp @linedone
       @method3:
        lodsb;or al,al;jz @vynech3
        sub al,[es:di];neg al;cmp al,25;jnc @y;mov al,25;@y:mov [es:di],al;@vynech3:inc di;loop @method3
        jmp @linedone
       @method4:
        lodsb;or al,al;jz @vynech4;cmp al,5;jnc @vynech4;sub [es:di],al;@vynech4:inc di;loop @method4
        jmp @linedone
       @method6:
        lodsb;or al,al;jz @vynech6;cmp al,4;jnc @vynech6;mov [es:di],al;@vynech6:inc di;loop @method6
        jmp @linedone
       @method7:
        push bx;mov bl,pom1;and bl,7;cmp bl,4;jc @low;neg bl;add bl,8;@low:
        mov bh,0;add di,bx;call REP_TransparentMOVSB_nz;sub di,bx;pop bx
        jmp @linedone
       @method8:
        push ax;mov ah,pom1;add ah,40;shr ah,4
        @met8:
        lodsb;or al,al;jz @vynech8
        cmp al,ah;jc @nepret8;mov al,ah;@nepret8:mov [es:di],al;@vynech8:inc di;loop @met8;
        pop ax
       @linedone:

     inc si
     add bx,4
     dec dh
     jnz @8x_NEXT_LINE
     pop cx

     pop ds
     jmp @DONE

   {vystup odstinovany podle y}
   @bardak:
     mov pom1,4{pom1=cislolajny+4}
     @08:
     inc pom1;mov al,pom1;shr al,2;cmp al,8;jc @07;mov al,8;@07:
     pusha
     CALL near ptr @ExpandLine_AL
     popa
     add bx,4
     mov al,1
     CALL near ptr @ExpandLine_AL
     dec dh
     jnz @08
     jmp @DONE
   {$ENDIF}

   {normalni mono vystup}
   @normal:
     mov al,byte ptr barva{al=barva}
     @09:
     CALL near ptr @ExpandLine_AL
     add bx,4
     dec dh
     jnz @09
     jmp @DONE

 {----------
    UTILS:
 {----------}

     {sirka_pismene bitu z DS:SI expanduje barvou AL
      do souradnice X linky v FS:BX (pres ES:DI)}
     @ExpandLine_AL:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add di,X
      mov dl,sirka_pismene
      add dl,7
      shr dl,3

     {DL bajtu z DS:SI expanduje barvou AL do ES:DI}
     @ExpandDLbytes_AL:
      @next:
      mov ah,[si]
      inc si
      or ah,ah
      jz @empty
      CALL ExpandAH_AL
      jmp @10
      @empty:
      add di,8
      @10:
      dec dl
      jnz @next
      retn

 {----------}
    @DONE:
 {----------}

   @skipOUTCHAR:
     {posun o sirku pismene}
     mov al,proporc
     cmp al,0;jz @real2
      mov ah,0{only for neproporc}
      jmp @real2done
     @real2:
      mov ax,shift{only for proporc}
     @real2done:
      add ax,oldX{vychazi ze stare souradnice aby nemusel odecitat kdeco}
      mov X,ax
      {sub ax,relX;add X,ax}

   @CHAR_DONE:
     dec delka
     jnz @NEXT_CHAR

   @END:
     {nastavi vystupy}
     les di,mezer;mov ax,local_mezer;mov [es:di],ax
     les di,sirmez;mov ax,local_sirmez;mov [es:di],ax

   @FAREND:
     mov ax,X
     mov ds,oldds
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

var result:integer;

procedure UserInit;
 begin
  BugList.Register(erBadFont,'Vadnò font.');
 end;

procedure UserDone;
 begin
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.