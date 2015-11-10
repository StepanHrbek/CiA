{$G+I-} {rutiny pro praci se soubory}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
unit fajls;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
interface
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
uses dos,syst;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 FileStr=string[13];
 DirStr=string[67];
 string20=string[20];
 dskType=(dskNone,dskFloppy,dskHard,dskNet,dskCdrom);
var
 diskwriteable:boolean;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  fileExists(name:PathStr):boolean;
FUNCTION  fileSize(name:PathStr):longint;
PROCEDURE fileDelete(name:PathStr);
FUNCTION  dskReady(dsk:char):boolean;
FUNCTION  dskCur:char;
FUNCTION  dskList:string;
FUNCTION  dskId(dsk:char):dskType;
FUNCTION  dskChanged(dsk:char):byte;
FUNCTION  dskSectorSize(dsk:char):word;
FUNCTION  dirWriteable(dir:DirStr):boolean;
FUNCTION  ConvertLetter(dsk:char):byte;
FUNCTION  dskName(dsk:char):FileStr;
FUNCTION  dskSerialNumber(dsk:char):longint;
FUNCTION  dirExists(dir:PathStr):boolean;
FUNCTION  dirCurAt(dsk:char):DirStr;
PROCEDURE SetVerify(mode:boolean);
FUNCTION  GetVerify:boolean;
FUNCTION  InsertSpace(var g:file; odkud:longint; zn:char; hm:longint):boolean;
FUNCTION  DeleteSpace(var g:file; odkud,hm:longint):boolean;
FUNCTION  GetFileName(fn:DirStr):FileStr;
FUNCTION  DosErrorMsg(n:byte):string20;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
implementation
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  fileExists(name:PathStr):boolean;
var di:SearchRec;
begin {fileExists}
 FindFirst(name,AnyFile-VolumeID-Directory,di);
 fileExists:=(DosError=0) and (di.attr and Directory=0)
end;  {fileExists}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dirExists(dir:PathStr):boolean;
var di:SearchRec;
begin {dirExists}
 dir:=fExpand(getcore(dir));
 if (dir[0]+dir[length(dir)]=#2':') or (dir[0]+dir[2]+dir[3]=#3':\') then
  begin
   dirExists:=dskReady(dir[1]);
   exit;
  end;
 if dir[length(dir)]='\' then dec(dir[0]);
 di.attr:=0;
 FindFirst(dir,Directory,di);
 dirExists:=(DosError=0) and (di.attr and Directory<>0);
end;  {dirExists}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  fileSize(name:PathStr):longint;
var di:SearchRec;
begin {fileSize}
 fileSize:=-1;
 FindFirst(name,AnyFile-VolumeID,di);
 if (DosError<>0) or (di.Attr and Directory<>0) then exit;
 fileSize:=di.Size;
end;  {fileSize}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE fileDelete(name:PathStr);
var f:file;
begin {fileDelete}
 if not fileExists(name) then exit;
 assign(f,name);
 setfattr(f,Archive);
 erase(f);
end;  {fileDelete}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dskReady(dsk:char):boolean;
var di:SearchRec;
begin {dskReady}
 FindFirst(dsk+':\*.*',AnyFile,di);
 dskReady:=DosError in [0,18]
end;  {dskReady}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dskCur:char; assembler;
asm   {dskCur}
 mov  ah,19h
 int  21h
 add  al,'A'
end;  {dskCur}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION dskList:string; assembler;
asm   {dskList}
 mov  ah,19h
 int  21h
 push ax { v AL soucasny disk }
 les  di,@result
 push di
 inc  di
 mov  cx,'z'-'a'+1 { Projede se od A az po Z }
 mov  dx,0
@1:
 mov  ah,0Eh
 int  21h { ChDir disk v DL }
 mov  ah,19h {aktualni disk =}
 int  21h
 cmp  al,dl
 jne  @none {kdyz neni stejny}
 mov  al,dl
 add  al,'A'
 stosb
 @none:
 inc  dl
 loop @1
@konec:
 mov  ax,di
 pop  di
 sub  ax,di
 dec  ax
 stosb {nakonec delka stringu}
 pop  ax
 mov  ah,0Eh
 mov  dl,al
 int  21h {a ChDir na puvodni disk}
end;  {dskList}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dskId(dsk:char):dskType; assembler;
var
 buf:string[ord('Z')-ord('A')];
 bufs,bufo:word;
asm   {dskId}
 push sp            {ne prilis cistym zpusobem zjisti a ulozi adresu bufu}
 pop  ax
 add  ax,4
 mov  bufo,ax
 mov  ax,ss
 mov  bufs,ax
 mov  al,dsk        {testuje, jestli nebyl zadan blud}
 cmp  al,'A'        {dsk<'A'?}
 jl   @None
 cmp  al,'z'        {dsk>'z'?}
 jg   @None
 cmp  al,'a'        {dsk<'a'?}
 jl   @1
 sub  al,'a'-'A'    {zkonvertuje na velke pismeno}
@1:                 {dsk ma nyni urcite mensi ASCII kod nez male 'a'}
 cmp  al,'Z'        {dsk>'Z'?}
 jg   @None
 mov  dsk  ,al      {ulozime si osetrene pismeno disku}
 mov  ax,0DADAh     {testujeme CD-ROM}
 push ax            {dame do stacku slovo $DADA}
 mov  ax,01100h
 int  2Fh
 pop  bx            {vyndame z trouby upecene slovo}
 cmp  bx,0ADADh     {zmenilo se na $ADAD?}
 jne  @3            {kdyz ne, pokracuje dal}
 cmp  al,0FFh       {kdyz zaroven neni ah=$FF, pokracuje dal}
 jne  @3
 mov  ax,1500h
 int  2Fh           {zjisti pocet CD-ROMek a pismeno disku prvni z nich}
 add  cl,'A'
 cmp  dsk,cl        {zkusi, jestli se %dsk nerovna pismenu prvni CD-ROMky}
 je   @Cdrom
 mov  cx,bx         {v cx je nyni pocet CD-ROMek}
 jcxz @None
 mov  bx,bufs       {nastavi adresu [es:bx] do buferu}
 mov  es,bx
 mov  bx,bufo
 mov  ax,150Dh
 int  2Fh           {naplni bufer pismeny}
@2:
 mov  al,es:[bx]    {cx-krat precte z buferu pismeno,}
 inc  bx
 add  al,'A'
 cmp  dsk,al        {porovna ho se zadanym diskem}
 je   @Cdrom        {a v pripade, ze se sobe rovnaj odskoci na @Cdrom}
 loop @2
@3:
 mov  bl,dsk
 sub  bl,'A'-1      {prevedeme pismeno disku na (0..vybrany,1..A,2..B atd.)}
 mov  ax,04409h     {test na sitovy disk}
 int  21h
 jc   @None         {kdyz je CarryFlag=1, pak nastala chyba}
 test dh,010h       {DH and $10 <> 0 ?}
 jnz  @Net
 mov  ax,04408h     {test na floppy a hard drive}
 int  21h
 jc   @None         {kdyz je CarryFlag=1, pak nastala chyba}
 cmp  al,0          {al = 0...Floppy,  1...HardDisk}
 je   @Floppy
 cmp  al,1
 jne  @None
 mov  al,dskHard
 jmp  @end
@CDROM:
 mov  al,dskCDROM
 jmp  @end
@Net:
 mov  al,dskNet
 jmp  @end
@Floppy:
 mov  al,dskFloppy
 jmp  @end
@None:
 mov  al,dskNone
@end:
end;  {dskId}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION dskChanged(dsk:char):byte; assembler;
asm   {dskChanged}
 mov  dh,1      {dh v sobe nosi vysledek funkce}
 cmp  al,'@'
 je   @end
 mov  dh,3
 mov  al,dsk    {prevede 'A','b','C'.. na 0,1,2..}
 cmp  al,'z'
 ja   @end
 cmp  al,'A'
 jb   @end
 and  al,31
 cmp  al,'Z'-'A'
 ja   @end
 dec  al
 mov  dsk,al
 mov  dh,1
 mov  ah,19h
 int  21h
 cmp  al,dsk    {je dsk soucasny drive?}
 je   @end      {pokud ano, nemusime menit}
 mov  dh,2
 mov  al,dsk
 add  al,'A'
 push ax
 call dskReady
 cmp  al,false
 je   @end
 mov  ah,0Eh
 mov  dl,dsk
 int  21h       {Changneme disk}
 mov  ah,19h
 int  21h       {Overime si, jestli se zmenil}
 mov  dh,0
 cmp  al,dl     {rovnaji se zadany a aktualni disk?}
 je   @end
 mov  dh,2
@end:
 mov  al,dh
end;  {dskChanged}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION dskSectorSize(dsk:char):word; assembler;
asm   {dskSectorSize}
 mov  ah,036h
 mov  dl,dsk
 sub  dl,'A'-1
 int  21h
 mul  cx
end;  {dskSectorSize}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dirWriteable(dir:DirStr):boolean;
begin {dirWriteable}
 dirWriteable:=false;
 dir:=FExpand(dir);
 DeStr2Pc(dir);
 if dskId(dir[0]) in [dskFloppy,dskHard,dskNet] then
  asm
   push ds
   push ss
   pop  ds
   mov  ah,05Ah
   xor  cx,cx
   lea  dx,dir
   int  21h
   jc   @err
   xchg bx,ax
   mov  ah,40h
   inc  cx
   int  21h
   jc   @err
   mov  ah,3Eh
   int  21h
   jc   @err
   mov  ah,41h
   int  21h
   jc   @err
   mov  @result,true
  @err:
   pop  ds
  end
end;  {dirWriteable}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION ConvertLetter(dsk:char):byte; assembler;
{Zkonvertuje pismeno '@','A','b','C','d',.. na 0,1,2,3,..
 Pro neplatne pismeno vrati $FF. (pro potreby zdejsich funkci)}
asm   {ConvertLetter}
 mov  al,dsk
 cmp  al,'z'
 ja   @err
 cmp  al,'Z'
 jbe  @1
 sub  al,'a'-'A'
@1:
 cmp  al,'@'
 jb   @err
 sub  al,'@'
 and  al,1Fh
 jmp  @end
@err:
 mov  al,0FFh
@end:
end;  {ConvertLetter}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dskName(dsk:char):FileStr;
var di:SearchRec;
begin {dskName}
 FindFirst(dsk+':\*.*',VolumeID,di);
 if DosError=0 then dskName:=di.name else dskName:='';
end;  {dskName}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dskSerialNumber(dsk:char):longint; assembler;
var dib:
 record
  level:word;
  serial:longint;
  name:array[1..11] of char;
  fattype:array[1..8] of char;
 end;
asm   {dskSerialNumber}
 mov  bx,ss
 mov  dx,sp
 push ds
 mov  al,dsk
 push ax
 call ConvertLetter
 cmp  al,0FFh
 je   @err
 mov  ds,bx
 mov  bl,al
 mov  ax,6900h
 int  21h
 jc   @err
 mov  bx,dx
 mov  ax,ds:[bx+2]
 mov  dx,ds:[bx+4]
 jmp  @end
@err:
 xor  ax,ax
 xor  dx,dx
@end:
 pop  ds
end;  {dskSerialNumber}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION dirCurAt(dsk:char):DirStr; assembler;
{vrati soucasny adresar zadaneho disku vcetne cesty, zakoncene lomitkem.
 pokud dojde k chybe (spatny drajv nebo podobne), vrati prazdny retezec.
 To same dela procedura GetDir, ale ta pri chybe vraci retezec 'X:\',
 kteryzto muze byt platnym adresarem.
 dsk='@'-soucasny disk, jinak pismeno disku}
asm   {dirCurAt}
 push ds
 mov  al,dsk
 push ax
 call ConvertLetter
 cmp  al,0FFh
 je   @err
 mov  dsk,al
 lds  si,@result
 add  si,4         {posune offset na pozici prvniho adresare}
 mov  ah,047h
 mov  dl,dsk
 int  21h
 jc   @err
 sub  si,3         {posune offset na pozici pismene disku}
 mov  al,dsk
 add  al,'A'-1
 cmp  dsk,0
 ja   @1
 mov  ah,019h
 int  21h
 add  al,'A'
@1:
 mov  ds:[si],al
 inc  si
 mov  ax,'\:'
 mov  ds:[si],ax
 dec  si           {nyni zjisti delku stringu}
 mov  ah,0
 mov  cx,0FFh
@2:
 lodsb
 cmp  al,0
 je   @3
 inc  ah
 loop @2
@3:
 sub  si,2         {a nakonec vyresi zpetne lomitko}
 lodsb
 cmp  al,'\'
 je   @4
 mov  al,'\'
 mov  ds:[si],al
 inc  ah
@4:
 lds  si,@result
 mov  ds:[si],ah
 jmp  @end
@err:
 lds  si,@result
 mov  al,0
 mov  ds:[si],al
@end:
 pop  ds
end;  {dirCurAt}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE SetVerify(mode:boolean); assembler;
{Jako DOSovy prikaz VERIFY,
 zapne/vypne overovani uspesnosti pri zapisu na disk.
 Se zapnutou verifikaci je to bezpecnejsi, s vypnutou zase rychlejsi}
asm   {SetVerify}
 mov  ah,02Eh
 mov  al,mode
 int  21h
end;  {SetVerify}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  GetVerify:boolean; assembler;
{Zjisti rezim verifikace: true-zapnuta, false-vypnuta}
asm   {GetVerify}
 mov  ah,054h
 int  21h
end;  {GetVerify}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  InsertSpace(var g:file; odkud:longint; zn:char; hm:longint):boolean;
const
 bufsize=4096;
var
 buf:array[0..bufsize-1] of char;
 OrigPos,OrigSize,si,di,cx:longint;
 count:word;
begin {InsertSpace}
 insertspace:=false;
 if hm<1 then exit;
 OrigPos:=odkud;
 OrigSize:=system.fileSize(g);
 Seek(g,OrigSize-hm);
 si:=filepos(g);
 di:=OrigSize;
 for cx:=1 to hm div bufsize do
  begin
   Seek(g,si);
   blockread(g,buf[0],bufsize,count);
   si:=filepos(g);
   Seek(g,di);
   blockwrite(g,buf[0],bufsize,count);
   di:=filepos(g);
  end;
 if hm mod bufsize<>0 then
  begin
   Seek(g,si);
   blockread(g,buf[0],hm mod bufsize,count);
   si:=filepos(g);
   Seek(g,di);
   blockwrite(g,buf[0],hm mod bufsize,count);
   di:=filepos(g);
  end;
 if OrigPos+hm<OrigSize then
  begin
   si:=OrigPos;
   di:=OrigPos+hm;
   for cx:=1 to (OrigSize-OrigPos-hm) div bufsize do
    begin
     Seek(g,si);
     blockread(g,buf[0],bufsize,count);
     si:=filepos(g);
     Seek(g,di);
     blockwrite(g,buf[0],bufsize,count);
     di:=filepos(g);
    end;
   cx:=(OrigSize-OrigPos-hm) mod bufsize;
   if cx<>0 then
    begin
     Seek(g,si);
     blockread(g,buf[0],cx,count);
     si:=filepos(g);
     Seek(g,di);
     blockwrite(g,buf[0],cx,count);
     di:=filepos(g);
    end;
  end;
 seek(g,OrigPos);
 fillchar(buf[0],bufsize,ord(zn));
 for cx:=1 to hm div bufsize do
  blockwrite(g,buf[0],bufsize,count);
 if hm mod bufsize<>0 then
  blockwrite(g,buf[0],hm mod bufsize,count);
 odkud:=OrigPos;
 Seek(g,odkud);
 insertspace:=true;
end;  {InsertSpace}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  DeleteSpace(var g:file; odkud,hm:longint):boolean;
const
 bufsize=4096;
var
 buf:array[0..bufsize-1] of char;
 cx,si,di,OrigPos:longint;
 count:word;
begin {DeleteSpace}
 OrigPos:=odkud;
 si:=OrigPos+hm;
 di:=OrigPos;
 for cx:=1 to (system.fileSize(g)-OrigPos) div bufsize do
  begin
   seek(g,si);
   blockread(g,buf[0],bufsize,count);
   si:=filepos(g);
   seek(g,di);
   blockwrite(g,buf[0],bufsize,count);
   di:=filepos(g);
  end;
 cx:=(system.fileSize(g)-OrigPos) mod bufsize;
 if cx<>0 then
  begin
   seek(g,si);
   blockread(g,buf[0],cx,count);
   si:=filepos(g);
   seek(g,di);
   blockwrite(g,buf[0],cx,count);
   di:=filepos(g);
  end;
 seek(g,system.filesize(g)-hm);
 truncate(g);
 close(g);
 FileMode:=2;
 reset(g,SizeOf(char));
 seek(g,OrigPos);
end;  {DeleteSpace}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  GetFileName(fn:DirStr):FileStr;
begin {GetFileName}
 while fn[length(fn)]='\' do dec(fn[0]);
 while pos('\',fn)>0 do delete(fn,1,pos('\',fn));
 GetFileName:=fn;
end;  {GetFileName}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  DosErrorMsg(n:byte):string20;
begin {DosErrorMsg}
 case n of
 0:  DosErrorMsg:='No error';
 2:  DosErrorMsg:='File not found';
 3:  DosErrorMsg:='Path not found';
 5:  DosErrorMsg:='Access denied';
 6:  DosErrorMsg:='Invalid handle';
 8:  DosErrorMsg:='Not enough memory';
 10: DosErrorMsg:='Invalid environment';
 11: DosErrorMsg:='Invalid format';
 18: DosErrorMsg:='No more files';
 else DosErrorMsg:='(unknown error)';
 end;
end;  {DosErrorMsg}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin
 SetVerify(true);
 diskwriteable:=dirWriteable(dirCurAt('@'));
end.
