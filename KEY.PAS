{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Key;
Interface {$i define.inc}
Uses      Chyby;
Function  Init:TError;
Procedure Done;

{define printkey}

{
Handler klavesnice. Slouzi presnemu zjistovani stisknutych klaves,
vsech krome pause. Chces vedet zda je stisknuty treba levy Ctrl?
Mas to v kPressed[kLCtrl].

Pozn: obcas, velmi ridce, se mi nektere klavesy zasekavaji, zustanou
nastavene i kdyz uz nejsou stisknuty. Pry je to chyba biosu, nevim.
Kazdopadne, pravidelne (tak 50-200x za vterinu) volam kDecPressed,
tim se kazda zaseknuta klavesa nejdele za 1-2 vteriny vypne.
Nevyhoda je, ze kdyz umyslne dlouho drzis stisklou klavesu,
automaticky ji to za chvili vypne. Takze se rozhodni a volani
kDecPressed pripadne odstran ze scrol.pas.

Pozn: vim o jednom pocitaci, na kterem kdyz behem nebo i kdykoliv po pouziti
tohoto handleru stisknes Alt, vytuhnou Windows... nechapu
}

var       kHandler:boolean;                 {je na int9 povesen nas handler?}
          kPressed:array[0..255] of boolean;{stisknute klavesy}
          kDirty:boolean;                   {nastavi se pri kazdem eventu}

procedure kSetHandler(b:boolean);           {zavesi/odpoji nas handler}
procedure kDecPressed;

const
 kExtended  =224;
 kExtendedpause=225;
 kEsc       =1;                             {kody vsech beznych klaves}
 k1         =2;
 k2         =3;
 k3         =4;
 k4         =5;
 k5         =6;
 k6         =7;
 k7         =8;
 k8         =9;
 k9         =10;
 k0         =11;
 kMinus     =12;
 kPlus      =13;
 kBackspace =14;
 kTab       =15;
 kQ         =16;
 kW         =17;
 kE         =18;
 kR         =19;
 kT         =20;
 kY         =21;
 kU         =22;
 kI         =23;
 kO         =24;
 kP         =25;
 kLZavorka  =26;
 kRZavorka  =27;
 kEnter     =28;
 kLCtrl     =29;
 kA         =30;
 kS         =31;
 kD         =32;
 kF         =33;
 kG         =34;
 kH         =35;
 kJ         =36;
 kK         =37;
 kL         =38;
 kStrednik  =39;
 kApostrof  =40;
 kTilda     =41;
 kLShift    =42;
 kBackslash =43;
 kZ         =44;
 kX         =45;
 kC         =46;
 kV         =47;
 kB         =48;
 kN         =49;
 kM         =50;
 kCarka     =51;
 kTecka     =52;
 kSlash     =53;
 kRShift    =54;
 kkMul      =55;
 kLAlt      =56;
 kSpace     =57;
 kCaps      =58;
 kF1        =59;
 kF2        =60;
 kF3        =61;
 kF4        =62;
 kF5        =63;
 kF6        =64;
 kF7        =65;
 kF8        =66;
 kF9        =67;
 kF10       =68;
 kkNum      =69;
 kScrol     =70;
 kk7        =71;
 kk8        =72;
 kk9        =73;
 kkMinus    =74;
 kk4        =75;
 kk5        =76;
 kk6        =77;
 kkPlus     =78;
 kk1        =79;
 kk2        =80;
 kk3        =81;
 kk0        =82;
 kkTecka    =83;
 kF11       =87;
 kF12       =88;
 kWin1      =91;
 kWin2      =92;
 kWin3      =93;
 kkEnter    =128+28;
 kRCtrl     =128+29;
 kkSlash    =128+53;
 kPrintScr  =128+55;
 kRAlt      =128+56;
 kHome      =128+71;
 kUp        =128+72;
 kPgUp      =128+73;
 kLeft      =128+75;
 kRight     =128+77;
 kEnd       =128+79;
 kDown      =128+80;
 kPgDwn     =128+81;
 kInsert    =128+82;
 kDelete    =128+83;
 kMacro     =128+111;

function  num:boolean;   {Indikator Num locku}
function  caps:boolean;  {Indikator CAPS locku}
function  scroll:boolean;{Indikator Scroll locku}

function  ReadKeyboardLocks:byte;
procedure SetKeyboardLocks(n:byte);

{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


function num:boolean;
begin  num:=boolean(mem[seg0040:$17] and 32) end; {num}

function caps:boolean;
begin  caps:=boolean(mem[seg0040:$17] and 64) end; {caps}

function scroll:boolean;
begin  scroll:=boolean(mem[seg0040:$17] and 16) end; {scroll}

function ReadKeyboardLocks:byte; assembler;
{Precte stav 'locku'. Vrati nasledujici cislo:
 bit:     vyznam:
  0  (&1) SCROLL Lock
  1  (&2) NUMeric Lock
  2  (&4) CAPitalS Lock}
asm {ReadKeyboardLocks}
 mov  ah,2
 int  16h
 shr  al,4
 and  al,7
end;{ReadKeyboardLocks}

procedure SetKeyboardLocks(n:byte); assembler;
{Rozsviti prislusnou LEDku na klavesnici.
 Zadejte nulu, chcete-li, aby vsechny LEDky zhasly.
 Prictete k cislu jednicku, chcete-li, aby se rozsvitil SCROLL Lock.
 Prictete k cislu dvojku, chcete-li, aby se rozsvitil NUM Lock.
 Prictete k cislu ctyrku, chcete-li, aby se rozsvitil CAPS Lock.}
asm {SetKeyboardLocks}
 mov  dx,064h
 in   al,dx
 mov  al,0EDh
 out  dx,al
 mov  cx,1000h
@wait:
 nop
 loop @wait
 mov  al,n
 and  al,7
 out  dx,al
 shl  al,4
 push es
 xor  dx,dx
 mov  es,dx
 mov  di,0417h
 mov  ah,es:[di]
 and  ah,10001111b
 add  al,ah
 stosb
 pop  es
end;{SetKeyboardLocks}


{$ifdef printkey}
procedure debugprint(b:byte);
begin
 write(b,',');
end;
{$endif}

var   waitforextended:boolean;
      skip:boolean;
      old9:pointer;

const pressed=100;{tento bajt (=true) se zapise do pole pri stisku,
                   pri kazdem kDecPressed se zapsany bajt snizi,
                   zastavi se az na nule (=false)}

PROCEDURE kSetHandler(b:boolean);assembler;
 asm
     cmp b,false
     je @odpoj

   @ZAVES:
     cmp kHandler,false
     jnz @end
     {set vars}
     mov waitforextended,false
     mov skip,0
     {get old}
     mov ax,3509h
     int 21h
     mov old9.word[0],bx
     mov old9.word[2],es
     {set new}
     mov ax,2509h
     PUSH DS
     push cs
     pop ds
     lea dx,@handler
     int 21h
     POP DS
     mov kHandler,true
     jmp @clrpressed

   @ODPOJ:
     cmp kHandler,false
     jz @end
     {set old}
     mov ax,2509h
     PUSH DS
     lds dx,old9
     int 21h
     POP DS
     mov kHandler,false
     jmp @clrpressed

   @HANDLER:
     PUSH DS
     push seg @data
     pop ds
     mov kDirty,true
     PUSHF
     PUSHA

     in al,60h
{$ifdef printkey}
     pusha
     push ax
     call debugprint
     popa
{$endif}
     cmp skip,0
     jz @normal
     dec skip
     jmp @endhandler

    @normal:
     cmp waitforextended,false
     jne @extendedsecond

    @startseq:
     cmp al,kExtended
     jz @extendedstart
     cmp al,kExtendedpause
     jz @pausestart

    @singlestart:
     test al,128
     jz @singleon
     @singleoff:
     and al,127
     mov ah,0
     jmp @write
     @singleon:
     mov ah,pressed
     jmp @write

    @extendedstart:
     mov waitforextended,true
     jmp @endhandler

    @pausestart:
     mov skip,2            {klavesu pause ignoruje}
     jmp @endhandler

    @extendedsecond:
     mov waitforextended,false
     test al,128
     jz @extendedon
     @extendedoff:
     mov ah,0
     jmp @write
     @extendedon:
     add al,128
     mov ah,pressed

    @write:
     mov bl,al
     mov bh,0
     lea si,kPressed
     mov [si+bx],ah

    @endhandler:
     POPA
     call old9
     POP DS
     iret

   @ClrPressed:
     push ds
     pop es
     lea di,kPressed
     mov cx,128
     xor ax,ax
     rep stosw

   @END:
 end;

PROCEDURE kDecPressed;assembler;
 asm
     lea di,kPressed-1
     xor ax,ax
     mov cx,256
     @1:
     inc di
     cmp [di],al
     loope @1
     jcxz @2
     dec byte ptr [di]
     jmp @1
     @2:
 end;

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='key';
var result:TError;

procedure UserInit;
 begin
  kHandler:=false;
  kDirty:=false;
  fillchar(kPressed,sizeof(kPressed),0);
 end;

procedure UserDone;
 begin
  kSetHandler(false);
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.