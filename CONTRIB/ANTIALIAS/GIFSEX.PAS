{Borland/TMT Pascal example}
{$IFNDEF __TMT__}
  {$G+}
{$ENDIF}
uses gifs{$IFDEF __TMT__},mcgalib{$ENDIF};
var
  buf:TBuf;
  i:integer;
begin
  asm mov ax,13h; int 10h; end;
  {$IFDEF __TMT__}mSetMode320x200;{$ENDIF}
  if paramcount>0
  then loadgif(paramstr(1),0,buf)
  else loadgif('boulder.gif',0,buf);
  {savegif('fg.gif',0,0,159,99);}
  if buf.d<>nil then begin
    {$IFDEF __TMT__}mPutSprite(0,0,buf.w-1,buf.h-1,buf.d);{$ENDIF}
    freebuf(buf);
  end;
  asm
   db 66h;xor  ax,ax
   int  16h
   mov  ax,0003h
   int  10h
  end;
  if giferror<>0 then writeln('GifError=',giferror);
end.
