{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Mys;
Interface {$i define.inc}
Uses      Chyby,Memo, Stringy;
Function  Init:TError;
Procedure Done;

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
          mouseHandler :boolean;{je na mysi povesen nas handler?}
          mouseDirty   :boolean;{nastavi se pri kazdem eventu}

PROCEDURE mouseGet(var x,y:integer;var z:word);
PROCEDURE mouseGetPos(var x,y:integer);
FUNCTION  mouseGetX:integer;
FUNCTION  mouseGetY:integer;
FUNCTION  mouseGetZ:word;
PROCEDURE mouseGetChange(var x,y:integer);
PROCEDURE mouseSetPos(x,y:integer);
PROCEDURE mouseSetRange(x1,y1,x2,y2:integer);
PROCEDURE mouseSetSpeed(x,y:word);
FUNCTION  mouseRescanPress(var x,y:integer;var z,actions:word):boolean;
PROCEDURE mouseSetJump(x,y:word);
PROCEDURE mouseSetHandler(b:boolean);


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


var
      mouseX       :word;   {teoreticka poloha mysi neni-li pritomen driver}
      mouseY       :word;    {nebo skutecna kterou zachytil mistni handler}
      mouseZ       :word;   {stav tlacitek zachyceny mistnim handlerem}
      pressX       :word;   {posledni zachyceny stisk/uvolneni}
      pressY       :word;
      pressZ       :word;   {stav tlacitek po nem}
      pressActions :word;   {jake konkretni akce se staly}
      jumpX        :word;   {viz mouseSetJump}
      jumpY        :word;   {pozn: souradnice mouseXXXX a presXXXX jsou}
                             {v jednotkach driveru, nedelene jumpem}

{---------------------------------------------------------------------------
 Inicializuje mys. Nutno provest jako prvni vec s mysi.
 ---------------------------------------------------------------------------}
PROCEDURE mouseInit;assembler;
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
     xor ax,ax
     mov mouseX,ax
     mov mouseY,ax
     mov mouseButtons,al

     @end:
 end;

{---------------------------------------------------------------------------
 Vraci momentalni polohu a stav tlacitek mysi.
 ---------------------------------------------------------------------------}
PROCEDURE mouseGet(var x,y:integer;var z:word);
begin
 if (not mouseHandler) and (mouseButtons>0) then
   asm
    mov  ax,3
    int  33h
    mov  mouseX,cx
    mov  mouseY,dx
    xor  bh,bh
    mov  mouseZ,bx
   end;
 x:=mouseX div jumpX;
 y:=mouseY div jumpY;
 z:=mouseZ;
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
 Jednotkou je asi mickey.
 ---------------------------------------------------------------------------}
PROCEDURE mouseGetChange(var x,y:integer);assembler;
 asm
     xor cx,cx;xor dx,dx
     cmp mouseButtons,0;jz @end
     mov ax,0bh;int 33h
     @end:
     les di,x;mov [es:di],cx
     les di,y;mov [es:di],dx
 end;

{---------------------------------------------------------------------------
 Nastavi polohu sipky.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetPos(x,y:integer);
begin
 x:=x*jumpX;
 y:=y*jumpY;
 if mouseButtons>0 then asm mov ax,4;mov cx,x;mov dx,y;int 33h;end;
 mouseX:=x;
 mouseY:=y;
end;

{---------------------------------------------------------------------------
 Nastavi rozsah pohybu sipky.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetRange(x1,y1,x2,y2:integer);
begin
 if mouseButtons>0 then begin
   x1:=x1*jumpX;
   y1:=y1*jumpY;
   x2:=x2*jumpX;
   y2:=y2*jumpY;
   asm
    mov ax,7;mov cx,x1;mov dx,x2;int 33h;
    mov ax,8;mov cx,y1;mov dx,y2;int 33h;
    mov ax,3;int 33h;mov mouseX,cx;mov mouseY,dx;mov bh,0;mov mouseZ,bx;
   end;
  end;
end;

{---------------------------------------------------------------------------
 Nastavi rychlost pohybu sipky ve smerech x,y.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetSpeed(x,y:word);
begin
 if mouseButtons>0 then begin
   x:=x div jumpX;if x=0 then x:=1;
   y:=y div jumpY;if y=0 then y:=1;
   asm
    mov ax,0fh;mov cx,x;mov dx,y;int 33h;
   end;
  end;
end;

{---------------------------------------------------------------------------
 Do X,Y,Z zapise souradnice posledniho stisku/uvolneni mysi,
 bylo-li nejake, jinak nemeni.
 ---------------------------------------------------------------------------}
FUNCTION mouseRescanPress(var x,y:integer;var z,actions:word):boolean;
begin
 if (not mouseHandler) and (mouseButtons>0) then
   asm
     mov ax,5;mov bx,0;int 33h;or bx,bx;jz @1;or pressActions,maLeftPressed   ;jmp @press;@1:
     mov ax,6;mov bx,0;int 33h;or bx,bx;jz @2;or pressActions,maLeftReleased  ;jmp @press;@2:
     mov ax,5;mov bx,1;int 33h;or bx,bx;jz @3;or pressActions,maRightPressed  ;jmp @press;@3:
     mov ax,6;mov bx,1;int 33h;or bx,bx;jz @4;or pressActions,maRightReleased ;jmp @press;@4:
     cmp mouseButtons,2;jz @end
     mov ax,5;mov bx,2;int 33h;or bx,bx;jz @5;or pressActions,maCenterPressed ;jmp @press;@5:
     mov ax,6;mov bx,2;int 33h;or bx,bx;jz @6;or pressActions,maCenterReleased;jmp @press;@6:
     jmp @end
    @press:
     mov pressX,cx
     mov pressY,dx
     mov pressZ,ax
    @end:
   end;
 mouseRescanPress:=false;
 if pressActions<>0 then begin
   mouseRescanPress:=true;
   x      :=pressX div jumpX;
   y      :=pressY div jumpY;
   z      :=0;XchgW(z,pressZ);
   actions:=0;XchgW(actions,pressActions);
   end;
end;

{---------------------------------------------------------------------------
 Nastavi kolikanasobne se ma zvysit presnost v osach x,y.
 Priklad:
  V nekterych modech skace sipka po 8 pixelech. Nastavis-li 8 (nebo vic),
  bude se pohybovat plynule, ale 8-nasobne se snizi maximalni nastavitelna
  citlivost=rychlost.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetJump(x,y:word);assembler;
 asm
     mov ax,x;mov jumpX,ax
     mov ax,y;mov jumpY,ax
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
     cmp  b,false
     je   @odpoj

   @ZAVES:
     cmp  mouseHandler,false
     jnz  @end
     cmp  SafeMode,false
     jnz  @end
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
     jmp  @end

   @HANDLER:
     PUSH DS
     push seg @data
     pop  ds
     mov  mouseDirty,true
      mov  mouseX,cx
      mov  mouseY,dx
      mov  mouseZ,bx
      and  ax,3*2ah
      jz   @nopress
      mov  pressX,cx
      mov  pressY,dx
      mov  pressZ,bx
      or   pressActions,ax
   @nopress:
     POP  DS
     RETF

   @END:
 end;

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='mys';
var result:TError;

procedure UserInit;
 begin
  mouseInit;
  mouseHandler :=false;
  mouseDirty   :=false;
  pressActions :=0;
  jumpX        :=1;
  jumpY        :=1;
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