{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 1.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Stringy;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Strings;
Function  Init:TError;
Procedure Done;

Type      string2=string[2];
          string8=string[8];
          string11=string[11];

{---------------------------------------------------------------------------
 Konverze
 ---------------------------------------------------------------------------}
{obecne konverze}
PROCEDURE Xlat(var st:openstring;src,dest:string);
FUNCTION  Xlated(st,src,dest:string):string;

{hexa cisla}
const     hex:array[0..15] of char='0123456789ABCDEF';
FUNCTION  Hexed(d:longint):string8;
FUNCTION  Dehexed(s:string):longint;

{maly/velky/kamenici}
FUNCTION  DnCase(c:char):char;
PROCEDURE LoCasni(var st:openstring);
PROCEDURE UpCasni(var st:openstring);
FUNCTION  LoCased(st:string):string;
FUNCTION  UpCased(st:string):string;
FUNCTION  Kamenici2Ascii(st:openstring):string;
FUNCTION  lcased(s:string):string;
FUNCTION  ucased(s:string):string;

{string/pchar}
FUNCTION  Pc2Str(pc:pchar):string;
FUNCTION  Str2Pc(var st:openstring):pchar;
FUNCTION  DeStr2Pc(var st:openstring):pchar;
FUNCTION  Str2TempPc(st:string):pchar;

{ostatni}
FUNCTION  Rep(c:char;kolikrat:byte):string;
FUNCTION  Left(st:string;len:byte):string;
FUNCTION  Right(st:string;len:byte):string;
FUNCTION  LeftRight(levy,pravy:string;len:byte):string;
FUNCTION  Middle(st:string;len:byte):string;
FUNCTION  Reversed(s:string):string;

{cas na string}
FUNCTION  DateS:string8;
FUNCTION  TimeS:string8;

{---------------------------------------------------------------------------
 Zpracovani strukturovanych stringu.
 ---------------------------------------------------------------------------}
{zakladni operace}
FUNCTION  GetCore(st:string):string;
FUNCTION  GetPos(st:string;c:char;n:integer):integer;
FUNCTION  GetString(st:string;separator:char;n:integer):string;
FUNCTION  CutString(var s:openstring;separator:char):string;
FUNCTION  CutName(var st:openstring):string;
FUNCTION  CutChar(var st:openstring):char;
FUNCTION  CutAll(var st:openstring):string;
PROCEDURE AddName(var st:openstring;name:PathStr);
FUNCTION  WithoutChar(c:char;s:string):string;
FUNCTION  WithoutChars(chars,s:string):string;
FUNCTION  CharsIn(c:char;s:string):byte;

{prace s cisly ve stringu}
const     Zero:char='0';
FUNCTION  WithZeroes(num:longint;len:byte):string11;
FUNCTION  Stri(num:longint):string11;
FUNCTION  Valu(st:string11):longint;
FUNCTION  GetNumPos(st:string;n:integer;var pos,len:integer):longint;
FUNCTION  GetNum(st:string;n:integer):longint;
FUNCTION  ReplacedNum(st:string;n:integer;value:longint):string;
FUNCTION  CutNum(var st:openstring):longint;
FUNCTION  Ptr2Str(p:pointer):string11;
FUNCTION  MultiCase(variable:string;environment:pchar):string;

{const     SubstChar:char='^';
FUNCTION  SubstString(c:char; s:string):string;
FUNCTION  DeSubstString(s:string):string;
FUNCTION  IsInStr(item,list:string):boolean;

{---------------------------------------------------------------------------
 Vse pro pchary.
 ---------------------------------------------------------------------------}
FUNCTION  StrNewStr(st:string):pchar;
FUNCTION  StrNewNum(l:longint):pchar;
FUNCTION  StrGetNum(pc:pchar):longint;
FUNCTION  StrCutChar(var pc:pchar):char;
FUNCTION  StrCutNum(var pc:pchar):longint;
FUNCTION  StrCutName(var pc:pchar):string;
FUNCTION  StrCutStr(var pc:pchar;separator:char):string;
FUNCTION  StrRolChar(pc:pchar):char;
FUNCTION  StrRolNum(pc:pchar):longint;
FUNCTION  StrRolName(pc:pchar):string;
FUNCTION  StrRolStr(pc:pchar;separator:char):string;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}



FUNCTION MinW(x,y:word):word;inline($58/$5b/$3b/$c3/$72/$01/$93);{pop ax;pop bx;cmp ax,bx;jb +1;xchg ax,bx}
FUNCTION MaxI(x,y:integer):integer;inline($58/$5b/$3b/$d8/$7e/$01/$93);{pop ax;pop bx;cmp bx,ax;jle +1;xchg ax,bx}

{---------------------------------------------------------------------------
 Znaky ze src nahradi znaky z dest.
 ---------------------------------------------------------------------------}
PROCEDURE Xlat(var st:openstring;src,dest:string);
var   i,j:word;
begin
 for i:=1 to length(st) do begin
   j:=pos(st[i],src);
   if j>0 then st[i]:=dest[j];
   end;
end;

{---------------------------------------------------------------------------
 Znaky ze src nahradi znaky z dest.
 Priklad: Xlated('ahoj','aj','Ay')='Ahoy'
 ---------------------------------------------------------------------------}
FUNCTION  Xlated(st,src,dest:string):string;
begin
 Xlat(st,src,dest);
 Xlated:=st;
end;

{---------------------------------------------------------------------------
 Zameni jednu cast stringu za druhou.
 ---------------------------------------------------------------------------}
PROCEDURE XLatStr(var s:string; scr,dest:string);
var i:byte;
begin
 i:=Pos(scr,s);
 if i<1 then exit;
 Delete(s,i,length(scr));
 Insert(dest,s,i);
end;

{---------------------------------------------------------------------------
 Zameni jednu cast stringu za druhou.
 Priklad: Xlated('klavesnice','vesnice','mesto')='klamesto'
 ---------------------------------------------------------------------------}
FUNCTION  XlatedStr(st,src,dest:string):string;
begin
 XlatStr(st,src,dest);
 XlatedStr:=st;
end;

const Kamenici: string[30] = 'à®á©ëò†°Ç£ñü§É¢'+
                             'âõÄûíùèãêó¶Ü•Öï';
      Ascii   : string[30] = 'escrzyaieuutndo'+
                             'ESCRZYAIEUUTNDO';

{---------------------------------------------------------------------------
 Zkonverti longint do hexastringu.
 ---------------------------------------------------------------------------}
FUNCTION Hexed(d:longint):string8; assembler;
asm   {hexed}
 push es
 les  di,@result
 mov  si,di
 inc  di
 xor  bx,bx   {bl=delka vysledneho stringu}
 mov  al,byte ptr d+3
 call @hex
 mov  al,byte ptr d+2
 call @hex
 mov  al,byte ptr d+1
 call @hex
 mov  al,byte ptr d
 call @hex
 jmp  @end
@hex:
 mov  ah,al
 shr  ah,4
 test bh,1    {bh=either("narazili jsme na 1. nenulovy hex (zleva)",1,0)}
 jnz  @hex0
 or   ax,ax
 jz   @hexdone
 or   bh,1
 or   ah,ah
 jz   @nextnibble
@hex0:
 cmp  ah,9
 jbe  @hex1
 add  ah,'A'-'0'-0Ah
@hex1:
 add  ah,'0'
 mov  es:[di],ah
 inc  di
 inc  bl
@nextnibble:
 and  al,0Fh
 or   ax,ax
 jz   @hexdone
 cmp  al,9
 jbe  @hex2
 add  al,'A'-'0'-0Ah
@hex2:
 add  al,'0'
 stosb
 inc  bl
@hexdone:
 retn
@end:
 mov  es:[si],bl
 pop  es
end;  {hexed}

FUNCTION  Dehexed(s:string):longint; assembler;
asm   {Dehexed}
 push ds
 lds  si,s
 xor  ch,ch
 lodsb
 mov  cl,al
 xor  bx,bx
 xor  dx,dx
 cmp  cx,4
 ja   @2
@1:
 call @zpracujhex
 shl  bx,4
 add  bl,al
 inc  al
 jz   @err
 loop @1
 jmp  @end
@2:
 add  si,cx
 sub  si,4
 mov  cx,4
@3:
 call @zpracujhex
 shl  bx,4
 add  bl,al
 inc  al
 jz   @err
 loop @3
 lds  si,s
 lodsb
 xor  ch,ch
 mov  cl,al
 sub  cx,4
 cmp  cx,4
 jb   @4
 add  si,cx
 sub  si,4
 mov  cx,4
@4:
 call @zpracujhex
 shl  dx,4
 add  dl,al
 inc  al
 jz   @err
 loop @4
 jmp  @end

@zpracujhex:       {nahraje hex a prevede ho na cislo -1..15 v AL (-1=chyba)}
 lodsb
 cmp  al,'f'
 ja   @hexerr
 cmp  al,'a'
 jae  @hex1
 cmp  al,'F'
 ja   @hexerr
 cmp  al,'A'
 jae  @hex2
 cmp  al,'9'
 ja   @hexerr
 cmp  al,'0'
 jae  @hex3
@hexerr:
 mov  al,0FFh
 jmp  @hexdone
@hex1:
 sub  al,'a'-'A'
@hex2:
 sub  al,'A'-'0'-0Ah
@hex3:
 sub  al,'0'
@hexdone:
 retn

@err:
 mov  bx,0FFFFh
 mov  dx,0FFFFh
@end:
 mov  ax,bx
 mov  cx,dx
 pop  ds
end;  {Dehexed}

{---------------------------------------------------------------------------
 Complement UpCase. Napr.: DnCase('F')='f'
 ---------------------------------------------------------------------------}
FUNCTION DnCase(c:char):char; assembler;
asm  {DnCase}
 mov  al,c
 cmp  al,'A'
 jb   @1
 cmp  al,'Z'
 ja   @1
 add  al,'a'-'A'
@1:
end; {DnCase}

{---------------------------------------------------------------------------
 String zkonverti do malych pismen. Reaguje i na ceske znaky.
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
 String zkonverti do velkych pismen. Reaguje i na ceske znaky.
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
begin
 LoCasni(st);
 LoCased:=st;
end;

{---------------------------------------------------------------------------
 Vraci string zkonverteny do velkych pismen.
 ---------------------------------------------------------------------------}
FUNCTION UpCased(st:string):string;
begin
 UpCasni(st);
 UpCased:=st;
end;

{---------------------------------------------------------------------------
 String zkonverti do malych pismen. Nereaguje na ceske znaky.
 ---------------------------------------------------------------------------}
FUNCTION lcased(s:string):string; assembler;
asm   {lcased}
 push ds
{ push es}
 lds  si,s
 les  di,@Result
 xor  ch,ch
 mov  cl,ds:[si]
 movsb
 jcxz @3
@1:
 lodsb
 cmp  al,'A'
 jl   @2
 cmp  al,'Z'
 jg   @2
 add  al,32
@2:
 stosb
 loop @1
@3:
{ pop  es}
 pop  ds
end;  {lcased}

{---------------------------------------------------------------------------
 String zkonverti do velych pismen. Nereaguje na ceske znaky.
 ---------------------------------------------------------------------------}
FUNCTION ucased(s:string):string; assembler;
asm   {ucased}
 push es
 push ds
 {cld}
 lds  si,s
 les  di,@Result
 xor  ch,ch
 mov  cl,ds:[si]
 movsb
 jcxz @3
@1:
 lodsb
 cmp  al,'a'
 jl   @2
 cmp  al,'z'
 jg   @2
 sub  al,'a'-'A'
@2:
 stosb
 loop @1
@3:
 pop  ds
 pop  es
end;  {ucased}

{---------------------------------------------------------------------------
 Vraci string zkonverteny z Kameniku do ASCII.
 ---------------------------------------------------------------------------}
FUNCTION Kamenici2Ascii(st:openstring):string;
var i:byte;
begin
 for i:=1 to length(st) do
  if pos(st[i],Kamenici)<>0 then st[i]:=ascii[pos(st[i],Kamenici)];
 Kamenici2Ascii:=st;
end;

{---------------------------------------------------------------------------
 Konverti pchar na string. Z prilis dlouhych vraci prvnich 255 znaku.
 Btw, toto je okopcene z Borlandi unity strings.pas, ale opravil
 jsem chybu s dlouhymi pchary a pridal kontrolu na nil.
 ---------------------------------------------------------------------------}
FUNCTION  Pc2Str(pc:pchar):string;assembler;
asm
 PUSH DS
 MOV  CX,000FeH
 db 66h;cmp word ptr pc,0
 jz   @nil
 inc  cx
 {CLD}
 LES  DI,pc
 XOR  AL,AL
 REPNE SCASB
@nil:
 NOT  Cl
 DEC  Cl
 LDS  SI,pc
 LES  DI,@Result
 MOV  AL,CL
 STOSB
 REP  MOVSB
 POP  DS
end;

{---------------------------------------------------------------------------
 Destruktivne zkonverti string na Pchar (st[i]->st[i-1], st[last]=#0)
 a vraci na nej pcharovy pointer. Zadne alokace, pouze prostor stringu.
 ---------------------------------------------------------------------------}
FUNCTION DeStr2Pc(var st:openstring):pchar;assembler;
var p:byte absolute st;
asm
 push ds
 {cld}
 lds  si,p
 les  di,p
 lodsb
 mov  cl,al
 xor  ch,ch
 rep  movsb
 xor  al,al
 stosb
 pop  ds
 mov  ax,word ptr p
 mov  dx,word ptr p+2
end;

{---------------------------------------------------------------------------
 Vytvori docasny PChar. Nemusis ho pak odalokovat, ale za chvili sam zanikne
 (az zas nekdo jiny pouzije staticke pole free).
 ---------------------------------------------------------------------------}
FUNCTION  Str2TempPc(st:string):pchar;
begin
 move(st[1],freeC,length(st));
 freeC[length(st)]:=#0;
 Str2TempPc:=@freeC[0];
end;

{---------------------------------------------------------------------------
 Temer nedestruktivne zkonverti openstring na Pchar (st[last+1]=#0)
 a vraci na nej pcharovy pointer. Zadne alokace, pouze prostor stringu.
 U stringu maximalni delky prepise posledni znak nulou!
 ---------------------------------------------------------------------------}
FUNCTION Str2Pc(var st:openstring):pchar;assembler;
var p:word absolute st;
asm
 les  di,p
 mov  bl,[es:di]
 xor  bh,bh
 cmp  bx,p.word[-2]
 je   @overwritelast
 inc  bx
@overwritelast:
 mov  [es:bx+di],bh
 xchg ax,di
 mov  dx,es
 inc  ax
end;

{---------------------------------------------------------------------------
 Vygeneruje sekvenci znaku... Rep('x',3)='xxx'.
 ---------------------------------------------------------------------------}
FUNCTION  Rep(c:char;kolikrat:byte):string;assembler;
asm   {Rep}
 les  di,@result
 mov  al,kolikrat
 {cld}
 stosb
 mov  cl,al
 xor  ch,ch
 mov  al,c
 call REP_STOSB
end;  {Rep}

FUNCTION  RepW(c:string2;kolikrat:byte):string;assembler;
asm   {RepW}
 push ds
 push es
 {cld}
 les  di,@result
 mov  al,kolikrat
 and  al,7Fh
 shl  al,1
 stosb
 mov  cl,al
 xor  ch,ch
 lds  si,c
 inc  si
 lodsw
 call REP_STOSW_o
 pop  es
 pop  ds
end;  {RepW}

FUNCTION RepS(s:string; kolikrat:byte):string; assembler;
{Narychlo spichnutej Rep pro stringy}
asm   {RepS}
 push ds
 push es
 {cld}
 cmp  kolikrat,0
 je   @end
 les  di,@result
 lds  si,s
 lodsb
 cmp  al,0
 je   @end
 xor  ah,ah
 mov  bl,al
 xor  bh,bh
 mul  kolikrat
 cmp  ah,0
 jz   @normalne
@1:
 dec  byte ptr kolikrat
 sub  ax,bx
 cmp  ax,0FFh
 ja   @1
 mov  cl,kolikrat
 xor  ch,ch
 inc  di
 mov  ah,kolikrat
 call @cykl
 mov  al,ah
 xor  ah,ah
 mul  bx
 not  al
 mov  cl,al
 lds  si,s
 inc  si
 call REP_MOVSB_na
 les  di,@result
 mov  byte ptr es:[di],0FFh
 jmp  @end
@normalne:
 stosb
 mov  cl,kolikrat
 xor  ch,ch
 call @cykl
 jmp  @end
@cykl:
 push cx
 lds  si,s
 lodsb
 mov  cl,al
 xor  ch,ch
 call REP_MOVSB_na
 pop  cx
 loop @cykl
 ret
@end:
 pop  es
 pop  ds
end;  {RepS}

{---------------------------------------------------------------------------
 Zarovna string Left/Right/z obou kraju na zadanou delku.
 Kdyz se nevejde, orizne ho. Kdyz je kratkej, doplni mezery.
 ---------------------------------------------------------------------------}
FUNCTION  Left(st:string;len:byte):string;
begin
 Left:=copy(st,1,len)+rep(' ',maxI(0,len-length(st)));
end;

FUNCTION  Right(st:string;len:byte):string;
begin
 Right:=rep(' ',maxI(0,len-length(st)))+copy(st,maxI(1,length(st)-len+1),255);
end;

FUNCTION  LeftRight(levy,pravy:string;len:byte):string;
begin
 {pri prekryti je videt levy string}
 LeftRight:=copy(levy,1,len)+Right(pravy,len-minW(len,length(levy)));
end;

{---------------------------------------------------------------------------
 Priklad: Middle('sirokouhly film',13)='irokouhly fil'
          Middle('sirokouhly film',20)='  sirokouhly film   '
 ---------------------------------------------------------------------------}
FUNCTION  Middle(st:string;len:byte):string;
begin
 if len<length(st) then
  Middle:=Copy(st,1+(length(st)-len) shr 1,len) else
 if len>length(st) then
  Middle:=Rep(' ',(len-length(st)) shr 1)+st+Rep(' ',(len-length(st)) shr 1+(len-length(st)) and 1)
 else
  Middle:=st;
end;


{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ ZPRACOVANI STRUKTUROVANYCH STRINGU ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{---------------------------------------------------------------------------
 Vraci jadro stringu - z obou kraju umazne pripadne mezery nebo znaky 0.
 ---------------------------------------------------------------------------}
FUNCTION GetCore(st:string):string;
begin
 while (st>'') and (st[length(st)] in [' ',#0]) do dec(st[0]);
 while (st>'') and (st[1] in [' ',#0]) do delete(st,1,1);
 GetCore:=st;
end;

{---------------------------------------------------------------------------
 Vrati pozici n-teho vyskytu znaku c ve stringu st.
 Pozice nulteho a nizsiho vyskytu je nula.
 Neni-li tam c tolikrat, pozice je length(st)+1.
 ---------------------------------------------------------------------------}
FUNCTION  GetPos(st:string;c:char;n:integer):integer;
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
 Vrati n-ty prvek z retezce slov oddelenych separatorem.
 ---------------------------------------------------------------------------}
FUNCTION  GetString(st:string;separator:char;n:integer):string;
var   i,j:integer;
begin
 i:=GetPos(st,separator,n-1);
 j:=GetPos(st,separator,n);
 GetString:=copy(st,i+1,j-i-1);
end;

{---------------------------------------------------------------------------
 Z kraje stringu odstrihne substring a vraci ho jako vysledek.
 ---------------------------------------------------------------------------}
FUNCTION  CutString(var s:openstring;separator:char):string; assembler;
{Odkroji string az po prvni vyskyt separatoru. Pravou cast da do promenne
 a levou vrati jako vysledek funkce. Neni optimalizovan†, ale presto je asi
 2.5 x rychlejsi nez Pascalska verze.}
var Len,Right:byte;
asm   {CutString}
 push ds
 push es
 {cld}
 les  di,s
 mov  ch,0
 mov  cl,es:[di]
 mov  Len,cl       {v cl je delka promenne}
 inc  di
 mov  al,separator
 repne scasb       {v cl je pocet znaku za separatorem}
 cmp  cl,0
 jne  @dal
 cmp  es:[di-1],al
 jne  @spec
@dal:
 mov  Right,cl
 neg  cl
 add  cl,Len
 dec  cl           {v cl je pocet znaku pred separatorem}
 les  di,@result
 mov  al,cl
 stosb
 lds  si,s         {zkopiruje levou cast do vysledku funkce}
 inc  si
 call REP_MOVSB_na
 les  di,s
 lds  si,s
 mov  al,Right
 stosb
 mov  cl,Len
 sub  cl,Right
 inc  cl
 add  si,cx
 mov  cl,Right
 call REP_MOVSB_na
 jmp  @end
@spec:             {zvlastni pripad, kdy string neobsahuje separator}
 lds  si,s
 les  di,@result
 lodsb
 stosb
 mov  cl,al
 call REP_MOVSB_na
 les  di,s
 mov  es:[di],ch
@end:
 pop  es
 pop  ds
end;  {CutString}
(* Pro jistotu je tu jeste star†, pascalsk† verze, pro pripad,
 kdyby se zjistilo, ze tadyta "zelen† n†dhera" nefunguje dokonale.
FUNCTION CutString(separator:char;var st:openstring):string;
var i:word;
begin {CutString}
 i:=pos(separator,st);if i=0 then i:=length(st)+1;
 CutString:=copy(st,1,i-1);
 delete(st,1,i);
end;  {CutString}*)

{---------------------------------------------------------------------------
 Z kraje stringu odstrihne filename a vraci ho jako vysledek.
 Rozpozna oddelovac souboru (viz pouzity seznam znaku).
 ---------------------------------------------------------------------------}
FUNCTION  CutName(var st:openstring):string;
var i:word;
begin
 i:=1;
 while (i<=length(st)) and
  not (st[i] in [' ',',',';','+',{':','\','?','*',}#0..#31]) do inc(i);
 CutName:=copy(st,1,i-1);
 delete(st,1,i);
end;

{---------------------------------------------------------------------------
 Z kraje stringu odstrihne znak a vraci ho jako vysledek.
 Z prazdneho stringu vraci #0.
 ---------------------------------------------------------------------------}
FUNCTION  CutChar(var st:openstring):char;
begin
 if st='' then CutChar:=#0 else begin
   CutChar:=st[1];
   delete(st,1,1);
   end;
end;

{---------------------------------------------------------------------------
 Z kraje stringu odstrihne vse.
 ---------------------------------------------------------------------------}
FUNCTION  CutAll(var st:openstring):string;
begin
 CutAll:=st;
 st:='';
end;

{---------------------------------------------------------------------------
 Na konec seznamu st prida polozku name oddelenou mezerou.
 ---------------------------------------------------------------------------}
PROCEDURE AddName(var st:openstring;name:PathStr);
begin
 if st='' then st:=name else
  if name<>'' then st:=st+' '+name;
end;

{---------------------------------------------------------------------------
 Zkonverti cislo do stringu.
 ---------------------------------------------------------------------------}
FUNCTION  Stri(num:longint):string11;
var st:string11;
begin
 str(num,st);
 stri:=st;
end;

{---------------------------------------------------------------------------
 Zkonverti cislo do stringu zadane delky bez mezer.
 Kdyz se nevejde, vrati nejblizsi cislo ktere se jeste vejde.
 Prikady: WithZeroes(  79,5)='00079'
          WithZeroes( -79,5)='-0079'
          WithZeroes( 500,2)='99'
          WithZeroes(-500,2)='-9'
          WithZeroes( -12,1)='0'
 ---------------------------------------------------------------------------}
FUNCTION WithZeroes(num:longint;len:byte):string11;
var s:string11;
begin {WithZeroes}
 if len=0 then begin WithZeroes:='';exit;end;
 if (len=1) and (num<0) then begin WithZeroes:=Zero; exit; end;
 if num<0 then dec(len);
 s:=stri(abs(num));
 if length(s)>len then s:=rep('9',len) else s:=rep(Zero,len-length(s))+s;
 if num<0
  then WithZeroes:='-'+s
  else WithZeroes:=s;
end;  {WithZeroes}
{* Kdyby tady tak byla RealWithZeroes i pro realna cisla}

{---------------------------------------------------------------------------
 Zkonverti string do longintu ale na rozdil od 'System.Val' je to funkce.
 Pri nekorektnim vstupu vraci 0.
 ---------------------------------------------------------------------------}
FUNCTION  Valu(st:string11):longint;
var   l:longint;
      code:word;
begin {Valu}
 val(st,l,code);
 if code=0 then valu:=l else valu:=0;
end;  {Valu}

{---------------------------------------------------------------------------
 Pomocna funkce:
  oproti GetNum vraci navic pozici cisla uvnitr stringu.
 ---------------------------------------------------------------------------}
FUNCTION  GetNumPos(st:string;n:integer;var pos,len:integer):longint;
var   i,i0:word;
      innum:boolean;

  PROCEDURE start;
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

FUNCTION  CutNum(var st:openstring):longint;
var   pos,len:integer;
begin
 CutNum:=GetNumPos(st,1,pos,len);
 delete(st,1,pos+len-1);
end;

{---------------------------------------------------------------------------
 Nahradi n-te cislo ve stringu. Ohlida si aby se dve cisla nesloucila.
 Neni-li tam n-te cislo, neudela nic.
 Priklad: ReplacedNum('1+2*3-004--5',4,14)='1+2*3+14--5'
          ReplacedNum('1+2*3+14--5',5,15)='1+2*3+14-+15'
 ---------------------------------------------------------------------------}
FUNCTION  ReplacedNum(st:string;n:integer;value:longint):string;
var   pos,len:integer;
      plus:string[1];
begin
 GetNumPos(st,n,pos,len);
 plus:='';
 if value>=0 then if st[pos-1] in ['+','-','0'..'9'] then plus:='+';
 if len>0 then ReplacedNum:=copy(st,1,pos-1)+plus+Stri(value)+copy(st,pos+len,255);
end;

FUNCTION  Ptr2Str(p:pointer):string11;
begin
 Ptr2Str:=stri(PtrRec(p).Seg)+':'+stri(PtrRec(p).Ofs);
end;

{---------------------------------------------------------------------------
 Takovy komprimovany case.
 Environment je pchar obsahujici radu promennych a hodnot.
 Multicase pak vraci hodnotu pozadovane promenne.
 Prvni dva znaky environmentu jsou oddelovace promennych a hodnot.
 Posledni hodnota, je-li zadana bez nazvu promenne, slouzi jako else.
  multicase( 'netscape', '=;microsoft=lame;netscape=cool'       )='cool'
  multicase( 'borland',  '=;microsoft=lame;netscape=cool;dunno' )='dunno'
 ---------------------------------------------------------------------------}
FUNCTION  MultiCase(variable:string;environment:pchar):string;
label 1;
var rovnitko,strednik:char;
    last:pchar;
begin
 rovnitko:=StrCutChar(environment);
 strednik:=StrCutChar(environment);
 1:
 last:=environment;
 if StrCutStr(environment,rovnitko)=variable
  then MultiCase:=StrCutStr(environment,strednik)
  else if environment^<>#0 then goto 1 else MultiCase:=Pc2Str(last);
end;

{---------------------------------------------------------------------------
 Jeden priklad za vsechny: WithoutChar('.','M.A.S.H.')='MASH'
 ---------------------------------------------------------------------------}
FUNCTION WithoutChar(c:char;s:string):string; assembler;
asm   {vyjmiznak}
 push ds
 push es
 {cld}
 les  di,@result
 lds  si,s
 lodsb
 inc  di
 xor  ch,ch
 mov  cl,al
 xor  bl,bl
 jcxz @3
@1:
 lodsb
 cmp  al,c
 je   @2
 stosb
 inc  bl
@2:
 loop @1
@3:
 les  di,@result
 mov  es:[di],bl
@end:
 pop  es
 pop  ds
end;  {vyjmiznak}

FUNCTION  WithoutChars(chars,s:string):string;
var i:integer;
begin
 for i:=1 to length(chars) do s:=WithoutChar(chars[i],s);
 WithoutChars:=s;
end;

{---------------------------------------------------------------------------
 Vraci kolikrat se vyskytuje znak c ve stringu s.
 ---------------------------------------------------------------------------}
FUNCTION  CharsIn(c:char; s:string):byte; assembler;
asm   {CharsIn}
 push es
 {cld}
 les  di,s
 mov  al,es:[di]
 cmp  al,0
 je   @end
 inc  di
 mov  cl,al
 xor  ch,ch
 xor  ah,ah
 mov  al,c
 repne scasb
 jcxz @ven
@znova:
 repne scasb
 inc  ah
 jcxz @ven
 jmp  @znova
@ven:
 cmp  byte ptr es:[di-1],al
 jne  @cont
 inc  ah
@cont:
 mov  al,ah
@end:
 pop  es
end;  {CharsIn}
{ po vyzkouseni a uvazeni smazte jednu z verzi..
FUNCTION  CharsIn(c:char;s:string):byte;
var i,j:word;
begin
 j:=0;
 for i:=1 to length(s) do if s[i]=c then inc(j);
 CharsIn:=j;
end;}

(*
FUNCTION  SubstString(c:char; s:string):string; assembler;
{Nasledujici dve funkce umoznuji zakodovat urcity znak ve stringu
 do kodu, ve kterem se tento znak nebude vyskytovat (substituce)
 a zpetne rozkodovat substituovany string (desubstituce).
 Priklad vyuziti: Funkce CutString - ta odrezava casti retezce,
 ktere jsou oddeleny separatorem. Takze do ni nemuzete pouzit polozky,
 ktere v sobe tento znak obsahuji. Muzete vsak ve stringu, ktery
 bude CutString zpracovavat, nechat tento znak substituovat. Kazdy znak,
 se po substituci zmeni na SubstChar + dvoumistny hexadecimalni kod,
 takze napr. strednik se vsude zmeni na '^3B'. Takto upraveny retezec
 jiz bez problemu projde funkci CutString a po desubstituci dostanete
 nezmeneny, puvodni string. Abych se zas tolik nevytahoval, toto je vlastne
 zvlastni pripad funkce Xlated, ktery konvertuje kodovy a zadany znak, v asm. :)
 Pozn.: kodovy znak (promennou SubstChar) si muzete zmenit, a pokud se
 vyskytne funkce, ktera ho bude take pouzivat, pak to rozhodne udelejte.}
asm   {SubstString}
 push ds
 push es
 {cld}
 les  di,@result
 lds  si,s
 lodsb
 mov  bh,al        {bh-length(s)}
 stosb
 xor  bl,bl        {bl-citac poctu kodovych znaku ve stringu}
 mov  cl,al
 xor  ch,ch
@cykl:
 lodsb
 cmp  al,c
 je   @zakoduj
 cmp  al,SubstChar
 je   @zakoduj
@pokracuj:
 stosb
 loop @cykl
 les  di,@result
 add  bh,bl        {u prilis dlouheho stringu s hodne kodama muze dojit k preteceni-v tom pripade vrati vstupni string}
 jc   @preteceni
 mov  al,bh
 stosb
 jmp  @end
@zakoduj:
 inc  bl
 cmp  al,SubstChar
 je   @done
 mov  al,SubstChar
 stosb
 mov  al,c
 shr  al,4
 cmp  al,9
 jbe  @dal1
 add  al,7
@dal1:
 add  al,'0'
 stosb
 inc  bl
 mov  al,c
 and  al,0Fh
 cmp  al,9
 jbe  @dal2
 add  al,7
@dal2:
 add  al,'0'
 jmp  @pokracuj
@done:
 stosb
 jmp  @pokracuj
@preteceni:
 lds  si,s
 les  di,@result
 lodsb
 stosb
 mov  cl,al
 xor  ch,ch
 call REP_MOVSB_na
@end:
 pop  es
 pop  ds
end;  {SubstString}

FUNCTION  DeSubstString(s:string):string; assembler;
asm   {DeSubstString}
 push ds
 push es
 {cld}
 lds  si,s
 lodsb
 les  di,@result
 stosb
 cmp  al,0
 je   @end
 xor  bl,bl        {bl-pocet kodu ve stringu}
 mov  cl,al
 xor  ch,ch
@cykl:
 lodsb
 cmp  al,SubstChar
 je   @rozkoduj
@pokracuj:
 stosb
 loop @cykl
 lds  si,s
 lodsb
 les  di,@result
 sub  al,bl
 stosb
 jmp  @end
@rozkoduj:
 lodsb
 inc  bl
 cmp  al,SubstChar
 je   @pokracuj
 cmp  al,'a'
 jb   @1
 sub  al,'a'-'A'
@1:
 cmp  al,'9'
 jbe  @2
 sub  al,7
@2:
 sub  al,'0'
 shl  al,4
 mov  ah,al
 lodsb
 inc  bl
 cmp  al,'a'
 jb   @3
 sub  al,'a'-'A'
@3:
 cmp  al,'9'
 jbe  @4
 sub  al,7
@4:
 sub  al,'0'
 add  al,ah
 jmp  @pokracuj
@end:
 pop  es
 pop  ds
end;  {DeSubstString}

{---------------------------------------------------------------------------
 IsIn pro stringy. Vraci, jesli v seznamu, jehoz jednotlive polozky jsou
 oddeleny strednikem, je pritomen dany retezec.
 Priklad: IsInStr('jablko','pomeranc;citron;banan;kiwi;hruska;kokos')=false
 Rozlisuje mala a velka pismena. Podporuje (De)SubstString. Omezeni na 255b.
 {* a) nevyzkouseno  b) asi bude lepsi verze pro PChary misto string£.
 ---------------------------------------------------------------------------}
FUNCTION  IsInStr(item,list:string):boolean;
begin {IsInStr}
 IsInStr:=false;
 while list<>'' do
  if DesubstString(CutString(list,';'))=item then
   begin
    IsInStr:=true;
    exit
   end
end;  {IsInStr}
*)

FUNCTION Reversed(s:string):string; assembler;
{Vraci string pozpatku.}
asm   {Reversed}
 push ds
 lds  si,s
 les  di,@result
 lodsb
 stosb
 or   al,al
 jz   @@3
 mov  bl,al
 mov  cl,al
 xor  ch,ch
 and  bx,3
 add  di,cx
 shr  cl,2
 or   cl,cl
 jnz  @@1
 mov  cx,bx
 jmp  @@2
@@1:
 db   66h;lodsw
 xchg ah,al
 db   66h;rol  ax,16
 xchg ah,al
 sub  di,4
 db   66h;mov  es:[di],ax
 loop @@1
 or   bl,bl
 jz   @@3
 mov  cx,bx
@@2:
 lodsb
 dec  di
 mov  es:[di],al
 loop @@2
@@3:
 pop  ds
end;  {Reversed}

{---------------------------------------------------------------------------
 Vraci systemove datum v podobe stringu (napr.'02.29.96')
 ---------------------------------------------------------------------------}
FUNCTION  DateS:string8;
var y,m,d,dow:word;
begin {dates}
 GetDate(y,m,d,dow);
 dates:=WithZeroes(d,2)+'.'+WithZeroes(m,2)+'.'+Right(WithZeroes(y,4),2);
end;  {dates}

{---------------------------------------------------------------------------
 Vraci systemovy cas v podobe stringu (napr.: '23:59:58')
 ---------------------------------------------------------------------------}
FUNCTION  TimeS:string8;
var h,m,s,s100:Word;
begin {times}
 GetTime(h,m,s,s100);
 times:=WithZeroes(h,2)+':'+WithZeroes(m,2)+':'+WithZeroes(s,2);
end;  {times}



{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ VSE PRO PCHARY ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

{---------------------------------------------------------------------------
 Vytvori novy pchar ze stringu.
 ---------------------------------------------------------------------------}
FUNCTION  StrNewStr(st:string):pchar;
var p:pchar;
begin
 if st='' then StrNewStr:=nil
  else StrNewStr:=StrNew(Str2Pc(st));
end;

{---------------------------------------------------------------------------
 Vytvori novy pchar z cisla.
 ---------------------------------------------------------------------------}
FUNCTION  StrNewNum(l:longint):pchar;
begin
 StrNewNum:=StrNewStr(Stri(l));
end;

{---------------------------------------------------------------------------
 Z pcharu urizne prvni znak.
 Zadne alokace, jen posune pointer. Nelze pote pouzit StrDispose(pc).
 ---------------------------------------------------------------------------}
FUNCTION StrCutChar(var pc:pchar):char;
begin
 if pc=nil then StrCutChar:=#0 else begin
   StrCutChar:=pc^;
   inc(pc);
   end;
end;

{---------------------------------------------------------------------------
 Z pcharu urizne prvni cislo.
 Zadne alokace, jen posune pointer. Nelze pote pouzit StrDispose(pc).
 ---------------------------------------------------------------------------}
FUNCTION StrCutNum(var pc:pchar):longint;
var num:longint;
    sgn:shortint;
label 1;
begin
 if pc=nil then begin StrCutNum:=0;exit;end;
 1:
 {odmazne chaos}
 while not (pc^ in ['0'..'9','-',#0]) do inc(pc);
 {odmazne znamenko}
 num:=0;
 sgn:=1;
 if pc^='-' then begin sgn:=-1;inc(pc);if not (pc^ in ['0'..'9']) then goto 1;end;
 {odmazne cislo}
 while pc^ in ['0'..'9'] do begin
   num:=10*num+ord(pc^)-48;
   inc(pc);
   end;
 StrCutNum:=sgn*num;
end;

{---------------------------------------------------------------------------
 Z pcharu precte prvni cislo.
 ---------------------------------------------------------------------------}
FUNCTION StrGetNum(pc:pchar):longint;
begin
 StrGetNum:=StrCutNum(pc);
end;

{---------------------------------------------------------------------------
 Z kraje pcharu odstrihne filename a vraci ho jako vysledek.
 Rozpozna oddelovac souboru (viz pouzity seznam znaku).
 Zadne alokace, jen posune pointer. Nelze pote pouzit StrDispose(pc).
 ---------------------------------------------------------------------------}
FUNCTION  StrCutName(var pc:pchar):string;
var st:string;
begin
 st:='';
 if pc<>nil then begin
   while not (pc^ in [' ',',',';','+',#0..#31])
    do begin st:=st+pc^;inc(pc);end;
   if pc^<>#0 then inc(pc);
   end;
 StrCutName:=st;
end;

{---------------------------------------------------------------------------
 Z kraje pcharu odstrihne string az do oddelovace a vraci ho jako vysledek.
 Zadne alokace, jen posune pointer. Nelze pote pouzit StrDispose(pc).
 ---------------------------------------------------------------------------}
FUNCTION  StrCutStr(var pc:pchar;separator:char):string;
var st:string;
begin
 st:='';
 if pc<>nil then begin
   while (pc^<>#0) and (pc^<>separator) do begin st:=st+pc^;inc(pc);end;
   if pc^<>#0 then inc(pc);
   end;
 StrCutStr:=st;
end;

{---------------------------------------------------------------------------
 Z pcharu urizne prvni znak.
 Zadne alokace, jen posune telo pcharu. Nelze pote pouzit StrDispose(pc).
 ---------------------------------------------------------------------------}
FUNCTION  StrRolChar(pc:pchar):char;
begin
 StrRolChar:=#0;
 if pc<>nil then begin
   StrRolChar:=pc^;
   StrCopy(pc,pc+1);
   end;
end;

{---------------------------------------------------------------------------
 Z pcharu urizne prvni cislo.
 Zadne alokace, jen posune telo pcharu. Nelze pote pouzit StrDispose(pc).
 ---------------------------------------------------------------------------}
FUNCTION  StrRolNum(pc:pchar):longint;
var oldpc:pchar;
begin
 oldpc:=pc;
 StrRolNum:=StrCutNum(pc);
 if oldpc<>nil then StrCopy(oldpc,pc);
end;

{---------------------------------------------------------------------------
 Z kraje pcharu odstrihne filename a vraci ho jako vysledek.
 Rozpozna oddelovac souboru.
 Zadne alokace, jen posune telo pcharu. Nelze pote pouzit StrDispose(pc).
 ---------------------------------------------------------------------------}
FUNCTION  StrRolName(pc:pchar):string;
var oldpc:pchar;
begin
 oldpc:=pc;
 StrRolName:=StrCutName(pc);
 if oldpc<>nil then StrCopy(oldpc,pc);
end;

{---------------------------------------------------------------------------
 Z kraje pcharu odstrihne string az do oddelovace a vraci ho jako vysledek.
 Zadne alokace, jen posune telo pcharu. Nelze pote pouzit StrDispose(pc).
 ---------------------------------------------------------------------------}
FUNCTION  StrRolStr(pc:pchar;separator:char):string;
var oldpc:pchar;
begin
 oldpc:=pc;
 StrRolStr:=StrCutStr(pc,separator);
 if oldpc<>nil then StrCopy(oldpc,pc);
end;

{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

function Init:TError;
 begin
  Init:=erOk;
 end;

procedure Done;
 begin
 end;

END.