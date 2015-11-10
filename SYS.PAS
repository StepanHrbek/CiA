{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.10ƒƒƒø
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
FUNCTION MakeLong(hi,lo:word):longint;inline($58/$5a);{pop ax;pop dx}
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
PROCEDURE BiosWrite(st:string);
PROCEDURE BiosWriteln(st:string);


{---------------------------------------------------------------------------
 Klasicke stopky.
 ---------------------------------------------------------------------------}

Type  TStopky = object
                  cas        :longint; {po Start a Stop je tu ubehly cas v ms}
                  ticks      :longint; {po Start a Stop je tu ubehly cas v 'ticich' (asi pet a pul ms)}
                  procedure  Start;
                  function   Stop:longint;
                  procedure  Cont;
                end;


{---------------------------------------------------------------------------
 Presne mereni casu (presnejsi nez stopky).
 ---------------------------------------------------------------------------}

{jednoduchy interface}
PROCEDURE DelayStart(mikrosekund:longint);
FUNCTION  DelayEnd:boolean;

{interface pouze pro specialni ucely}
Type      PDelayRec = ^TDelayRec;
          TDelayRec = record
                       flag:boolean;
                       {$ifdef dpmi}
                       seg:word;
                       {$endif}
                      end;
Var       DelayRec:PDelayRec;{struktura na mereni casu,
                          staci mi jedna globalni, ta AT sluzba stejne asi neni reentrantni,
                          naalokuje se automaticky, neodalokovava se}
FUNCTION  DelayFlag(var p:PDelayRec;mikrosekund:longint):boolean;


{---------------------------------------------------------------------------
 DTA - disk transfer address
 ---------------------------------------------------------------------------}

PROCEDURE StoreDTA;
PROCEDURE RestoreDTA;



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


FUNCTION Long2Word(n:longint):word;
begin
 if n>65535 then Long2Word:=65535 else
 if n<0 then Long2Word:=0 else Long2Word:=n;
end;

FUNCTION Long2Int(n:longint):integer;
begin
 if n>32767 then Long2Int:=32767 else
 if n<-32768 then Long2Int:=-32768 else Long2Int:=n;
end;

FUNCTION Bounded(base,bot,top:longint):longint;
begin
 if base<bot then base:=bot else
 if base>top then base:=top;
 Bounded:=base;
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


PROCEDURE BiosWrite(st:string);assembler;
 var p:pointer absolute st;
 asm
     push bp
     mov ax,300h;xor bx,bx;int 10h
     mov ax,1301h;mov bx,7;xor cx,cx
     les bp,p;mov cl,[es:bp];inc bp
     int 10h
     pop bp
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


{€€€€€€€€€€€€€€€€ STOPKY €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Je-li p nil, naalokuje ho, jinak pouzije tento.
 Za zadany pocet mikrosekund nastavi flag.
 Vraci jestli je sluzba podporovana.
 ---------------------------------------------------------------------------}
{$ifndef dpmi}
FUNCTION DelayFlag(var p:pdelayrec;mikrosekund:longint):boolean;
begin
 DelayFlag:=false;
 {naalokuje flag}
 if p=nil then
  if not GetMem(pointer(p),sizeof(p^)) then exit;
 p^.flag:=false;
 {vola at sluzbu}
 asm
     mov ax,8300h
     les bx,p
     les bx,[es:bx]
     mov dx,word ptr mikrosekund
     mov cx,word ptr mikrosekund+2
     int 15h
 end;
 DelayFlag:=true
end;
{$else}
FUNCTION DelayFlag(var p:pdelayrec;mikrosekund:longint):boolean;
var   segment:word;
      RealModeRegs:dpmiRealCallRegs;
begin
 DelayFlag:=false;
 {naalokuje flag}
 if p=nil then begin
  if not GetMemDos(segment,pointer(p),sizeof(p^)) then exit;
  p^.seg:=segment;
  end;
 p^.flag:=false;
 {vola at sluzbu}
 with RealModeRegs do begin
  clr;
  rEAX:=$8300;
  rES:=p^.seg;
  rEBX:=word(p);
  rEDX:=LoWord(mikrosekund);
  rECX:=HiWord(mikrosekund);
  end;
 if midasDumbError(dpmiRealModeInt($15,@RealModeRegs))=0
  then DelayFlag:=true
  else p^.flag:=true;
end;
{$endif}

{---------------------------------------------------------------------------
 Za zadany pocet mikrosekund od DelayStart bude DelayEnd vracet true.
 Pouziva globalni promennou DelayRec.
 ---------------------------------------------------------------------------}
PROCEDURE DelayStart(mikrosekund:longint);
begin
 DelayFlag(DelayRec,mikrosekund);
end;

FUNCTION DelayEnd:boolean;
begin
 DelayEnd:=DelayRec^.flag;
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
 Cas:=round(ticks*5.4925493);
 Stop:=Cas;
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


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const
 inited:boolean=false;

function Init:word;
 begin
  Init:=erOk;
  if not inited then begin
   DelayRec     :=nil;
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