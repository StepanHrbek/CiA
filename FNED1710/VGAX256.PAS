{$G+}
unit vgax256;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
interface
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 TFont=array[0..2047] of byte;
const
 scrwidth :word=256;
 scrheight:word=256;
 _stdc         =$010F;
 _stde         =$0804;
 _mysw          =14;
 _mysh          =14;
 mys:array[0.._mysw*_mysh-1] of byte=( {14x14}
 $1E,$1D,$1C,$17,$15,$00,$00,$00,$00,$00,$00,$00,$00,$00,
 $1A,$1E,$1E,$1E,$1E,$1D,$1C,$17,$15,$00,$00,$00,$00,$00,
 $15,$1C,$1E,$1E,$1F,$1E,$1E,$1D,$1C,$1A,$17,$15,$00,$00,
 $00,$1A,$1C,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1D,$1D,$1A,$1A,
 $00,$15,$1A,$1C,$1E,$1E,$1E,$1D,$1D,$1D,$1D,$1C,$1A,$15,
 $00,$14,$1A,$1A,$1A,$1E,$1D,$1D,$1D,$1D,$1C,$1A,$16,$00,
 $00,$00,$18,$1A,$1A,$1A,$1D,$1D,$1D,$1C,$1A,$16,$15,$00,
 $00,$00,$16,$19,$19,$18,$17,$1D,$1C,$1B,$17,$15,$00,$00,
 $00,$00,$15,$18,$18,$16,$16,$17,$1D,$1C,$18,$14,$00,$00,
 $00,$00,$14,$17,$16,$15,$15,$15,$16,$1D,$1A,$16,$00,$00,
 $00,$00,$13,$16,$15,$15,$14,$14,$15,$16,$1C,$18,$15,$00,
 $00,$00,$00,$15,$15,$13,$12,$00,$12,$14,$15,$1C,$16,$14,
 $00,$00,$00,$14,$12,$00,$00,$00,$00,$12,$12,$15,$1A,$15,
 $00,$00,$00,$12,$00,$00,$00,$00,$00,$00,$00,$12,$14,$16);
{ _mysw          =8;
 _mysh          =10;
 mys:array[0..9,0..7] of byte=(
 ($1D,$00,$00,$00,$00,$00,$00,$00),
 ($1E,$1C,$00,$00,$00,$00,$00,$00),
 ($1F,$1E,$1B,$00,$00,$00,$00,$00),
 ($1E,$1F,$1C,$1A,$00,$00,$00,$00),
 ($1E,$1E,$1D,$1B,$18,$00,$00,$00),
 ($1E,$1D,$1C,$1A,$19,$16,$00,$00),
 ($1E,$1E,$1B,$18,$17,$15,$14,$00),
 ($1D,$1C,$18,$00,$00,$00,$00,$00),
 ($1C,$19,$00,$00,$00,$00,$00,$00),
 ($1A,$00,$00,$00,$00,$00,$00,$00));}
 {$I fonty.inc}
var
 mbk:array[0..sizeof(mys) shr 3-1,0..7] of byte;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure OutDxAx;
procedure WaitForTrace;
procedure SetMode(n:word);
procedure pal(col,r,g,b:byte);
procedure SetBorderColor(c:byte);
procedure x256x256;
procedure pset(x,y,c:byte; where:word);
procedure pnet(x,y,c:byte; where:word);
procedure quad(x,y:byte; w,h:word; c:byte; where:word);
procedure quadE(x,y:byte; w,h:word; c:byte; where:word);
procedure quadB(x,y:byte; w,h:word; c1,c2:byte; where:word);
procedure quadG(x,y,w,h,c1,c2:byte; where:word);
procedure butt(x,y,w,h,c1,c2,c3,d:byte; where:word);
procedure putbitmap(var sprite; x,y,w,h,xo,wo,e,where:word);
procedure getbitmap(var sprite; x,y,w,h:byte; where:word);
procedure fw(s:string; x,y:byte; c,e,where:word; font:Tfont);
function  pget(x,y:byte; where:word):byte;
function  input(r:string; x,y,l:byte; col:word; c:byte; e,where:word; font:Tfont):string;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
implementation
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 _PalReg    =$03C0;
 _MiscOutReg=$03C2;
 _SeqAddrReg=$03C4;
 _GFXAddrReg=$03CE;
 _PELAddrReg=$03C8;
 _CRTCReg   =$03D4;
 _CRTIntReg =$03D5;
 _FeatureReg=$03DA;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure OutDxAx; assembler;
asm   {OutDxAx}
 out  dx,al
 inc  dx
 xchg al,ah
 out  dx,al
 dec  dx
 xchg al,ah
end;  {OutDxAx}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure WaitForTrace; assembler;
asm   {WaitForTrace}
@1:
 mov  dx,_FeatureReg
 in   al,dx
 test al,8
 jnz  @1
end;  {WaitForTrace}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure SetMode(n:word); assembler;
asm   {SetMode}
 mov  ax,n
 or   ah,ah
 jz   @1
 mov  bx,ax
 mov  ax,4F02h
@1:
 int  10h
end;  {SetMode}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure pal(col,r,g,b:byte); assembler;
asm   {pal}
 mov  dx,_PELAddrReg
 mov  al,col
 out  dx,al
 inc  dx
 mov  al,r
 out  dx,al
 mov  al,g
 out  dx,al
 mov  al,b
 out  dx,al
end;  {pal}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure SetBorderColor(c:byte); assembler;
asm {SetBorderColor}
 mov ax,1001h
 mov bh,c
 int 10h
end;{SetBorderColor}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure x256x256data; assembler;
asm   {x256x256data}
 dw 3C2h; db 0E3h
 dw 3D4h; db 0h
 dw 3D5h; db 5Fh
 dw 3D4h; db 1h
 dw 3D5h; db 3Fh
 dw 3D4h; db 2h
 dw 3D5h; db 40h
 dw 3D4h; db 3h
 dw 3D5h; db 82h
 dw 3D4h; db 4h
 dw 3D5h; db 4Ah
 dw 3D4h; db 5h
 dw 3D5h; db 9Ah
 dw 3D4h; db 6h
 dw 3D5h; db 6Fh
 dw 3D4h; db 7h
 dw 3D5h; db 0B2h
 dw 3D4h; db 8h
 dw 3D5h; db 0h
 dw 3D4h; db 9h
 dw 3D5h; db 61h
 dw 3D4h; db 10h
 dw 3D5h; db 28h
 dw 3D4h; db 11h
 dw 3D5h; db 8Ah
 dw 3D4h; db 12h
 dw 3D5h; db 0FFh
 dw 3D4h; db 13h
 dw 3D5h; db 20h
 dw 3D4h; db 14h
 dw 3D5h; db 40h
 dw 3D4h; db 15h
 dw 3D5h; db 7h
 dw 3D4h; db 16h
 dw 3D5h; db 1Ah
 dw 3D4h; db 17h
 dw 3D5h; db 0A3h
 dw 3C4h; db 1h
 dw 3C5h; db 1h
 dw 3C4h; db 3h
 dw 3C5h; db 0h
 dw 3C4h; db 4h
 dw 3C5h; db 0Eh
 dw 3CEh; db 5h
 dw 3CFh; db 40h
 dw 3CEh; db 6h
 dw 3CFh; db 5h
 dw 0FFFFh
end;  {x256x256data}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure x256x256; assembler;
asm   {x256x256}
 mov  scrwidth,256
 mov  scrheight,256
 push ds
 push es
 mov  ax,13h
 int  10h
 mov  dx,3D4h
 mov  al,11h
 out  dx,al
 mov  dx,3D5h
 in   al,dx
 and  al,07Fh
 out  dx,al
 lea  si,x256x256data
 mov  ax,es
 mov  ds,ax
 mov  ax,cs
 mov  ds,ax
@smycka:
 lodsw
 cmp  ax,0FFFFh
 je   @ven
 mov  dx,ax
 lodsb
 out  dx,al
 jmp  @smycka
@ven:
 pop  es
 pop  ds
end;  {x256x256}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure pset(x,y,c:byte; where:word); assembler;
asm   {pset}
 mov  es,where
 mov  ah,y
 mov  al,x
 mov  di,ax
 mov  al,c
 mov  es:[di],al
end;  {pset}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  pget(x,y:byte; where:word):byte; assembler;
asm   {pget}
 mov  es,where
 mov  ah,y
 mov  al,x
 mov  di,ax
 mov  al,es:[di]
end;  {pget}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure pnet(x,y,c:byte; where:word); assembler;
asm   {pnet}
 mov  es,where
 mov  ah,y
 mov  al,x
 mov  di,ax
 mov  al,es:[di]
 xor  al,c
 mov  al,es:[di]
end;  {pnet}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure quad(x,y:byte; w,h:word; c:byte; where:word); assembler;
asm   {quad}
 cmp  w,0
 je   @end
 cmp  h,0
 je   @end
 mov  es,where
 mov  ah,y
 mov  al,x
 mov  di,ax
 mov  si,scrwidth
 mov  bx,w
 sub  si,bx
 and  bl,3
 shr  w,1
 shr  w,1
 mov  al,c
 mov  ah,al
 db   66h;shl  ax,16
 mov  al,c
 mov  ah,al
 mov  cx,h
@1:
 mov  dx,cx
 mov  cx,w
 db   66h;rep stosw
 mov  cl,bl
 rep  stosb
 add  di,si
 mov  cx,dx
 loop @1
@end:
end;  {quad}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure quadE(x,y:byte; w,h:word; c:byte; where:word); assembler;
asm   {quadE}
 cmp  w,0
 je   @end
 cmp  h,0
 je   @end
 mov  es,where
 mov  dl,x
 mov  dh,y
 mov  di,dx
 mov  cx,w
 mov  bl,cl
 and  bl,3
 shr  cx,1
 shr  cx,1
 mov  bh,cl
 mov  al,c
 mov  ah,al
 db   66h;rol ax,16
 mov  al,c
 mov  ah,al
 db   66h;rep  stosw
 mov  cl,bl
 rep  stosb
 mov  bx,h
 add  dh,bl
 mov  di,dx
 mov  cx,w
 mov  bl,cl
 and  bl,3
 shr  cx,1
 shr  cx,1
 db   66h;rep  stosw
 mov  cl,bl
 rep  stosb
 mov  ax,h
 sub  dh,al
 inc  dh
 mov  di,dx
 mov  si,scrwidth
 dec  w
 sub  si,w
 mov  cx,h
 mov  al,c
@1:
 mov  es:[di],al
 add  di,w
 mov  es:[di],al
 add  di,si
 loop @1
@end:
end;  {quadE}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure quadB(x,y:byte; w,h:word; c1,c2:byte; where:word); assembler;
asm   {quadB}
 cmp  w,0
 je   @end
 cmp  h,0
 je   @end
 mov  es,where
 mov  dl,x
 mov  dh,y
 mov  di,dx
 mov  cx,w
 mov  bl,cl
 and  bl,3
 shr  cx,1
 shr  cx,1
 mov  bh,cl
 mov  al,c1
 mov  ah,al
 db   66h;rol ax,16
 mov  al,c1
 mov  ah,al
 db   66h;rep  stosw
 mov  cl,bl
 rep  stosb
 mov  bx,h
 add  dh,bl
 dec  dh
 mov  di,dx
 mov  cx,w
 mov  bl,cl
 and  bl,3
 shr  cx,1
 shr  cx,1
 mov  al,c2
 mov  ah,al
 db   66h;rol ax,16
 mov  al,c2
 mov  ah,al
 db   66h;rep  stosw
 mov  cl,bl
 rep  stosb
 mov  ax,h
 sub  dh,al
 inc  dh
 mov  di,dx
 mov  si,scrwidth
 dec  w
 sub  si,w
 mov  cx,h
 mov  al,c1
 mov  ah,c2
@1:
 mov  es:[di],al
 add  di,w
 mov  es:[di],ah
 add  di,si
 loop @1
@end:
end;  {quadB}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure quadG(x,y,w,h,c1,c2:byte; where:word); assembler;
asm   {quadG}
 push ds
 push es
 cmp  w,0
 je   @end
 cmp  h,0
 je   @end
 mov  es,where
 mov  al,x
 mov  ah,y
 mov  di,ax
 mov  bl,w
 xor  bh,bh
 mov  si,scrwidth
 sub  si,bx
 mov  bh,bl
 shr  bl,1
 and  bh,1
 mov  al,c1
 mov  ah,c2
 xor  ch,ch
 mov  cl,h
@ForY:
 mov  dx,cx
 mov  cl,bl
 rep  stosw
 mov  cl,bh
 rep  stosb
 xchg ah,al
 add  di,si
 mov  cx,dx
 loop @ForY
@end:
 pop  es
 pop  ds
end;  {quadG}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure butt(x,y,w,h,c1,c2,c3,d:byte; where:word);
var i:byte;
begin {butt}
 if (w<d shl 1) then exit;
 for i:=0 to d-1 do
  quadB(x+i,y+i,w-i shl 1,h-i shl 1,c1,c3,where);
 quad(x+d,y+d,w-d shl 1,h-d shl 1,c2,where);
end;  {butt}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure putbitmap(var sprite; x,y,w,h,xo,wo,e,where:word); assembler;
{zkopiruje sprite (resp. jeho horizontalni vyrez) do (video)pameti
 ONLY FOR UNCHAINED MODE 256x256 with 256 colors!
 x,y - souradnice leveho horniho rohu ve (video)pameti (1. pixel vyrezu)
 w,h - sirka,vyska spritu
 xo - horizontalni ofset (0..w-1) spritu
 wo - delka viditelne casti spritu (xo+wo<=w)
    sprite:                 (virtualni) obrazovka s sirkou 256:
      xo                    [0,0]
Ú ÉÍÍÍËÍÍÍÍÍÍËÍ»              ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ---
³ º   ³//////³ º              ³  [x,y]
h º   ³//////³ º     --->     ³   ÉÍÍÍÍÍÍ»
³ º   ³//////³ º              ³   ³\\\\\\³
À ÈÍÍÍÊÍÍÍÍÍÍÊÍ¼              ³   ³\\\\\\³
  ³   ÀÄÄwoÄÄÙ ³              ³   ³\\\\\\³
  ÀÄÄÄÄÄwÄÄÄÄÄÄÙ              |   ÈÍÍÍÍÍÍ¼

 e - dolni byte:
     0 = zobraz vsechno (movsd)
     1 = zobraz vsechno krome barvy v hornim bytu (ta bude transparentn¡)
     2 = nenulove byty spritu vybarvi barvou v hornim bytu
     3 = nulove byty spritu vybarvi barvou v hornim bytu
    +8 = otocit sprite vertikalne
    +16= nekontrolovat "prelejzani" pres okraj obrazovky
    +32= nekontrolovat spravnost zadanych hodnot
   - horni byte: barva, o kterou se jedn 
 pro e and 3=0 pouziva movsw nebo movsd, coz znamena az ctyrnasobne zrychleni
 (x,y,w,h,xo,wo jsou sice typu word ale pro rezim 256x256 jsou
  horni byty ignorovany (usetrilo se tim par zbytecnych instrukc¡)}
var
 scr_wo,w_wo:word;
asm   {putbitmap}
 push ds
 push es
 test e,20h
 jnz  @KontrolaDone1
 mov  ax,xo {"if xo+wo>w then wo:=w-xo"}
 add  ax,wo
 cmp  ax,w
 jbe  @Kontrola2
 mov  al,byte ptr w
 sub  al,byte ptr xo
 mov  byte ptr wo,al
@Kontrola2:
 mov  ax,x  {"if x+wo>=scrwidth then wo:=scr_width-x"}
 add  ax,wo
 cmp  ax,256{*scrwidth}
 jb   @Kontrola3
 mov  ax,scrwidth
 sub  ax,x
 mov  byte ptr wo,al
@Kontrola3:
 mov  ax,y  {"if y+h>=scrheight then h:=scr_height-y"}
 add  ax,h
 cmp  ax,256{*scrheight}
 jb   @KontrolaDone1
 mov  ax,256{*scrheight}
 sub  ax,y
 mov  byte ptr h,al
@KontrolaDone1:
 lds  si,sprite {[ds:si] - sprite (1. pixel vyrezu)}
 mov  es,where  {[es:di] - (video)pamet na pozici [x,y]}
 mov  al,byte ptr x
 mov  ah,byte ptr y
 mov  di,ax
 mov  ax,ds {"if (sprite^=nil) or (ptr(where,0)=nil) then exit"}
 cmp  ax,0
 je   @end
 cmp  where,0
 je   @end
 test e,20h
 jnz  @KontrolaDone2
 cmp  w,0  {"if (w=0) or (h=0) or (wo=0) or (xo>w) then exit"}
 jz   @end
 cmp  h,0
 jz   @end
 cmp  wo,0
 jz   @end
 mov  al,byte ptr xo
 cmp  al,byte ptr w
 ja   @end
@KontrolaDone2:
 add  si,xo
 mov  ax,256{*scrwidth}
 sub  ax,wo        {scr_wo:=scrwidth-wo}
 mov  scr_wo,ax
 mov  bl,byte ptr e+1
 mov  cx,h
 test e,8
 jnz  @Flip
@NoFlip:
 mov  ax,w  {w_wo:=w-wo}
 sub  ax,wo
 mov  w_wo,ax
 mov  al,byte ptr e
 and  al,3
 or   al,al
 jnz  @NoFlip_e123
 mov  bx,scr_wo
 shr  wo,1
 jc   @NoFlip_e0a
 shr  wo,1
 jc   @NoFlip_e0c
 jmp  @NoFlip_e0b
@NoFlip_e123:
 cmp  al,1
 je   @NoFlip_e1
 cmp  al,2
 je   @NoFlip_e2
@NoFlip_e3:
 mov  dx,cx
 mov  cx,wo
@ForX_e3nf:
 lodsb
 or   al,al
 jnz  @ForX_e3nf2
 mov  es:[di],bl
@ForX_e3nf2:
 inc  di
 loop @ForX_e3nf
 add  si,w_wo
 add  di,scr_wo
 mov  cx,dx
 loop @NoFlip_e3
 jmp  @end
@NoFlip_e2:
 mov  dx,cx
 mov  cx,wo
@ForX_e2nf:
 lodsb
 or   al,al
 jz   @ForX_e2nf2
 mov  es:[di],bl
@ForX_e2nf2:
 inc  di
 loop @ForX_e2nf
 add  si,w_wo
 add  di,scr_wo
 mov  cx,dx
 loop @NoFlip_e2
 jmp  @end
@NoFlip_e1:
 mov  dx,cx
 mov  cx,wo
@ForX_e1nf:
 lodsb
 cmp  al,bl
 je   @ForX_e1nf2
 mov  es:[di],al
@ForX_e1nf2:
 inc  di
 loop @ForX_e1nf
 add  si,w_wo
 add  di,scr_wo
 mov  cx,dx
 loop @NoFlip_e1
 jmp  @end
@NoFlip_e0a:
 mov  dx,cx
 mov  cx,wo
 shr  cx,1
 db   66h;rep  movsw
 adc  cx,0
 rep  movsw
 movsb
 add  si,w_wo
 add  di,bx
 mov  cx,dx
 loop @NoFlip_e0a
 jmp  @end
@NoFlip_e0b:
 mov  dx,cx
 mov  cx,wo
 db   66h;rep  movsw
 add  si,w_wo
 add  di,bx
 mov  cx,dx
 loop @NoFlip_e0b
 jmp  @end
@NoFlip_e0c:
 mov  dx,cx
 mov  cx,wo
 db   66h;rep  movsw
 movsw
 add  si,w_wo
 add  di,bx
 mov  cx,dx
 loop @NoFlip_e0c
 jmp  @end
@Flip:
 mov  ax,w  {w_wo:=w+wo}
 add  ax,wo
 mov  w_wo,ax
 add  si,wo
 dec  si
 STD {movsb bude ted' SI dekrementovat}
 mov  al,byte ptr e
 and  al,3
 or   al,al
 jnz  @Flip_e123
 mov  bx,scr_wo
 dec  si
 shr  wo,1
 jc   @Flip_e0a
 jmp  @Flip_e0b
@Flip_e123:
 cmp  al,1
 je   @Flip_e1
 cmp  al,2
 je   @Flip_e2
@Flip_e3:
 mov  dx,cx
 mov  cx,wo
@ForX_e3f:
 lodsb
 or   al,al
 jnz  @ForX_e3f2
 mov  es:[di],bl
@ForX_e3f2:
 inc  di
 loop @ForX_e3f
 add  si,w_wo
 add  di,scr_wo
 mov  cx,dx
 loop @Flip_e3
 jmp  @end
@Flip_e2:
 mov  dx,cx
 mov  cx,wo
@ForX_e2f:
 lodsb
 or   al,al
 jz   @ForX_e2f2
 mov  es:[di],bl
@ForX_e2f2:
 inc  di
 loop @ForX_e2f
 add  si,w_wo
 add  di,scr_wo
 mov  cx,dx
 loop @Flip_e2
 jmp  @end
@Flip_e1:
 mov  dx,cx
 mov  cx,wo
@ForX_e1f:
 lodsb
 cmp  al,bl
 je   @ForX_e1f2
 mov  es:[di],al
@ForX_e1f2:
 inc  di
 loop @ForX_e1f
 add  si,w_wo
 add  di,scr_wo
 mov  cx,dx
 loop @Flip_e1
 jmp  @end
@Flip_e0a:
 mov  dx,cx
 lodsb
 mov  es:[di],al
 inc  di
 mov  cx,wo
@ForX_e0af:
 lodsw
 xchg ah,al
 mov  es:[di],ax
 inc  di
 inc  di
 loop @ForX_e0af
 add  si,w_wo
 add  di,bx
 mov  cx,dx
 loop @Flip_e0a
 jmp  @end
@Flip_e0b:
 mov  dx,cx
 mov  cx,wo
@ForX_e0bf:
 lodsw
 xchg ah,al
 mov  es:[di],ax
 inc  di
 inc  di
 loop @ForX_e0bf
 add  si,w_wo
 add  di,bx
 mov  cx,dx
 loop @Flip_e0b
 jmp  @end
@end:
 CLD
 pop  es
 pop  ds
end;  {putbitmap}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure getbitmap(var sprite; x,y,w,h:byte; where:word); assembler;
var scrw_w,w2:word;
asm   {getbitmap}
 push ds
 push es
 cmp  w,0
 je   @end
 cmp  h,0
 je   @end
 les  di,sprite
 mov  ds,where
 mov  ah,y
 mov  al,x
 mov  si,ax
 mov  w2,0
 xor  bh,bh
 mov  bl,w
 xor  dh,dh
 mov  dl,x
 mov  ax,256{*scrwidth}
 sub  ax,bx
 mov  scrw_w,ax
 {"if x+w>=scrwidth then begin w:=scrwidth-x; w2:=x+w-scrwidth; end"}
 mov  ax,dx
 add  ax,bx
 cmp  ax,256{*scrwidth}
 jb   @1
 mov  ax,dx
 add  ax,bx
 sub  ax,256{*scrwidth}
 mov  w2,ax
 mov  ax,256{*scrwidth}
 sub  ax,dx
 mov  w,al
@1:
 mov  bl,w
 mov  bh,bl
 shr  bl,1
 shr  bl,1
 and  bh,3
 xor  ch,ch
 mov  cl,h
@ForY:
 mov  dx,cx
 mov  cl,bl
 db   66h;rep movsw
 mov  cl,bh
 rep  movsb
 add  di,w2
 add  si,w2
 add  si,scrw_w
 mov  cx,dx
 loop @ForY
@end:
 pop  es
 pop  ds
end;  {getbitmap}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION either(cond:boolean; res1,res2:byte):byte; assembler;
asm   {either}
 mov  al,cond
 cmp  al,0
 je   @res2
 mov  al,res1
 jmp  @end
@res2:
 mov  al,res2
@end:
end;  {either}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure fw(s:string; x,y:byte; c,e,where:word; font:TFont); assembler;
{Napise string fontem 4x6 na mem[whereseg:0] na pozici x,y barvou c.
 c and 255 barva popredi, c shr 8 je barva pozadi
 e shr 8 je sirka, e and 127 vyska kazdeho znaku a
 7. bit u e indikuje, ze ma byt barva pozadi transparentni
 POUZE PRO X-MODE 256x256! POUZE PRO FONT S SIRKOU 8!
 Nekontroluje pretekani pres okraje}
var
 znak,chrH,chrW,scrw_w,strs,stro,fnts,fnto,ch2ch:word;
asm   {fw}
 push ds
 push es
 {es:[di] - videopamet,  ds:[si] - font,  fs:[bx] - string}
 cmp  where,0
 je   @end
 mov  es,where
 mov  al,x
 mov  ah,y
 mov  di,ax
 lds  si,font
 mov  fnts,ds
 mov  fnto,si
 lds  si,s
 mov  strs,ds
 mov  stro,si
 cmp  di,0
 je   @end
 mov  cx,e
 mov  ax,cx
 xor  al,al
 mov  ch2ch,ax
 mov  ax,cx
 xchg ah,al
 xor  ah,ah
 and  cx,07Fh
 mov  chrH,ax
 mov  chrW,cx
 sub  ch2ch,cx
 mov  ax,256{*scrwidth}
 sub  ax,cx
 mov  scrw_w,ax
 xor  ch,ch
 lodsb
 mov  stro,si
 mov  cl,al
 test cx,0FFFFh
 jz   @end
 test byte ptr e,80h
 jnz  @ForZnak2
@ForZnak:
 mov  znak,cx
 mov  ds,strs
 mov  si,stro
 lodsb
 mov  stro,si
 xor  ah,ah
 shl  ax,3
 mov  ds,fnts
 mov  si,fnto
 add  si,ax
 mov  cx,chrH
@ForY:
 mov  dx,cx
 lodsb
 mov  bl,al
 mov  bh,80h
 mov  al,byte ptr c
 mov  ah,byte ptr c+1
 mov  cx,chrW
@ForX:
 test bl,bh
 jz   @backgrnd
 stosb
 jmp  @dal
@backgrnd:
 mov  es:[di],ah
 inc  di
@dal:
 shr  bh,1
 loop @ForX
 add  di,scrw_w
 mov  cx,dx
 loop @ForY
 sub  di,ch2ch
 mov  cx,znak
 loop @ForZnak
 jmp  @end
@ForZnak2:
 mov  znak,cx
 mov  ds,strs
 mov  si,stro
 lodsb
 mov  stro,si
 xor  ah,ah
 shl  ax,3
 mov  ds,fnts
 mov  si,fnto
 add  si,ax
 mov  cx,chrH
@ForY2:
 mov  dx,cx
 lodsb
 mov  bl,al
 mov  bh,80h
 mov  al,byte ptr c
 mov  ah,byte ptr c+1
 mov  cx,chrW
@ForX2:
 test bl,bh
 jz   @backgrnd2
 stosb
 dec  di
@backgrnd2:
 inc  di
 shr  bh,1
 loop @ForX2
 add  di,scrw_w
 mov  cx,dx
 loop @ForY2
 sub  di,ch2ch
 mov  cx,znak
 loop @ForZnak2
@end:
 pop  es
 pop  ds
end;  {fw}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION Bounded(n,min,max:longint):longint; assembler;
asm {Bounded}
 db   66h;mov ax,word ptr n
 db   66h;mov bx,word ptr min
 db   66h;cmp ax,bx; jle @bx
 db   66h;mov bx,word ptr max
 db   66h;cmp bx,ax; jle @bx
 mov  dx,word ptr n+2
 jmp  @end
@bx:
 mov  ax,bx
 db   66h;shr bx,16
 mov  dx,bx
@end:
end;  {Bounded}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  Rep(c:char;kolikrat:byte):string; assembler;
asm   {Rep}
 push es
 les  di,@result
 mov  al,kolikrat
 stosb
 mov  cl,al
 xor  ch,ch
 mov  al,c
 mov  ah,al
 shr  cx,1
 rep  stosw
 adc  cx,0
 rep  stosb
 pop  es
end;  {Rep}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  MaxI(x,y:integer):integer;inline($58/$5b/$3b/$d8/$7e/$01/$93);{pop ax;pop bx;cmp bx,ax;jle +1;xchg ax,bx}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  Left(st:string;len:byte):string;
begin {Left}
 Left:=copy(st,1,len)+rep(' ',maxI(0,len-length(st)));
end;  {Left}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
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
 shr  cx,1
 rep  movsw
 adc  cx,0
 rep  movsb
 pop  ds
end;  {eitherS}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type string2=string[2];
FUNCTION Inkeys:string2; assembler;
asm   {inkeys}
 push es
 les  di,@result
 mov  ah,0Bh
 int  21h
 cmp  al,0
 je   @nic
 xor  ah,ah
 int  16h
 cmp  al,0
 je   @extended
 mov  byte ptr es:[di],1
 inc  di
 stosb
 jmp  @end
@extended:
 mov  byte ptr es:[di],2
 inc  di
 stosw
 jmp  @end
@nic:
 xor  ax,ax
 stosw
@end:
 pop  es
end;  {inkeys}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  MinW(x,y:word):word;inline($58/$5b/$3b/$c3/$72/$01/$93);{pop ax;pop bx;cmp ax,bx;jb +1;xchg ax,bx}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  input(r:string; x,y,l:byte; col:word; c:byte; e,where:word; font:Tfont):string;
var
 keys:string[2];
 ins:boolean;
 s:string;
begin {input}
 s:=copy(r,1,l);
 ins:=false;
 repeat
  c:=bounded(c,1,l); c:=bounded(c,1,length(s)+1);
  fw(left(s,l),x,y,col,e,where,font);
  fw(eitherS(c>length(s),' ',s[c]),x+(c-1)*(e and 127),y,$1807,e and $FF00+(e and $FF shr byte(ins)),SegA000,font);
  repeat keys:=inkeys until keys<>'';
  case keys[0] of
  #2:
   case keys[2] of
   'K': c:=bounded(c-1,1,minW(length(s)+1,l));
   'M': c:=bounded(c+1,1,length(s)+1);
   'G': c:=0;
   'O': c:=length(s)+1;
   'R': ins:=not ins;
   'S': if length(s)>0 then delete(s,c,1);
   end;
  #1:
   case keys[1] of
   #8:
    if (c>1) and (length(s)>0) then
     begin
      c:=bounded(c-1,1,length(s)+1);
      delete(s,c,1);
     end;
   #13:
    begin
     fw(left(s,l),x,y,col,e,where,font);
     input:=s;
     break;
    end;
   #9:
    begin
     fw(left(s,l),x,y,col,e,where,font);
     input:=r+#9;
     break;
    end;
   #27:
    begin
     fw(left(r,l),x,y,col,e,where,font);
     input:=r;
     break;
    end
   else
    if (length(s)<l) or not ins then
     begin
      if ins then
       if length(s)<l then insert(keys[1],s,c) else
      else
       begin
        s[c]:=keys[1];
        if c>length(s) then inc(s[0]);
       end;
      c:=bounded(c+1,1,l);
     end;
   end;
  end;
 until false;
end;  {input}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin
end.