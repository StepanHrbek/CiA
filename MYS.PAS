{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Mys;
Interface {$i define.inc}
Uses      Chyby,Memo, Stringy,Sys;
Function  Init:TError;
Procedure Done;

{
---------------------------------------------------------------------------
                         Low-level prace s mysi
---------------------------------------------------------------------------

Pokud budes pracovat s obrazovkou T(Scrol)Screen, pouzijes pro snadnou
praci s mysi jeji metody mouseXxxx.

Ty jsou implementovany s vyuzitim zdejsich low-level rutin, ktere jinak
nepotrebujes.


---------------------------------------------------------------------------
                  Technicky komentar k mysi v CiA 2.00
---------------------------------------------------------------------------

ZMENA IMPLEMENTACE
 Interface mys.pas zustava zachovan, implementace ale prodelala velke zmeny.
 Zatimco drive jsem spolehal na inteligenci driveru mysi, predaval mu
 pozadovanou senzitivitu, meze apod a odebiral souradnice v pixelech,
 po seznameni s tragedii zvanou DOSova mys ve Windows NT/2000
 (z desitek mysich sluzeb Microsoft vetsinu zcela ignoruje)
 bylo nutne pristup zcela prehodnotit.
 Soucasna implementace vyuziva extremne malo sluzeb,
 pta se pouze na relativni zmenu souradnic v mickeyich;
 prepocet na pixely, zarazeni o meze apod uz provadi sama.

MOUSEHANDLER
 Nic se nemeni ani na tom, ze lze pozadat o pouziti mousehandleru
 (veskery vyznam handleru je v tom, ze implementace pak nemusi driver pollovat
  cim usetri zlomek casu, driver sam zavola handler kdyz se mys hne),
 interne je ale momentalne mousehandler mimo provoz, zakomentovan.
 Na funkcnost to nema zadny vliv.

DOSEMU
 Nekolik funkci je nyni zbytecnych a zustava jen kvuli zpetne kompatibilite,
 stale sem lze dosadit starsi verzi mys.pas.
 Vyznam starsi verze je pouze v optimalni spolupraci s DOSem bezicim
 v okne, napriklad s DOSemu pod X Windows; poloha mysi v okne presne odpovidala
 poloze systemove mysi a nedochazelo k mateni tim, ze by se kazda pohybovala
 jinak rychle (dosahnout tehoz s novou implementaci je obtizne).
}

const     {mXXXX - mouse buttons, kody tlacitek vracene vzdy v parametru Z}
          mLeft           = 1;
          mRight          = 2;
          mCenter         = 4;

          {maXXXX - mouse actions vracene fci RescanPress}
          maLeftPressed   = 2;
          maLeftReleased  = 4;
          maRightPressed  = 8;
          maRightReleased =16;
          maCenterPressed =32;
          maCenterReleased=64;

var       mouseButtons :byte;   {pocet tlacitek mysi, 0=neni mys}
          mouseDirty   :boolean;{nastavi se pri kazdem eventu}
const     mouseHandler :boolean=false;{je na mysi povesen nas handler?}

PROCEDURE mouseGet(var x,y:integer;var z:word);
PROCEDURE mouseGetPos(var x,y:integer);
FUNCTION  mouseGetX:integer;
FUNCTION  mouseGetY:integer;
FUNCTION  mouseGetZ:word;
PROCEDURE mouseGetChange(var x,y:integer);
PROCEDURE mouseSetPos(x,y:integer);
PROCEDURE mouseSetRange(x1,y1,x2,y2:integer);
PROCEDURE mouseSetSpeed(x,y:real);
FUNCTION  mouseRescanPress(var x,y:integer;var z,actions:word):boolean;
PROCEDURE mouseSetJump(x,y:word);
PROCEDURE mouseSetHandler(b:boolean);


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


const MIC=50;{tolikrat jemnejsi jsou nase mickeye nez driverovy}
             {zjemneni zabrani cukani sipky pri serizovani rychlosti apod}

var   {mickey coords}
      rngMickeyX1  :longint;{pozadovany rozsah prepocteny do mickeys}
      rngMickeyY1  :longint;
      rngMickeyX2  :longint;
      rngMickeyY2  :longint;
      nowMickeyX   :longint;{aktualni pozice mysi a stav tlacitek}
      nowMickeyY   :longint;
      nowZ         :word;
      pressMickeyX :longint;{posledni zachyceny stisk/uvolneni}
      pressMickeyY :longint;
      pressZ       :word;
      pressActions :word;   {jake konkretni akce se staly}
      {conversion}
      speedX       :real;   {mouseX=mickeyX*speedX}
      speedY       :real;
      {user coords}
      rngUserX1    :word;   {pozadovany rozsah}
      rngUserY1    :word;
      rngUserX2    :word;
      rngUserY2    :word;
      {getChange}
      changeX      :integer;
      changeY      :integer;

{---------------------------------------------------------------------------
 Inicializuje mys. Nutno provest jako prvni vec s mysi.
 ---------------------------------------------------------------------------}
procedure mouseInit;assembler;
 asm
     push false
     call mouseSetHandler

     xor ax,ax;int 33h
     inc ax;jnz @nomouse

     cmp bl,2;jz @dve
     cmp bl,0ffh;jz @dve
     mov mouseButtons,3
     jmp @end
     @dve:
     mov mouseButtons,2
     jmp @end
     @nomouse:
     mov mouseButtons,0

     @end:
 end;

{---------------------------------------------------------------------------
 Posune interni pozici o tolik mickeys, zarazi se pritom o range.
 ---------------------------------------------------------------------------}
procedure move(deltaX,deltaY:integer);
begin
 {ignoruje prilis prudky pohyby (=chyby myho driveru):}
 if abs(deltaX)+abs(deltaY)>500 then exit;

 nowMickeyX:=bounded(nowMickeyX+longint(deltaX)*MIC,rngMickeyX1,rngMickeyX2);
 nowMickeyY:=bounded(nowMickeyY+longint(deltaY)*MIC,rngMickeyY1,rngMickeyY2);
 if (deltaX<>0) or (deltaY<>0) then mouseDirty:=true;
end;

{---------------------------------------------------------------------------
 Vraci momentalni polohu a stav tlacitek mysi.
 ---------------------------------------------------------------------------}
PROCEDURE mouseGet(var x,y:integer;var z:word);
begin
 if (not mouseHandler) and (mouseButtons>0) then
   asm
     mov ax,0bh;int 33h
     add changex,cx;add changey,dx
     push cx;push dx;call move

     mov ax,3;int 33h
     mov nowZ,bx
   end;
 x:=round(nowMickeyX*speedX);
 y:=round(nowMickeyY*speedY);
 z:=nowZ;
end;

{---------------------------------------------------------------------------
 Vraci momentalni stav tlacitek.
 Bit 0 - leve stisknute
     1 - prave stisknute
     2 - prostredni stisknute
 ---------------------------------------------------------------------------}
FUNCTION mouseGetZ:word;
var x,y:integer;
    z:word;
begin;
 mouseGet(x,y,z);
 mouseGetZ:=z;
end;

{---------------------------------------------------------------------------
 Vraci momentalni polohu mysi.
 ---------------------------------------------------------------------------}
PROCEDURE mouseGetPos(var x,y:integer);
var z:word;
begin;
 mouseGet(x,y,z);
end;

{---------------------------------------------------------------------------
 Vraci x-ovou souradnici mysi.
 ---------------------------------------------------------------------------}
FUNCTION mouseGetX:integer;
var x,y:integer;
    z:word;
begin;
 mouseGet(x,y,z);
 mouseGetX:=x
end;

{---------------------------------------------------------------------------
 Vraci y-ovou souradnici mysi.
 ---------------------------------------------------------------------------}
FUNCTION mouseGetY:integer;
var x,y:integer;
    z:word;
begin;
 mouseGet(x,y,z);
 mouseGetY:=y
end;

{---------------------------------------------------------------------------
 Vraci relativni zmenu polohy sipky od posledniho volani teto funkce.
 Jednotkou je mickey.
 ---------------------------------------------------------------------------}
PROCEDURE mouseGetChange(var x,y:integer);assembler;
 asm
     xor cx,cx;xor dx,dx
     cmp mouseButtons,0;jz @end
     mov ax,0bh;int 33h
     pusha
      push cx;push dx;call move
     popa
     @end:
     {pricte naakumulovanej change}       {vrati vysledek}
     xor ax,ax;xchg ax,changex;add ax,cx; les di,x;mov [es:di],ax
     xor ax,ax;xchg ax,changey;add ax,dx; les di,y;mov [es:di],ax
 end;

{---------------------------------------------------------------------------
 Nastavi polohu sipky.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetPos(x,y:integer);
begin
 nowMickeyX:=round(x/speedX);
 nowMickeyY:=round(y/speedY);
end;

{---------------------------------------------------------------------------
 Nastavi rozsah pohybu sipky.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetRange(x1,y1,x2,y2:integer);
begin
 rngUserX1:=x1;
 rngUserY1:=y1;
 rngUserX2:=x2;
 rngUserY2:=y2;
 rngMickeyX1:=round(rngUserX1/speedX);
 rngMickeyY1:=round(rngUserY1/speedY);
 rngMickeyX2:=round(rngUserX2/speedX);
 rngMickeyY2:=round(rngUserY2/speedY);
 move(0,0);
end;

{---------------------------------------------------------------------------
 Nastavi rychlost pohybu sipky ve smerech x,y.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetSpeed(x,y:real);
begin
 if x=0 then x:=1;
 if y=0 then y:=1;
 x:=x/MIC;
 y:=y/MIC;
 nowMickeyX:=round(nowMickeyX*speedX/x);
 nowMickeyY:=round(nowMickeyY*speedY/y);
 speedX:=x;
 speedY:=y;
 rngMickeyX1:=round(rngUserX1/speedX);
 rngMickeyY1:=round(rngUserY1/speedY);
 rngMickeyX2:=round(rngUserX2/speedX);
 rngMickeyY2:=round(rngUserY2/speedY);
end;

{---------------------------------------------------------------------------
 Do X,Y,Z zapise souradnice posledniho stisku/uvolneni mysi,
 bylo-li nejake, jinak nemeni.
 ---------------------------------------------------------------------------}
FUNCTION mouseRescanPress(var x,y:integer;var z,actions:word):boolean;
label nopress;
begin
 if (not mouseHandler) and (mouseButtons>0) then
   asm
     mov ax,5;mov bx,0;int 33h;or bx,bx;jz @1;or pressActions,maLeftPressed   ;jmp @press;@1:
     mov ax,6;mov bx,0;int 33h;or bx,bx;jz @2;or pressActions,maLeftReleased  ;jmp @press;@2:
     mov ax,5;mov bx,1;int 33h;or bx,bx;jz @3;or pressActions,maRightPressed  ;jmp @press;@3:
     mov ax,6;mov bx,1;int 33h;or bx,bx;jz @4;or pressActions,maRightReleased ;jmp @press;@4:
     cmp mouseButtons,2;jz @nopress
     mov ax,5;mov bx,2;int 33h;or bx,bx;jz @5;or pressActions,maCenterPressed ;jmp @press;@5:
     mov ax,6;mov bx,2;int 33h;or bx,bx;jz @6;or pressActions,maCenterReleased;jmp @press;@6:
     jmp @nopress
    @press:
     mov  pressZ,ax
     db 66h;mov ax,word ptr nowMickeyX;db 66h;mov word ptr pressMickeyX,ax
     db 66h;mov ax,word ptr nowMickeyY;db 66h;mov word ptr pressMickeyY,ax
     mov mouseDirty,true
    @nopress:
   end;
 mouseRescanPress:=false;
 if pressActions<>0 then begin
   mouseRescanPress:=true;
   x      :=round(pressMickeyX*speedX);
   y      :=round(pressMickeyY*speedY);
   z      :=0;XchgW(z,pressZ);
   actions:=0;XchgW(actions,pressActions);
   end;
end;

{---------------------------------------------------------------------------
 Pouze pro zpetnou kompatibilitu.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetJump(x,y:word);assembler;
 asm
 end;

{---------------------------------------------------------------------------
 Zavesi nebo odpoji od mysiho driveru vlastni event-handler.
 Pred ukoncenim programu se musi odpojit.
 Handler pouze zachycuje souradnice do vlastnich promennych,
 odtud si je berou ostatni funkce v unite, tim se znacne zrychli.
 Pouziti handleru zaroven zabranuje nekterym nesvarum (bez handleru jeden
 stisk tlacitka nekdy vygeneruje 3 po sobe jdouci signaly 'stisk').
 Pouziti handleru je zcela transparentni, funkcnost je totozna s nim
 i bez nej.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetHandler(b:boolean);assembler;
 asm
(*     cmp  b,false
     je   @odpoj

   @ZAVES:
     cmp  mouseHandler,false
     jnz  @end
     cmp  SafeMode,false
     jnz  @end
     {$ifdef dpmi}
     db 66h;cmp word ptr SwapSize,0
     jnz  @end
     {$endif}
     {set vars}
     mov  mouseZ,0
     mov  pressZ,0
     {set new}
     mov  ax,0Ch
     mov  cx,7Fh
     lea  dx,@handler
     push cs
     pop  es
     int  33h
     mov  mouseHandler,true
     jmp  @end

   @ODPOJ:
     cmp  mouseHandler,false
     jz   @end
     {set old}
     mov  ax,0ch
     xor  cx,cx
     lea  dx,@handler
     push cs
     pop  es
     int  33h
     mov  mouseHandler,false
     {clear possibly buffered events}
     mov ax,5;mov bx,0;int 33h
     mov ax,6;mov bx,0;int 33h
     mov ax,5;mov bx,1;int 33h
     mov ax,6;mov bx,1;int 33h
     cmp mouseButtons,2;jz @end
     mov ax,5;mov bx,2;int 33h
     mov ax,6;mov bx,2;int 33h
     jmp  @end

   @HANDLER:
     PUSH DS
     push seg @data
     pop  ds
     mov  mouseDirty,true
      mov  nowZ,bx
      PUSHA
      push si
      push di
      call move
      POPA
      and  ax,3*2ah
      jz   @nopress
      mov  pressZ,bx
      or   pressActions,ax
      db 66h;mov ax,word ptr nowMickeyX;db 66h;mov word ptr pressMickeyX,ax
      db 66h;mov ax,word ptr nowMickeyY;db 66h;mov word ptr pressMickeyY,ax
   @nopress:
     POP  DS
     RETF

   @END:*)
 end;

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='mys';
var result:TError;

procedure UserInit;
 begin
  mouseInit;
  speedX       :=1;
  speedY       :=1;
  rngMickeyX1  :=0;
  rngMickeyY1  :=0;
  rngMickeyX2  :=640;{nastavuje jen tak at tam na zacatku nejsou nesmysly}
  rngMickeyY2  :=480;
  asm mov ax,0bh;int 33h;end;{pro jistotu vynuluje deltax/y v mousedriveru}
  nowMickeyX   :=0;
  nowMickeyY   :=0;
  nowZ         :=0;
  pressActions :=0;
  rngUserX1    :=0;
  rngUserY1    :=0;
  rngUserX2    :=640;
  rngUserY2    :=480;
  mouseDirty   :=false;
  changeX      :=0;
  changeY      :=0;
 end;

procedure UserDone;
 begin
  mouseSetHandler(false);
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.