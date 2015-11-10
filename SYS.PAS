{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 2.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Sys;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos {$ifdef dpmi},Dpmi{$endif},Key,Stringy;
Function  Init:TError;
Procedure Done;

{---------------------------------------------------------------------------
 Uzitecna makra.
 ---------------------------------------------------------------------------}

{minima, maxima}
FUNCTION MinW(x,y:word):word;inline($58/$5b/$3b/$c3/$72/$01/$93);{pop ax;pop bx;cmp ax,bx;jb +1;xchg ax,bx}
FUNCTION MaxW(x,y:word):word;inline($58/$5b/$3b/$c3/$77/$01/$93);{pop ax;pop bx;cmp ax,bx;ja +1;xchg ax,bx}
FUNCTION MinI(x,y:integer):integer;inline($58/$5b/$3b/$c3/$7e/$01/$93);{pop ax;pop bx;cmp ax,bx;jle +1;xchg ax,bx}
FUNCTION MaxI(x,y:integer):integer;inline($58/$5b/$3b/$d8/$7e/$01/$93);{pop ax;pop bx;cmp bx,ax;jle +1;xchg ax,bx}
FUNCTION MinL(x,y:longint):longint;inline($66/$58/$66/$5b/$66/$3b/$c3/$7e/$02/$66/$93/ $66/$50/$59/$5a);{jako MaxI/MinI,}
FUNCTION MaxL(x,y:longint):longint;inline($66/$58/$66/$5b/$66/$3b/$d8/$7e/$02/$66/$93/ $66/$50/$59/$5a);{ale s hi(eax)->dx}

{rozklad vetsich cisel na mensi}
FUNCTION HiWord(l:longint):word;inline($58/$58);{pop ax;pop ax}
FUNCTION LoWord(l:longint):word;inline($66/$58);{pop eax}
FUNCTION HiInt(l:longint):integer;inline($58/$58);{pop ax;pop ax}
FUNCTION LoInt(l:longint):integer;inline($66/$58);{pop eax}
FUNCTION HiByte(w:word):byte;inline($58/$8a/$c4);{pop ax;mov al,ah}
FUNCTION LoByte(w:word):byte;inline($58);{pop ax}

{skladani mensich cisel ve vetsi cislo}
FUNCTION MakeLong(hi,lo:word):longint;inline($58/$5a);{pop ax;pop dx}
FUNCTION MakeWord(hi,lo:byte):word;inline($58/$5a/$8a/$e2);{pop ax;pop dx;mov ah,dl}
FUNCTION MakeInt(hi,lo:byte):integer;inline($58/$5a/$8a/$e2);{pop ax;pop dx;mov ah,dl}

{rotace o 1 nebo n bitu}
FUNCTION RolB(a:byte):byte;inline($58/$d0/$c0);{pop ax;rol al,1}
FUNCTION RorB(a:byte):byte;inline($58/$d0/$c8);{pop ax;ror al,1}
FUNCTION RolS(a:shortint):shortint;inline($58/$d0/$c0);{pop ax;rol al,1}
FUNCTION RorS(a:shortint):shortint;inline($58/$d0/$c8);{pop ax;ror al,1}
FUNCTION RolI(a:integer):integer;inline($58/$d1/$c0);{pop ax;rol ax,1}
FUNCTION RorI(a:integer):integer;inline($58/$d1/$c8);{pop ax;ror ax,1}
FUNCTION RolW(a:word):word;inline($58/$d1/$c0);{pop ax;rol ax,1}
FUNCTION RorW(a:word):word;inline($58/$d1/$c8);{pop ax;ror ax,1}
FUNCTION RolBn(a:byte;n:byte):byte;inline($59/$58/$d2/$c0);{pop cx;pop ax;rol al,cl}
FUNCTION RorBn(a:byte;n:byte):byte;inline($59/$58/$d2/$c8);{pop cx;pop ax;ror al,cl}
FUNCTION RolSn(a:shortint;n:byte):shortint;inline($59/$58/$d2/$c0);{pop cx;pop ax;rol al,cl}
FUNCTION RorSn(a:shortint;n:byte):shortint;inline($59/$58/$d2/$c8);{pop cx;pop ax;ror al,cl}
FUNCTION RolIn(a:integer;n:byte):integer;inline($59/$58/$d3/$c0);{pop cx;pop ax;rol ax,cl}
FUNCTION RorIn(a:integer;n:byte):integer;inline($59/$58/$d3/$c8);{pop cx;pop ax;ror ax,cl}
FUNCTION RolWn(a:word;n:byte):word;inline($59/$58/$d3/$c0);{pop cx;pop ax;rol ax,cl}
FUNCTION RorWn(a:word;n:byte):word;inline($59/$58/$d3/$c8);{pop cx;pop ax;ror ax,cl}

FUNCTION Str2Char(st:string):char;{if length(st)=1 then vrat st[1] else vrat #0}
 inline($5f   /$07   /$26/$8b/$05   /$3c/$01 /$b0/$00 /$75/$02/$8a/$c4);
       {pop di;pop es;mov ax,[es:di];cmp al,1;mov al,0;jnz +2;mov al,ah}

{---------------------------------------------------------------------------
 Dalsi funkce na praci s cisly.
 ---------------------------------------------------------------------------}

{konverze cisel}
FUNCTION  Bi2By(w:word):word;inline($58/5/7/0/$c1/$e8/3);{pop ax;add ax,7;shr ax,3}
FUNCTION  Long2Word(n:longint):word;
FUNCTION  Long2Int(n:longint):integer;

{napasovani cisla do zadaneho intervalu}
FUNCTION  Bounded(n,min,max:longint):longint;
PROCEDURE Bound(var n:longint;min,max:longint);
FUNCTION  Wrapped(n,min,max:longint):longint;
PROCEDURE Wrap(var n:longint;min,max:longint);
FUNCTION  RoundedUp(n,step:longint):longint;
FUNCTION  RoundedDown(n,step:longint):longint;

{dalsi operace s cisly}
FUNCTION  IsIn(n,min,max:LongInt):boolean;
FUNCTION  RealPower(base,p:real):real;
FUNCTION  Epx(zaklad:longint;exponent:shortint):longint;
FUNCTION  Sgn(a:integer):Integer;
FUNCTION  Bit(n:longint;b:byte):boolean;
PROCEDURE Switch(var boo:boolean);

{secte vsechny nenulove bity ve slove}
FUNCTION BitCount1(n:byte):byte;
FUNCTION BitCount2(n:word):byte;
FUNCTION BitCount4(n:LongInt):byte;

{ternarni operatory}
FUNCTION  either(cond:boolean; res1,res2:LongInt):LongInt;
FUNCTION  eitherS(cond:boolean; res1,res2:string):string;

Const
 minbyte =          0;
 maxbyte =        255;
 minshort=       -128;
 maxshort=        127;
 minword =          0;
 maxword =      65535;
 minint  =     -32768;
 maxint  =      32767;
 minlong =-2147483647-1;
 maxlong = 2147483647;

{---------------------------------------------------------------------------
 Klavesnice.
 ---------------------------------------------------------------------------}

FUNCTION  KeyPressed:boolean; inline($b4/$0b/$cd/$21);{mov ah,0bh;int 21h}
FUNCTION  ReadKey:char; inline($b4/$08/$cd/$21);{mov ah,8;int 21h}
PROCEDURE WaitKey; inline($b8/$0c08/$cd/$21);{mov ax,0c08h;int 21h}
FUNCTION  AskKey(list:string):char;
FUNCTION  AskKeyExt(list:string):string2;
PROCEDURE FlushKey;
PROCEDURE TypeAsciiCode(zn:char);
PROCEDURE TypeScanCode(code:byte);
PROCEDURE TypeWrite(s:string);


{---------------------------------------------------------------------------
 Eventy.

 Promenna event typu TEvent obsahuje tri udaje:
   code(event) - scan-code stisknute klavesy
   char(event) - znak vygenerovany stiskem nebo #0 pokud jde o rozsireny znak
   extchar(event) - rozsireny znak nebo #0 pokud jde o normalni znak
 Mas-li kod, znak a rozsireny znak, event vytvoris pomoci
   MakeEvent(kod,znak,extznak).
 ---------------------------------------------------------------------------}

type      TEvent = longint;
function  MakeEvent(code:byte;char,extchar:char):TEvent; inline($5a/$58/$5b/$8a/$e3);{pop dx;pop ax;pop bx;mov ah,bl}
function  code(e:TEvent):byte; inline($66/$58/$8a/$c4);{pop eax;mov al,ah}
function  extchar(e:TEvent):char; inline($58/$58);{pop ax;pop ax}
var       switchYZ:boolean;

FUNCTION  GuessCode:byte;
FUNCTION  ReadEvent:TEvent;


{---------------------------------------------------------------------------
 HODINY
 ---------------------------------------------------------------------------}

{ Klasicke stopky.}

Type  TStopky = object
                  mili       :longint; {po Start a Stop je tu ubehly cas v ms (pretece asi za 25 dni)}
                  mikro      :longint; {po Start a Stop je tu ubehly cas v Ês (pretece asi za 35 minut)}
                  ticks      :longint; {po Start a Stop je tu hlavni cast ubehleho casu
                                        v ticich=1h/2^16=asi 55 ms (pretece asi za 4 roky)}
                  mticks     :longint; {po Start a Stop je tu zbyla mala (muze byt i zaporna)
                                        cast ubehleho casu v mikroticich=1h/2^32=0.838 Ês}
                  procedure  Start;
                  function   LookAt:longint;
                  function   Stop:longint;
                  procedure  Cont;
                  procedure  Eat(eatmikro:longint);{uber z casu na bezicich hodinkach tolik mikrosekund}
                end;


{ Kolik ubehlo milisekund od resetu? }

FUNCTION  GetMs:longint;


{ Presnost... TStopky i GetMs mohou byt presne(mikrosec)/nepresne(5milisec) }

FUNCTION  GetPreciseClock:boolean;
PROCEDURE SetPreciseClock(precise:boolean);


{ Cekani, nahrada Delay z Crt }

PROCEDURE DelayS(s:real);
PROCEDURE Delay(ms:real);


{ Jeste presnejsi mereni casu. }

var       EventWaitOk:boolean; {funguji nasledujici funkce?}

FUNCTION  DelayStart(mikrosekund:longint):boolean;
FUNCTION  DelayEnd:boolean;


{---------------------------------------------------------------------------
 DTA - disk transfer address
 ---------------------------------------------------------------------------}

PROCEDURE StoreDTA;
PROCEDURE RestoreDTA;


{---------------------------------------------------------------------------
 Operacni system / Timeslice / CPU
 ---------------------------------------------------------------------------}

Const
  MDOS      =0;
  OS2       =1;
  Windows   =2;
  NT        =3;
  DesqView  =4;
  NetWare   =5;
  DoubleDOS =6;
  DOSemu    =7;

  os:array[-1..7] of pchar=('?','DOS','OS/2','Windows','Windows NT','DesqView','NetWare','DoubleDos','DOSemu');

  Ops:shortint=-1; {po volani CheckOs je zde zdetekovany operacni system}

PROCEDURE CheckOS;
FUNCTION  DosVersion:word; inline($b4/$30/$cd/$21/$86/$c4);{mov ah,30h;int 21h;xchg al,ah}
FUNCTION  DosAtLeast(ver:word):boolean;
FUNCTION  EquipList:word; inline($cd/$11); {fakt dlouha :-)}

PROCEDURE GiveTimeSlice;

FUNCTION  WhatCpu:word;

FUNCTION  PParams:PString;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{---------------------------------------------------------------------------
 Vraci n napasovane do intervalu min..max.
 Kdyz je mensi nebo vetsi, zarovna ho na min nebo max.
 ---------------------------------------------------------------------------}
FUNCTION Bounded(n,min,max:longint):longint; assembler;
asm
 db 66h;mov ax,word ptr n
 db 66h;mov bx,word ptr min; db 66h;cmp ax,bx; jle @bx
 db 66h;mov bx,word ptr max; db 66h;cmp bx,ax; jle @bx
 mov dx,word ptr n+2
 jmp @end
@bx:
 mov ax,bx
 db 66h;shr bx,16
 mov dx,bx
@end:
end;

PROCEDURE Bound(var n:longint;min,max:longint);
begin
 n:=Bounded(n,min,max);
end;

{---------------------------------------------------------------------------
 Vraci n posunute do intervalu min..max.
 Pro lepsi pochopeni toho vzorce, je to jako kdyz posouvas n o (max-min+1)
 nahoru nebo dolu tak dlouho dokud nespadne do intervalu min..max.
 Je to takove zobecnene modulo.

 Priklad pouziti:
  k:=wrapped(k+1,0,40) posune k ve smycce 0..40
 ---------------------------------------------------------------------------}
FUNCTION Wrapped(n,min,max:longint):longint;
begin
 n:=(n-min) mod (max-min+1);
 if n<0 then wrapped:=n+max+1 else wrapped:=n+min;
end;

PROCEDURE Wrap(var n:longint;min,max:longint);
begin
 n:=wrapped(n,min,max);
end;

{---------------------------------------------------------------------------
 Vraci n zaokrouhlene na nasobek step.
 Priklad pouziti:
   RoundedDown(799,100)=700, RoundedDown(-61,20)=-80
   RoundedUp(901,100)=1000, RoundedUp(-61,20)=-60
 ---------------------------------------------------------------------------}
FUNCTION RoundedDown(n,step:longint):longint;
begin
 if step=0 then RoundedDown:=n {jinak by doslo k chybe #0 - Division by zero}
 else RoundedDown:=n-n mod step-byte(n<0)*step
end;

FUNCTION RoundedUp(n,step:longint):longint;
var hlp:longint;
begin
 if step=0 then RoundedUp:=n
 else RoundedUp:=n-n mod step+byte(n>0)*step
end;

{---------------------------------------------------------------------------
 Vraci word nejblizsi zadanemu longintu.
 ---------------------------------------------------------------------------}
FUNCTION Long2Word(n:longint):word;
begin
 Long2Word:=Bounded(n,minword,maxword);
end;

{---------------------------------------------------------------------------
 Vraci integer nejblizsi zadanemu longintu.
 ---------------------------------------------------------------------------}
FUNCTION Long2Int(n:longint):integer;
begin
 Long2Int:=Bounded(n,minint,maxint);
end;

{---------------------------------------------------------------------------
 Vraci true, jestli %n lezi mezi %min a %max.
 Napriklad: IsIn(3,-7,8)=TRUE stejne jako IsIn(3,8,-7)=TRUE
 ---------------------------------------------------------------------------}
FUNCTION IsIn(n,min,max:LongInt):boolean; assembler;
asm   {IsIn}
 db  66h;mov  ax,word ptr [n]
 db  66h;mov  bx,word ptr [min]
 db  66h;mov  cx,word ptr [max]
 db  66h;cmp  bx,cx
 jle @cont
 db  66h;mov  bx,word ptr [max]
 db  66h;mov  cx,word ptr [min]
@cont:
 db  66h;cmp  ax,bx
 jl  @ne
 db  66h;cmp  ax,cx
 jg  @ne
 mov al,true
 jmp @end
@ne:
 mov al,false
@end:
end;  {IsIn}
(* Kdyby nefungovala, smazte ji a nahradte ji t°mhle:
FUNCTION IsIn(n,min,max:LongInt):boolean;
begin
 isin:=(n>=min) and (n<=max)
end;*)

{---------------------------------------------------------------------------
 Vraci mocninu o zakladu a exponentu (neni chranena proti 'preteceni')
 Pro zaporne exponenty vraci 1.
 ---------------------------------------------------------------------------}
FUNCTION Epx(zaklad:longint;exponent:shortint):LongInt;
var res:LongInt;
begin {epx}
 res:=1;
 for exponent:=exponent downto 1 do res:=res*zaklad;
 epx:=res
end;  {epx}

FUNCTION RealPower(base,p:real):real;
begin {RealPower}
 if base<=0 then RealPower:=-1 else
 RealPower:=Exp(p*Ln(base)) {n*ln(x)=ln(x^n);  ln(e^y)=e^(ln y)=y}
end;  {RealPower}

{---------------------------------------------------------------------------
 Vraci znamenko: 1 kdyz a>0, -1 kdyz a<0 a 0 kdyz a=0
 ---------------------------------------------------------------------------}
FUNCTION Sgn(a:Integer):Integer;assembler;
asm {Sgn}
 mov  ax,[a]
 sar  ax,00Eh
 and  al,0FEh
 inc  ax
end;{Sgn}

{---------------------------------------------------------------------------
 Vraci jestli je nastaven b-ty bit(pocitano od nuly) cisla n.
 ---------------------------------------------------------------------------}
FUNCTION Bit(n:longint;b:byte):boolean;
begin
 bit:=boolean((n shr b) and 1);
end;
{
 Mate-li cislo n a chcete vynulovat jeho b-ty bit, pak napiste
 n:=n and not(1 shl b);  (nebo napr. pro byte:  n:=n and ($FE shl b))
 chcete-li tento b-ty bit zmenit na jenicku, pak napiste
 n:=n or 1 shl b;
 A mate-li cislo n a chcete pouze switchnout b-ty bit, pak napiste
 n:=n xor (1 shl b);
}

{---------------------------------------------------------------------------
 Zneguje boolean.
 ---------------------------------------------------------------------------}
PROCEDURE Switch(var boo:boolean);
begin
 boo:=not boo;
end;

{---------------------------------------------------------------------------
 Vrati cislo prvniho nebo posledniho nenuloveho bitu nebo 0 pro nulu.
 ---------------------------------------------------------------------------}
function BsF1(n:byte):byte; assembler;
{Bit Scan Forward - vrati cislo nejvyznamnejsiho nenuloveho bitu v cisle
 (1..8) nebo 0 pro nulu.}
asm
 mov  ah,n
 mov  al,8
 mov  bl,80h
 mov  cx,8
@cykl:
 test ah,bl
 jnz  @ven
 dec  al
 shr  bl,1
 loop @cykl
@ven:
end;  {BsF1}

function BsR1(n:byte):byte; assembler;
{Bit Scan Reverse - vrati cislo nejmene vyznamneho nenuloveho bitu v cisle
 (1..8) nebo 0 pro nulu.}
asm
 xor  al,al
 mov  ah,n
 cmp  ah,0
 je   @ven
 mov  bl,1
 mov  cx,8
@cykl:
 inc  al
 test ah,bl
 jnz  @ven
 shl  bl,1
 loop @cykl
@ven:
end;  {BsR1}

{---------------------------------------------------------------------------
 Spocita nenulove bity slova delky 1,2 nebo 4 byty.
 ---------------------------------------------------------------------------}
FUNCTION BitCount1(n:byte):byte; assembler;
asm
 mov  al,0
 mov  bl,[n]
 mov  bh,1
 mov  cx,8
@cykl:
 test bl,bh
 jz   @cont
 inc  al
@cont:
 shl  bh,1
 loop @cykl
end;  {BitCount1}

FUNCTION BitCount2(n:word):byte; assembler;
asm
 mov  al,0
 mov  bx,[n]
 mov  dx,1
 mov  cx,16
@cykl:
 test bx,dx
 jz   @cont
 inc  al
@cont:
 shl  bx,1
 loop @cykl
end;  {BitCount2}

FUNCTION BitCount4(n:LongInt):byte; assembler;
asm
 mov  al,0
 mov  bx,word ptr [n]
 mov  dx,1
 mov  cx,16
@cykl:
 test bx,dx
 jz   @cont1
 inc  al
@cont1:
 shl  dx,1
 loop @cykl
 mov  bx,word ptr [n]+2
 mov  dx,1
 mov  cx,16
@cykl2:
 test bx,dx
 jz   @cont2
 inc  al
@cont2:
 shl  dx,1
 loop @cykl2
end;  {BitCount4}

{---------------------------------------------------------------------
 Assemblerovsky ekvivalent "if cond then either:=res1 else either:=res2"
 ---------------------------------------------------------------------}
FUNCTION either(cond:boolean; res1,res2:LongInt):LongInt; assembler;
asm   {either}
 mov  al,cond
 cmp  al,0
 je   @res2
 mov  ax,word ptr res1
 mov  dx,word ptr res1+2
 jmp  @end
@res2:
 mov  ax,word ptr res2
 mov  dx,word ptr res2+2
@end:
end;  {either}

FUNCTION eitherS(cond:boolean; res1,res2:string):string; assembler;
asm   {eitherS}
 push ds
 les  di,@result
 cmp  cond,0
 je   @1
 lds  si,res1
 jmp  @2
@1:
 lds  si,res2
@2:
 mov  ch,0
 mov  cl,ds:[si]
 inc  cx
 call REP_MOVSB_si_nz
 pop  ds
end;  {eitherS}


{€€€€€€€€€€€€€€€€ KEYBOARD €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Ceka na stisk klavesy ze seznamu znaku.
 ---------------------------------------------------------------------------}
FUNCTION  AskKey(list:string):char;
var   c:char;
begin
 repeat c:=readkey until pos(c,list)>0;
 AskKey:=c;
end;

{---------------------------------------------------------------------------
 Zde je verze i pro rozsirene klavesy. Napr.: AskKeyExt('abcd'#0'H') bude
 reagovat na 'a','b','c','d' a sipku nahoru  (nikoli vsak na 'H'!).
 ---------------------------------------------------------------------------}
FUNCTION AskKeyExt(list:string):string2;
var
 c:string2;
 j:byte;
begin {AskKeyExt}
 AskKeyExt:='';
 if list='' then 
  begin
   waitkey;
   exit;
  end;
 repeat
  c[1]:=readkey;
  if c[1]=#0
  then begin c[0]:=#2; c[2]:=readkey; end
  else       c[0]:=#1;
  j:=Pos(c,list);
  if length(c)=1 then
   while (j>1) and (list[j-1]=#0) do
    j:=Pos(c,Copy(list,j+1,$FF));
 until j<>0;
 AskKeyExt:=c;
end;  {AskKeyExt}

{---------------------------------------------------------------------------
 Vymaze buffer se stisknutymi klavesami.
 ---------------------------------------------------------------------------}
PROCEDURE FlushKey;
begin
 {slusnaci by udelali "while keypressed do readkey;"}
 memw[seg0040:$1c]:=memw[seg0040:$1a];
end;


{---------------------------------------------------------------------------
 Je-li keypressed (si musis overit sam), hada pristi znak (koukne se do
 bufferu v biosu). Extended znak (#0,znak) je interpretovan jako 128+znak.
 ---------------------------------------------------------------------------}
FUNCTION  GuessCode:byte;
var   i:byte;
      code,info:byte;
      infocode:word absolute info;
const bads=
       chr(18)+chr(19)+chr(247)+chr(245)+chr(4)+chr(246)+chr(13)+chr(17)+chr(243)+chr(244)+
       chr(162)+chr(163)+chr(151)+chr(159)+chr(153)+chr(161)+chr(152)+chr(160)+chr(155)+chr(157)+
       chr(149)+chr(150)+chr(142)+chr(144)+chr(181)+chr(147)+
       chr(146)+chr(117)+chr(145)+chr(118)+chr(115)+chr(143)+chr(116)+chr(119)+chr(141)+chr(132);
      goods:array[1..36] of byte=(
       kInsert,kDelete,kHome,kEnd,kPgUp,kPgDwn,kUp,kDown,kLeft,kRight,
       kInsert,kDelete,kHome,kEnd,kPgUp,kPgDwn,kUp,kDown,kLeft,kRight,
       kkSlash,kkMul,kkMinus,kkPlus,kkEnter,kkTecka,
       kk0,kk1,kk2,kk3,kk4,kk5,kk6,kk7,kk8,kk9);
      fixes=14;
      fix:array[1..fixes,1..3] of byte=(
       (133, 0,kF11   ), {F11}
       (134, 0,kF12   ), {F12}
       (135, 0,kF11   ), {Shift-F11}
       (136, 0,kF12   ), {Shift-F12}
       (137, 0,kF11   ), {Ctrl-F11}
       (138, 0,kF12   ), {Ctrl-F12}
       (139, 0,kF11   ), {Alt-F11}
       (140, 0,kF12   ), {Alt-F12}
       (224,47,kkSlash), {/}
       (149, 0,kkSlash), {Ctrl-/}
       (164, 0,kkSlash), {Alt-/}
       (224,13,kkEnter), {Enter}
       (224,10,kkEnter), {Ctrl-Enter}
       (166, 0,kkEnter));{Alt-Enter}
begin
 infocode:=memw[seg0040:mem[seg0040:$1a]];
 if info=kExtended then inc(code,128);
{ writeln('-> ',code,' ',info);
 {naprava chaotickych kodu vracenych biosem na nejak usporadana cisla}
 {opravi Shift/Ctrl/Alt-F1..F10, Alt-1..=}
 if info=0 then
  case code of 84.. 93:dec(code, 84-kF1);{Shift-F1 az Shift-F10}
               94..103:dec(code, 94-kF1);{Ctrl-F1 az Ctrl-F10}
              104..113:dec(code,104-kF1);{Alt-F1 az Alt-F10}
              120..131:dec(code,120-k1 );{Alt-1 az Alt-=}
              end;
 {opravi ctrl/alt-midpad/numpad}
 if (info in [0,224]) and (pos(chr(code),bads)>0)
  and ((code>127) or (info>0))
  then code:=goods[pos(chr(code),bads)];
 {opravi zbyle vyjimky}
 for i:=1 to fixes do
  if (code=fix[i,1]) and (info=fix[i,2]) then begin
    code:=fix[i,3];
    break;
    end;
 GuessCode:=code;
end;

{---------------------------------------------------------------------------
 Precte signal z klavesnice.
 Event se sklada z kodu stisknute klavesy (kEnter, kA, kF12 apod)
 a znaku generovaneho stiskem (#13, 'a', 'A', #0#72 apod).
 ---------------------------------------------------------------------------}
FUNCTION  ReadEvent:TEvent;
var   co:byte;
      ch,ext:char;
begin
 while not keypressed do;
 co:=GuessCode;
 ch:=ReadKey;
 if ch=#0 then ext:=ReadKey else ext:=#0;
 {na pozadani aspon zcasti prehodi Y a Z}
 if switchYZ then
   case co of
     kY:begin
        co:=kZ;
        case ch of
          'y':ch:='z';
          'Y':ch:='Z';
          #25:ch:=#26;
          #0 :if ext=#21 then ext:=#44;
          end;
        end;
     kZ:begin
        co:=kY;
        case ch of
          'z':ch:='y';
          'Z':ch:='Y';
          #26:ch:=#25;
          #0 :if ext=#44 then ext:=#21;
          end;
        end;
     end;
 ReadEvent:=MakeEvent(co,ch,ext);
end;

{---------------------------------------------------------------------------
 A nakonec 'vesela' rutinka pro zapsani klaves do
 buferu klavesnice, emulujici jejich fyzicky stisk.
 Pozn.: Pouze pro BIOS od roku 1985 a maximalne pro 16 znaku.
 ---------------------------------------------------------------------------}
procedure TypeAsciiCode(zn:char); assembler;
asm   {TypeAsciiCode}
 mov  ah,5
 xor  ch,ch
 mov  cl,zn
 int  16h
end;  {TypeAsciiCode}

procedure TypeScanCode(code:byte); assembler;
asm   {TypeScanCode}
 mov  ah,5
 mov  ch,code
 xor  cl,cl
 int  16h
end;  {TypeScanCode}

procedure TypeWrite(s:string);
{emuluje zapsani kratkeho stringu. #nnn znamena, ze napise znak s
ascii-kodem nnn a @mmm znamena, ze napise znak se scan-kodem mmm.}
var
 i:byte;
 hlp:char;
 hlpb:byte absolute hlp;
 code:word;
begin {TypeWrite}
 for i:=1 to length(s) do
  if s[i]='#' then
     begin
      val(copy(s,i+1,3),hlpb,code);
      TypeAsciiCode(hlp);
      inc(i,3);
      if i>ord(s[0]) then break
     end
  else
  if s[i]='@' then
     begin
      val(copy(s,i+1,3),hlpb,code);
      TypeScanCode(hlpb);
      inc(i,3);
      if i>ord(s[0]) then break
     end
  else
  TypeAsciiCode(s[i])
end;  {TypeWrite}


{€€€€€€€€€€€€€€€€ HODINY €€€€€€€€€€€€€€€€}

{$define new8} {vlastni pocitani tiku, bez toho tikaji dolni a horni bity hodin ve windows asynchronne}
{$define _squarewave} {pouziti jineho modu timeru, ve windows ovsem neni emulovan, takze dolni bity hodin sumi}

const preciseClock:boolean=false;

{$ifdef new8}
var new8ticks:longint;
{$endif}

{---------------------------------------------------------------------------
 Precte aktualni relativni cas v jednotkach 0.838 Ês.
 ticks - hornich 32 bitu
 mticks - dolnich 16 bitu
 ---------------------------------------------------------------------------}
{$ifndef squarewave}
PROCEDURE ReadTimeInitAsm;assembler;
 asm
   mov al,34h
   out 43h,al
   mov al,0
   out 40h,al
   out 40h,al
 end;

PROCEDURE ReadTimeDoneAsm;assembler;
 asm
 end;

PROCEDURE ReadTime(var ticks:longint;var mticks:word);assembler;
 asm
   cmp preciseClock,false
   jne @precise

   mov es,seg0040
   db 66h;mov cx,word ptr es:[6ch]{v ecx jsou 16-47.bit vysledku}
   xor bx,bx
   jmp @return

  @precise:
   {pripravi registry}
{$ifndef new8}
   mov es,seg0040
{$endif}
  @repeat:
   mov al,0
   {co nejrychlejc nacte cas}
   out 43h,al
   in al,40h
   mov bl,al
   in al,40h
{$ifdef new8}
   db 66h;mov cx,word ptr new8ticks{v ecx jsou 16-47.bit vysledku}
{$else}
   db 66h;mov cx,word ptr es:[6ch]{v ecx jsou 16-47.bit vysledku}
{$endif}
   {znova nacte cas a kdyz pretek, opakuje}
   mov bh,al
   test al,80h
   jnz @nepretek
   mov al,0
   out 43h,al
   in al,40h
   in al,40h
   test al,80h
   jnz @repeat
  @nepretek:
   {dopocita mticks}
   not bx

  @return:
   {zapise mticks z bx}
   les di,mticks
   mov es:[di],bx
   {zapise ticks z ecx}
   les di,ticks
   db 66h;mov word ptr es:[di],cx
 end;
{$else}
{
  to nahore je rate generator verze, dole square wave generator verze
}
PROCEDURE ReadTimeInitAsm;assembler;
 asm
   mov al,36h
   out 43h,al
   mov al,0
   out 40h,al
   out 40h,al
 end;

PROCEDURE ReadTimeDoneAsm;assembler;
 asm
 end;

PROCEDURE ReadTime(var ticks:longint;var mticks:word);assembler;
 asm
   cmp preciseClock,false
   jne @precise

   mov es,seg0040
   db 66h;mov cx,word ptr es:[6ch]{v ecx jsou 16-47.bit vysledku}
   xor ax,ax
   jmp @return

  @precise:
   {pripravi registry}
{$ifndef new8}
   mov es,seg0040
{$endif}
   {ulozi si nebezpecny 15.bit vysledku}
  @repeat:
   mov al,0e2h
   out 43h,al
   in al,40h {7.bit je 15.bit vysledku}
   mov bl,al
   {nacte cas}
   in al,40h {1-7.bit jsou 0-6.bit vysledku}
   db 66h;ror ax,7
   in al,40h {0-7.bit jsou 7-14.bit vysledku}
   db 66h;ror ax,8
{$ifdef new8}
   db 66h;mov cx,word ptr new8ticks{v ecx jsou 16-47.bit vysledku}
{$else}
   db 66h;mov cx,word ptr es:[6ch]{v ecx jsou 16-47.bit vysledku}
{$endif}
   mov al,0e2h
   out 43h,al
   in al,40h {7.bit je 15.bit vysledku}
   {porovna starsi a novejsi 15.bit, jde opakovat cteni pokud se zmenil}
   xor bl,al
   test bl,80h
   jnz @repeat
   {dopocita mticks}
   shr al,7
   db 66h;rol ax,15
   not ax

  @return:
   {zapise mticks z ax}
   les di,mticks
   mov es:[di],ax
   {zapise ticks z ecx}
   les di,ticks
   db 66h;mov word ptr es:[di],cx
 end;
{$endif}

{$ifdef new8}
var old8:pointer;

procedure new8;interrupt;
begin
 inc(new8ticks);
 asm pushf;call dword ptr old8;end;
end;
{$endif}

PROCEDURE ReadTimeInit;
begin
 {$ifdef new8}
 new8ticks:=meml[seg0040:$6c];
 GetIntVec(8,old8);
 SetIntVec(8,@new8);
 {$endif}
 ReadTimeInitAsm;
end;

PROCEDURE ReadTimeDone;
begin
 ReadTimeDoneAsm;
 {$ifdef new8}
 SetIntVec(8,old8);
 {$endif}
end;

FUNCTION GetPreciseClock:boolean;
begin
 GetPreciseClock:=preciseClock;
end;

PROCEDURE SetPreciseClock(precise:boolean);
begin
 if not preciseClock and precise then ReadTimeInit else
  if preciseClock and not precise then ReadTimeDone;
 preciseClock:=precise;
end;

{---------------------------------------------------------------------------
 Kolik asi milisekund ubehlo od posledniho resetu?
 ---------------------------------------------------------------------------}
FUNCTION  GetMs:longint;
var nowticks:longint;
    nowmticks:word;
begin
 ReadTime(nowticks,nowmticks);
 GetMs:=round(nowticks*54.931640625+nowmticks*0.00083819031715);
end;

{---------------------------------------------------------------------------
 Ceka tolik sekund.
 Parametr je real, cekat lze s presnosti az mikrosekund.
 ---------------------------------------------------------------------------}
PROCEDURE DelayS(s:real);
var startticks,nowticks:longint;
    startmticks,nowmticks:word;
begin
 ReadTime(startticks,startmticks);
 repeat
  ReadTime(nowticks,nowmticks);
 until nowticks*0.054931640625+nowmticks*0.00000083819031715>
       startticks*0.054931640625+startmticks*0.00000083819031715+s;
end;

{---------------------------------------------------------------------------
 Nahrada Delay z Crt, ceka tolik milisekund.
 ---------------------------------------------------------------------------}
PROCEDURE Delay(ms:real);
begin
 DelayS(ms/1000);
end;


{€€€€€€€€€€€€€€€€ STOPKY €€€€€€€€€€€€€€€€}

{---------------------------------------------------------------------------
 Zacne merit cas.
 ---------------------------------------------------------------------------}
Procedure TStopky.Start;
begin
 mticks:=0;
 ReadTime(ticks,word(mticks));
end;

{---------------------------------------------------------------------------
 Zastavi mereni casu.
 Ubehlou dobu vraci v milisekundach.
 Mimo to ji nastavi do promennych mili a mikro.
 ---------------------------------------------------------------------------}
Function TStopky.Stop:longint;
var nowticks:longint;
    nowmticks:word;
begin
 ReadTime(nowticks,nowmticks);
 ticks:=nowticks-ticks;
 mticks:=longint(nowmticks)-mticks;
 mili:=round(ticks*54.931640625+mticks*0.00083819031715);
 mikro:=round(ticks*54931.640625+mticks*0.83819031715);
 Stop:=mili;
end;

{---------------------------------------------------------------------------
 Koukne se na bezici stopky.
 Ubehlou dobu vraci v milisekundach.
 Mimo to ji nastavi do promennych mili a mikro.
 ---------------------------------------------------------------------------}
Function TStopky.LookAt:longint;
var nowticks:longint;
    nowmticks:longint;
begin
 nowmticks:=0;
 ReadTime(nowticks,word(nowmticks));
 {write('t=',hexed(nowticks),' mt=',hexed(nowmticks),' ');}
 dec(nowticks,ticks);
 dec(nowmticks,mticks);
 mili:=round(nowticks*54.931640625+nowmticks*0.00083819031715);
 mikro:=round(nowticks*54931.640625+nowmticks*0.83819031715);
 LookAt:=mili;
end;

{---------------------------------------------------------------------------
 Opet rozbehne stopky od casu na kterem byly naposled stopnuty.
 ---------------------------------------------------------------------------}
Procedure TStopky.Cont;
var nowticks:longint;
    nowmticks:word;
begin
 ReadTime(nowticks,nowmticks);
 ticks:=nowticks-ticks;
 mticks:=longint(nowmticks)-mticks;
end;

{---------------------------------------------------------------------------
 Ubere z bezicich stopek tolik mikrosekund.
 ---------------------------------------------------------------------------}
Procedure TStopky.Eat(eatmikro:longint);
var hi:integer;
begin
 inc(mticks,round(eatmikro/0.83819031715));
 hi:=HiInt(mticks);
 inc(ticks,hi);
 dec(mticks,hi*65536);
end;

{€€€€€€€€€€€€€€€€ EVENT WAIT €€€€€€€€€€€€€€€€}

Var       DelaySeg    :word;
          DelayFlag   :^boolean;

{---------------------------------------------------------------------------
 Po zadanem pocet mikrosekund bude DelayEnd vracet true.
 DelayStart vraci jestli je sluzba podporovana a zaclo odpocitavani.
 ---------------------------------------------------------------------------}
FUNCTION DelayStart(mikrosekund:longint):boolean;
var   ok:boolean;
      {$ifdef dpmi}
      RealModeRegs:dpmiRealCallRegs;
      {$endif}
begin
 DelayFlag^:=not EventWaitOk;
 DelayStart:=EventWaitOk;
 if EventWaitOk then begin
   {$ifdef dpmi}
   with RealModeRegs do begin
    {stop previous wait}
    ClrRegs(RealModeRegs);
    rEAX:=$8301;
    erCheck(TError(dpmiRealModeInt($15,@RealModeRegs)));
    {start new wait}
    ClrRegs(RealModeRegs);
    rEAX:=$8300;
    rES:=DelaySeg;
    rEBX:=PtrRec(DelayFlag).Ofs;
    rEDX:=LoWord(mikrosekund);
    rECX:=HiWord(mikrosekund);
    erCheck(TError(dpmiRealModeInt($15,@RealModeRegs)));
    ok:=(flags and 1{cf})=0;
    end;
   {$else}
   asm
    {stop previous wait}
    mov ax,8301h
    int 15h
    {start new wait}
    mov ax,8300h
    les bx,DelayFlag
    mov dx,word ptr mikrosekund
    mov cx,word ptr mikrosekund+2
    int 15h
    {ok?}
    mov ok,true
    jnc @ok
    mov ok,false
    @ok:
   end;
   {$endif}
   if not ok then begin
     if not dumb then erMsg(_(_erEvWaitBusy));
     DelayFlag^:=true;
     DelayStart:=false;
     end;
   end;
end;

FUNCTION DelayEnd:boolean;
begin
 DelayEnd:=DelayFlag^;
end;

{---------------------------------------------------------------------------
 Overi funkcnost event wait. Trva n ms.
 ---------------------------------------------------------------------------}
Function TestEventWaitMs(n:word):boolean;
var   s:TStopky;
begin
 TestEventWaitMs:=false;
 if DelayStart(longint(n)*1000) then
  if not DelayEnd then begin
    s.Start;
    repeat
    until (s.LookAt>n+60) or DelayEnd;
    TestEventWaitMs:=DelayEnd;
    end;
end;

{---------------------------------------------------------------------------
 Overi funkcnost event wait. V prumeru trva 1ms, maximalne asi 200ms.
 ---------------------------------------------------------------------------}
Function TestEventWait:boolean;
begin
 TestEventWait:=TestEventWaitMs(1) or TestEventWaitMs(10) or TestEventWaitMs(100);
end;

{€€€€€€€€€€€€€€€€ DTA €€€€€€€€€€€€€€€€}

var   oldDTA:pointer;
      newDTA:array[1..43] of byte;

{---------------------------------------------------------------------------
 Presmeruje DTA do vlastni pameti.
 Uzitecne pouzit pred nejakymi specifickymi prasecinkami, jinak celkem nanic.
 ---------------------------------------------------------------------------}
PROCEDURE StoreDTA;assembler;
 asm
     mov ah,2fh
     int 21h
     mov word ptr oldDTA+2,es
     mov word ptr oldDTA,bx
     mov ah,1ah
     lea dx,newDTA
     int 21h
 end;

{---------------------------------------------------------------------------
 Vrati puvodni DTA.
 ---------------------------------------------------------------------------}
PROCEDURE RestoreDTA;assembler;
 asm
     push ds
     mov ah,1ah
     lds dx,oldDTA
     int 21h
     pop ds
 end;


FUNCTION PParams:PString;assembler;
asm{dos 3.0+}
 push 30h
 call DosAtLeast
 mov  ah,0
 xor  dx,dx
 or   al,al
 jz   @olddos
 mov  ah,62h
 int  21h
 mov  dx,bx
 mov  ax,80h
 @olddos:
end;


{€€€€€€€€€€€€€€€€ TIMESLICE €€€€€€€€€€€€€€€€}

var needDos:word;

FUNCTION DosAtLeast(ver:word):boolean;
begin
 if DosVersion<ver then begin
   if ver>needDos then begin
     needDos:=ver;
     ReportErr(_(_erChciDosAspon)+' '+stri(HiByte(ver))+'.'+stri(LoByte(ver))+'.');
     end;
   DosAtLeast:=false;
   end
 else
   DosAtLeast:=true;
end;

Procedure CheckOS;assembler;
{ Currently Supports DesqView, Microsoft Windows and IBM's OS/2 }
asm
  cmp ops,-1    { pokud uz zdetekoval, nedetekuje podruhe }
  jne @finish

  mov ops, MDOS { Default DOS }
  mov ah, 30h   { AH = 30h }
  int 21h       { dos version }
  cmp al, 14h
  jae @IBMOS2   { Jump if >= to 20 }

  mov ax,2B01h
  mov cx,4445h
  mov dx,5351h
  int 21h       { Desqview Installed? }
  cmp al, 255
  jne @DesqView { Jump if AL <> 255 }

  mov ax,160Ah
  int 2Fh       { Windows Install? test1}
  or  ax,ax
  je  @Windows  { If = Jump to Windows }

  mov ax,1600h
  int 2Fh       { Windows Install? test2}
  test ax,17fh
  jnz @Windows

  mov ax,3306h
  int 21h       { NT?}
  cmp bx,3205h
  jz @NT

  {* detekovat DOSemu:
	       /* check if running under Linux DOSEMU */
	       dosmemget(0xFFFF5, 10, buf);
	       buf[8] = 0;
	       if (!strcmp(buf, "02/25/93")) {
		  regs.x.ax = 0;
		  int86(0xE6, &regs, &regs);
		  if (regs.x.ax == 0xAA55) {
		     os_type = OSTYPE_DOSEMU;
		     windows_version = -1;
		     windows_sub_version = -1;
		     i_love_bill = TRUE;     /* (evil chortle) */
		  }

  jmp @Finish   { Nothing found, go to the end }

@IBMOS2:
  mov Ops, Os2  { Set OS Value }
  jmp @Finish

@DesqView:
  mov ops, DesqView  { Set OS Value }
  jmp @Finish

@Windows:
  mov ops, Windows  { Set OS Value }
  jmp @Finish

@NT:
  mov ops, NT  { Set OS Value }
  jmp @Finish

@FINISH:
end;

Procedure GiveTimeSlice;assembler;
asm
  mov   al,Ops
  cmp   al, DesqView
  je    @DVwait
  cmp   al, Windows
  je    @WinOS2wait
  cmp   al, NT
  je    @WinOS2wait
  cmp   al, OS2
  je    @WinOS2wait
  cmp   al, NetWare
  je    @Netwarewait
  cmp   al, DoubleDOS
  je    @DoubleDOSwait

@Doswait:
  int   $28
  jmp   @WaitDone

@DVwait:
  mov   AX, $1000
  int   $15
  jmp   @WaitDone

@DoubleDOSwait:
  mov   AX, $EE01
  int   $21
  jmp   @WaitDone

@WinOS2wait:
  mov   AX, $1680
  int   $2F
  jmp   @WaitDone

@Netwarewait:
  mov   BX, $000A
  int   $7A

@WaitDone:
end;


{€€€€€€€€€€€€€€€€ TYP PROCESORU €€€€€€€€€€€€€€€€}

function WhatCpu:word; assembler;
const
 cpu8086 =1;
 cpu80286=2;
 cpu80386=3;
 cpu80486=4;
asm {function whatcpu}
 mov  dx,cpu8086
 push sp
 pop  ax
 cmp  sp,ax
 jne  @out
 mov  dx,cpu80286
 pushf
 pop  ax
 or   ax,4000h
 push ax
 popf
 pushf
 pop  ax
 test ax,4000h
 je   @out
 mov  dx,cpu80386          {"db 66h" makes '386 extended instruction}
 db   66h; mov bx,sp       {mov ebx,esp}
 db   66h, 83h, 0e4h, 0fch {and esp,fffch}
 db   66h; pushf           {pushfd}
 db   66h; pop ax          {pop eax}
 db   66h; mov cx, ax      {mov ecx,eax}
 db   66h, 35h, 00
 db   00h, 04h, 00         {xor eax,00040000; switchne 18.bit u eax}
 db   66h; push ax         {push eax}
 db   66h; popf            {popfd}
 db   66h; pushf           {pushfd}
 db   66h; pop ax          {pop eax}
 db   66h, 25h,00h
 db   00h, 04h,00h         {and eax,00040000}
 db   66h, 81h,0e1h,00h
 db   00h, 04h,00h         {and ecx,00040000}
 db   66h; cmp ax,cx       {cmp eax,ecx}
 je   @not486
 mov  dx, cpu80486
@not486:
 db   66h; push cx         {push ecx}
 db   66h; popf            {popfd}
 db   66h; mov sp, bx      {mov esp,ebx}
@out:
 mov ax, dx
end;{function whatcpu}


var orig1Bint:procedure;
{$F+,S-,W-}
procedure IgnoreBreak; assembler;
asm
 iret
end;
{$F-,S+}
procedure EnableBreak;
begin
 GetIntVec($1B,@orig1Bint);
 SetIntVec($1B,@orig1Bint);
end;

procedure DisableBreak;
begin
 GetIntVec($1B,@orig1Bint);
 SetIntVec($1B,@IgnoreBreak);
end;

{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='sys';
var result:TError;

procedure UserInit;
 begin
  ops          :=MDOS;
  EventWaitOk  :=true;
  needDos      :=0;
  switchYZ     :=false;
  {$ifdef dosmem}
  if GetMemDos(DelaySeg,pointer(DelayFlag),1) then
  {$else}
  DelaySeg:=$40;
  DelayFlag:=ptr(seg0040,$fa);
  {$endif}
    begin
    EventWaitOk:=TestEventWait;
    exit;
    end;
  result:=_erLowDosMem;
 end;

procedure UserDone;
 begin
  SetPreciseClock(false);
  {$ifdef dosmem}
  FreeMemDos(pointer(DelayFlag),1);
  {$endif}
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.