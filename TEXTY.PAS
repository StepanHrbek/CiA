{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.50ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Texty;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects,Strings, Sys;
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                            Uvod k Textum
---------------------------------------------------------------------------

Objekt TText1 je vhodny ke cteni viceradkovych textu (do 64K).
Vetsina jeho metod souvisi s nacitanim textu po radcich a vyhledavanim
zacatku/koncu radku.
Symbol pro novy radek je v atributu newln. Ten se pri initu naplni
konstantou default_newln, coz je #13#10 - standardni CR/LF radkovani.
Samozrejme si to muzes zmenit.

TText2 pridava psani textu, vkladani, mazani, konverze.


{---------------------------------------------------------------------------
                                TEXT 1
 ---------------------------------------------------------------------------}

const default_newln=#13#10;{odradkovac, posledni znak odradkovace se v nem
                            ani jinde na radce nesmi vyskytovat vickrat}

const EOT          =#0;   {znak oznamujici konec textu}

type  PText1 = ^TText1;
      TText1 = object(TObject)
                     newln        :string[4];{oddelovac radek, si ho prodluz jestli chces}
                     start        :word;{offset zacatku textu}
                     pos          :pchar;{pozice v textu}
                     konec        :word;{offset nuly na konci textu}
                     constructor  Init(p:pchar);
                     procedure    Reset;
                     function     StartPtr:pchar;
                     function     EndPtr:pchar;
                     function     Eof:boolean;
                     function     Oof:boolean;
                     function     FileSize:longint;
                     function     GetChar:char;
                     function     ReadChar:char;
                     function     GetCif:byte;
                     function     ReadCif:byte;
                     procedure    ScanSize(var sir,vys:word);

                     {--NAZVOSLOVI--

                      Pripona:
                        From - vyjdi od zadane odresy
                        zadna- vyjdi od Pos

                      Predpona:
                        ch   - skonci az na n-tem vyskytu znaku   (cti do nej, skoc za nej)
                        nl   - skonci az na n-tem vyskytu newline (cti do newline, skoc za newline)

                      Koren:
                        Adr  - vrat adresu
                        Goto - jdi na adresu=nastav Pos na adresu
                        Get  - vrat string
                        Read - precti string=vrat string a jdi za nej
                        }
                     function     chAdrFrom (c:char;adr:word;n:integer):word;    {adresu nuly}
                     function     chAdr     (c:char;         n:integer):word;    {adresu nuly}
                     procedure    chGoto    (c:char;         n:integer);         {jde na nulu}
                     function     nlAdrFrom (       adr:word;n:integer):word;    {vraci length(newln)-1 za nulou}
                     function     nlAdr     (                n:integer):word;    {vraci ^^}
                     procedure    nlGoto    (                n:integer);         {jde na ^^}
                     function     chGetFrom (c:char;adr:word          ):string;
                     function     chGet     (c:char                   ):string;
                     function     chRead    (c:char                   ):string;
                     function     nlGetFrom (       adr:word          ):string;
                     function     nlGet                                :string;
                     function     nlRead                               :string;
                   end;
{
co kdyz nektera z prohledavacich funkci narazi na konec souboru?

chAdrFrom  vraci adresu nuly
chAdr      vraci adresu nuly
chGoto     jde na nulu
nlAdrFrom  vraci length(newln) za nulou
nlAdr      vraci  -"-
nlGoto     jde na -"-
}

{---------------------------------------------------------------------------
                                TEXT 2
 ---------------------------------------------------------------------------}

type  PText2 = ^TText2;
      TText2 = object(TText1)
                     static       :boolean;{nema pri done uvolnit pamet s textem?}
                     maxkonec     :word;{nejvyssi pripustny konec}
                     blkStart     :word;{offset prvniho znaku bloku}
                     blkEnd       :word;{offset posledniho znaku bloku}
                     insert       :boolean;{insert mod prikazu write,writeln}
                     constructor  Init(p:pchar;maxlen:word);
                     constructor  InitEmpty(p:pchar;maxlen:word);
                     destructor   Done;virtual;
                     procedure    Rewrite;
                     procedure    RewriteWith(st:string);
                     procedure    DelSpaces(adr,kolik:word);
                     procedure    InsSpaces(adr,kolik:word);
                     function     InsStr(adr,space:word;st:string):integer;
                     procedure    Write(st:string);
                     procedure    WriteLn(st:string);
                     procedure    Konverze(konfig:PText2;oddelovac:char);
                   end;



{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}



{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßß TEXT 1 ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}

{---------------------------------------------------------------------------
 Zapamatuje si kde lezi zacatek a kde konec textu, hodi ukazatel na start.
 Text uz musi byt na miste.
 ---------------------------------------------------------------------------}
Constructor TText1.Init(p:pchar);
begin
 inherited Init;
 newln:=default_newln;
 start:=word(p);
 konec:=word(p)+StrLen(p);{hleda konec textu - nejblizsi nulu}
 pos:=p;
end;

{---------------------------------------------------------------------------
 Hodi ukazatel na start.
 ---------------------------------------------------------------------------}
Procedure TText1.Reset;
begin
 word(pos):=start;
end;

{---------------------------------------------------------------------------
 Vraci zacatek textu.
 ---------------------------------------------------------------------------}
Function TText1.StartPtr:pchar;
begin
 StartPtr:=ptr(PtrRec(pos).Seg,start);
end;

{---------------------------------------------------------------------------
 Vraci konec textu (#0).
 ---------------------------------------------------------------------------}
Function TText1.EndPtr:pchar;
begin
 EndPtr:=ptr(PtrRec(pos).Seg,konec);
end;

{---------------------------------------------------------------------------
 Vraci delku textu. Nula na konci se nepocita.
 ---------------------------------------------------------------------------}
Function TText1.FileSize:longint;
begin
 FileSize:=konec-start;
end;

{---------------------------------------------------------------------------
 Vraci jestli je pos na konci textu nebo dokonce mimo text.
 ---------------------------------------------------------------------------}
Function TText1.Eof:boolean;
begin
 Eof:=(word(pos)>=konec) or (word(pos)<start)
end;

{---------------------------------------------------------------------------
 Jako jestli je pos mimo text (na konci textu byt muze).
 ---------------------------------------------------------------------------}
Function TText1.Oof:boolean;
begin
 Oof:=(word(pos)>konec) or (word(pos)<start)
end;

{---------------------------------------------------------------------------
 Precte znak, cifru.. ukazatel posune, neposune..
 ---------------------------------------------------------------------------}
Function TText1.GetChar:char;
begin
 GetChar:=pos^;
end;

Function TText1.ReadChar:char;
begin
 ReadChar:=pos^;
 inc(pos);
end;

Function TText1.GetCif:byte;
var   i:integer;
begin
 i:=-48+ord(pos^);
 {$ifdef beta}
 if (i<0) or (i>9) then erBetaMsg('ttext1.getcif');
 {$endif}
 GetCif:=i;
end;

Function TText1.ReadCif:byte;
begin
 ReadCif:=GetCif;
 inc(pos);
end;

{---------------------------------------------------------------------------
 Zjisti rozmery textu:
  sir = nejdelsi radek
  vys = pocet radku
 Pozn: prazdny text se chova klasicky, tak jak to zname z textovych editoru,
  tj. jako 1 radek nulove delky.
 ---------------------------------------------------------------------------}
Procedure TText1.ScanSize(var sir,vys:word);
var   oldoldpos:pchar;
      oldpos:pchar;
begin
 oldoldpos:=pos;
 Reset;
 sir:=0;
 vys:=0;
 while not Oof do begin
   oldpos:=pos;
   nlGoto(+1);
   sir:=maxW(sir,pos-oldpos-length(newln));
   inc(vys);
   end;
 pos:=oldoldpos;
end;

{---------------------------------------------------------------------------
 Vraci adresu n-teho vyskytu znaku c.
 Pri kladnem n hleda dopredu, pri nule nebo zapornem od minuleho znaku dozadu.
 ---------------------------------------------------------------------------}
Function TText1.chAdrFrom(c:char;adr:word;n:integer):word;assembler;
 asm
     les di,self
     mov cx,[es:di+konec];sub cx,adr;inc cx{tolik znaku do konce textu}
     mov dx,adr;sub dx,[es:di+start];inc dx{tolik znaku do zacatku textu?}
     mov es,[es:di+offset pos+2]
     mov di,adr
     mov al,c
     mov bx,n
     dec bx
     js @n_minus_or_zero
     @n_plus:
      repne scasb
      dec bx
      jns @n_plus
      dec di
      jmp @done
     @n_minus_or_zero:
      std
      mov cx,dx
      @m:
      repne scasb
      inc bx
      jnz @m
      inc di
      cld
     @done:
     mov ax,di
 end;

{---------------------------------------------------------------------------
 Vraci adresu zacatku n-teho nasledujiciho (resp.predchazejiciho) vyskytu znaku.
 ---------------------------------------------------------------------------}
Function TText1.chAdr(c:char;n:integer):word;assembler;
 asm
     les di,self
     push word ptr c
     push word ptr [es:di+pos]
     push n
     db 66h;push word ptr self
     call chAdrFrom
 end;

{---------------------------------------------------------------------------
 Skoci na zacatek n-teho nasledujiciho (resp.predchazejiciho) vyskytu znaku.
 ---------------------------------------------------------------------------}
Procedure TText1.chGoto(c:char;n:integer);assembler;
 asm
     les di,self
     push word ptr c
     push word ptr [es:di+pos]
     push n
     db 66h;push word ptr self
     call chAdrFrom
     les di,self
     inc ax
     mov word ptr [es:di+pos],ax
 end;

{---------------------------------------------------------------------------
 Vraci adresu zacatku n-teho nasledujiciho (resp.predchazejiciho) radku.
 ---------------------------------------------------------------------------}
Function TText1.nlAdrFrom(adr:word;n:integer):word;assembler;
 asm
     {push newlnsize}
     les bx,self
     add bx,newln
     add bl,[es:bx]
     adc bh,0
     push word ptr [es:bx]

     push adr
     push n
     db 66h;push word ptr self
     call chAdrFrom
     inc ax

     {pokud se zarazil o konec souboru, pricte length(newln)-1}
     or cx,cx
     jnz @no_eof
     les di,self
     dec ax
     add al,byte ptr [es:di+newln]
     add ah,0
     @no_eof:
 end;

{---------------------------------------------------------------------------
 Vraci adresu zacatku n-teho nasledujiciho (resp.predchazejiciho) radku.
 ---------------------------------------------------------------------------}
Function TText1.nlAdr(n:integer):word;assembler;
 asm
     les di,self
     push word ptr [es:di+pos]
     push n
     db 66h;push word ptr self
     call nlAdrFrom
 end;

{---------------------------------------------------------------------------
 Skoci na zacatek n-teho nasledujiciho (resp.predchazejiciho) radku.
 ---------------------------------------------------------------------------}
Procedure TText1.nlGoto(n:integer);assembler;
 asm
     les di,self
     push word ptr [es:di+pos]
     push n
     db 66h;push word ptr self
     call nlAdrFrom
     les di,self
     mov word ptr [es:di+pos],ax
 end;


{---------------------------------------------------------------------------
 Nacte string do prvniho vyskytu znaku.
 Z prilis dlouhych radku vraci jen prvnich 255 znaku.
 Navic krome stringu vraci v AX adresu dalsiho radku.
 ---------------------------------------------------------------------------}
Function TText1.chGetFrom(c:char;adr:word):string;assembler;
 asm
     PUSH DS
     lds si,self
     mov cx,[si+konec];sub cx,adr;inc cx
     mov es,[si+offset pos+2]
     mov di,adr
     mov al,c
     repne scasb
     PUSH DI
     mov cx,di{cx=nova poloha}
     sub cx,adr{cx=nova poloha-stara}
     dec cx{ubere znak c na konci stringu}
     or ch,ch{dlouhy stringy zkrati na 255 znaku, zaporny na 0}
     jz @do
     js @zapor
     @big:
     mov cx,255;jmp @do
     @zapor:
     mov cx,0
     @do:
     mov si,adr
     push es;pop ds
     les di,@result
     mov al,cl;stosb{string length}
     call REP_MOVSB_si
     POP AX
     POP DS
 end;

{---------------------------------------------------------------------------
 Nacte string do prvniho vyskytu znaku.
 Z prilis dlouhych radku vraci jen prvnich 255 znaku.
 ---------------------------------------------------------------------------}
Function TText1.chGet(c:char):string;assembler;
 asm
     les di,@result
     push es
     push di
     les di,self
     push word ptr c
     push word ptr [es:di+pos]
     db 66h;push word ptr self
     call chGetFrom
 end;

{---------------------------------------------------------------------------
 Nacte string do prvniho vyskytu znaku a posune ukazatel za znak.
 Z prilis dlouhych radku vraci jen prvnich 255 znaku.
 ---------------------------------------------------------------------------}
Function TText1.chRead(c:char):string;assembler;
 asm
     les di,@result
     push es
     push di
     les di,self
     push word ptr c
     push word ptr [es:di+pos]
     db 66h;push word ptr self
     call chGetFrom
     les di,self
     mov word ptr [es:di+pos],ax
 end;


{---------------------------------------------------------------------------
 Nacte radek.
 Z prilis dlouhych radku vraci jen prvnich 255 znaku.
 Navic krome stringu vraci v AX adresu dalsiho radku.
 ---------------------------------------------------------------------------}
Function TText1.nlGetFrom(adr:word):string;assembler;
 asm
     PUSH DS
     push adr
     push 1
     db 66h;push word ptr self
     call nlAdrFrom
     PUSH AX

     lds si,self
     mov cx,ax{cx=zacetek dalsiho radku}
     sub cl,byte ptr [si+newln]
     sbb ch,0{cx=zacatek newln}
     sub cx,adr{cx=delka radku}
     or ch,ch{dlouhy stringy zkrati na 255 znaku, zaporny na 0}
     jz @do
     js @zapor
     @big:
     mov cx,255;jmp @do
     @zapor:
     xor cx,cx
     @do:
     mov ds,word ptr [si+pos+2]
     mov si,adr
     les di,@result
     mov al,cl;stosb{string length}
     call REP_MOVSB_si
     POP AX
     POP DS
 end;

{---------------------------------------------------------------------------
 Nacte radek.
 Z prilis dlouhych radku vraci jen prvnich 255 znaku.
 ---------------------------------------------------------------------------}
Function TText1.nlGet:string;assembler;
 asm
     les di,@result
     push es
     push di
     les di,self
     push word ptr [es:di+pos]
     db 66h;push word ptr self
     call nlGetFrom
 end;

{---------------------------------------------------------------------------
 Nacte radek a posune ukazatel na dalsi.
 Z prilis dlouhych radku vraci jen prvnich 255 znaku.
 ---------------------------------------------------------------------------}
Function TText1.nlRead:string;assembler;
 asm
     les di,@result
     push es
     push di
     les di,self
     push word ptr [es:di+pos]
     db 66h;push word ptr self
     call nlGetFrom
     les di,self
     mov word ptr [es:di+pos],ax
 end;




{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßß TEXT 2 ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}

{---------------------------------------------------------------------------
 Zapamatuje si kde lezi zacatek textu, hodi ukazatel na start.
 Volat az kdyz je text na miste.
 ---------------------------------------------------------------------------}
Constructor TText2.Init(p:pchar;maxlen:word);
begin
 inherited Init(p);
 maxkonec:=PtrRec(p).Ofs+(maxlen-1);
 insert:=true;
end;

{---------------------------------------------------------------------------
 Zapamatuje si kde bude lezet zacatek textu, hodi ukazatel na start.
 Volat pokud text jeste neni na miste.
 ---------------------------------------------------------------------------}
Constructor TText2.InitEmpty(p:pchar;maxlen:word);
begin
 p^:=#0;{nastavi hned na zacatek nulu ocnacujici konec textu}
 {ted bych chtel zavolat prvni konstruktor, ale kvuli chybe pascalu nemuzu}
 {musim ho opsat}
 {jinak by se potomkum TText2 volajicim InitEmpty nastavila VMT TText2}
 inherited Init(p);
 maxkonec:=PtrRec(p).Ofs+(maxlen-1);
 insert:=true;
end;

{---------------------------------------------------------------------------
 Volitelne odalokuje text. Implicitne ano.
 ---------------------------------------------------------------------------}
Destructor TText2.Done;
var   p:pointer;
begin
 p:=StartPtr;
 if not static then FreeMem(p,maxkonec-start+1);
 inherited Done;
end;

{---------------------------------------------------------------------------
 Vynuluje delku textu.
 ---------------------------------------------------------------------------}
Procedure TText2.Rewrite;
begin
 word(pos):=start;
 pos^:=#0;
 konec:=start;
end;

{---------------------------------------------------------------------------
 Smaze kus textu (delete).
 Osetri zmenu konce,bloku,pos pokud je adr <.
 ---------------------------------------------------------------------------}
Procedure TText2.DelSpaces(adr,kolik:word);assembler;
 asm
     PUSH DS
     lds di,self
     mov cx,[di+konec];sub cx,adr;inc cx
     mov ax,word ptr [di+pos+2]
     mov ds,ax
     mov es,ax
     mov si,adr;add si,kolik
     mov di,adr
     call REP_MOVSB_si
     mov ax,adr
     mov cx,kolik
     lds di,self
     sub [di+konec],cx

     mov bx,offset blkStart;call near ptr @adjust
     mov bx,offset blkEnd  ;call near ptr @adjust
     mov bx,offset pos     ;call near ptr @adjust
     POP DS
     jmp @end

     @adjust:
     cmp ax,[di+bx]
     jnb @ret{adr>=pos ... nic}
     sub [di+bx],cx
     cmp ax,[di+bx]
     jb @ret{adr-kolik<pos ... dec(pos,kolik)}
     mov [di+bx],ax{else ... pos=adr}
     @ret:
     retn

     @end:
 end;

{---------------------------------------------------------------------------
 Vlozi misto pro kus textu (insert).
 ---------------------------------------------------------------------------}
Procedure TText2.InsSpaces(adr,kolik:word);assembler;
 asm
     PUSH DS
     lds di,self
     mov cx,[di+konec];sub cx,adr;inc cx
     mov ax,word ptr [di+pos+2]
     mov si,[di+konec]
     mov bx,[di+maxkonec]
     mov di,si;add di,kolik
     {$ifdef beta}
      cmp di,bx;jna @enough
      push cs
      push offset @msg1
      call chyby.erBetaMsg
      @msg1:
      db 18,'ttext2.insspaces 1'
      @enough:
     {$endif}
     mov ds,ax
     mov es,ax
     std
     call REP_MOVSB_back
     cld
     mov ax,adr
     mov bx,kolik
     lds di,self
     add [di+konec],bx

     cmp word ptr [di+blkStart],ax;jc @no1;add word ptr [di+blkStart],bx;@no1:
     cmp word ptr [di+blkEnd  ],ax;jc @no2;add word ptr [di+blkEnd  ],bx;@no2:
     cmp word ptr [di+pos     ],ax;jc @no3;add word ptr [di+pos     ],bx;@no3:
     POP DS
 end;

{---------------------------------------------------------------------------
 Nahradi kus textu jinym textem.
 Space je delka mazaneho textu, tj.
     space=0          -> cisty insert noveho stringu
     space=length(st) -> cisty overwrite
     space jine       -> vyuzije stavajici space, ale kousek si jeste
                         priinsertne nebo oddeletne
 Vraci kolik znaku musel insertnout (zaporne cislo = deletnout).
 ---------------------------------------------------------------------------}
Function TText2.InsStr(adr,space:word;st:string):integer;
var   oldpos:word;
begin
 DelSpaces(adr,space);
 InsSpaces(adr,length(st));
 move(st[1],ptr(PtrRec(pos).Seg,adr)^,length(st));
 InsStr:=integer(length(st))-space;
end;

{---------------------------------------------------------------------------
 Obdoba write do fajlu, ale s podporou insert modu.
 ---------------------------------------------------------------------------}
Procedure TText2.Write(st:string);
var   i:word;
begin
 if insert then i:=0 else i:=length(st);
 InsStr(word(pos),i,st);
end;

{---------------------------------------------------------------------------
 Obdoba writeln do fajlu, ale s podporou insert modu.
 ---------------------------------------------------------------------------}
Procedure TText2.WriteLn(st:string);
var   i:word;
begin
 if insert then i:=0 else i:=length(st)+length(newln);
 InsStr(word(pos),i,st+newln);
end;

{---------------------------------------------------------------------------
 Vynuluje delku textu, vlozi kus na zacatek.
 ---------------------------------------------------------------------------}
Procedure TText2.RewriteWith(st:string);
begin
 Rewrite;
 InsStr(konec,0,st);
end;


{---------------------------------------------------------------------------
 Konvertuje text.
 Na kazde radce konfigu ocekava dva stringy oddelene oddelovacem,
 pricemz v textu prevadi levy string na pravy.
 ---------------------------------------------------------------------------}
Procedure TText2.Konverze(konfig:PText2;oddelovac:char);
var   st,st2:string;
label 1;
begin
 Reset;
 while not Eof do begin
   konfig^.Reset;
   while not konfig^.Eof do begin
     st:=konfig^.chRead(oddelovac);
     if CmpBlock(@st[1],Pos,length(st)) then begin
       st2:=konfig^.nlGet;
       InsStr(word(Pos),length(st),st2);
       goto 1;
       end;
     konfig^.nlGoto(+1);
     end;
   inc(Pos);
   1:
   end;
end;


{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

function Init:word;
 begin
  Init:=erOk;
 end;

procedure Done;
 begin
 end;

END.