{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      LdTXT;
Interface {$i define.inc}

{funkce jsou v interface jen proto, aby mohly byt volany z jinych loaderu}
Uses      Chyby,Objects,Vga;
Function  GetInfo(s:PStream;var model,x,y:word):TError;
Function  Decompress(s:PStream;map:PBitmap):TError;
Function  Compress(s:PStream;map:PBitmap):TError;

Implementation
Uses      Memo, Sys,Fonty,Fajly,Texty,Loadery;

function GetInfo(s:PStream;var model,x,y:word):TError;
var   i            :word;
      datasize     :longint;
      freesize     :longint;
      t            :TText2;
begin
 GetInfo:=erOk;
 model:=model_text;
 datasize:=65536;
 freesize:=0;
 if not fileLoad('?.txt',s,freeptr,datasize,freesize)
  then GetInfo:=erFileLoad
  else begin
   mem[freeseg:datasize]:=0;
   t.Init(freeptr,65535);
   t.static:=true;
   x:=0;
   y:=0;
   while not t.eof do begin
     x:=maxW(x,length(t.nlRead));
     inc(y);
     end;
   t.Done;
   end;
end;

function Decompress(s:PStream;map:PBitmap):TError;
var   color        :byte;
      i            :word;
      datasize     :longint;
      freesize     :longint;
      t            :TText2;
begin
 Decompress:=erOk;
 datasize:=65536;
 freesize:=0;
 s^.Seek(0);
 map^.Clr2Ful;
 if not fileLoad('?.txt',s,freeptr,datasize,freesize)
  then Decompress:=erFileLoad
  else begin
   mem[freeseg:datasize]:=0;
   t.Init(freeptr,65535);
   t.static:=true;
   for i:=1 to map^.sizeY do OutStr(t.nlRead,map,0,i,nil,1,7);
   t.Done;
   end;
end;

function Compress(s:PStream;map:PBitmap):TError;
var   i,y,lastx:integer;
      fullWidthReached:boolean;
const crlf:array[1..2] of char=#13#10;
      spaces=[0,32];
begin
 fullWidthReached:=false;
 with map^ do
  for y:=0 to sizeY-1 do begin
    lastx:=sizeX-1;
    if (y<sizeY-1) or fullWidthReached then
     while (lastx>0) and (tab^[y]^[2*lastx] in spaces) do dec(lastx);
    fullWidthReached:=fullWidthReached or (lastx=sizeX-1);
    for i:=0 to lastx do s^.Write(tab^[y]^[2*i],1);
    s^.Write(crlf[1],2);
    end;
 Compress:=erOk;
end;

const formats=11;
      ext:array[1..formats] of string[3]=
       ('TXT','ASC','NFO','DIZ','INI','ASM','PAS','INC','C','H','CPP');
var   i:word;
begin
 for i:=1 to formats do
  picRegister(ext[i],isLoadable+isTextmode+isFixedSize,GetInfo,Decompress,Compress,chr(model_text));
end.