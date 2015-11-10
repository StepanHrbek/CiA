{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.10ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Stringy;
Interface {$i define.inc}
Uses      Chyby,Memo;
Function  Init:word;
Procedure Done;


TYPE      PString = ^string;

{---------------------------------------------------------------------------
 Konverze
 ---------------------------------------------------------------------------}
{obecne konverze}
PROCEDURE Xlat(var st:string;src,dest:string);
FUNCTION  Xlated(st,src,dest:string):string;

{hexa cisla}
FUNCTION  Hexed(l:longint):string;
FUNCTION  Dehexed(st:string):longint;

{maly/velky/kamenici}
PROCEDURE LoCasni(var st:openstring);
PROCEDURE UpCasni(var st:openstring);
FUNCTION  LoCased(st:string):string;
FUNCTION  UpCased(st:string):string;
FUNCTION  Kamenici2Ascii(var st:openstring):string;{*nestaci jeden zpusob vraceni vysledku?}

{string/pchar}
FUNCTION  Pc2Str(pc:pchar):string;
FUNCTION  Str2Pc(var st:openstring):pchar;
FUNCTION  DeStr2Pc(var st:openstring):pchar;

{---------------------------------------------------------------------------
 Zpracovani strukturovanych stringu.
 ---------------------------------------------------------------------------}
{zakladni operace}
FUNCTION  GetCore(st:string):string;
FUNCTION  GetPos(c:char;st:string;n:integer):integer;
FUNCTION  GetString(delic:char;st:string;n:integer):string;
FUNCTION  CutString(delic:char;var st:openstring):string;
FUNCTION  CutName(var st:openstring):string;

{prace s cisly ve stringu}
FUNCTION  Stri(n:longint):string;
FUNCTION  Valu(st:string):longint;
FUNCTION  CutWord(delic:char;var st:openstring;var prom:word):Boolean;
FUNCTION  CutLong(delic:char;var st:openstring;var prom:longint):Boolean;
FUNCTION  GetNumPos(st:string;n:integer;var pos,len:integer):longint;
FUNCTION  GetNum(st:string;n:integer):longint;
FUNCTION  ReplacedNum(st:string;n:integer;value:longint):string;
FUNCTION  CutNum(var st:openstring):longint;

{---------------------------------------------------------------------------
 Hvezdickova konvence.
 ---------------------------------------------------------------------------}
FUNCTION  hkIsOk(st:string):boolean;
FUNCTION  hkNalezi(prvek,mnozina:string):boolean;


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


{---------------------------------------------------------------------------
 Znaky ze src nahradi znaky z dest.
 ---------------------------------------------------------------------------}
PROCEDURE Xlat(var st:string;src,dest:string);
var   i,j:word;
begin
 for i:=1 to length(st) do begin
   j:=pos(st[i],src);
   if j>0 then st[i]:=dest[j];
   end;
end;

{---------------------------------------------------------------------------
 Znaky ze src nahradi znaky z dest.
 ---------------------------------------------------------------------------}
FUNCTION  Xlated(st,src,dest:string):string;
var   i,j:word;
begin
 Xlat(st,src,dest);
 Xlated:=st;
end;


const Kamenici: string[30] = 'ˆ¨‡©‘˜ ¡‚£–Ÿ¤ƒ¢'+
                             '‰›€ž’‹—¦†¥…•';
      Ascii   : string[30] = 'escrzyaieuutndo'+
			     'ESCRZYAIEUUTNDO';

{---------------------------------------------------------------------------
 Zkonverti jeden hexaznak do bajtu, vraci -1 pri chybe.
 ---------------------------------------------------------------------------}
FUNCTION DehexedChar(ch:char):shortint;
begin
 case ch of '0'..'9':dehexedchar:=ord(ch)-ord('0');
            'a'..'f':dehexedchar:=ord(ch)-ord('a')+10;
            'A'..'F':dehexedchar:=ord(ch)-ord('A')+10;
                else dehexedchar:=-1;
                end;
end;

{---------------------------------------------------------------------------
 Zkonverti hexastring do longintu, vraci -1 pri chybe.
 ---------------------------------------------------------------------------}
FUNCTION Dehexed(st:string):longint;
var i:word;
    l:longint;
    d:shortint;
begin
 l:=0;
 for i:=1 to length(st) do begin
   d:=DehexedChar(st[i]);
   if d=-1 then begin Dehexed:=-1;exit;end;
   l:=l shl 4+d;
   end;
 Dehexed:=l;
end;

{---------------------------------------------------------------------------
 Zkonverti longint do hexastringu.
 ---------------------------------------------------------------------------}
FUNCTION Hexed(l:longint):string;
var   st:string[8];
const hex:array[0..15] of char='0123456789ABCDEF';
begin
 st:='';
 repeat
   insert(hex[l mod 16],st,1);
   l:=l shr 4;
 until l=0;
 Hexed:=st;
end;

{---------------------------------------------------------------------------
 String zkonverti do malych pismen.
 ---------------------------------------------------------------------------}
PROCEDURE LoCasni(var st:openstring);
var i,j:byte;
begin
 for i:=1 to length(st) do begin
	case st[i] of 'A'..'Z':inc(st[i],32); end;
        j:=pos(st[i],Kamenici);
        if j > 15 then st[i]:=Kamenici[j-15];
        end;
end;

{---------------------------------------------------------------------------
 String zkonverti do velkych pismen.
 ---------------------------------------------------------------------------}
PROCEDURE UpCasni(var st:openstring);
var i,j:byte;
begin
 for i:=1 to length(st) do begin
	st[i]:=upcase(st[i]);
        j:=pos(st[i],Kamenici);
        case j of 1..15:st[i]:=Kamenici[j+15]; end;
        end;
end;

{---------------------------------------------------------------------------
 Vraci string zkonverteny do malych pismen.
 ---------------------------------------------------------------------------}
FUNCTION LoCased(st:string):string;
var i:byte;
begin
 LoCasni(st);
 LoCased:=st;
end;

{---------------------------------------------------------------------------
 Vraci string zkonverteny do velkych pismen.
 ---------------------------------------------------------------------------}
FUNCTION UpCased(st:string):string;
var i:byte;
begin
 UpCasni(st);
 UpCased:=st;
end;

{---------------------------------------------------------------------------
 Vraci string zkonverteny z Kameniku do ASCII.
 ---------------------------------------------------------------------------}
FUNCTION Kamenici2Ascii(var st:openstring):string;
var i:byte;
begin
 for i:=1 to length(st) do
  if pos(st[i],Kamenici) <> 0 then st[i]:=ascii[pos(st[i],Kamenici)];
 Kamenici2Ascii:=st;
end;

{---------------------------------------------------------------------------
 Konverti pchar na string. Z prilis dlouhych vraci prvnich 255 znaku.
 Btw, toto je okopcene z Borlandi unity strings.pas, ale opravil
 jsem chybu s dlouhymi pchary a pridal kontrolu na nil.
 ---------------------------------------------------------------------------}
FUNCTION  Pc2Str(pc:pchar):string;assembler;
 asm
	PUSH	DS
	MOV	CX,000FeH
        db 66h;cmp word ptr pc,0
        jz      @nil
        inc     cx
	CLD
	LES	DI,pc
	XOR	AL,AL
	REPNE	SCASB
        @nil:
	NOT	Cl
	DEC	Cl
	LDS	SI,pc
	LES	DI,@Result
	MOV	AL,CL
	STOSB
	REP	MOVSB
	POP	DS
 end;

{---------------------------------------------------------------------------
 Destruktivne zkonverti string na Pchar (st[i]->st[i-1], st[last]=#0)
 a vraci na nej pcharovy pointer. Zadne alokace, pouze prostor stringu.
 IMHO lepsi nez nedestruktivni konverze, ktera by nedokazala zkonvertit
 stringy delky 255, nebo ne ?
 ---------------------------------------------------------------------------}
FUNCTION DeStr2Pc(var st:openstring):pchar;assembler;
 var   p:byte absolute st;
 asm
     push ds
     lds si,p
     les di,p
     lodsb
     mov cl,al
     mov ch,0
     rep movsb
     mov al,0
     stosb
     pop ds
     mov ax,word ptr p
     mov dx,word ptr p+2
 end;

{---------------------------------------------------------------------------
 Temer nedestruktivne zkonverti openstring na Pchar (st[last+1]=#0)
 a vraci na nej pcharovy pointer. Zadne alokace, pouze prostor stringu.
 U stringu maximalni delky prepise posledni znak nulou!
 ---------------------------------------------------------------------------}
FUNCTION Str2Pc(var st:openstring):pchar;assembler;
 var   p:word absolute st;
 asm
     les di,p
     mov bl,[es:di]
     xor bh,bh
     cmp bx,p.word[-2]
     je @overwritelast
     inc bx
     @overwritelast:
     mov [es:bx+di],bh
     xchg ax,di
     mov dx,es
     inc ax
 end;


{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ ZPRACOVANI STRUKTUROVANYCH STRINGU ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


{---------------------------------------------------------------------------
 Vraci jadro stringu - z obou kraju umazne pripadne mezery nebo znaky 0.
 ---------------------------------------------------------------------------}
FUNCTION GetCore(st:string):string;
begin
 while (st>'') and ((st[length(st)]=' ') or (st[length(st)]=#0)) do dec(st[0]);
 while (st>'') and ((st[1]=' ') or (st[1]=#0)) do delete(st,1,1);
 GetCore:=st;
end;

{---------------------------------------------------------------------------
 Vrati pozici n-teho vyskytu znaku c ve stringu st.
 Pozice nulteho a nizsiho vyskytu je nula.
 Neni-li tam c tolikrat, pozice je length(st)+1.
 ---------------------------------------------------------------------------}
FUNCTION  GetPos(c:char;st:string;n:integer):integer;
var   i:word;
begin
 if n<1 then begin GetPos:=0;exit;end;
 for i:=1 to length(st) do
  if st[i]=c then
   if n>1 then dec(n)
          else begin GetPos:=i;exit;end;
 GetPos:=length(st)+1;
end;

{---------------------------------------------------------------------------
 Vrati n-ty prvek z retezce slov oddelenych delicem.
 ---------------------------------------------------------------------------}
FUNCTION  GetString(delic:char;st:string;n:integer):string;
var   i,j:integer;
begin
 i:=GetPos(delic,st,n-1);
 j:=GetPos(delic,st,n);
 GetString:=copy(st,i+1,j-i-1);
end;

{---------------------------------------------------------------------------
 Z kraje stringu odstrihne substring a vraci ho jako vysledek.
 ---------------------------------------------------------------------------}
FUNCTION CutString(delic:char;var st:openstring):string;
var i:word;
begin
 i:=pos(delic,st);if i=0 then i:=length(st)+1;
 CutString:=copy(st,1,i-1);
 delete(st,1,i);
end;

{---------------------------------------------------------------------------
 Z kraje stringu odstrihne filename a vraci ho jako vysledek.
 Rozpozna oddelovac souboru (viz pouzity seznam znaku).
 ---------------------------------------------------------------------------}
FUNCTION  CutName(var st:openstring):string;
var i:word;
begin
 i:=1;
 while (i<=length(st)) and
  not (st[i] in [' ',',',';','+',':','\','?','*',#0..#31]) do inc(i);
 CutName:=copy(st,1,i-1);
 delete(st,1,i);
end;

{---------------------------------------------------------------------------
 Zkonverti cislo do stringu ale na rozdil od 'System.Str' je to funkce.
 ---------------------------------------------------------------------------}
FUNCTION  Stri(n:longint):string;
var st:string[10];
begin
 str(n,st);
 stri:=st;
end;

{---------------------------------------------------------------------------
 Zkonverti string do longintu ale na rozdil od 'System.Val' je to funkce.
 Pri nekorektnim vstupu vraci 0.
 ---------------------------------------------------------------------------}
FUNCTION  Valu(st:string):longint;
var   l:longint;
      code:word;
begin
 val(st,l,code);
 if code=0 then valu:=l else valu:=0;
end;

{---------------------------------------------------------------------------
 Z kraje stringu odstrihne cislo a nastavi ho do prom.
 Pri nekorektnim zadani cisla nastavi 0 a vraci false.
 ---------------------------------------------------------------------------}
FUNCTION  CutWord(delic:char;var st:openstring;var prom:word):Boolean;
var code:word;
begin
 val(CutString(delic,st),prom,code);
 if code>0 then prom:=0;
 CutWord:=code=0;
end;

{---------------------------------------------------------------------------
 Z kraje stringu odstrihne cislo a nastavi ho do prom.
 Pri nekorektnim zadani cisla nastavi 0 a vraci false.
 ---------------------------------------------------------------------------}
FUNCTION  CutLong(delic:char;var st:openstring;var prom:longint):Boolean;
var code:word;
begin
 val(CutString(delic,st),prom,code);
 if code>0 then prom:=0;
 CutLong:=code=0;
end;

{---------------------------------------------------------------------------
 Pomocna funkce:
  oproti GetNum vraci navic pozici cisla uvnitr stringu.
 ---------------------------------------------------------------------------}
FUNCTION  GetNumPos(st:string;n:integer;var pos,len:integer):longint;
var   i,i0:word;
      innum:boolean;

  procedure start;
  begin
   innum:=true;
   dec(n);
   pos:=i;
  end;

  function stop:boolean;
  begin
   stop:=false;
   innum:=false;
     {pozor na nasledujici radek: kdyz v '--1' narazi na druhe minus, zjisti ze to prvni minus byl plany poplach}
   if (st[i-1]='-') or (st[i-1]='+') then inc(n);
   if n=0 then begin
     len:=i-pos;
     GetNumPos:=Valu(copy(st,pos,len));
     stop:=true;
     end;
  end;

begin
 GetNumPos:=0;
 pos:=0;
 len:=0;
 if n<1 then exit;
 innum:=false;
 for i:=1 to length(st) do
   case st[i] of '0'..'9':if not innum then start;
                 '+','-' :if not innum then start else begin if stop then exit;start;end;
                 else     if innum then if stop then exit;
                 end;
 if innum then begin inc(i);stop;end;
end;

{---------------------------------------------------------------------------
 Vrati n-te cislo ze stringu. Cislo muze zacinat znakem + nebo -.
 Je-li cisel mene nez n, vraci 0.
 Priklad: string '1+2*003-4--5' obsahuje v tomto poradi cisla 1,2,3,-4,-5.
 ---------------------------------------------------------------------------}
FUNCTION  GetNum(st:string;n:integer):longint;
var   pos,len:integer;
begin
 GetNum:=GetNumPos(st,n,pos,len);
end;

{---------------------------------------------------------------------------
 Nahradi n-te cislo ve stringu. Ohlida si aby se dve cisla nesloucila.
 Neni-li tam n-te, betaverze ohlasi chybu, ostra nedela nic.
 Priklad: ReplacedNum('1+2*3-04--5',4,14)='1+2*3+14--5'
          ReplacedNum('1+2*3+14--5',5,15)='1+2*3+14-+15'
 ---------------------------------------------------------------------------}
FUNCTION  ReplacedNum(st:string;n:integer;value:longint):string;
var   pos,len:integer;
      plus:string[1];
begin
 GetNumPos(st,n,pos,len);
 plus:='';
 if value>=0 then if st[pos-1] in ['+','-','0'..'9'] then plus:='+';
 if len>0 then ReplacedNum:=copy(st,1,pos-1)+plus+Stri(value)+copy(st,pos+len,255)
          else {$ifdef beta}erBetaMsg('replacednum'){$endif};
end;

{---------------------------------------------------------------------------
 Ustrihne a vraci prvni cislo ze stringu. Cislo muze zacinat znakem + nebo -.
 Neni-li tam uz zadne, vraci 0.
 Priklady: z 'x1--5..' vraci 1 a '--5..'
           z   '--5..' vraci -5 a '..'
           z      '..' vraci 0 a '..'.
 ---------------------------------------------------------------------------}
FUNCTION  CutNum(var st:openstring):longint;
var   pos,len:integer;
begin
 CutNum:=GetNumPos(st,1,pos,len);
 delete(st,1,pos+len-1);
end;



{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ HVEZDICKOVA KONVENCE ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}

{---------------------------------------------------------------------------
 Vraci zda string neporusuje syntaxi rozsirene hvezdickove konvence.
 ---------------------------------------------------------------------------}
FUNCTION  hkIsOk(st:string):boolean;
var   zavorek:integer;
      i:word;
label bad;
begin
 hkIsOk:=false;
 zavorek:=0;
 for i:=1 to length(st) do case st[i] of '"':goto bad;
                                         '[':inc(zavorek);
                                         ']':if zavorek>0 then dec(zavorek) else goto bad;
                                     #0..#31:goto bad;
                                         '|':if zavorek=0 then goto bad;
                                         end;
 if zavorek<>0 then goto bad;
 hkIsOk:=true;
 bad:
end;

{---------------------------------------------------------------------------
 Vraci zda prvek nalezi do mnoziny zadane rozsirenou hvezdickovou konvenci.
 Funkce predpoklada ze druhy parametr odpovida konvenci, nesnazi se
 detekovat nejake syntakticke chyby.
 Vysvetleni nazvu: *.bak je mnozina souboru, bagr.bak jeji prvek, a tahle
  funkce zjisti jestli prvek nalezi do mnoziny.
 ---------------------------------------------------------------------------}
FUNCTION hkNalezi(prvek,mnozina:string):boolean;
var   i,j,k,l,m:byte;
label ok;
begin
 hkNalezi:=false;
 if prvek=mnozina then goto OK;

 {odstrani sekvence hvezdicek, ktere zada vul snazici se zahltiti stack}
 for i:=length(mnozina) downto 2 do if (mnozina[i]='*') and (mnozina[i-1]='*') then delete(mnozina,i,1);

 if prvek='' then begin
   if mnozina[1]='*' then if hkNalezi('',copy(mnozina,2,255)) then goto OK;
   exit;
   end;

 for i:=1 to length(prvek) do
   if i>length(mnozina) then exit
   {---------------- obstara syntaxi * ---------------}
   else
   if mnozina[i]='*' then
     begin
     for j:=i to length(prvek)+1 do if hkNalezi(copy(prvek,j,255),copy(mnozina,i+1,255)) then goto OK;
     end
   {---------------- obstara syntaxi [|] ---------------}
   else
   if mnozina[i]='[' then
     begin
     {i <- pozice zacatku vyrazu: '['}
     {k <- pozice konce vyrazu: ']'}
     l:=0;
     for k:=i+1 to length(mnozina) do case mnozina[k] of '[':inc(l);
                                                     ']':if l>0 then dec(l) else break;
                                                     end;
     {j <- pozice zacatku substringu: '[' nebo '|'}
     j:=i;
     repeat
       {m <- pozice konce substringu: '|' nebo ']'}
       l:=0;
       for m:=j+1 to k do case mnozina[m] of '[':inc(l);
                                           ']':if l>0 then dec(l) else break;
                                           '|':if l=0 then break;
                                           end;
       if hkNalezi(copy(prvek,i,200),copy(mnozina,j+1,m-j-1)+copy(mnozina,k+1,255)) then goto OK;
       j:=m;
     until mnozina[m]=']';
     exit;
     end
   {---------------- obstara syntaxi ? ---------------}
   else
   if (mnozina[i]<>prvek[i]) and (mnozina[i]<>'?') then exit;

 if not hkNalezi('',copy(mnozina,length(prvek)+1,255)) then exit;
 ok:
 hkNalezi:=true;
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