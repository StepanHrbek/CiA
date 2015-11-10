{$G+}
unit xvga;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
interface
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 scrwidth:word=360;
 scrheight:word=480;
 _mysw          =14;
 _mysh          =14;
 mys:array[0.._mysw-1,0.._mysh-1] of byte=( {14x14}
 ($1E,$1D,$1C,$17,$15,$00,$00,$00,$00,$00,$00,$00,$00,$00),
 ($1A,$1E,$1E,$1E,$1E,$1D,$1C,$17,$15,$00,$00,$00,$00,$00),
 ($15,$1C,$1E,$1E,$1F,$1E,$1E,$1D,$1C,$1A,$17,$15,$00,$00),
 ($00,$1A,$1C,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1D,$1D,$1A,$1A),
 ($00,$15,$1A,$1C,$1E,$1E,$1E,$1D,$1D,$1D,$1D,$1C,$1A,$15),
 ($00,$14,$1A,$1A,$1A,$1E,$1D,$1D,$1D,$1D,$1C,$1A,$16,$00),
 ($00,$00,$18,$1A,$1A,$1A,$1D,$1D,$1D,$1C,$1A,$16,$15,$00),
 ($00,$00,$16,$19,$19,$18,$17,$1D,$1C,$1B,$17,$15,$00,$00),
 ($00,$00,$15,$18,$18,$16,$16,$17,$1D,$1C,$18,$14,$00,$00),
 ($00,$00,$14,$17,$16,$15,$15,$15,$16,$1D,$1A,$16,$00,$00),
 ($00,$00,$13,$16,$15,$15,$14,$14,$15,$16,$1C,$18,$15,$00),
 ($00,$00,$00,$15,$15,$13,$12,$00,$12,$14,$15,$1C,$16,$14),
 ($00,$00,$00,$14,$12,$00,$00,$00,$00,$12,$12,$15,$1A,$15),
 ($00,$00,$00,$12,$00,$00,$00,$00,$00,$00,$00,$12,$14,$16));
{ mys:array[0..9,0..7] of byte=(
 ($1D,$00,$00,$00,$00,$00,$00,$00),
 ($1E,$1C,$00,$00,$00,$00,$00,$00),
 ($1F,$1E,$1B,$00,$00,$00,$00,$00),
 ($1E,$1F,$1C,$1A,$00,$00,$00,$00),
 ($1E,$1E,$1D,$1D,$18,$00,$00,$00),
 ($1D,$1D,$1C,$1B,$19,$16,$00,$00),
 ($1E,$1E,$1B,$18,$17,$15,$14,$00),
 ($1D,$1C,$18,$00,$00,$00,$00,$00),
 ($1C,$19,$00,$00,$00,$00,$00,$00),
 ($1A,$00,$00,$00,$00,$00,$00,$00));}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure SetMode(n:word);
procedure pal(c,r,g,b:byte);
procedure WaitForTrace;
procedure x360x480;
procedure xpset(x,y:word; c:byte);
procedure xquad(x,y,w,h:word; c:byte);
procedure xquadE(x,y,w,h:word; c:byte);
procedure screen(page:byte);
procedure x320x200;
procedure ClearScreen;
procedure CopyPage(page1,page2:byte);
procedure cursorset(x,y:word);
procedure cursorget(x,y:word);
procedure cursorret(x,y:word);
procedure PutPixel(x,y:integer; color:byte);
function  GetPixel(x,y:integer):byte;
procedure BIOSPutPixel(x,y:integer; color:byte);
function  BIOSGetPixel(x,y:integer):byte;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
implementation
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
uses maus,syst;
const
 _PalReg    =$03C0;
 _MiscOutReg=$03C2;
 _SeqAddrReg=$03C4;
 _GFXAddrReg=$03CE;
 _PELAddrReg=$03C8;
 _CRTCReg   =$03D4;
 _CRTIntReg =$03D5;
 _FeatureReg=$03DA;
 Offset_Adr:array[0..3] of word=($0000,$3E80,$7D00,$BB80);
var
 mbk:array[0.._mysw-1,0.._mysh-1] of byte;
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
procedure pal(c,r,g,b:byte); assembler;
asm   {pal}
 mov  dx,_PELAddrReg
 mov  al,c
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
procedure x360x480data; assembler;
asm   {x360x480data}
 dw   6B00h,5901h,5A02h,8E03h
 dw   5E04h,8A05h,0D06h,3E07h
 dw   4009h,0EA10h,0AC11h,0DF12h
 dw   2D13h,0014h,0E715h,0616h
 dw   0E317h,0FFFFh
end;  {x360x480data}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure x360x480; assembler;
asm   {x360x480}
 push ds
 push es
 mov  scrwidth,360
 mov  scrheight,480
 mov  ax,13h
 int  10h
 mov  dx,_SeqAddrReg {3C4h}
 mov  ax,0604h
 call outDxAx
 mov  ax,0F02h
 call outDxAx
 mov  es,SegA000
 xor  di,di
 mov  cx,8000h
 xor  ax,ax
 rep  stosw
 mov  ax,0100h
 call outDxAx
 mov  dx,_MiscOutReg {3C2h}
 mov  al,0E7h
 out  dx,al
 mov  dx,_SeqAddrReg {3C4h}
 mov  ax,0300h
 call outDxAx
 mov  dx,_CRTCReg    {3D4}
 mov  al,11h
 out  dx,al
 inc  dx
 in   al,dx
 and  al,7Fh
 out  dx,al
 mov  si,seg x360x480data
 mov  ds,si
 mov  si,offset x360x480data
 mov  dx,_CRTCReg    {3D4}
@1:
 lodsw
 cmp  ax,0FFFFh
 je   @end
 call outDxAx
 jmp  @1
@end:
 pop  es
 pop  ds
end;  {x360x480}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure xpset(x,y:word; c:byte); assembler;
asm   {xpset}
 mov  cx,x
 and  cx,3
 mov  ax,100h
 shl  ax,cl
 inc  al
 inc  al
 mov  dx,_SeqAddrReg
 out  dx,al
 inc  dx
 xchg al,ah
 out  dx,al
 mov  es,SegA000
 mov  ax,y
 mov  bx,scrwidth
 shr  bx,1
 shr  bx,1
 mul  bx
 mov  di,ax
 mov  ax,x
 shr  ax,1
 shr  ax,1
 add  di,ax
 mov  al,c
 mov  es:[di],al
end;  {xpset}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure xquad(x,y,w,h:word; c:byte); assembler;
var ofs0,delta,plane,wand3:word;
asm   {xquad}
 mov  es,SegA000
 mov  ax,y
 mov  bx,scrwidth
 shr  bx,1
 shr  bx,1
 mul  bx
 mov  ofs0,ax
 mov  ax,x
 shr  ax,1
 shr  ax,1
 add  ofs0,ax
 mov  ax,w
 and  ax,3
 mov  wand3,ax
 shr  w,1
 shr  w,1
 mov  ax,scrwidth
 shr  ax,1
 shr  ax,1
 sub  ax,w
 mov  delta,ax
 mov  al,c
 mov  ah,al
 mov  plane,0
@0:
 mov  di,ofs0
 mov  cx,h
@1:
 mov  si,cx
 mov  cx,x
 add  cx,plane
 and  cx,3
 mov  ax,100h
 shl  ax,cl
 inc  al
 inc  al
 mov  dx,_SeqAddrReg
 out  dx,al
 inc  dx
 xchg al,ah
 out  dx,al
 mov  al,c
 mov  ah,al
 mov  cx,w
 shr  cx,1
 rep  stosw
 adc  cx,0
 rep  stosb
 mov  cx,wand3
 cmp  cx,plane
 jbe  @2
 mov  es:[di],al
@2:
 add  di,delta
 mov  cx,si
 loop @1
 inc  plane
 cmp  plane,4
 je   @end
 jmp  @0
@end:
end;  {xquad}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure xquadE(x,y,w,h:word; c:byte); assembler;
var ofs0,delta,wshr2,plane,wand3,sire:word;
asm   {xquadE}
 mov  es,SegA000
 mov  ax,y
 mov  bx,scrwidth
 shr  bx,1
 shr  bx,1
 mul  bx
 mov  ofs0,ax
 mov  ax,x
 shr  ax,1
 shr  ax,1
 add  ofs0,ax
 mov  ax,w
 and  ax,3
 mov  wand3,ax
 mov  ax,scrwidth
 mul  h
 shr  ax,1
 shr  ax,1
 mov  sire,ax
 shr  w,1
 shr  w,1
 mov  ax,scrwidth
 shr  ax,1
 shr  ax,1
 mov  wshr2,ax
 sub  ax,w
 mov  delta,ax
 mov  plane,0
 mov  cx,x
 add  cx,plane
 and  cx,3
 mov  ax,100h
 shl  ax,cl
 inc  al
 inc  al
 mov  dx,_SeqAddrReg
 out  dx,al
 inc  dx
 xchg al,ah
 out  dx,al
 mov  al,c
 mov  di,ofs0
 mov  cx,h
@first:
 mov  es:[di],al
 add  di,90
 loop @first
 mov  al,c
 mov  ah,al
@0:
 mov  di,ofs0
 mov  cx,2
@1:
 mov  si,cx
 mov  al,c
 mov  ah,al
 mov  cx,w
 shr  cx,1
 rep  stosw
 adc  cx,0
 rep  stosb
 mov  cx,wand3
 cmp  cx,plane
 jb   @2
 mov  es:[di],al
@2:
 cmp  si,2
 jne  @3
 cmp  cx,plane
 jne  @3
 push di
 push cx
 mov  cx,h
@last:
 mov  es:[di],al
 add  di,wshr2
 loop @last
 pop  cx
 pop  di
@3:
 add  di,delta
 mov  cx,si
 mov  di,ofs0
 add  di,sire
 loop @1
 cmp  plane,4
 je   @4
 mov  cx,x
 add  cx,plane
 and  cx,3
 mov  ax,100h
 shl  ax,cl
 inc  al
 inc  al
 mov  dx,_SeqAddrReg
 out  dx,al
 inc  dx
 xchg al,ah
 out  dx,al
 inc  plane
 jmp  @0
@4:
end;  {xquadE}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function xpget(x,y:Word):byte; assembler;
asm   {xpget}
 mov  cx,x
 and  cx,3
 mov  ax,100h
 shl  ax,cl
 inc  al
 inc  al
 mov  dx,_SeqAddrReg
 out  dx,al
 inc  dx
 xchg al,ah
 out  dx,al
 mov  es,SegA000
 mov  ax,y
 mov  bx,scrwidth
 shr  bx,1
 shr  bx,1
 mul  bx
 mov  di,ax
 mov  ax,x
 shr  ax,1
 shr  ax,1
 add  di,ax
 mov  al,es:[di]
end;  {xpget}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure cursorset(x,y:word);
var i,j:byte;
begin {cursorset}
 for j:=0 to _mysh-1 do
  for i:=0 to _mysw-1 do
   if (x+i<scrwidth) and (y+j<scrheight) and (mys[j,i]<>0) then
    putpixel(x+i,y+j,mys[j,i]);
end;  {cursorset}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure cursorget(x,y:word);
var i,j:byte;
begin {cursorget}
 for j:=0 to _mysh-1 do
  for i:=0 to _mysw-1 do
   mbk[j,i]:=getpixel(x+i,y+j);
end;  {cursorget}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure cursorret(x,y:word);
var i,j:byte;
begin {cursorret}
 for j:=0 to _mysh-1 do
  for i:=0 to _mysw-1 do
   if (x+i<scrwidth) and (y+j<scrheight) then
    putpixel(x+i,y+j,mbk[j,i]);
end;  {cursorret}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure screen(page:byte); assembler;
asm   {screen}
 mov  dx,_FeatureReg
@001:
 in   al,dx
 test al,8
 jz   @001
@002:
 in   al,dx
 test al,8
 jnz  @002
 cmp  page,3
 je   @3
 cmp  page,2
 je   @2
 cmp  page,1
 je   @1
 xor  cx,cx
 jmp  @pokr
@1:
 mov  cx,3E80h
 jmp  @pokr
@2:
 mov  cx,7D00h
 jmp  @pokr
@3:
 mov  cx,0BB80h
@pokr:
 mov  dx,_CRTCReg
 mov  al,0Dh
 out  dx,al
 inc  dx
 mov  al,cl
 out  dx,al
 dec  dx
 mov  al,0Ch
 out  dx,al
 inc  dx
 mov  al,ch
 out  dx,al
end;  {screen}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure x320x200; assembler;
asm   {x320x200}
 mov  ax,13h
 int  10h
 mov  dx,_SeqAddrReg
 mov  al,4
 out  dx,al
 inc  dx
 in   al,dx
 and  al,0F7h
 or   al,4
 out  dx,al
 dec  dx
 mov  al,2
 out  dx,al
 inc  dx
 mov  al,0Fh
 out  dx,al
 mov  es,SegA000
 xor  di,di
 mov  scrwidth,0140h
 mov  scrheight,00C8h
 mov  cx,0140h*00C8h/4
 db   66h;xor  ax,ax
 db   66h;rep  stosw
 mov  dx,_CRTCReg
 mov  al,14h
 out  dx,al
 inc  dx
 in   al,dx
 and  al,0BFh
 out  dx,al
 dec  dx
 mov  al,17h
 out  dx,al
 inc  dx
 in   al,dx
 or   al,040h
 out  dx,al
 push 0
 call screen
end;  {x320x200}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure CopyPage(page1,page2:byte);
var oldport:byte;
begin {CopyPage}
 port[_GFXAddrReg]:=5;
 oldport:=port[_GFXAddrReg+1];
 port[_GFXAddrReg]:=5;
 port[_GFXAddrReg+1]:=oldport and $FC or 1;
 move(mem[SegA000:Offset_Adr[page1]],mem[SegA000:Offset_Adr[page2]],scrwidth shr 2*scrheight);
 port[_GFXAddrReg]:=5;
 port[_GFXAddrReg+1]:=oldport;
end;  {CopyPage}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure ClearScreen; assembler;
asm
@1:
 mov  dx,_FeatureReg
 in   al,dx
 test al,8
 jnz  @1
 mov  dx,_SeqAddrReg
 mov  al,2
 out  dx,al
 inc  dx
 mov  al,0Fh
 out  dx,al
 mov  es,SegA000
 xor  di,di
 mov  cx,4000h
 db   66h;xor  ax,ax
 db   66h;rep  stosw
end;  {ClearScreen}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure PutPixel(x,y:integer; color:byte); assembler;
asm   {PutPixel}
 mov  cl,byte ptr x
 and  cl,3
 mov  ax,0102h
 shl  ah,cl
 mov  dx,_SeqAddrReg
 out  dx,al
 inc  dx
 mov  al,ah
 out  dx,al
 mov  ax,scrwidth
 shr  ax,1
 shr  ax,1
 mul  y
 mov  di,ax
 mov  ax,x
 shr  ax,1
 shr  ax,1
 add  di,ax
 mov  al,color
 mov  es,SegA000
 mov  es:[di],al
end;  {PutPixel}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function GetPixel(x,y:integer):byte; assembler;
asm
 mov  ah,byte ptr x
 and  ah,3
 mov  al,4
 mov  dx,_GFXAddrReg
 out  dx,al
 inc  dx
 mov  al,ah
 out  dx,al
 mov  es,SegA000
 mov  ax,scrwidth
 shr  ax,1
 shr  ax,1
 mul  y
 mov  di,ax
 mov  ax,x
 shr  ax,1
 shr  ax,1
 add  di,ax
 mov  al,es:[di]
end;  {GetPixel}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure BIOSPutPixel(x,y:integer; color:byte); assembler;
asm   {BIOSPutPixel}
 mov  ah,0Ch
 xor  bh,bh
 mov  dx,x
 mov  cx,y
 mov  al,color
 int  10h
end;  {BIOSPutPixel}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  BIOSGetPixel(x,y:integer):byte; assembler;
asm   {BIOSGetPixel}
 mov  ah,0Dh
 xor  bh,bh
 mov  dx,x
 mov  cx,y
 int  10h
end;  {BIOSGetPixel}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin
end.
