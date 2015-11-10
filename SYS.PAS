{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.32ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Sys;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos {$ifdef dpmi},Dpmi{$endif};
Function  Init:word;
Procedure Done;


{---------------------------------------------------------------------------
 Uzitecna makra.
 ---------------------------------------------------------------------------}

FUNCTION MinW(x,y:word):word;inline($58/$5b/$3b/$c3/$72/$01/$93);{pop ax;pop bx;cmp ax,bx;jb +1;xchg ax,bx}
FUNCTION MaxW(x,y:word):word;inline($58/$5b/$3b/$c3/$77/$01/$93);{pop ax;pop bx;cmp ax,bx;ja +1;xchg ax,bx}
FUNCTION MinI(x,y:integer):integer;inline($58/$5b/$3b/$c3/$7e/$01/$93);{pop ax;pop bx;cmp ax,bx;jle +1;xchg ax,bx}
FUNCTION MaxI(x,y:integer):integer;inline($58/$5b/$3b/$d8/$7e/$01/$93);{pop ax;pop bx;cmp bx,ax;jle +1;xchg ax,bx}
FUNCTION MinL(x,y:longint):integer;inline($66/$58/$66/$5b/$66/$3b/$c3/$7e/$02/$66/$93);{jako integery, ale s db 66}
FUNCTION MaxL(x,y:longint):integer;inline($66/$58/$66/$5b/$66/$3b/$d8/$7e/$02/$66/$93);
FUNCTION HiWord(l:longint):word;inline($58/$58);{pop ax;pop ax}
FUNCTION LoWord(l:longint):word;inline($58/$5b);{pop ax;pop bx}
FUNCTION HiInt(l:longint):integer;inline($58/$58);{pop ax;pop ax}
FUNCTION LoInt(l:longint):integer;inline($58/$5b);{pop ax;pop bx}
FUNCTION HiByte(w:word):byte;inline($58/$8a/$c4);{pop ax;mov al,ah}
FUNCTION LoByte(w:word):byte;inline($58);{pop ax}
FUNCTION MakeLong(hi,lo:word):longint;inline($58/$5a);{pop ax;pop dx}
FUNCTION MakeWord(hi,lo:byte):word;inline($58/$5a/$8a/$e2);{pop ax;pop dx;mov ah,dl}
FUNCTION MakeInt(hi,lo:byte):integer;inline($58/$5a/$8a/$e2);{pop ax;pop dx;mov ah,dl}
FUNCTION Long2Word(n:longint):word;
FUNCTION Long2Int(n:longint):integer;
FUNCTION Bounded(base,bot,top:longint):longint;

{if length(st)=1 then vrat st[1] else vrat #0}
FUNCTION Str2Char(st:string):char;
 inline($5f   /$07   /$26/$8b/$05   /$3c/$01 /$b0/$00 /$75/$02/$8a/$c4);
       {pop di;pop es;mov ax,[es:di];cmp al,1;mov al,0;jnz +2;mov al,ah}

{bezpecnostni opatreni pri nahlem ukonceni programu}
PROCEDURE FixInts;
 inline($b0/$0  /$e6/$21   /$b0/$20   /$e6/$20   /$fb);
       {mov al,0;out 21h,al;mov al,20h;out 20h,al;sti}

{---------------------------------------------------------------------------
 Klavesnice.
 ---------------------------------------------------------------------------}

FUNCTION  KeyPressed:boolean; inline($b4/$0b/$cd/$21);{mov ah,0bh;int 21h}
FUNCTION  ReadKey:char; inline($b4/$08/$cd/$21);{mov ah,8;int 21h}
PROCEDURE WaitKey; inline($b8/$0c08/$cd/$21);{mov ax,0c08h;int 21h}
FUNCTION  AskKey(list:string):char;
PROCEDURE FlushKey;
FUNCTION  GuessKey:char;


{---------------------------------------------------------------------------
 Kurzor.
 ---------------------------------------------------------------------------}

PROCEDURE BiosGotoXY(x,y:byte);
FUNCTION  BiosGetXY:word;


{---------------------------------------------------------------------------
 Klasicke stopky.
 ---------------------------------------------------------------------------}

Type  TStopky = object
                  cas        :longint; {po Start a Stop je tu ubehly cas v ms}
                  ticks      :longint; {po Start a Stop je tu ubehly cas v 'ticich' (asi 55 ms)}
                  procedure  Start;
                  function   LookAt:longint;
                  function   Stop:longint;
                  procedure  Cont;
                end;


{---------------------------------------------------------------------------
 Presne mereni casu (presnejsi nez stopky).
 ---------------------------------------------------------------------------}

var       EventWaitOk:boolean; {funguji nasledujici funkce?}

FUNCTION  DelayStart(mikrosekund:longint):boolean;
FUNCTION  DelayEnd:boolean;


{---------------------------------------------------------------------------
 DTA - disk transfer address
 ---------------------------------------------------------------------------}

PROCEDURE StoreDTA;
PROCEDURE RestoreDTA;


{---------------------------------------------------------------------------
 Operacni system / Timeslice
 ---------------------------------------------------------------------------}

Const
  MDOS      =0;
  OS2       =1;
  Windows   =2;
  DesqView  =3;
  NetWare   =4;
  DoubleDOS =5;

  os:array[0..5] of pchar=('DOS','OS/2','Windows','DesqView','NetWare','DoubleDos');

Var
  Ops            : Byte;    { Operating System OS/2/DOS/WIN/DV}

PROCEDURE CheckOS;
FUNCTION  DosVersionMaj:byte; inline($b4/$30/$cd/$21);{mov ah,30h;int 21h}
FUNCTION  DosVersionMin:byte; inline($b4/$30/$cd/$21/$8a/$c4);{mov ah,30h;int 21h;mov al,ah}

PROCEDURE GiveTimeSlice;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


FUNCTION Bounded(base,bot,top:longint):longint;assembler;
 asm
  db 66h;mov ax,word ptr base
  db 66h;mov bx,word ptr bot;db 66h;cmp ax,bx;jle @bx
  db 66h;mov bx,word ptr top;db 66h;cmp bx,ax;jle @bx
  mov dx,word ptr base+2
  jmp @end
  @bx:
  mov ax,bx
  db 66h;shr bx,16
  mov dx,bx
  @end:
 end;
{o 49 bajtu delsi a mnohem pomalejsi ekvivalent:
begin
 if base<bot then base:=bot else
 if base>top then base:=top;
 Bounded:=base;
end;
to abys vedel co stoji "slusnost" :)}

FUNCTION Long2Word(n:longint):word;
begin
 Long2Word:=Bounded(n,0,65535);
end;

FUNCTION Long2Int(n:longint):integer;
begin
 Long2Int:=Bounded(n,-32768,32767);
end;


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
 Vymaze buffer se stiknutymi klavesami.
 ---------------------------------------------------------------------------}
PROCEDURE FlushKey;
begin
 {slusnaci by udelali "while keypressed do readkey;"}
 memw[seg0040:$1c]:=memw[seg0040:$1a];
end;


{---------------------------------------------------------------------------
 Je-li keypressed (si musis overit sam), hada pristi znak.
 Extended znak (#0,znak) je interpretovan jako 128+znak.
 ---------------------------------------------------------------------------}
FUNCTION  GuessKey:char;
var   c:byte;
begin
 c:=mem[seg0040:memw[seg0040:$1a]];
 if c=224 then GuessKey:=chr(128+mem[seg0040:memw[seg0040:$1a]+1])
          else GuessKey:=chr(c);
end;


{€€€€€€€€€€€€€€€€ KURZOR €€€€€€€€€€€€€€€€}

{---------------------------------------------------------------------------
 Presune kurzor do souradnic x,y. Levy horni roh je v 0,0.
 ---------------------------------------------------------------------------}
PROCEDURE BiosGotoXY(x,y:byte);assembler;
 asm
     mov dl,x;mov dh,y
     mov ah,2;mov bh,0
     int 10h
 end;

{---------------------------------------------------------------------------
 Vraci souradnice kurzoru. Levy horni roh je v 0,0.
 Lo(BiosGetXY) je souradnice X, Hi(BiosGetXY) je Y.
 ---------------------------------------------------------------------------}
FUNCTION  BiosGetXY:word;assembler;
 asm
     mov ah,3;mov bh,0
     int 10h
     xchg ax,dx
 end;


{€€€€€€€€€€€€€€€€ STOPKY €€€€€€€€€€€€€€€€}

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
    clr;
    rEAX:=$8301;
    erCheck(dpmiRealModeInt($15,@RealModeRegs));
    {start new wait}
    clr;
    rEAX:=$8300;
    rES:=DelaySeg;
    rEBX:=PtrRec(DelayFlag).Ofs;
    rEDX:=LoWord(mikrosekund);
    rECX:=HiWord(mikrosekund);
    erCheck(dpmiRealModeInt($15,@RealModeRegs));
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
     if not dumb then erMsg('event wait busy');
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


{---------------------------------------------------------------------------
 Zacne merit cas.
 ---------------------------------------------------------------------------}
Procedure TStopky.Start;
begin
 ticks:=meml[seg0040:$6c];
end;

{---------------------------------------------------------------------------
 Zastavi mereni casu. Ubehlou dobu vraci v promenne Cas i jako result.
 ---------------------------------------------------------------------------}
Function TStopky.Stop:longint;
begin
 ticks:=meml[seg0040:$6c]-ticks;
 Cas:=round(ticks*54.925493);
 Stop:=Cas;
end;

{---------------------------------------------------------------------------
 Koukne se na bezici stopky a vrati cas v ms.
 ---------------------------------------------------------------------------}
Function TStopky.LookAt:longint;
begin
 LookAt:=round((meml[seg0040:$6c]-ticks)*54.925493);
end;

{---------------------------------------------------------------------------
 Pokracuje v mereni casu.
 ---------------------------------------------------------------------------}
Procedure TStopky.Cont;
begin
 ticks:=meml[seg0040:$6c]-ticks;
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


{€€€€€€€€€€€€€€€€ TIMESLICE €€€€€€€€€€€€€€€€}

Procedure CheckOS;assembler;
{ Currently Supports DesqView, Microsoft Windows and IBM's OS/2 }
asm
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
  and al,7fh
  or  al,al
  jne @Windows

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

@FINISH:
end;

Procedure GiveTimeSlice;assembler;
asm
  mov   al,Ops
  cmp   al, DesqView
  je    @DVwait
  cmp   al, Windows
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


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

var result:integer;

procedure UserInit;
 begin
  ops          :=MDOS;
  EventWaitOk  :=true;
  if GetMemDos(DelaySeg,pointer(DelayFlag),1) then begin
    EventWaitOk:=TestEventWait;
    exit;
    end;
  result:=erLowMem;
 end;

procedure UserDone;
 begin
  FreeMemDos(pointer(DelayFlag),1);
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.