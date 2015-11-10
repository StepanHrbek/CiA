{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.10ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Texty;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects;
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                           Uvod k Textum
---------------------------------------------------------------------------

Objekt TText1 je vhodny ke cteni viceradkovych textu (do 64K).
Vetsina jeho metod souvisi s nacitanim textu po radcich a vyhledavanim
zacatku/koncu radku. Nejsou provadeny zadne kontroly konce textu.
Radkovani je nastaveno na #13+#10, ale jde i zmenit, viz newln.

TText2 pridava psani textu a s nim souvisejici hlidani konce textu,
vkladani, mazani.

{*hlidani konce je zatim jen zcasti
}

{---------------------------------------------------------------------------
                                TEXT 1
 ---------------------------------------------------------------------------}

const default_newln=#13#10;{odradkovac, posledni znak odradkovace se v nem
                            ani jinde na radce nesmi vyskytovat vickrat}

type  PText1 = ^TText1;
      TText1 = object(TObject)
                     newln        :string[4];{oddelovac radek, si ho prodluz jestli chces}
                     start        :word;{offset zacatku textu}
                     pos          :pchar;{pozice v textu}
                     constructor  Init(p:pchar);
                     procedure    Reset;
                     function     StartPtr:pchar;
                     function     GetChar:char;
                     function     ReadChar:char;
                     function     GetCif:byte;
                     function     ReadCif:byte;

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
                     function     chAdrFrom (c:char;adr:word;n:integer):word;
                     function     chAdr     (c:char;         n:integer):word;
                     procedure    chGoto    (c:char;         n:integer);
                     function     nlAdrFrom (       adr:word;n:integer):word;
                     function     nlAdr     (                n:integer):word;
                     procedure    nlGoto    (                n:integer);
                     function     chGetFrom (c:char;adr:word          ):string;
                     function     chGet     (c:char                   ):string;
                     function     chRead    (c:char                   ):string;
                     function     nlGetFrom (       adr:word          ):string;
                     function     nlGet                                :string;
                     function     nlRead                               :string;
                   end;


{---------------------------------------------------------------------------
                                TEXT 2
 ---------------------------------------------------------------------------}

const EOT          =#0;   {znak oznamujici konec textu}

type  PText2 = ^TText2;
      TText2 = object(TText1)
                     static       :boolean;{nema pri done uvolnit pamet s textem?}
                     konec        :word;{offset nuly na konci textu}
                     maxkonec     :word;{nejvyssi pripustny konec}
                     blkStart     :word;{offset prvniho znaku bloku}
                     blkEnd       :word;{offset posledniho znaku bloku}
                     insert       :boolean;{insert mod prikazu write,writeln}
                     constructor  Init(p:pchar;maxend:word);
                     destructor   Done;virtual;
                     procedure    Rewrite;
                     procedure    RewriteWith(st:string);
                     function     Eof:boolean;
                     function     EndPtr:pchar;
                     function     FileSize:longint;
                     procedure    EndNewline;
                     procedure    DelSpaces(adr,kolik:word);
                     procedure    InsSpaces(adr,kolik:word);
                     function     InsStr(adr,space:word;st:string):integer;
                     procedure    Write(st:string);
                     procedure    WriteLn(st:string);
                     procedure    Konverze(konfig:PText2;oddelovac:char);
                   end;



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ TEXT 1 ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

{---------------------------------------------------------------------------
 Zapamatuje si kde lezi zacatek textu, hodi ukazatel na start.
 Text jeste nemusi byt na miste.
 ---------------------------------------------------------------------------}
Constructor TText1.Init(p:pchar);
begin
 inherited Init;
 newln:=default_newln;
 start:=word(p);
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
 Vraci adresu n-teho vyskytu znaku c.
 Pri kladnem n hleda dopredu, pri nule nebo zapornem od minuleho znaku dozadu.
 ---------------------------------------------------------------------------}
Function TText1.chAdrFrom(c:char;adr:word;n:integer):word;assembler;
 asm
     les di,self
     mov es,[es:di+offset pos+2]
     mov di,adr
     mov al,c
     mov cx,65535
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
     mov es,[si+offset pos+2]
     mov di,adr
     mov cx,65535
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
     lds si,self
     mov es,[si+offset pos+2]
     mov di,adr
     mov cx,65535

     {al=newlnlast}
     mov bl,byte ptr [si+newln]
     mov bh,0
     mov al,byte ptr [si+bx+newln]

     repne scasb
     PUSH DI
     mov cx,di{cx=nova poloha}
     sub cx,adr{cx=nova poloha-stara}
     sub cl,byte ptr [si+newln]{ubere cr/lf na konci radku}
     sbb ch,0
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




{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ TEXT 2 ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

{---------------------------------------------------------------------------
 Zapamatuje si kde lezi zacatek textu, hodi ukazatel na start.
 Volat az kdyz je text na miste.
 ---------------------------------------------------------------------------}
Constructor TText2.Init(p:pchar;maxend:word);
begin
 inherited Init(p);
 konec:=chAdr(EOT,1);
 maxkonec:=maxend;
 insert:=true;
end;

{---------------------------------------------------------------------------
 Zapamatuje si kde lezi zacatek textu, hodi ukazatel na start.
 Text jeste nemusi byt na miste.
 ---------------------------------------------------------------------------}
Destructor TText2.Done;
var   p:pointer;
begin
 p:=StartPtr;
 if not static then FreeMem(p,maxkonec-start+1);
 inherited Done;
end;

{---------------------------------------------------------------------------
 Zapamatuje si kde lezi zacatek textu, hodi ukazatel na start.
 Volat az kdyz je text na miste.
 ---------------------------------------------------------------------------}
Procedure TText2.Rewrite;
begin
 word(pos):=start;
 konec:=start;
end;

{---------------------------------------------------------------------------
 Vraci konec textu (#0).
 ---------------------------------------------------------------------------}
Function TText2.EndPtr:pchar;
begin
 EndPtr:=ptr(PtrRec(pos).Seg,konec);
end;

{---------------------------------------------------------------------------
 Vraci delku textu. Nula na konci se nepocita.
 ---------------------------------------------------------------------------}
Function TText2.FileSize:longint;
begin
 FileSize:=konec-start;
end;

{---------------------------------------------------------------------------
 Na konec textu da symbol newline, pokud tam jeste neni.
 Nektere metody zatim neumi pracovat s textem nezakoncenym newline.
 {*vyresit rozumnejc
 ---------------------------------------------------------------------------}
Procedure TText2.EndNewline;
begin
 if not CmpBlock(EndPtr-length(newln),@newln[1],length(newln))
  then InsStr(konec,0,newln);
 EndPtr^:=#0;
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
var   rozdil:integer;
      oldpos:word;
begin
 DelSpaces(adr,space);
 InsSpaces(adr,length(st));
 move(st[1],ptr(PtrRec(pos).Seg,adr)^,length(st));

 rozdil:=integer(length(st))-space;
(*
 if adr+space>konec then space:=konec-adr;
 oldpos:=word(pos);
 if rozdil>0 then InsSpaces(adr,rozdil) else
 if rozdil<0 then DelSpaces(adr,-rozdil);
 {*tady to nejak nesedi kdyz je space<>0}
 if (oldpos>=adr) and (oldpos<adr+length(st))
  then word(pos):=oldpos+length(st);{*totez s blkstart/end}
 move(st[1],ptr(PtrRec(pos).Seg,adr)^,length(st));
*)
 InsStr:=rozdil;
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
 Vraci jestli je pos na konci textu nebo dokonce mimo text.
 ---------------------------------------------------------------------------}
Function TText2.Eof:boolean;
begin
 Eof:=(word(pos)>=konec) or (word(pos)<start)
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


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

function Init:word;
 begin
  Init:=erOk;
 end;

procedure Done;
 begin
 end;

END.