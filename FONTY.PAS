{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.10ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Fonty;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Memory,Objects, Fajly,Vga;
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                            Uvod k fontum
---------------------------------------------------------------------------

Unita obsahuje podporu pro bitmapove fonty ukladane ve formatu FN,
cachovany seznam fontu a zaklady psani temito fonty do bitmap.


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
                     function    LoadFromMem(p:pointer;siz:word):boolean;
                     function    LoadFromDisk(hledamfilename:string):boolean;
                     destructor  Done;virtual;
                   end;

const fnmagic:pchar='Îm’onÁ ';
      fnmagiclen   =7;

      fnDefault    ='modern.fn';{nejaky font, ktery urcite bude po ruce}


{---------------------------------------------------------------------------
 Cache.
 ---------------------------------------------------------------------------}

const     prior_font=10;{priorita jakou dostanou fonty v cache}

function  CFontGet(hledamfilename:PathStr):PFont;
procedure CFontLeave(var fn:PFont);



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
Function TFont.LoadFromMem(p:pointer;siz:word):boolean;
var   b:^char;
      c:char;
label neuspech;
begin
 loadfrommem :=false;
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
 loadfrommem :=true;
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
Function TFont.LoadFromDisk(hledamfilename:string):boolean;
var   p       :pointer;
      filesize:longint;
begin
 p:=nil;
 filesize:=65520;
 LoadFromDisk:=false;
 if LoadFile(hledamfilename,p,true,filesize,0)=full then
  if LoadFromMem(p,filesize) then LoadFromDisk:=true
                             else FreeMem(p,filesize);
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
{$ifndef memory_cache}
 PCacheIdentif = ^TCacheIdentif;
 TCacheIdentif = TObject;
{$endif}

 PFontIdentif = ^TFontIdentif;
 TFontIdentif = object(TCacheIdentif)
   filename:PathStr;
   function Compare(id:PCacheIdentif):boolean;virtual;
   function Load:PObject;virtual;
 end;

Function TFontIdentif.Compare(id:PCacheIdentif):boolean;
begin
 Compare:=filename=PFontIdentif(id)^.filename;
end;

Function TFontIdentif.Load:PObject;
var   f:PFont;
begin
 Load:=nil;
 New(f,Init);
 if f=nil then exit;
 if not f^.LoadFromDisk(filename) then begin
   f^.Free;
   exit;
   end;
 Load:=f;
end;

{---------------------------------------------------------------------------
 Zadany font nahraje a vrati na nej pointer.
 Pozor: Ziskany font neuvolnuj pres TFont.Free, ale pres CFontLeave.
 ---------------------------------------------------------------------------}
Function CFontGet(hledamfilename:PathStr):PFont;
var   id:PFontIdentif;
      f:PFont;
begin
 CFontGet:=nil;
 if hledamfilename='' then exit;
 new(id,Init);
 if id=nil then exit;
 id^.filename:=hledamfilename;
{$ifdef memory_cache}
 if CacheInited then
   begin
   f:=PFont(CacheMaster.Get(id,prior_font));
   if f=nil then id^.Free;
   end
  else
{$endif}
   begin
   f:=PFont(id^.Load);
   id^.Free;
   end;
 CFontGet:=f;
end;

{---------------------------------------------------------------------------
 Uvolni zadany font, vynuluje ti pointer na nej (parametr fn).
 ---------------------------------------------------------------------------}
Procedure CFontLeave(var fn:PFont);
begin
 if fn=nil then exit;
{$ifdef memory_cache}
 if CacheInited
  then CacheMaster.Leave(fn)
  else {$endif}fn^.Free;
 fn:=nil;
end;




{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ PSANI TEXTU DO BITMAP ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

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
      relX,shift    :integer;
      local_addspace:word;
      local_mezer   :word;
      local_sirmez  :word;
asm
     {
      DS:SI-src text
      DS:SI-font
      ES:DI-jeden radek bitmapy
      FS:BX-tabulka pointeru na radky bitmapy
     }

     PUSH DS

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
      db 13,'outtextfull 1'
     @bad2:
      push cs
      push offset @msg2
      call chyby.erBetaMsg
      @msg2:
      db 13,'outtextfull 2'
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


     {vetveni podle modelu}
     mov al,UseModel
     cmp al,model_packed;jz @PACKED
     jmp @DONE

 {----------}
   @PACKED:
 {----------}

     lodsb
     cbw
     mov relX,ax
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

     mov si,[si]{loadne si=ofsb}

     cmp sirka_pismene,0
     jz @skipOUTCHAR{nekresli nic kdyz je znak sirokej 0}

 @8_NEXT_LINE:
     db 64h,0c4h,3fh{LES DI,[FS:BX]}
     add di,X

     mov dl,sirka_pismene
     add dl,7
     shr dl,3
 @8_NEXT_BYTE:
     lodsb
     or al,al
     jnz @bajt
     add di,8
     jmp @8_byte_done

     @bajt:
     mov ah,al{ah=nactenej bajt}
     mov al,byte ptr barva{al=barva}

     shl ah,1;jc @setbit7;inc di;jmp @end7;@setbit7:stosb;@end7:
     shl ah,1;jc @setbit6;inc di;jmp @end6;@setbit6:stosb;@end6:
     shl ah,1;jc @setbit5;inc di;jmp @end5;@setbit5:stosb;@end5:
     shl ah,1;jc @setbit4;inc di;jmp @end4;@setbit4:stosb;@end4:
     shl ah,1;jc @setbit3;inc di;jmp @end3;@setbit3:stosb;@end3:
     shl ah,1;jc @setbit2;inc di;jmp @end2;@setbit2:stosb;@end2:
     shl ah,1;jc @setbit1;inc di;jmp @end1;@setbit1:stosb;@end1:
     shl ah,1;jc @setbit0;inc di;jmp @end0;@setbit0:stosb;@end0:

   @8_BYTE_DONE:
     dec dl
     jnz @8_NEXT_BYTE

   @8_LINE_DONE:
     add bx,4
     dec dh
     jnz @8_NEXT_LINE
     jmp @DONE


 {----------}
    @DONE:
 {----------}

   @skipOUTCHAR:
     {posun o sirku pismene}
     mov al,proporc
     cmp al,0;jz @real2
      mov ah,0
      jmp @real2done
     @real2:
      mov ax,shift
     @real2done:
      sub ax,relX
      add X,ax

   @CHAR_DONE:
     dec delka
     jnz @NEXT_CHAR

   @END:
     {nastavi vystupy}
     les di,mezer;mov ax,local_mezer;mov [es:di],ax
     les di,sirmez;mov ax,local_sirmez;mov [es:di],ax

   @FAREND:
     mov ax,X
     POP DS
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const
 inited:boolean=false;

function Init:word;
 begin
  Init:=erOk;
  if not inited then begin
   inited       :=true;
   end;
 end;

procedure Done;
 begin
  if inited then begin
   inited       :=false;
   end;
 end;

{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.





(*

 {*tohle casem zpracuju a zlikviduju, je potreba rozsirit *.FN
   na barevny fonty, tyhle bigfonty do toho pak zapracuju



{€€€€€€€€€€€€€€€€ BIG FONT €€€€€€€€€€€€€€€€}

{$I bigfont2.inc}

CONST fontu             =2;
      lastchar          ='©';

VAR   minifonty_sir               :array[0..2,' '..lastchar] of byte;
      minifonty                   :array[0..1,' '..lastchar,0..15] of byte;
      minifonty_num               :word;
      minifonty_adr               :word;
      minifonty_sir_adr           :word;

VAR   charseg:array[1..fontu,' '..lastchar] of word;
      cetnost:array[1..fontu,' '..lastchar] of byte;
CONST charseglen=sizeof(charseg)+sizeof(cetnost);

CONST vys=128+1;
      sir=64;
      obtahbase=8;
      fillbase=8;
TYPE  tchara=array[0..vys-1,0..sir shr 3-1] of byte;
      mapa=array[1..vys,1..sir] of byte;
VAR   chara:tchara;
      freebyte:byte{musi byt pred sha};sha:mapa;
      obtahu:word;
      b1:array[0..999] of word;
      b2:array[0..999] of word;


PROCEDURE Obrys(zn:char;size:byte);
var i,j,k,l,z:integer;
function Q(x,y:shortint):byte;
begin
 if (y<0) or (y>=vys shr 3) or (x<0) or (x>=sir shr 3) then q:=0 else
  q:=mem[seg(tlustejDB):ofs(tlustejDB)+16*(ord(zn)-32)+y] shr (8-x) mod 2;
end;
Begin
 {clr chara}
 asm mov ax,ds;mov es,ax;lea di,chara;mov cx,sir*vys/8/2/2;db 66h;xor ax,ax;db 66h;rep stosw;end;

 for j:=0 to vys shr 3-1 do for i:=0 to sir shr 3-1 do begin
   z:=bigfont_tab[2*(2*(2*(2*(2*(2*(2*(2*
      q(i-1,j+1)+q(i,j+1))+q(i+1,j+1))+q(i-1,j))+q(i,j))+q(i+1,j))+q(i-1,j-1))+q(i,j-1))+q(i+1,j-1)]
      -255+n;
   case size of 2:for k:=0 to 7 do chara[8*j+k,i]:=bigfont_b[z,k];
                1:for k:=0 to 3 do begin
                   l:=bigfont_b[z,2*k] or bigfont_b[z,2*k+1];
                   l:=l or l shl 1;
                   l:=l and 128+l shl 1 and 64+l shl 2 and 32+l shl 3 and 16;
                   chara[4*j+k,i div 2]:=chara[4*j+k,i div 2] or (l shr (4*(i mod 2)));
                   end;
                end;
   end;
End;

PROCEDURE TransTo256Bitmap;assembler;
 asm mov ax,ds;mov es,ax;
     lea di,sha;mov cx,sir*vys/2/2;db 66h;xor ax,ax;db 66h;rep stosw;{clear bitmap}
     lea si,chara;mov di,offset sha-1{+656}
     mov dh,vys{128 radek pod sebou}
     @1:
     mov dl,sir/8{8 bajtu vedle sebe}
     @2:
     lodsb;mov ah,al;mov al,obtahbase;mov cx,8;
     @3:shl ah,1;jc @bit;inc di;loop @3;jmp @9;
                     @bit:stosb;loop @3;@9:
     dec dl;jnz @2
     add di,sir-64
     dec dh;jnz @1
     end;

PROCEDURE OBTAH1;assembler;
 asm lea si,sha+sir+1
     lea di,b1
     mov ax,ds;mov es,ax
     mov bx,0
     mov dl,0
     mov cx,sir*(vys-2)-2
    @loop:inc si;cmp byte ptr [si],obtahbase;loopnz @loop;jcxz @end;
     cmp [si-1],dl;jz @okraj
     cmp [si+1],dl;jz @okraj
     cmp [si-sir+1],dl;jz @okraj
     cmp [si+sir-1],dl;jz @okraj
     jmp @loop
    @okraj:
     mov byte ptr [si],1
     mov ax,si;stosw
     inc bx
     jmp @loop
    @end:
     mov obtahu,bx
     end;

PROCEDURE OBTAH2(cil:byte);assembler;
 asm mov cx,obtahu;or cx,cx;jz @99;
     mov si,offset b1;mov di,offset b2;mov al,fillbase;mov ah,cil;mov dx,0
  @1:mov bx,[si];inc si;inc si
  @5:dec bx;      cmp [bx],al;jnz @6;mov [bx],ah;mov [di],bx;inc di;inc di;inc dx;
  @6:add bx,2;    cmp [bx],al;jnz @7;mov [bx],ah;mov [di],bx;inc di;inc di;inc dx;
  @7:sub bx,sir+1;cmp [bx],al;jnz @8;mov [bx],ah;mov [di],bx;inc di;inc di;inc dx;
  @8:add bx,2*sir;cmp [bx],al;jnz @9;mov [bx],ah;mov [di],bx;inc di;inc di;inc dx;
  @9:loop @1;mov obtahu,dx;mov di,offset b1;mov si,offset b2;mov cx,dx
     cld;mov ax,ds;mov es,ax;rep segds movsw
     @99:
     end;

FUNCTION FreeMoreConv:Boolean;
var cet,j,j2,ha,segx:word;
    d,d2:char;
label 1;
begin
 {$ifdef cachefont}
 ha:=10000;
 for j:=1 to fontu do for d:=' ' to lastchar do begin
   cet:=cetnost[j,d]-1;
   if cet<ha then begin
     ha:=cet;
     j2:=j;d2:=d;
     if ha=0 then goto 1;
     end;
   end;
 if ha=10000 then begin FreeMoreConv:=false;exit;end;
 1:
 segx:=charseg[j2,d2];charseg[j2,d2]:=0;cetnost[j2,d2]:=0;
 asm mov ah,49h;mov es,segx;int 21h;end;
 FreeMoreConv:=true;
 {$else}
 FreeMoreConv:=false;
 {$endif}
end;

PROCEDURE CONVbigfontDone;
var i:word;
    c:char;
begin
 {$ifdef cachefont}
 for i:=1 to fontu do for c:=' ' to lastchar do deallocConv(charseg[i,c]);
 {$endif}
end;

FUNCTION GetPackedBigCharSeg(font:byte;c:char):word;
var   j,myseg:word;
label 2,bad;
begin
 myseg:=charseg[font,c];
 if myseg=0 then begin
         2:
         asm mov ah,48h;mov bx,65535;int 21h;mov j,bx;end;
         if j<300 then if FreeMoreConv then goto 2 else goto bad;
         obrys(c,font);
         transto256bitmap;
         obtah1;
         for j:=2 to 7 do obtah2(j);
         asm {zapakovani sha}
             mov ax,ds;mov es,ax {es=ds}
             mov si,offset sha;mov di,si
             mov cx,vys
          @newline:
             push cx

             mov cx,sir          {meri pocet nul=bx}
          @continueline:
             mov bx,0
             @2:
             lodsb
             inc bx
             or al,al;loopz @2
             jcxz @endofline

             mov al,bl;dec al;stosb     {tolik nul}

             mov bx,0            {meri pocet dat=bx}
             @3:
             lodsb
             inc bx
             or al,al;jnz @3
             sub cx,bx

             {otestovat vsechny bigchary, jestli se tady nehaltnou}
             jnc @ok
             {push 103;call erhalt {errorhalt(103)}
             @ok:

             mov al,bl;stosb     {tolik dat}
             sub si,bx           {ulozi data}
             dec si
             push cx;mov cx,bx;rep movsb;pop cx
             inc cx
             jmp @continueline

          @endofline:
             mov al,0;stosb

             pop cx
             loop @newline

             sub di,offset sha   {alloc conv mem}
            push di{size}
             mov bx,di{size}
             shr bx,4;inc bx;mov ah,48h;int 21h;jc bad;mov myseg,ax;

             mov es,ax
             mov si,offset sha;mov di,0  {copy}
            pop cx{size}
             rep movsb
             mov al,255;stosb
            end;
         charseg[font,c]:=myseg;
         end;

 inc(cetnost[font,c]);
 GetPackedBigCharSeg:=myseg;
 exit;
bad:
 GetPackedBigCharSeg:=0;
end;


