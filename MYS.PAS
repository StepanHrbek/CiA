{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.10ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Mys;
Interface {$i define.inc}
Uses      Chyby;
Function  Init:word;
Procedure Done;


var       mouseButtons :byte;         {pocet tlacitek mysi, 0=neni mys}

FUNCTION  mouseGetPress:byte;
PROCEDURE mouseGetPos(var x,y:integer);
PROCEDURE mouseGet(var x,y,z:integer);
PROCEDURE mouseGetChange(var x,y:integer);
PROCEDURE mouseSetPos(x,y:word);
PROCEDURE mouseSetRange(x1,y1,x2,y2:word);
PROCEDURE mouseSetSpeed(x,y:word);
FUNCTION  mouseRescanPress(var x,y,z:integer):boolean;
PROCEDURE mouseSetJump(x,y:word);


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


var   mouseX             :word;         {teoreticka poloha mysi neni-li}
      mouseY             :word;         {pritomen mysi driver}

      jumpX              :word;         {viz mouseSetJump}
      jumpY              :word;

{---------------------------------------------------------------------------
 Inicializuje mys. Nutno provest jako prvni vec s mysi.
 ---------------------------------------------------------------------------}
PROCEDURE mouseInit;assembler;
 asm
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
     mov mouseX,0
     mov mouseY,0
     mov mouseButtons,0

     @end:
 end;

{---------------------------------------------------------------------------
 Vraci momentalni stav tlacitek.
 Bit 0 - leve stisknute
     1 - prave stisknute
     2 - prostredni stisknute
 ---------------------------------------------------------------------------}
FUNCTION mouseGetPress:byte;
var x,y,z:integer;
begin;
 mouseGet(x,y,z);
 mouseGetPress:=z;
end;

{---------------------------------------------------------------------------
 Vraci momentalni polohu mysi.
 ---------------------------------------------------------------------------}
PROCEDURE mouseGetPos(var x,y:integer);
var z:integer;
begin;
 mouseGet(x,y,z);
end;

{---------------------------------------------------------------------------
 Vraci momentalni polohu a stav tlacitek mysi.
 ---------------------------------------------------------------------------}
PROCEDURE mouseGet(var x,y,z:integer);
var i,j,k:integer;
begin
 if mouseButtons>0 then begin
   asm mov ax,3;int 33h;mov i,cx;mov j,dx;mov bh,0;mov k,bx;end;
   x:=i div jumpX;
   y:=j div jumpY;
   z:=k;
  end
 else begin
   x:=mouseX;
   y:=mouseY;
   z:=0;
  end
end;

{---------------------------------------------------------------------------
 Vraci relativni zmenu polohy sipky od posledniho volani teto funkce.
 Jednotkou je tusim mickey.
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
PROCEDURE mouseSetPos(x,y:word);
begin
 if mouseButtons>0 then begin
   x:=x*jumpX;
   y:=y*jumpY;
   asm mov ax,4;mov cx,x;mov dx,y;int 33h;end;
  end
  else begin
   mouseX:=x;
   mouseY:=y;
  end;
end;

{---------------------------------------------------------------------------
 Nastavi rozsah pohybu sipky.
 ---------------------------------------------------------------------------}
PROCEDURE mouseSetRange(x1,y1,x2,y2:word);
begin
 if mouseButtons>0 then begin
   x1:=x1*jumpX;
   y1:=y1*jumpY;
   x2:=x2*jumpX;
   y2:=y2*jumpY;
   asm
    mov ax,7;mov cx,x1;mov dx,x2;int 33h;
    mov ax,8;mov cx,y1;mov dx,y2;int 33h;
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
 Do X,Y,Z zapise souradnice posledniho stisku mysi byl-li, jinak nemeni.
 ---------------------------------------------------------------------------}
FUNCTION mouseRescanPress(var x,y,z:integer):boolean;
var   xx,yy,zz:integer;
label ende;
begin
 mouseRescanPress:=false;
 if mouseButtons>0 then begin
  asm
     mov ax,5;mov bx,0;int 33h;mov ax,1;cmp bx,0;jnz @found
     mov ax,5;mov bx,1;int 33h;mov ax,2;cmp bx,0;jnz @found
     cmp mouseButtons,2;jz ende
     mov ax,5;mov bx,2;int 33h;mov ax,4;cmp bx,0;jnz @found
     jmp ende
    @found:
     mov xx,cx
     mov yy,dx
     mov zz,ax
  end;
  x:=xx div jumpX;
  y:=yy div jumpY;
  z:=zz;
  mouseRescanPress:=true;
  end;
 ende:
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


{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const
 inited:boolean=false;

function Init:word;
 begin
  Init:=erOk;
  if not inited then begin
   mouseInit;
   jumpX        :=1;
   jumpY        :=1;
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