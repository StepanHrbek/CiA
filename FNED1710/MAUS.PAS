{Obsluha mysi}
{$G+}
unit maus;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
interface
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysInit:boolean;
PROCEDURE mysOn;
PROCEDURE mysOff;
FUNCTION  mysL:boolean;
FUNCTION  mysR:boolean;
FUNCTION  mysM:boolean;
FUNCTION  mysN:boolean;
FUNCTION  mysX:word;
FUNCTION  mysY:word;
PROCEDURE mysReScan;
PROCEDURE mysRange(x1,y1,x2,y2:word);
PROCEDURE mysSet(x,y:word);
FUNCTION  mysXrel:integer;
FUNCTION  mysYrel:integer;
PROCEDURE mysSetCur(n:byte);
PROCEDURE mysSens(x,y:word);
PROCEDURE mysWaitForRelease;
FUNCTION  mysPointed(x1,x2,y1,y2:word):boolean;
FUNCTION  mysClicks(x1,x2,y1,y2:word):boolean;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 mouseHandler:boolean;
 mouseX,mouseY,mouseZ,mouseN,mouseActions:word;
 pressX,pressY,pressZ,pressActions:word;
 mouseL,mouseR,mouseM:boolean;
 mouseLoff,mouseRoff,mouseMoff:boolean;
 mouseDirty,mouseRepos:boolean;
 mouseButtons,mouseType,mouseIRQ:byte;
 mouseVer:word;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
implementation
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysInit:boolean; assembler;
asm   {mysInit}
 mov  mouseButtons,0
 mov  mouseVer,0600h
 mov  mouseType,2
 mov  mouseIRQ,2
 xor  ax,ax
 int  33h
 or   ax,ax
 jz   @end
 mov  mouseButtons,bl
 mov  ax,0024h
 int  33h
 inc  ax
 jnz  @1
 mov  mouseVer,bx
 mov  mouseType,ch
 mov  mouseIRQ,cl
@1:
 cmp  mouseButtons,4
 jb   @end
 mov  ax,11h
 int  33h
 inc  ax
 jnz  @end
 mov  mouseButtons,bl
@end:
end;  {mysInit}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mysOn; assembler;
asm   {mysOn}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,1
 int  33h
@end:
end;  {mysOn}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mysOff; assembler;
asm   {mysOff}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,2
 int  33h
@end:
end;  {mysOff}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysL:boolean; assembler;
asm   {mysL}
 xor  al,al
 cmp  mouseButtons,0
 jz   @end
 mov  ax,3
 int  33h
 mov  al,bl
 and  al,1
@end:
end;  {mysL}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysR:boolean; assembler;
asm   {mysR}
 xor  al,al
 cmp  mouseButtons,0
 jz   @end
 mov  ax,3
 int  33h
 mov  al,bl
 and  al,2
@end:
end;  {mysR}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysM:boolean; assembler;
asm   {mysM}
 xor  al,al
 cmp  mouseButtons,0
 jz   @end
 mov  ax,3
 int  33h
 mov  al,bl
 and  al,4
@end:
end;  {mysM}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysN:boolean; assembler;
asm   {mysN}
 xor  al,al
 cmp  mouseButtons,0
 jz   @end
 mov  ax,3
 int  33h
 mov  al,bl
@end:
end;  {mysN}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysX:word; assembler;
asm   {mysX}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,3
 int  33h
 mov  ax,cx
 shr  ax,1
@end:
end;  {mysX}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysY:word; assembler;
asm   {mysY}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,3
 int  33h
 mov  ax,dx
@end:
end;  {mysY}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mysReScan; assembler;
asm   {mysReScan}
 cmp  mouseButtons,0
 jz   @err
 mov  ax,3
 int  33h
 shr  cx,1
 mov  mouseX,cx
 mov  mouseY,dx
 and  bx,7
 mov  mouseZ,bx
 jmp  @end
@err:
 mov  mouseX,0
 mov  mouseY,0
 mov  mouseZ,0
@end:
end;  {mysReScan}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mysRange(x1,y1,x2,y2:word); assembler;
asm   {mysRange}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,7
 mov  cx,x1
 mov  dx,x2
 shr  cx,1
 shr  dx,1
 int  33h
 mov  ax,8
 mov  cx,y1
 mov  dx,y2
 int  33h
@end:
end;  {mysRange}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mysSet(x,y:word); assembler;
asm   {mysSet}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,4
 mov  cx,x
 mov  dx,y
 shl  cx,1
 int  33h
@end:
end;  {mysSet}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysXrel:integer; assembler;
asm   {mysXrel}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,0Bh
 int  33h
 mov  ax,cx
@end:
end;  {mysXrel}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysYrel:integer; assembler;
asm   {mysYrel}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,0Bh
 int  33h
 mov  ax,dx
@end:
end;  {mysYrel}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE cursors; assembler;
asm   {cursors}
 dw   0011111111111111b
 dw   0001111111111111b
 dw   0000111111111111b
 dw   0000011111111111b
 dw   0000001111111111b
 dw   0000000111111111b
 dw   0000000011111111b
 dw   0000000001111111b
 dw   0000000000111111b
 dw   0000000000011111b
 dw   0000000000111111b
 dw   0000011111111111b
 dw   0000111111111111b
 dw   0001111111111111b
 dw   1011111111111111b
 dw   1111111111111111b
 dw   0000000000000000b
 dw   0100000000000000b
 dw   0110000000000000b
 dw   0111000000000000b
 dw   0111100000000000b
 dw   0111110000000000b
 dw   0111111000000000b
 dw   0111111100000000b
 dw   0111111110000000b
 dw   0111111111000000b
 dw   0111100000000000b
 dw   0111000000000000b
 dw   0110000000000000b
 dw   0100000000000000b
 dw   0000000000000000b
 dw   0000000000000000b
 dw   0111111111111111b
 dw   0011111111111111b
 dw   0001111111111111b
 dw   0000111111111111b
 dw   0000011111111111b
 dw   0000001111111111b
 dw   0000000111111111b
 dw   0000000011111111b
 dw   0000000001111111b
 dw   0000000000111111b
 dw   0000000000111111b
 dw   0000111111111111b
 dw   0001111111111111b
 dw   0011111111111111b
 dw   1111111111111111b
 dw   1111111111111111b
 dw   1000000000000000b
 dw   1100000000000000b
 dw   1110000000000000b
 dw   1111000000000000b
 dw   1111100000000000b
 dw   1111110000000000b
 dw   1111111000000000b
 dw   1111111100000000b
 dw   1111111110000000b
 dw   1111111111000000b
 dw   1111000000000000b
 dw   1110000000000000b
 dw   1100000000000000b
 dw   1000000000000000b
 dw   0000000000000000b
 dw   0000000000000000b
end;  {cursors}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mysSetCur(n:byte); assembler;
asm   {mysSetCur}
 cmp  mouseButtons,0
 jz   @end
 push es
 xor  bx,bx
 xor  cx,cx
 mov  dx,seg cursors
 mov  es,dx
 mov  dx,offset cursors
 xor  al,al
 mov  ah,n
 shr  ax,1
 shr  ax,1
 add  dx,ax
 mov  ax,9
 int  33h
 pop  es
@end:
end;  {mysSetCur}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mysSens(x,y:word); assembler;
asm   {mysSens}
 cmp  mouseButtons,0
 jz   @end
 mov  ax,0Fh
 mov  cx,x
 mov  dx,y
 int  33h
@end:
end;  {mysSens}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mouseSetHandler(b:boolean);assembler;
asm
 cmp  b,false
 je   @odpoj
@zaves:
 cmp  mouseHandler,false
 jnz  @end
 mov  mouseZ,0
 mov  pressZ,0
 mov  ax,0Ch
 mov  cx,7Fh
 lea  dx,@handler
 push cs
 pop  es
 int  33h
 mov  mouseHandler,true
 jmp  @end
@odpoj:
 cmp  mouseHandler,false
 jz   @end
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
 and  ax,7Eh
 jz   @nopress
 mov  pressX,cx
 mov  pressY,dx
 mov  pressZ,bx
 or   pressActions,ax
@nopress:
 POP  DS
 RETF
@end:
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE mysWaitForRelease; assembler;
asm   {mysWaitForRelease}
 cmp  mouseButtons,0
 jz   @end
@1:
 mov  ax,3
 int  33h
 or   bl,bl
 jnz  @1
@end:
end;  {mysWaitForRelease}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysPointed(x1,x2,y1,y2:word):boolean; assembler;
asm
 cmp  mouseButtons,0
 jz   @ne
 mov  ax,3
 int  33h
 shr  cx,1
 cmp  cx,x1
 jb   @ne
 cmp  cx,x2
 ja   @ne
 cmp  dx,y1
 jb   @ne
 cmp  dx,y2
 ja   @ne
@ano:
 mov  al,1
 jmp  @end
@ne:
 xor  al,al
@end:
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  mysClicks(x1,x2,y1,y2:word):boolean; assembler;
asm
 cmp  mouseButtons,0
 jz   @ne
 mov  ax,3
 int  33h
 test bx,3
 jz   @ne
 shr  cx,1
 cmp  cx,x1
 jb   @ne
 cmp  cx,x2
 ja   @ne
 cmp  dx,y1
 jb   @ne
 cmp  dx,y2
 ja   @ne
@ano:
 mov  al,1
 jmp  @end
@ne:
 xor  al,al
@end:
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin
 mysInit;
end.