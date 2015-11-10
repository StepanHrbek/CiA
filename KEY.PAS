{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.32ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Key;
Interface {$i define.inc}
Uses      Chyby;
Function  Init:word;
Procedure Done;

{
Handler klavesnice. Slouzi presnemu zjistovani stisknutych klaves,
vsech krome pause. Chces vedet zda je stisknuty treba levy Ctrl?
Mas to v kPressed[kLCtrl].

Pozn: obcas, velmi ridce, se mi nektere klavesy zasekavaji, zustanou
nastavene i kdyz uz nejsou stisknuty. Pry je to chyba biosu, nevim.
Kazdopadne, pravidelne (tak 50-200x za vterinu) volam kDecPressed,
tim se kazda zaseknuta klavesa nejdele za 1-2 vteriny vypne.
}

var       kHandler:boolean;                 {je na int9 povesen nas handler?}
          kPressed:array[0..255] of boolean;{stisknute klavesy}

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
 kkEnter    =128+28;
 kRCtrl     =128+29;
 kPrnScr1   =128+42;
 kkSlash    =128+53;
 kPrnScr2   =128+55;
 kRAlt      =128+56;
 kHome      =128+71;
 kUp        =128+72;
 kPgUp      =128+73;
 kLeft      =128+75;
 kRight     =128+77;
 kEnd       =128+79;
 kDwn       =128+80;
 kPgDwn     =128+81;
 kInsert    =128+82;
 kDelete    =128+83;
 kMacro     =128+111;


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}

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
     jz @extendedpausestart

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

    @extendedpausestart:
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

var result:integer;

procedure UserInit;
 begin
  kHandler:=false;
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