{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Key;
Interface {$i define.inc}
Uses      Chyby{$ifdef dpmi},Memo{$endif};
Function  Init:TError;
Procedure Done;

{define printkey}

{
---------------------------------------------------------------------------
                     Klavesnice - low level
---------------------------------------------------------------------------

KONSTANTY kXxxx
 Kazda klavesa vcetne shiftu, pause apod pri stisku generuje sekvenci tzv.
 scan kodu. CiA sve uzivatele od tohoto naprosteho silenstvi odfiltrovava
 a kazde klavese vcetne pause prirazuje jeden kod deklarovany konstantou kXxx.

HANDLER KLAVESNICE
 Zapina a vypina se procedurou kSetHandler.
 Slouzi presnemu zjistovani stisknutych klaves, vsech vcetne pause.
 Chces vedet zda je stisknuty treba levy Ctrl?
 Pokud je zapnuty handler, mas to v kPressed[kLCtrl].

CTENI Z KLAVESNICE
 Fce pro pohodlny vstup z klavesnice je ReadEvent v unite Sys.
 (zdrojak GuessCode ukazuje ze za jejim pohodlim je skryt velky hacking)

 Pokud pracujes s obrazovkou, misto ReadEvent pouzijes obecnejsi
 T(Scrol)Screen.GetEvent, ktery zahrnuje i udalosti od tlacitek mysi.

 Priklady schopnosti teto unity jsou pr_key1.pas a pr_key2.pas.

ZASEKAVANI KLAVES
 Obcas, velmi ridce, se na nekterych starych pocitacich mohou nektere klavesy
 zasekavat, zustanou nastavene i kdyz uz nejsou stisknuty. Pry je to chyba
 biosu, nevim.
 Kazdopadne lze pouzit jednoduchy trik: pri pravidelnem volani kIncPressed
 je kazda stiskla klavesa po chvili (po zhruba 100 zavolanich) automaticky
 vypnuta. Pokud v unite scrol nastavis unlockLockedKeys:=true,
 volani kIncPressed bude automaticke (treba 70x za sekundu, podle monitoru).
 (Nevyhoda je, ze kdyz umyslne dlouho drzis stisklou klavesu,
 i ji to automaticky za chvili vypne.)
}

var       kHandler:boolean;                 {je na int9 povesen nas handler?}
          kPressed:array[0..255] of boolean;{stisknute klavesy}
          kDirty:boolean;                   {nastavi se pri kazdem eventu}

procedure kSetHandler(b:boolean);           {zavesi/odpoji nas handler}
procedure kIncPressed;

const
 kExtended  =224;
 kPause     =225;
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
 kWin1      =128+91;
 kWin2      =128+92;
 kWin3      =128+93;
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

const pressed=150;{tento bajt (=true) se zapise do pole pri stisku,
                   pri kazdem kIncPressed se zapsany bajt zvysi,
                   zastavi se az na nule (=false)}
      pressedforever=1;{tento bajt (=true) se zapise do pole pri stisku pause,
                   pri kIncPressed zustava porad true}

PROCEDURE kSetHandler(b:boolean);assembler;
 asm
     cmp b,false
     je @odpoj
{jmp @odpoj{}
   @ZAVES:
     cmp kHandler,false
     jnz @end
     {$ifdef dpmi}
     db 66h;cmp word ptr SwapSize,0
     jnz  @end
     {$endif}
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
     jz @noskip
     dec skip              {po pause ignoruje 2 kody}
     jmp @aborthandler
    @noskip:
     cmp waitforextended,false
     jne @extendedsecond

    @startseq:
     cmp al,kPause
     jz @pausestart
     cmp al,kExtended
     jz @extendedstart

    @singlestart:
     test al,128
     jz @singleon
     @singleoff:
     and al,127
     mov ah,0
     jmp @write
     @singleon:
     cmp byte ptr [kPressed+kPause],false
     jne @pauseend
     mov ah,pressed
     jmp @write

    @extendedstart:
     mov waitforextended,true

     jmp @endhandler
     cmp byte ptr [kPressed+kPause],false
     je @endhandler
     jmp @aborthandler

    @extendedsecond:
     mov waitforextended,false
     cmp byte ptr [kPressed+kPause],false
     jne @pauseend
     test al,128
     jz @extendedon
     @extendedoff:
     mov ah,0
     jmp @write
     @extendedon:
     add al,128
     mov ah,pressed
     jmp @write

    @pausestart:{
Welcome to hell. If you press this key while either of the the control keys
are being held down, it will behave like extended key 70, at all other times
it will send the following bytes: (225, 29, 69, 225, 157, 197). Holding the
key down does not result in autorepeat. Taking your finger off the key does
not send any extra bytes, they appear to be sent after the "key down" bytes
when you first press the key. Notice that 225 isn't 224, so our normal
extended character handler will not take care of this. My personal theory is
that while a scan code of 224 (E0h) means there is 1 more character
following, a scan code of 225 (E1h) means there are *2* more following. I've
seen a number of keyboard handler libraries and they all seem to overlook
this key. So why not be the first kid on your block to have a keyboard
handler which properly supports the Pause/Break key? CHECK IT OUT!!}
     mov byte ptr [kPressed+kPause],pressedforever {kPressed[kPause]:=true}
     mov skip,2            {a nasledujici 2 kody ignoruje}
     jmp @aborthandler

    @pauseend:             {prvni stisk po pause...pouze rusi pause, nic vic}
     mov byte ptr [kPressed+kPause],false
     jmp @aborthandler

    @write:                {zaneseni stisku/uvolneni do kPressed}
     mov bl,al
     mov bh,0
     lea si,kPressed
     mov [si+bx],ah

    @endhandler:           {konec s volanim puvodniho}
     POPA
     call old9
     POP DS
     iret

    @aborthandler:         {konec bez volani puvodniho}
     mov al,20h
     out 20h,al
     POPA
     POPF
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

PROCEDURE kIncPressed;assembler;
 asm
     lea di,kPressed-1
     mov cx,256
     @1:
     inc di
     test byte ptr [di],254
     loope @1
     jcxz @2
     inc byte ptr [di]
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