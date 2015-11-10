{$G+}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
unit syst; {Zakladni a velice potrebne funkce}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
interface
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
const
 lastscan:byte=0;
type
 string2 =string[2];
 string8 =string[8];
 string11=string[11];
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Bi2By(w:word):word;inline($58/5/7/0/$c1/$e8/3);{pop ax;add ax,7;shr ax,3}
FUNCTION  MinW(x,y:word):word;inline($58/$5b/$3b/$c3/$72/$01/$93);{pop ax;pop bx;cmp ax,bx;jb +1;xchg ax,bx}
FUNCTION  MaxW(x,y:word):word;inline($58/$5b/$3b/$c3/$77/$01/$93);{pop ax;pop bx;cmp ax,bx;ja +1;xchg ax,bx}
FUNCTION  MinI(x,y:integer):integer;inline($58/$5b/$3b/$c3/$7e/$01/$93);{pop ax;pop bx;cmp ax,bx;jle +1;xchg ax,bx}
FUNCTION  MaxI(x,y:integer):integer;inline($58/$5b/$3b/$d8/$7e/$01/$93);{pop ax;pop bx;cmp bx,ax;jle +1;xchg ax,bx}
FUNCTION  MinL(x,y:longint):longint;inline($66/$58/$66/$5b/$66/$3b/$c3/$7e/$02/$66/$93/ $66/$50/$59/$5a);{jako MaxI/MinI,}
FUNCTION  MaxL(x,y:longint):longint;inline($66/$58/$66/$5b/$66/$3b/$d8/$7e/$02/$66/$93/ $66/$50/$59/$5a);{ale s hi(eax)->dx}
FUNCTION  Wrapped(n,min,max:longint):longint;
FUNCTION  Bounded(n,min,max:longint):longint;
FUNCTION  IsIn(n,min,max:LongInt):boolean;
FUNCTION  either(cond:boolean; res1,res2:LongInt):LongInt;
FUNCTION  eitherS(cond:boolean; res1,res2:string):string;
PROCEDURE MoveFast(var source,dest; count:word);
PROCEDURE FillChar(var d; cnt:word; b:byte);
PROCEDURE FillWord(var d; cnt:word; w:Word);
FUNCTION  CmpByte(blok:pointer;val:byte;bytes:word):boolean;
PROCEDURE Xchg(var a,b;bytes:word);
PROCEDURE xchgbit(var n1:byte; b1:byte; var n2:byte; b2:byte);
PROCEDURE bitset(n:byte; var b:byte);
PROCEDURE bitdel(n:byte; var b:byte);
PROCEDURE invbitmap(var buf; s:word);
PROCEDURE rolbits(var buf; bits:word; doleva:boolean);
PROCEDURE BiosWrite(st:string);
PROCEDURE BiosWriteln(st:string);
FUNCTION  Rep(c:char;kolikrat:byte):string;
FUNCTION  Left(st:string;len:byte):string;
FUNCTION  Right(st:string;len:byte):string;
FUNCTION  WithoutChar(c:char;s:string):string;
FUNCTION  AskKeyExt(list:string):string2;
FUNCTION  KeyPressed:boolean; inline($b4/$0b/$cd/$21);{mov ah,0bh;int 21h}
FUNCTION  ReadKey:char; inline($b4/$08/$cd/$21);{mov ah,8;int 21h}
PROCEDURE WaitKey; inline($b8/$0c08/$cd/$21);{mov ax,0c08h;int 21h}
PROCEDURE FlushKey;
FUNCTION  Inkeys:string2;
FUNCTION  Stri(num:longint):string11;
FUNCTION  Valu(st:string11):longint;
FUNCTION  Hexed(d:longint):string8;
FUNCTION  Dehexed(s:string8):longint;
FUNCTION  CutString(var s:openstring;separator:char):string;
FUNCTION  times:string8;
FUNCTION  dates:string8;
PROCEDURE feasts;
FUNCTION  DosExitCode:byte;
PROCEDURE Xlat(var st:openstring;src,dest:string);
FUNCTION  Xlated(st,src,dest:string):string;
PROCEDURE XLatStr(var s:string; scr,dest:string);
FUNCTION  XlatedStr(st,src,dest:string):string;
FUNCTION  lcased(s:string):string;
FUNCTION  ucased(s:string):string;
FUNCTION  GetPos(st:string;c:char;n:integer):integer;
FUNCTION  GetString(st:string;separator:char;n:integer):string;
FUNCTION  MaxStrings(s:string; separator:char):byte;
FUNCTION  GetCore(st:string):string;
FUNCTION  Kamenici2Ascii(st:openstring):string;
FUNCTION  DeStr2Pc(var st:openstring):pchar;
PROCEDURE WaitTicks(n:word);
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
implementation
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
const
 Kamenici:string[30]=
 'à®á©ëò†°Ç£ñü§É¢'+
 'âõÄûíùèãêó¶Ü•Öï';
 Ascii:string[30]=
 'escrzyaieuutndo'+
 'ESCRZYAIEUUTNDO';
var
 origExitProc:pointer;
 memBefore:longint;
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
function ErrorMsg(n:integer):string;
begin {ErrorMsg}
 case n of
 1:   ErrorMsg:='Invalid function number';
 2:   ErrorMsg:='File not found';
 3:   ErrorMsg:='Path not found';
 4:   ErrorMsg:='Too many open files';
 5:   ErrorMsg:='File access denied';
 6:   ErrorMsg:='Invalid file handle';
 12:  ErrorMsg:='Invalid file access code';
 15:  ErrorMsg:='Invalid drive number';
 16:  ErrorMsg:='Cannot remove current directory';
 17:  ErrorMsg:='Cannot rename across drives';
 18:  ErrorMsg:='No more files';
 100: ErrorMsg:='Disk read error';
 101: ErrorMsg:='Disk write error';
 102: ErrorMsg:='File not assigned';
 103: ErrorMsg:='File not open';
 104: ErrorMsg:='File not open for input';
 105: ErrorMsg:='File not open for output';
 106: ErrorMsg:='Invalid numeric format';
 150: ErrorMsg:='Disk is write-protected';
 151: ErrorMsg:='Bad drive request struct length';
 152: ErrorMsg:='Drive not ready';
 154: ErrorMsg:='CRC error in data';
 156: ErrorMsg:='Disk seek error';
 157: ErrorMsg:='Unknown media type';
 158: ErrorMsg:='Sector Not Found';
 159: ErrorMsg:='Printer out of paper';
 160: ErrorMsg:='Device write fault';
 161: ErrorMsg:='Device read fault';
 162: ErrorMsg:='Hardware failure';
 200: ErrorMsg:='Division by zero';
 201: ErrorMsg:='Range check error';
 202: ErrorMsg:='Stack overflow error';
 203: ErrorMsg:='Heap overflow error';
 204: ErrorMsg:='Invalid pointer operation';
 205: ErrorMsg:='Floating point overflow';
 206: ErrorMsg:='Floating point underflow';
 207: ErrorMsg:='Invalid floating point operation';
 208: ErrorMsg:='Overlay manager not installed';
 209: ErrorMsg:='Overlay file read error';
 210: ErrorMsg:='Object not initialized';
 211: ErrorMsg:='Call to abstract method';
 212: ErrorMsg:='Stream registration error';
 213: ErrorMsg:='Collection index out of range';
 214: ErrorMsg:='Collection overflow error';
 215: ErrorMsg:='Arithmetic overflow error';
 216: ErrorMsg:='General Protection fault';
 255: ErrorMsg:='CTRL-Break pressed';
 else ErrorMsg:='(unknown error)';
 end; {/case}
end;  {ErrorMsg}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
{$F+}
procedure myExitProc;far;
{Tato procedura se zavola, kdyz dojde k chybe.
 Vypise cislo chyby, co znamena, kde nastala a volnou pamet'. Pak skonci.}
begin {myExitProc}
 ExitProc:=@origExitProc;
 asm
  push ds
  mov  ds,Seg0040
  mov  al,ds:[0049h]
  cmp  al,3
  je   @1
  mov  ax,1202h
  mov  bl,30h
  int  10h
  mov  ax,3
  int  10h
  mov  ax,1112h
  xor  bl,bl
  int  10h
 @1:
  pop  ds
 end;
 if ExitCode=0 then BiosWrite('Good bye'#13#10) else
 if ExitCode=255 then
  begin
   BiosWrite('Who turned the light off?'#13#10);
   BiosWrite('Mmm, only some chap pressed CTRL-Break.'#13#10);
   BiosWrite('A-ha.'#13#10);
  end
 else
  begin
   BiosWrite('Sorry, error:'#13#10);
   BiosWrite('ExitCode ='+stri(ExitCode)+', '+ErrorMsg(ExitCode)+#13#10);
   BiosWrite('ErrorAddr='+hexed(seg(ErrorAddr))+':'+hexed(ofs(ErrorAddr))+#13#10);
   BiosWrite('MemAvail ='+stri(memavail)+'b. (diff:'+stri(memBefore-memavail)+')'#13#10);
  end;
 asm
  mov  ax,4C00h
  int  21h
 end;
end;  {myExitProc}
{$F-}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure errExit(msg:string);
begin {errExit}
 asm
  push ds
  mov  ds,Seg0040
  mov  al,ds:[0049h]
  cmp  al,3
  je   @1
  mov  ax,1202h
  mov  bl,30h
  int  10h
  mov  ax,3
  int  10h
  mov  ax,1112h
  xor  bl,bl
  int  10h
 @1:
  pop  ds
 end;
 BiosWrite(msg+#13#10);
 halt(0);
end;  {errExit}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Wrapped(n,min,max:longint):longint;
begin {Wrapped}
 n:=(n-min) mod (max-min+1);
 if n<0 then wrapped:=n+max+1 else wrapped:=n+min;
end;  {Wrapped}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
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
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION IsIn(n,min,max:LongInt):boolean; assembler;
asm   {IsIn}
 db  66h;mov  ax,word ptr n
 db  66h;mov  bx,word ptr min
 db  66h;mov  cx,word ptr max
 db  66h;cmp  bx,cx
 jle @cont
 db  66h;mov  bx,word ptr max
 db  66h;mov  cx,word ptr min
@cont:
 db  66h;cmp  ax,bx
 jl  @ne
 db  66h;cmp  ax,cx
 jg  @ne
 mov al,true
 jmp @end
@ne:
 mov al,false
@end:
end;  {IsIn}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION either(cond:boolean; res1,res2:LongInt):LongInt; assembler;
asm   {either}
 mov  al,cond
 cmp  al,0
 je   @res2
 mov  ax,word ptr res1
 mov  dx,word ptr res1+2
 jmp  @end
@res2:
 mov  ax,word ptr res2
 mov  dx,word ptr res2+2
@end:
end;  {either}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
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
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
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
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE MoveFast(var source,dest; count:word); assembler;
{Presune count bytu ze source do dest. Pouziva zarovnavani a MovSD}
asm   {MoveFast}
 push es
 push ds
 cmp  count,0
 jz   @end
 cld
 lds  si,source    {ds:[si]=source}
 les  di,dest      {es:[di]=dest}
 mov  cx,count     {cx=count}
 test ax,1
 jz   @1
 movsb
@1:
 test cx,2
 jz   @2
 movsw
@2:
 shr  cx,2         {cx=count/4}
 db   66h;rep  movsw  {dw(es:[di])  dw(ds:[si]); add di,4; add si,4}
@end:
 pop  ds
 pop  es
end;  {MoveFast}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE FillChar(var d; cnt:word; b:byte);assembler;
{Vyplni promennou zadanym bytem. Pouziva zarovnavani a StoSD}
asm   {FillChar}
 push ds
 push es
 cmp  cnt,0
 je   @end
 cld
 les  di,d
 mov  cx,cnt
 mov  al,b
 mov  ah,al
 push ax
 push ax
 db   66h;pop  ax
 test cx,1
 jz   @1
 stosb
@1:
 test cx,2
 jz   @2
 stosw
@2:
 shr  cx,2
 db   66h;rep  stosw
@end:
 pop  es
 pop  ds
end;  {FillChar}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE FillWord(var d; cnt:word; w:Word);assembler;
{Vyplni promennou zadanym wordem. Pouziva zarovnavani a StoSD}
asm   {FillWord}
 push es
 cmp  cnt,0
 jz   @end
 cld
 les  di,d
 mov  cx,cnt
 mov  ax,w
 db   66h;rol  ax,16
 mov  ax,w
 test cx,1
 jz   @1
 stosw
@1:
 shr  cx,1
 db   66h;rep  stosw
@end:
 pop  es
end;  {FillWord}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  CmpByte(blok:pointer;val:byte;bytes:word):boolean; assembler;
asm   {CmpByte}
 push ds
 les  di,blok
 mov  al,val
 mov  cx,bytes
 repe scasb
 mov  al,1
 jz   @same
 xor  al,al
@same:
 pop  ds
end;  {CmpByte}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE Xchg(var a,b;bytes:word); assembler;
asm   {Xchg}
 push ds
 lds  si,a
 les  di,b
 mov  cx,bytes
@1:
 mov  al,[es:di]
 xchg al,[si]
 stosb
 inc  si
 loop @1
 pop  ds
end;  {Xchg}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure bitset(n:byte; var b:byte); assembler;
asm   {bitset}
 mov  al,1
 mov  cl,n
 shl  al,cl
 les  di,b
 mov  ah,es:[di]
 or   ah,al
 mov  es:[di],ah
end;  {bitset}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure bitdel(n:byte; var b:byte); assembler;
asm   {bitdel}
 mov  al,1
 mov  cl,n
 shl  al,cl
 not  al
 les  di,b
 mov  ah,es:[di]
 and  ah,al
 mov  es:[di],ah
end;  {bitdel}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure invbitmap(var buf; s:word); assembler;
asm   {invbitmap}
 push ds
 push es
 lds  si,buf
 les  di,buf
 mov  cx,s
 jcxz @end
 mov  bl,cl
 and  bl,3
 shr  cx,1
 shr  cx,1
 jcxz @2
@1:
 db   66h;lodsw
 db   66h;not  ax
 db   66h;stosw
 loop @1
@2:
 mov  cl,bl
 jcxz @end
@3:
 lodsb
 not  al
 stosb
 loop @3
@end:
 pop  es
 pop  ds
end;  {invbitmap}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE xchgbit(var n1:byte; b1:byte; var n2:byte; b2:byte); assembler;
asm   {xchgbit}
 les  di,n1
 mov  cx,es
 mov  bx,di
 mov  ah,es:[di]
 les  di,n2
 mov  dx,es
 sub  cx,dx
 jne  @dal
 cmp  di,bx
 je   @stejne
@dal:
 mov  al,es:[di]
 mov  dx,0101h
 mov  cl,b1
 shl  dh,cl
 mov  cl,b2
 shl  dl,cl
 not  dx
 mov  bx,ax
 and  ax,dx
 not  dx
 test bl,dl
 jz   @1
 add  ah,dh
@1:
 test bh,dh
 jz   @2
 add  al,dl
@2:
 mov  es:[di],al
 les  di,n1
 mov  es:[di],ah
 jmp  @end
@stejne:
 mov  dl,b1
 cmp  dl,b2
 je   @end
 mov  dx,0101h
 mov  cl,b1
 shl  dh,cl
 mov  cl,b2
 shl  dl,cl
 mov  al,dl
 add  al,dh
 not  al
 mov  cl,ah
 and  ah,al
 test cl,dl
 jz   @3
 add  ah,dh
@3:
 test cl,dh
 jz   @4
 add  ah,dl
@4:
 mov  es:[di],ah
@end:
end;  {xchgbit}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE rolbits(var buf; bits:word; doleva:boolean); assembler;
asm   {rolbits}
 cmp  bits,0
 je   @end
 les  di,buf
 mov  cl,byte ptr bits
 neg  cl
 and  cl,7
 mov  dx,0FF01h
 shl  dl,cl
 shl  dh,cl
 mov  cx,bits
 add  cx,7
 shr  cx,1
 shr  cx,1
 shr  cx,1
 mov  bx,cx
 dec  bx
 cmp  doleva,false
 je   @doprava
 test byte ptr es:[di],80h
 jz   @1
 shr  dl,1
 pushf {trochu prasacky, ale hlavne ze to funguje :)}
 or   es:[di+bx],dl
 add  di,bx
 popf
 jmp  @2
@1:
 add  di,bx
@2:
 rcl  byte ptr es:[di],1
 dec  di
 loop @2
 jmp  @usekni

@doprava:
 clc
 test byte ptr es:[di+bx],dl
 jz   @0
 stc
@0:
 rcr  byte ptr es:[di],1
 inc  di
 loop @0
@usekni:
 les  di,buf
 and  es:[di+bx],dh
@end:
end;  {rolbits}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE BiosWrite(st:string);assembler;
{To same jako write, ale funguje i pri IO chybe}
var p:pointer absolute st;
asm   {BiosWrite}
 push ds
 mov  ah,40h
 lds  bx,p
 mov  cl,[bx]
 mov  dx,bx
 xor  ch,ch
 inc  dx
 mov  bx,1
 int  21h
 pop  ds
end;  {BiosWrite}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE BiosWriteln(st:string);assembler;
var p:pointer absolute st;
asm   {BiosWriteln}
 push ds
 mov  ah,40h
 lds  bx,p
 mov  cl,[bx]
 mov  dx,bx
 mov  ch,0
 inc  dx
 mov  bx,1
 int  21h
 mov  ah,40h
 push cs
 pop  ds
 lea  dx,@newline
 mov  cl,2
 int  21h
 pop  ds
 jmp  @end
@newline:
 db   13,10
@end:
end;  {BiosWriteln}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Left(st:string;len:byte):string;
begin {Left}
 Left:=copy(st,1,len)+rep(' ',maxI(0,len-length(st)));
end;  {Left}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Right(st:string;len:byte):string;
begin {Right}
 Right:=rep(' ',maxI(0,len-length(st)))+copy(st,maxI(1,length(st)-len+1),255);
end;  {Right}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  WithoutChar(c:char;s:string):string; assembler;
asm   {WithoutChar}
 push ds
 push es
 cld
 les  di,@result
 lds  si,s
 lodsb
 inc  di
 xor  ch,ch
 mov  cl,al
 xor  bl,bl
 jcxz @3
@1:
 lodsb
 cmp  al,c
 je   @2
 stosb
 inc  bl
@2:
 loop @1
@3:
 les  di,@result
 mov  es:[di],bl
@end:
 pop  es
 pop  ds
end;  {WithoutChar}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION AskKeyExt(list:string):string2;
var
 c:string2;
 j:byte;
begin {AskKeyExt}
 AskKeyExt:='';
 if list='' then
  begin
   waitkey;
   exit;
  end;
 repeat
  c[1]:=readkey;
  if c[1]=#0
  then begin c[0]:=#2; c[2]:=readkey; end
  else       c[0]:=#1;
  j:=Pos(c,list);
  if length(c)=1 then
   while (j>1) and (list[j-1]=#0) do
    j:=Pos(c,Copy(list,j+1,$FF));
 until j<>0;
 AskKeyExt:=c;
end;  {AskKeyExt}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE FlushKey;
begin {FlushKey}
 memw[seg0040:$1C]:=memw[seg0040:$1A];
end;  {FlushKey}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
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
 mov  lastscan,ah
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
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Stri(num:longint):string11;
var st:string11;
begin {Stri}
 str(num,st);
 stri:=st;
end;  {Stri}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Valu(st:string11):longint;
var   l:longint;
      code:word;
begin {Valu}
 val(st,l,code);
 if code=0 then valu:=l else valu:=0;
end;  {Valu}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION Hexed(d:longint):string8; assembler;
asm   {hexed}
 push es
 les  di,@result
 mov  si,di
 inc  di
 xor  bx,bx   {bl=delka vysledneho stringu}
 mov  al,byte ptr d+3
 call @hex
 mov  al,byte ptr d+2
 call @hex
 mov  al,byte ptr d+1
 call @hex
 mov  al,byte ptr d
 call @hex
 jmp  @end
@hex:
 mov  ah,al
 shr  ah,4
 test bh,1    {bh=either("narazili jsme na 1. nenulovy hex (zleva)",1,0)}
 jnz  @hex0
 or   ax,ax
 jz   @hexdone
 or   bh,1
 or   ah,ah
 jz   @nextnibble
@hex0:
 cmp  ah,9
 jbe  @hex1
 add  ah,'A'-'0'-0Ah
@hex1:
 add  ah,'0'
 mov  es:[di],ah
 inc  di
 inc  bl
@nextnibble:
 and  al,0Fh
 or   ax,ax
 jz   @hexdone
 cmp  al,9
 jbe  @hex2
 add  al,'A'-'0'-0Ah
@hex2:
 add  al,'0'
 stosb
 inc  bl
@hexdone:
 retn
@end:
 mov  es:[si],bl
 pop  es
end;  {hexed}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Dehexed(s:string8):longint; assembler;
asm   {Dehexed}
 push ds
 lds  si,s
 xor  ch,ch
 lodsb
 mov  cl,al
 xor  bx,bx
 xor  dx,dx
 cmp  cx,4
 ja   @2
@1:
 call @zpracujhex
 shl  bx,4
 add  bl,al
 inc  al
 jz   @err
 loop @1
 jmp  @end
@2:
 add  si,cx
 sub  si,4
 mov  cx,4
@3:
 call @zpracujhex
 shl  bx,4
 add  bl,al
 inc  al
 jz   @err
 loop @3
 lds  si,s
 lodsb
 xor  ch,ch
 mov  cl,al
 sub  cx,4
 cmp  cx,4
 jb   @4
 add  si,cx
 sub  si,4
 mov  cx,4
@4:
 call @zpracujhex
 shl  dx,4
 add  dl,al
 inc  al
 jz   @err
 loop @4
 jmp  @end

@zpracujhex:       {nahraje hex a prevede ho na cislo -1..15 v AL (-1=chyba)}
 lodsb
 cmp  al,'f'
 ja   @hexerr
 cmp  al,'a'
 jae  @hex1
 cmp  al,'F'
 ja   @hexerr
 cmp  al,'A'
 jae  @hex2
 cmp  al,'9'
 ja   @hexerr
 cmp  al,'0'
 jae  @hex3
@hexerr:
 mov  al,0FFh
 jmp  @hexdone
@hex1:
 sub  al,'a'-'A'
@hex2:
 sub  al,'A'-'0'-0Ah
@hex3:
 sub  al,'0'
@hexdone:
 retn

@err:
 mov  bx,0FFFFh
 mov  dx,0FFFFh
@end:
 mov  ax,bx
 mov  cx,dx
 pop  ds
end;  {Dehexed}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  CutString(var s:openstring;separator:char):string; assembler;
{Odkroji string az po prvni vyskyt separatoru. Pravou cast da do promenne
 a levou vrati jako vysledek funkce. Neni optimalizovan†, ale presto je asi
 2.5 x rychlejsi nez Pascalska verze.}
var Len,Right:byte;
asm   {CutString}
 push ds
 push es
 cld
 les  di,s
 mov  ch,0
 mov  cl,es:[di]
 mov  Len,cl       {v cl je delka promenne}
 inc  di
 mov  al,separator
 repne scasb       {v cl je pocet znaku za separatorem}
 cmp  cl,0
 jne  @dal
 cmp  es:[di-1],al
 jne  @spec
@dal:
 mov  Right,cl
 neg  cl
 add  cl,Len
 dec  cl           {v cl je pocet znaku pred separatorem}
 les  di,@result
 mov  al,cl
 stosb
 lds  si,s         {zkopiruje levou cast do vysledku funkce}
 inc  si
 rep  movsb
 les  di,s
 lds  si,s
 mov  al,Right
 stosb
 mov  cl,Len
 sub  cl,Right
 inc  cl
 add  si,cx
 mov  cl,Right
 rep  movsb
 jmp  @end
@spec:             {zvlastni pripad, kdy string neobsahuje separator}
 lds  si,s
 les  di,@result
 lodsb
 stosb
 mov  cl,al
 rep  movsb
 les  di,s
 mov  es:[di],ch
@end:
 pop  es
 pop  ds
end;  {CutString}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  times:string8;
var h,m,s,z:byte;
begin {times}
 asm
  mov  ah,2Ch
  int  21h
  mov  h,ch
  mov  m,cl
  mov  s,dh
  mov  z,dl
 end;
 times:=chr(48+h div 10)+chr(48+h mod 10)+chr(32+26*byte(z>49))+chr(48+m div 10)+chr(48+m mod 10);
end;  {times}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  dates:string8;
var
 m,d:byte;
 y:word;
begin {dates}
 asm
  mov  ah,2Ah
  int  21h
  mov  y,cx
  mov  m,dh
  mov  d,dl
 end;
 dates:=chr(48+d div 10 mod 10)+chr(48+d mod 10)+'.'
 +chr(48+m div 10 mod 10)+chr(48+m mod 10)+'.'
 +chr(48+y div 10 mod 10)+chr(48+y mod 10);
end;  {dates}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE feasts;
{Precte systemove datum a podle nej zareaguje na nejvyznamnejsi svatky v roce}
const
 DayOfWeek:array[0..7] of string[7]=(
 'nedele','pondeli','utery','streda','ctvrtek','patek','sobota','nedele');
 Month:array[1..12] of string[8]=(
 'ledna','unora','brezna','dubna','qetna','cervna','cervence','srpna','zari','rijna','listopadu','prosince');
var
 w,m,d,h:byte;
 y:word;
begin {feasts}
 asm
  mov  ah,2Ah
  int  21h
  mov  w,al
  mov  y,cx
  mov  m,dh
  mov  d,dl
  mov  ah,2Ch
  int  21h
  mov  h,ch
 end;
 writeln('Dnes je '+DayOfWeek[w and 7]+', ',d,'. '+Month[1+(m-1) mod 12]+' ',y,'.');
 case h of
 4..6:   writeln('Jak videt, ran° pt†ce d†l dosk†ce. Preji V†m dobrÇ jitro.');
 7,8:    writeln('Preji V†m dobrÇ r†no.');
 9,10:   writeln('Preji V†m dobrÇ dopoledne.');
 11,12:  writeln('Preji V†m dobrÇ poledne.');
 13..16: writeln('Preji V†m dobrÇ odpoledne.');
 17,18:  writeln('Preji V†m dobrÇ pozdn° odpoledne.');
 19..20: writeln('Preji V†m dobry vecer.');
 21,22:  writeln('Preji V†m dobrou noc.');
 23,0:   writeln('Preji V†m £spesnou pulnoc :-)');
 1..3:   writeln('Preji V†m £spesny prichazej°c° den.');
 end;
 case d shl 8+m of
 $0101: begin
         writeln('Preji V†m stastny novy rok ',y,'!');
         {waitkey;}
        end;
 $0601: begin
         writeln('Na tri kr†le o krok d†le!');
         {waitkey;}
        end;
 $0102: begin
         writeln('Na hromnice o den v°ce!');
         {waitkey;}
        end;
 $0104: begin
         writeln('Program je asi nakazen!'); {waitkey;}
         writeln('Apr°l ;-)');;waitkey
        end;
 $0105: begin
         writeln('Dnes je sv†tek pr†ce.');
         writeln('Je od V†s velmi milÇ, ze jej tr†v°te pr†ve prac°.');
         {waitkey;}
        end;
 $0805: begin
         writeln('Dnes se slav° ',y-1945,'. vyroc° konce II. svetovÇ v†lky.');
         {waitkey;}
        end;
 $0607: begin
         writeln('Dnes si pripom°n†me vyroc° prvn°ho letu do vesm°ru.');
         writeln('Bohuzel, n†s prvn° kosmonaut shorel pri startu');
         {waitkey;}
        end;
 $1C0A: begin
         writeln('Dnes nemus°te pracovat, je st†tn° sv†tek.');
         writeln('Pred ',y-1918,'-ti lety bylo zalozeno samostatnÇ Ceskoslovensko.');
         {waitkey;}
        end;
 $060C: begin
         writeln('Dnes je Mikul†®e. At'' V†m neco nadel°');
         {waitkey;}
        end;
 $170C: writeln('Z°tra bude Stedry Den. Douf†m, ze jste nezapomneli nakoupit d†rky.');
 $180C: begin
         writeln('Dnes je Stedry Den.');
         writeln('VeselÇ v†noce!');
         {waitkey;}
        end;
 $190C: begin
         writeln('Dnes je prvni svatek vanocni.');
         writeln('VeselÇ v†noce!');
         {waitkey;}
        end;
 $1A0C: begin
         writeln('Dnes je druhy svatek vanocni.');
         writeln('VeselÇ v†noce!');
         {waitkey;}
        end;
 $1F0C: begin
         writeln('Vesely silvestr!');
         {waitkey;}
        end;
 end;
 if m in [7,8] then
  begin
   writeln('Nepracujte a uz°vejte si pr†zdniny.');
  end;
 if (m=4) and (d in [8..15]) then
  if w=0 then
   begin
    writeln('Dnes je velikonocn° nedele.');
    writeln('VeselÇ velikonoce!');
    {waitkey;}
   end else
  if w=1 then
   begin
    writeln('Dnes je velikonocn° pondel°.');
    writeln('VeselÇ velikonoce a bohatou poml†sku!');
    {waitkey;}
   end else
end;  {feasts}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  DosExitCode:byte; assembler;
asm    {DosExitCode}
 mov  ah,04Dh
 int  21h
 mov  al,ah
end;   {DosExitCode}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE Xlat(var st:openstring;src,dest:string);
var   i,j:word;
begin {Xlat}
 for i:=1 to length(st) do begin
   j:=pos(st[i],src);
   if j>0 then st[i]:=dest[j];
   end;
end;  {Xlat}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Xlated(st,src,dest:string):string;
begin {Xlated}
 Xlat(st,src,dest);
 Xlated:=st;
end;  {Xlated}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE XLatStr(var s:string; scr,dest:string);
var i:byte;
begin {XLatStr}
 i:=Pos(scr,s);
 if i<1 then exit;
 Delete(s,i,length(scr));
 Insert(dest,s,i);
end;  {XLatStr}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  XlatedStr(st,src,dest:string):string;
begin {XlatedStr}
 XlatStr(st,src,dest);
 XlatedStr:=st;
end;  {XlatedStr}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  lcased(s:string):string; assembler;
asm   {lcased}
 push ds
 push es
 lds  si,s
 les  di,@Result
 xor  ch,ch
 mov  cl,ds:[si]
 movsb
 jcxz @3
@1:
 lodsb
 cmp  al,'A'
 jl   @2
 cmp  al,'Z'
 jg   @2
 add  al,32
@2:
 stosb
 loop @1
@3:
 pop  es
 pop  ds
end;  {lcased}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  ucased(s:string):string; assembler;
asm   {ucased}
 push es
 push ds
 cld
 lds  si,s
 les  di,@Result
 xor  ch,ch
 mov  cl,ds:[si]
 movsb
 jcxz @3
@1:
 lodsb
 cmp  al,'a'
 jl   @2
 cmp  al,'z'
 jg   @2
 sub  al,'a'-'A'
@2:
 stosb
 loop @1
@3:
 pop  ds
 pop  es
end;  {ucased}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  Kamenici2Ascii(st:openstring):string;
var i:byte;
begin {Kamenici2Ascii}
 for i:=1 to length(st) do
  if pos(st[i],Kamenici)<>0 then st[i]:=ascii[pos(st[i],Kamenici)];
 Kamenici2Ascii:=st;
end;  {Kamenici2Ascii}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  DeStr2Pc(var st:openstring):pchar; assembler;
var p:byte absolute st;
asm   {DeStr2Pc}
 push ds
 cld
 lds  si,p
 les  di,p
 lodsb
 mov  cl,al
 xor  ch,ch
 rep  movsb
 xor  al,al
 stosb
 pop  ds
 mov  ax,word ptr p
 mov  dx,word ptr p+2
end;  {DeStr2Pc}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  GetCore(st:string):string;
begin {GetCore}
 while (st>'') and (st[length(st)] in [' ',#0]) do dec(st[0]);
 while (st>'') and (st[1] in [' ',#0]) do delete(st,1,1);
 GetCore:=st;
end;  {GetCore}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  GetPos(st:string;c:char;n:integer):integer;
{ Vrati pozici n-teho vyskytu znaku c ve stringu st.}
var i:word;
begin {GetPos}
 if n<1 then
  begin
   GetPos:=0;
   exit;
  end;
 for i:=1 to length(st) do
  if st[i]=c then
   if n>1 then dec(n) else
    begin
     GetPos:=i;
     exit;
    end;
 GetPos:=length(st)+1;
end;  {GetPos}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  GetString(st:string;separator:char;n:integer):string;
{Vrati n-ty prvek z retezce slov oddelenych separatorem.}
var i,j:integer;
begin {GetString}
 i:=GetPos(st,separator,n-1);
 j:=GetPos(st,separator,n);
 GetString:=copy(st,i+1,j-i-1);
end;  {GetString}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  MaxStrings(s:string; separator:char):byte; assembler;
{Vrati pocet prvku v retezci slov oddelenych separatorem.}
asm   {MaxStrings}
 push ds
 lds  si,s
 lodsb
 mov  cl,al
 xor  ch,ch
 xor  al,al
 jcxz @3
 inc  al
 dec  cl
 jcxz @3
 mov  bl,separator
 mov  ah,1
@1:
 lodsb
 cmp  al,bl
 jne  @2
 inc  ah
@2:
 loop @1
 mov  al,ah
@3:
 pop  ds
end;  {MaxStrings}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
PROCEDURE WaitTicks(n:word); assembler;
{Ceka n tiku (1 tik je priblizne osmnactnina sekundy nebo asi 55 ms.)}
asm   {WaitTicks}
 push ds
 mov  cx,n
 mov  ds,Seg0040
 mov  bx,006Ch
@1:
 mov  ah,byte ptr ds:[bx]
@2:
 mov  al,byte ptr ds:[bx]
 cmp  al,ah
 je   @2
 loop @1
 pop  ds
end;  {WaitTicks}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
begin
 origExitProc:=@ExitProc;
 ExitProc:=@myExitProc;
 memBefore:=memAvail;
end.

(*function nalezeno(var buf1; s1:word; var buf2; s2:word):word; assembler;
{Vrati, jestli nalezl bufer buf1 v buferu buf2 a na jakem offsetu.}
asm   {nalezeno}
 push ds
 push es
 cmp  s1,0
 je   @end
 cmp  s2,0
 je   @end
 lds  si,buf1
 les  di,buf2
 mov  al,ds:[si]
 mov  cx,s2
 cmp  cx,s1
 jb   @err
 dec  s1
@1:
 mov  dx,s1
 lds  si,buf1
 lodsb
 repne scasb
 cmp  dx,cx
 ja   @err
@2:
 cmpsb
 jne  @1
 dec  cx
 dec  dx
 or   dx,dx
 jz   @ok
 jmp  @2
@err:
 mov  ax,0FFFFh
 jmp  @end
@ok:
 mov  ax,s2
 sub  ax,s1
 sub  ax,cx
 dec  ax
@end:
 pop  es
 pop  ds
end;  {nalezeno}*)
