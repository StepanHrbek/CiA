{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Fonty;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Objects,Strings, Stringy,Sys,Cache,Fajly,Vga;
Function  Init:TError;
Procedure Done;

{
---------------------------------------------------------------------------
                            Uvod k fontum
---------------------------------------------------------------------------

Unita obsahuje podporu pro bitmapove fonty ukladane ve formatu FN,
a zaklady psani temito fonty do bitmap. Primo na obrazovku psat nelze.

Format FN je bitmapovy s velmi efektivnim ukladanim bitmap.
K dipozici jsou konvertory z jinych bitmapovych i true type formatu.
Balik vice nez sto ceskych fontu najdes na dee.misto.cz/cia.

---------------------------------------------------------------------------
                     Vypocty polohy pri psani textu
---------------------------------------------------------------------------

Jako pocatecni souradnice jsou pozadovany X=levy kraj prvniho pismene,
Y=linka, na ktere pismena sedi.

   ____
  |    | Y=0
  |    |
  |    |          <- levy horni pixel(v textmodu znak) bitmapy
  |____| Y=1

 X=0  X=1

V textmodu jsou pismena vysoka 1 jednotku. Kdyz chces nakreslit pismeno
do leveho horniho znaku, zadas souradnice X=0 a Y=1 (viz nacrt).
Tedy ne Y=0, jak to omylem fungovalo drive.

Po vykresleni jednoho pismene
se ukazatel X posune o sirku pismene (nemusi byt presne rovna sirce bitmapy
pismene). Mezi dvema pismeny se navic posune o addspace (mezi vzdelanci
se tomu tusim rika rozpal), u malych fontu obvykle 1 pixel. Vsechny tyto
udaje jsou soucasti fontu. Proporcionalitu lze vypnout, pak se misto
sirky pismene a addspace zapocitava jen jedna konstanta.

Lze vyuzit (lze i ignorovat) podporu pro psani zarovnanych textu.
Staci rict vystupni rutine kolik je v textu mezer a kolik pixelu
zbyva za textem k okraji, vystup bude natazeny az ke kraji.

---------------------------------------------------------------------------
                               Format FN
---------------------------------------------------------------------------

Pouze pro ty ktere zajima jak format vypada uvnitr.

Prikaz "FN -f" vyda strucny popis existujicich formatu.

.FN neobsahuje informace o kodovani, vsechny existujici .FN obsahuji ceske
a nektere i slovenske znaky v kodovani bri Kamenickych, coz je standard,
ktery se ujal a jen nekdo to stale odmita uznat.
No dobre, tak byl standard v dobe vzniku CiA.

.FN vzdy zacina znaky 'ëmÕonç ',nasleduje
fontname :pchar  libovolne dlouhy popis fontu zakonceny nulou
firstchar:char   prvni znak obsazeny ve fontu
lastchar :char   posledni
sizeover :short  orientacne kolik mista vyhradit pro bitmapy znaku nad linkou
                 na kterou se pise...pozn: ta linka je 0 pixelu vysoka
sizeunder:short  kolik mista vyhradit pod linkou
addspace :short  kolik pixelu mezery pridavat mezi sousedni pismena
future   :byte   zatim vzdy 0

nasleduje pole udaju pro znaky firstchar..lastchar
na kazdy znak ma 7 bajtu informace

relX :short  pozice leveho horniho rohu bitmapy vzhledem ke kurzoru
relY :short  pozice -"-
sirB :byte   sirka bitmapy
vysB :byte   vyska bitmapy
shift:byte   o tolik pixelu posun kurozr doprava po nakresleni pismene
ofsB :word   offset bitmapy od zacatku souboru

nasleduje hromada bitmap, mohou se prekryvat
(priklad: bitmapa A je soucasti bitmapy A_s_carkou)
(nalezt optimalni prekryvani vsech bitmap je NP uplny problem,
 fn.exe dosahuje pri ukladani .fn alespon slusneho priblizeni)

bitmapy jsou ulozene po radkach..treba 9pixelu siroky a 14 vysoke pismeno
je ulozeno jako dva bajty prvni radky (z druheho bajtu je vyuzit pouze
nejlevejsi bit), dva druhe radky atd az dva bajty ctrnacte.

treba ze znaku tecka se uklada jen ta tecka, ne mezery kolem,
relX a relY urcuji kde ta tecka zacina a sirB a vysB jak je velka.
kurzor se neposouva o sirku bitmapy ale o shift.

vsechno dohromady smi mit maximalne 64KB, protoze offsety jsou 16bitove.

praxe ukazala ze i giganticke fonty se do 64KB diky prekryvani bitmap
bezpecne vejdou, vice omezujici je ze rozmery a pozice pismen jsou ulozene
v bytech nebo shortintech. fonty ktere se do bajtu/shortu jeste tesne
vesly uz ale byly pro prakticke pouziti stejne prilis velke.

format je tedy co se tyce velikosti souboru optimalni, i primitivni
neproporcionalni .fnt obsahujici jen bitmapy uklada usporneji,
slozitejsi formaty jako .fon mnohonasobne usporneji.
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

      PFont = ^TFont;
      TFont = object(TObject)
                     all         :PLine;     {pointer na naloadovany cely soubor}
                     allsize     :word;      {velikost souboru}
                     fontname    :pchar;     {nazev fontu}
                     firstchar   :char;      {prvni definovany znak}
                     lastchar    :char;      {posledni definovany znak}
                     sizeOver    :shortint;  {+kolik pixelu nad carou by melo byt misto}
                     sizeUnder   :shortint;  {+kolik pixelu pod carou by melo byt misto}
                     addspace    :byte;      {doporucena mezera mezi pismeny}
                     maxpred     :shortint;  {-o kolik nejvic pixelu couha PRED vizualni levy kraj pismene (viz "J")}
                     maxza       :shortint;  {+o kolik nejvic pixelu dosahuje ZA -"-}
                     maxnad      :shortint;  {-o kolik nejvic pixelu vystupuje NAD caru, na ktere pismena "sedi"}
                     maxpod      :shortint;  {+o kolik nejvic pixelu leze POD caru}
                     future      :byte;      {future enhancements :-)}
                     tablo       :PFontTable;{pointer na tabulku informaci o definovanych znacich}
                     function    LoadFromMem(p:pointer;siz:word):TError;
                     function    LoadFromDisk(hledamfilename:string):TError;
                     function    GetFnt(var p:pointer;var charsize:word):TError;
                     function    SetFnt:TError;
                     function    SaveFnt(dest:PathStr):TError;
                     function    Save(dest:PathStr):TError;
                     destructor  Done;virtual;
                   end;


const fnmagic:pchar='ëmÕonç ';
      fnmagiclen   =7;

      fnDefault    ='modern.fn';{nejaky font, ktery urcite bude po ruce}
      fnDefaultNp  ='moder_np.fn';{nejaky neproporcionalni font}


{---------------------------------------------------------------------------
 Cache.
 ---------------------------------------------------------------------------}

const     cachePriorFont=10;{priorita jakou dostanou fonty v cache}

function  cacheGetFont(afilename:PathStr):PFont;



{---------------------------------------------------------------------------
 Prime psani textu do bitmapy.
  OutText - univerzalni verze pro tisk textu ulozeneho kdekoliv v pameti
  OutStr  - zjednodusena verze pro tisk stringu
  OutPc   - zjednodusena verze pro tisk pcharu
 ---------------------------------------------------------------------------}

FUNCTION  OutText({co }delka:word;src:pchar;var mezer,sirmez:word;
                  {kam}map:PBitmap;x,y:word;
                  {jak}font:PFont;proporc:byte;barva:longint):word;

FUNCTION  OutStr ({co }src:string;
                  {kam}map:PBitmap;x,y:word;
                  {jak}font:PFont;proporc:byte;barva:longint):word;

FUNCTION  OutPc  ({co }pc:pchar;
                  {kam}map:PBitmap;x,y:word;
                  {jak}font:PFont;proporc:byte;barva:longint):word;

FUNCTION  LenText(font:PFont;delka:word;pc:pchar):longint;
FUNCTION  LenPc  (font:PFont;pc:pchar):longint;
FUNCTION  LenStr (font:PFont;st:string):longint;

{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


FUNCTION LoadDiskFont(fnt:PathStr;vyska:byte):TError;far;
var   p:pointer;
      datasize,freesize:longint;
      result:TError;
      f:TFont;
begin
 p:=nil;
 datasize:=0;
 freesize:=0;
 if PathSlice(fnt,psExt)='FN' then begin
   f.Init;
   result:=f.LoadFromDisk(fnt);
   if result=erOk then begin
     f.sizeUnder:=trunc(f.sizeUnder*vyska/(f.sizeOver+f.sizeUnder));
     f.sizeOver:=vyska-f.sizeUnder;
     result:=f.SetFnt;
     end;
   f.Done;
   end
 else
   if not fileLoad(fnt,nil,p,datasize,freesize) then result:=_erFileLoad else begin
     result:=LoadUserFont(p,vyska);
     FreeMem(p,datasize+freesize);
     end;
 LoadDiskFont:=result;
end;


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßß FONTY ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}

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
 loadfrommem :=_erBadFont;
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
 sizeOver    :=shortint(b^);inc(b);
 sizeUnder   :=shortint(b^);inc(b);
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
 if firstchar>lastchar then begin
   {ocekava ze font bez znaku je pro textmod}
   maxpred     :=0;
   maxza       :=1;
   maxnad      :=-1;
   maxpod      :=0;
   end
 else begin
   maxpred     :=127;
   maxza       :=-128;
   maxnad      :=127;
   maxpod      :=-128;
   for c:=firstchar to lastchar do
    with tablo^[c] do begin
      if relX<maxpred     then maxpred :=relX;
      if relY<maxnad      then maxnad  :=relY;
      if relX+sirb>maxza  then maxza   :=relX+sirb;
      if relY+vysb>maxpod then maxpod  :=relY+vysb;
      end;
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
 ---------------------------------------------------------------------------}
Function TFont.LoadFromDisk(hledamfilename:string):TError;
var   p:pointer;
      datasize,freesize:longint;
      result:TError;
begin
 p:=nil;
 datasize:=0;
 freesize:=0;
 if not fileLoad(hledamfilename,nil,p,datasize,freesize) then result:=_erFileLoad else begin
   result:=LoadFromMem(p,datasize);
   if result<>erOk then FreeMem(p,datasize+freesize);
   end;
 LoadFromDisk:=result;
end;

{---------------------------------------------------------------------------
 Ulozi font do souboru dest.
 ---------------------------------------------------------------------------}
Function  TFont.Save(dest:PathStr):TError;
var   c:char;
begin
 {opravi offsety v tablu}
 for c:=firstchar to lastchar do dec(tablo^[c].ofsb,ofs(all^));
 {zapise all}
 if fileSave(fileOverwrite,dest,all,allsize) then Save:=erOk else Save:=_erFileSave;
 {opravi offsety v tablu}
 for c:=firstchar to lastchar do inc(tablo^[c].ofsb,ofs(all^));
end;

{---------------------------------------------------------------------------
 Vraci blok pameti s fontem prevedenym do formatu FNT.
 ---------------------------------------------------------------------------}
Function TFont.GetFnt(var p:pointer;var charsize:word):TError;
var   c:char;
      top,bot:shortint;
begin
 charsize:=sizeOver+sizeUnder;
 if (maxza-maxpred>16) or (charsize>255) then GetFnt:=_erTooBigFont else
  if not GetMem(p,256*charsize) then GetFnt:=erLowMem else begin
    fillchar(p^,256*charsize,0);
    for c:=firstchar to lastchar do
     with tablo^[c] do
      _ResizeChar(ptr(PtrRec(all).Seg,ofsb),relX,relY,sirB,vysB,
       ptr(PtrRec(p).Seg,PtrRec(p).Ofs+charsize*ord(c)),sizeOver,sizeUnder,
       c in ['°']{base},c in ['°'..'ß']{expand},top,bot);
    GetFnt:=erOk;
    end;
end;

{---------------------------------------------------------------------------
 Nastavi font na obrazovce (v textmodu).
 ---------------------------------------------------------------------------}
Function TFont.SetFnt:TError;
var   p         :pointer;
      charsize  :word;
      er        :TError;
begin
 er:=GetFnt(p,charsize);
 if er=erOk then begin
   if charsize>16 then er:=_erTooBigFont else er:=LoadUserFont(p,charsize);
   FreeMem(p,256*charsize);
   end;
 SetFnt:=er;
end;

{---------------------------------------------------------------------------
 Ulozi font na disk jako .fnt.
 ---------------------------------------------------------------------------}
Function TFont.SaveFnt(dest:PathStr):TError;
var   p         :pointer;
      charsize  :word;
      er        :TError;
begin
 er:=GetFnt(p,charsize);
 if er=erOk then begin
   if not fileSave(fileOverwrite,dest,p,256*charsize) then er:=_erFileSave;
   FreeMem(p,256*charsize);
   end;
 SaveFnt:=er;
end;

{---------------------------------------------------------------------------
 Uvolni pamet po fontu.
 ---------------------------------------------------------------------------}
Destructor TFont.Done;
begin
 if all<>nil then FreeMem(pointer(all),allsize);
 inherited Done;
end;





{ßßßßßßßßßßßßßßßßßßßßßßßß CACHOVANY SEZNAM FONTU ßßßßßßßßßßßßßßßßßßßßßßßßßß}

Type
 PFontId = ^TFontId;
 TFontId = object(TCacheId)
   filename:PathStr;
   constructor Init(name:PathStr);
   function Load:PObject;virtual;
   destructor Done;virtual;
 end;

Constructor TFontId.Init(name:PathStr);
begin
 {bioswrite('init('+name+')');}
 inherited Init;
 filename:=name;
end;

Destructor TFontId.Done;
begin
 {bioswrite('done('+filename+')');}
 inherited Done;
end;

Function TFontId.Load:PObject;
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
Function cacheGetFont(afilename:PathStr):PFont;
begin
 cacheGetFont:=PFont(caGet(New(PFontId,Init(afilename)),cachePriorFont));
end;




{ßßßßßßßßßßßßßßßßßßßßßßßßß PSANI TEXTU DO BITMAP ßßßßßßßßßßßßßßßßßßßßßßßßßßß}
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
{$ifdef beta}
procedure e1;begin erBetaMsg('outtext src=nil');end;
procedure e2;begin erBetaMsg('outtext map=nil');end;
procedure e3;begin erBetaMsg('outtext proporc/textmode');end;
{$endif}

FUNCTION  OutText({co }delka:word;src:Pchar;var mezer,sirmez:word;
                  {kam}map:PBitmap;x,y:word;
                  {jak}font:PFont;proporc:byte;barva:longint):word;
assembler;

var   ByPP          :word;
      sirka_pismene :byte;
      {vyska_pismene :byte;}
      shift         :integer;
      local_addspace:word;
      local_mezer   :word;
      local_sirmez  :word;
      total_mezer   :word;
      total_sirmez  :word;
      total_counter :word;
      pom1          :byte;
      oldds         :word;
      oldX          :word;
      expand        :pointer;
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
     db 66h;cmp word ptr src,0;jnz @nobug1;call e1;@nobug1:
     db 66h;cmp word ptr map,0;jnz @nobug2;call e2;@nobug2:
     {$endif}

     {prevede nektere parametry do lokalnich promennych}
     les di,mezer;mov ax,[es:di];mov local_mezer,ax;mov total_mezer,ax
     shr ax,1;mov total_counter,ax
     les di,sirmez;mov ax,[es:di];mov local_sirmez,ax;mov total_sirmez,ax

     {nastavi ByPP podle bitmapy}
     les di,map
     mov bl,[es:di+TBitmap.ByPP]
     mov bh,0
     mov ByPP,bx
     {do 'expand' nastavi pointer na expandovaci funkci}
     shl bx,2;add bx,offset @expand-4
     db 66h;mov bx,[cs:bx]
     db 66h;mov word ptr expand,bx

     {map:=map.tab+4*y}
     db 66h;mov bx,word ptr [es:di+tbitmap.tab]
     mov cx,y
     shl cx,2
     add bx,cx
     db 66h;mov word ptr map,bx{pozor: do MAP si ulozi MAP.TAB, MAP uz nebude ptrebovat}

     {vetveni podle modelu - TEXT a GRAFIKA zvlast}
     cmp [es:di+TBitmap.MapModel],model_text
     jnz @GRAPHIX

 {==========}
    @TEXT:
 {==========}

     {$ifdef beta}
     {kontrola zda do model_text pise neproporcionalne}
     cmp proporc,1;jz @nobug3;call e3;@nobug3:
     {$endif}
     db 0fh,0b4h,5eh,offset map{LFS BX,tab}
     lds si,src
     sub bx,4{fix: pismeno sedi na 0pixelu vysoke lince Y,
                   ovsem kresli se do 1pixelu vysoke radky Y-1!
                   viz uvodni komentar unity}
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
       push cx
       xchg ax,cx
       call near ptr @DistribuujMezeryDoX
       {vycisti prostor mezi slovy}
       xchg ax,cx{v ah tim zachova attr a do cx da delku}
       mov al,' '
       rep stosw
       pop cx
       pop ax
      @nemezera:
      stosw
      loop @nexttextchar2
      jmp @END


     @DistribuujMezeryDoX:
      mov ax,local_sirmez
      or ax,ax
      jz @ret
       xor dx,dx
      {pekne optimalni rutina, ale mezery se hromadej u konce radky:
        div local_mezer}
      {delsi rutina, ale mezery distribuuje rovnomerne}
      {total_mezer krat prijde mezera a ja musim total_sirmez pridat.
      zvysim citac o total_sirmez a pridam tolik, kolikrat pretece total_mezer}
        mov ax,total_counter
        add ax,total_sirmez
        xor dx,dx
        div total_mezer
        mov total_counter,dx
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

     {nacita z fontu udaje o znaku}
     lodsb
     cbw
     {mov relX,ax}
     add X,ax{zapocita relX}

     lodsb
     cbw
     shl ax,2
     add bx,ax{zapocita relY}

     lodsw
     mov sirka_pismene,al{loadne sirb}
     mov dh,ah{mov vyska_pismene,ah}{loadne vysb}

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

{$IFDEF DEMENT}
  {ruzne modifikace vystupu, kvuli zpetne kompatibilite P.}
  {------------------}
    @SPECIAL:
  {------------------}
     cmp ByPP,1
     jne @normal{model_direct -> psat normalne mono}

     mov dl,byte ptr barva+3
     dec dl
     js @normal{nejvyssi bajt barvy=0 -> psat normalne mono}
     jz @bardak{nejvyssi bajt barvy=1 -> psat bardem}

{     cmp dl,8
     jz @buttonak{nejvyssi bajt barvy=9 -> psat na button}

   {vystup odstinovany podle vzdalenosti od okraje bitmapy}
   @bumpos:
     push ds
     db 0fh,0a0h{push fs}
     pusha
      push ds{push adresa monobitmapy}
      push si
      mov al,sirka_pismene;mov ah,0;push ax{push sirka}
      mov al,dh{vyska_pismene};mov ah,0;push ax{push vyska}
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
        call REP_MOVS_1_nz_t
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
        mov bh,0;add di,bx;call REP_MOVS_1_nz_t;sub di,bx;pop bx
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
     dec dh{vyska_pismene}
     jnz @8x_NEXT_LINE
     pop cx

     pop ds
     jmp @DONE

   {vystup odstinovany podle y}
   @bardak:
     mov pom1,4{pom1=cislolajny+4}
   @bardak_params:
     inc pom1;mov al,pom1;shr al,2;cmp al,8;jc @07;mov al,8;@07:
     pusha
     CALL near ptr @ExpandLine_AL
     popa
     add bx,4
     mov al,1
     CALL near ptr @ExpandLine_AL
     dec dh{vyska_pismene}
     jnz @bardak_params
     jmp @DONE

(*   {varianta bardaku vyladena pro buttony}
   @buttonak:
     mov pom1,8*18
     @08:
     dec pom1;mov al,pom1;shr al,3;cmp al,16;jb @11;mov al,16;@11:
     pusha
     CALL near ptr @ExpandLine_AL
     popa
     add bx,4
     mov al,13
     CALL near ptr @ExpandLine_AL
     dec dh{vyska_pismene}
     jnz @08
     jmp @DONE
*)
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
{$ENDIF}

  {-----------}
    @NORMAL:
  {-----------}
     push cx
     push X

     push dx
     mov ax,ByPP
     mul X
     mov X,ax
     pop dx

     db 66h;mov ax,word ptr barva{eax=barva}
     mov cl,byte ptr barva+2{ch=barva}

     @nextline:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add di,X
      mov dl,sirka_pismene
      @nextbyte:
       mov ch,[si]
       call EXPAND
       inc si
       sub dl,8
       ja @nextbyte
      add bx,4
      dec dh{vyska_pismene}
      jnz @nextline

     pop X
     pop cx
     jmp @DONE

    @EXPAND:
      dd ExpandCH_AL
      dd ExpandCH_AX
      dd ExpandCH_CLAX
      dd ExpandCH_EAX

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


FUNCTION  OutPc(pc:pchar;map:PBitmap;x,y:word;font:PFont;proporc:byte;barva:longint):word;
const mezer:word=0;
      sirmez:word=0;
begin
 OutPc:=OutText(StrLen(pc),pc,mezer,sirmez,map,x,y,font,proporc,barva);
end;

FUNCTION  OutStr(src:string;map:PBitmap;x,y:word;font:PFont;proporc:byte;barva:longint):word;
const mezer:word=0;
      sirmez:word=0;
begin
 OutStr:=OutText(length(src),Str2Pc(src),mezer,sirmez,map,x,y,font,proporc,barva);
end;

FUNCTION  LenText(font:PFont;delka:word;pc:pchar):longint;
var len:longint;
begin
 len:=font^.addspace;
 for delka:=delka downto 1 do inc(len,font^.tablo^[(pc+delka-1)^].shift+font^.addspace);
 LenText:=len;
end;

FUNCTION  LenPc(font:PFont;pc:pchar):longint;
begin
 LenPc:=LenText(font,StrLen(pc),pc);
end;

FUNCTION  LenStr(font:PFont;st:string):longint;
begin
 LenStr:=LenText(font,length(st),@st[1]);
end;

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='fonty';
var result:TError;

procedure UserInit;
 begin
  _LoadDiskFont:=LoadDiskFont;
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