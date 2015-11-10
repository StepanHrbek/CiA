{
  // Algorithms in C  by  Sverre Huseby
  // Upgraded&modified  by  Ruzaev Sergei
  // e-mail:druiman@chat.ru

  Can load:
  01) 4 bit gif  -> 8,16 bit page
  02) 8 bit gif  -> 8,16 bit page

  Can save:
  01) 8 bit page  -> 8 bit gif

  only GIF87a with width <= 1024
}
{$IFNDEF __TMT__}
  {$G+}
{$ENDIF}
unit GIFs;
{----------------------------------------------------------------------------}
interface
{----------------------------------------------------------------------------}
type
{$IFNDEF __TMT__}
  dword=longint; {to sice neni pravda, ale takovy typ u BP neni.}
{$ENDIF}
  string80=string[80];
  PBuf=^TBuf;
  TBuf=record
    w:word;
    h:word;
    d:pointer;
  end;  {TBuf}
const
  {Error Codes}
  errImageOk          =   0;
  errBadFile          =   1;
  errBadGifCode       =   2;
  errNotAGifFile      =   3;
  errInvalidBlockSize =   4;
  errBadSymbolSize    =   5;
  errBadFirstGifCode  =   6;
  errBadSeek          =   7;
  errBufferError      =   8;
  errUnknownError     = 255;
  GIF87a     ='GIF87a';
  PALETTESIZE=256*3;
  MAXBITS    =12;
  SPACESIZE  =1 shl MAXBITS;
{----------------------------------------------------------------------------}
var
  GifPal   :array[0..PALETTESIZE-1] of byte;
  GifError :integer;
  lastGifDX:longint;
  lastGifDY:longint;
{----------------------------------------------------------------------------}
procedure loadGif(filename:string80; fseek:dword; var buf:TBuf);
function  saveGif(filename:string80; x0,y0,x1,y1:longint):dword;
procedure freeBuf(var buf:TBuf);
{----------------------------------------------------------------------------}
implementation
{----------------------------------------------------------------------------}
function  GetPixel(x,y:longint):byte; begin GetPixel:=mem[SegA000:y*320+x] end;
procedure SetPal(c,r,g,b:byte); begin port[$3C8]:=c;port[$3C9]:=r;port[$3C9]:=g;port[$3C9]:=b; end;
{----------------------------------------------------------------------------}
type
  TAnyImage=record
    width,height:word;
    bpp:byte;
    colors:word;
    size:longint;
    info:word;
  end;  {TAnyImage}
  TGIFHeader=record
    Signature:array[0..5] of char;
    GIFWidth,GIFHeight:word;
    flags,background,aspect:byte;
  end;  {TGIFHeader}
  {for loading...}
  TImageBlock=record
    left,top,width,height:word;
    flags:byte;
  end;  {TImageBlock}
  {for saving...}
  TTabByte=array[0..0] of byte;
  PTabByte=^TTabbyte;
  TTabword=array[0..0] of word;
  PTabword=^TTabword;
  TScreenDescriptor=record
    screenwidth :word;
    screenheight:word;
    flag,background,pixelaspectratio:byte;
  end;  {TScreenDescriptor}
  TImageDescriptor=record
    separator:char;
    leftpos:word;
    toppos:word;
    width,height:word;
    flag:byte;
  end;  {TImageDescriptor}
var
  WorkSpace1:array[0..SPACESIZE-1] of byte;
  WorkSpace2:array[0..SPACESIZE-1] of byte;
  WorkSpace3:array[0..SPACESIZE-1] of integer;
{----------------------------------------------------------------------------}
function safeshr(value:longint; cnt:word):longint; assembler;
asm
{$IFDEF __TMT__}
  mov  eax,value
  mov  cx,cnt
  shr  eax,cl
{$ELSE}
  db 66h;mov  ax,word ptr value
  mov  cx,cnt
  db 66h;shr  ax,cl
{$ENDIF}
end;  {safeshr}
{----------------------------------------------------------------------------}
function safeshl(value:longint; cnt:word):longint; assembler;
asm
{$IFDEF __TMT__}
  mov  eax,value
  mov  cx,cnt
  shl  eax,cl
{$ELSE}
  db 66h;mov  ax,word ptr value
  mov  cx,cnt
  db 66h;shl  ax,cl
{$ENDIF}
end;  {safeshl}
{----------------------------------------------------------------------------}
function bitsneeded(n:word):integer; assembler;
asm
{$IFDEF __TMT__}
  xor  eax,eax
  xor  ecx,ecx
  mov  cx,n
@1:
  shr  ecx,1
  inc  eax
  jecxz @end
  jmp  @1
@end:
{$ELSE}
  db 66h;xor  ax,ax
  db 66h;xor  cx,cx
  mov  cx,n
@1:
  shr  cx,1
  inc  ax
  jcxz @end
  jmp  @1
@end:
{$ENDIF}
end;  {bitsneeded}
{----------------------------------------------------------------------------}
procedure loadGif(filename:string80; fseek:dword; var buf:TBuf);
var
  f:file;
  GifImage          :TAnyImage;
  Interlaced        :boolean;
  imgWidth,imgHeight:integer;
  imgColorDepth     :byte;
  imgPaletteSize    :integer;
  ColorBits         :byte;
  GifBlock          :array[0..$FF] of byte;
  GifBlockindex     :word;
  NumStrings        :word;
  GifHeader         :TGIFHeader;
  imgBlock          :TImageBlock;
  imgSize           :longint;
  line_nb           :integer;
  line_gif          :array[0..$3FF] of byte;
  currentX          :integer;
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function get(var buf; bytes:word):boolean;
  var count:integer;
  begin
    blockread(f,buf,bytes,count);
    get:=(bytes=count) and (IOResult=0);
  end;  {get}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function put(x,j:integer):boolean;
  var
    n:word;
    data:array[0..1] of byte absolute x;
  begin
    n:=0;
    while (n<j) do begin
      line_gif[currentX]:=data[n];
      inc(n);
      inc(currentX);
      if currentX>=gifimage.width then begin
        with buf do move(line_gif[0],mem[{$IFNDEF __TMT__}seg(d^):{$ENDIF}ofs(d^)+line_nb*w+0],gifimage.width);
        currentX:=0;
      end;
    end;
    put:=true;
  end;  {put}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure UnpackImage(bits:integer);
  var
    bits2,bitsleft:integer;
    codesize,codesize2:integer;
    nextcode,thiscode,oldcode,currentcode:integer;
    oldtoken:integer;
    blocksize:integer;
    pass,byt:integer;
    p,q,u:integer;
    wordmask:word;
  const
    INCTABLE:array [0..4] of integer=(8,8,4,2,0);
    STARTTABLE:array [0..4] of integer=(0,4,2,1,0);
{-   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   }
    function GetBlock:boolean;
    begin {GetBlock}
      GetBlock:=False;
      blocksize:=0;
      if not Get(blocksize,1) then begin
        GifError:=errBadFile;
        exit;
      end;
      if blocksize>0 then begin
        p:=0;
        if not get(GifBlock,blocksize) then begin
          GifError:=errBadFile;
          exit;
        end;
        q:=blocksize;
        GetBlock:=True;
      end
      else begin
        GifError:=errInvalidBlockSize;
        exit;
      end;
    end;  {GetBlock}
{-   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   }
  begin {UnpackImage}
    pass:=0;
    line_nb:=0;
    byt:=0;
    p:=0;
    q:=0;
    blocksize:=0;
    FillChar(GifBlock,sizeof(GifBlock),0);
    bitsleft:=8;
    if (bits<2) or (bits>8) then begin
      GifError:=errBadSymbolSize;
      exit;
    end;
    bits2    :=1 shl bits;
    nextcode :=bits2 + 2;
    codesize :=bits + 1;
    codesize2:=1 shl codesize;
    oldcode  :=-1;
    oldtoken :=-1;
    while true do begin
      if bitsleft=8 then begin
        Inc(p);
        if p>=q then GetBlock;
        if GifError<>errImageOk then exit;
        bitsleft:=0;
      end;
      thiscode:=GifBlock[p];
      currentcode:=codesize+bitsleft;
      if currentcode<=8 then begin
        GifBlock[p]:=safeshr(GifBlock[p],codesize);
        bitsleft:=currentcode;
      end else begin
        inc(p);
        if (p>=q) and not GetBlock then exit;
        thiscode:=thiscode or safeshl(GifBlock[p],8-bitsleft);
        if currentcode<=16 then
          bitsleft:=currentcode-8
        else begin
          inc(p);
          if (p>=q) and not GetBlock then exit;
          thiscode:=thiscode Or safeshl(GifBlock[p],16-bitsleft);
          bitsleft:=currentcode-16;
        end;
        GifBlock[p]:=safeshr(GifBlock[p],bitsleft);
      end;
      wordmask:=0; if codesize>0 then wordmask:=pred(1 shl codesize);
      thiscode:=thiscode and wordmask;
      currentcode:=thiscode;
      if thiscode=bits2+1 then break;
      if thiscode>nextcode then begin
        GifError:=errBadGifCode;
        exit;
      end;
      if thiscode=bits2 then begin
        nextcode:=bits2+2;
        codesize:=bits+1;
        codesize2:=1 shl codesize;
        oldtoken:=-1;
        OldCode:=-1;
        Continue;
      end;
      u:=0;
      if thiscode=nextcode then begin
        if oldcode=-1 then begin
          GifError:=errBadFirstGifCode;
          Exit;
        end;
        WorkSpace1[u]:=oldtoken;
        Inc(u);
        thiscode:=oldcode;
      end;
      while thiscode>=bits2 do begin
        WorkSpace1[u]:=WorkSpace2[thiscode];
        inc(u);
        thiscode:=WorkSpace3[thiscode];
      end;
      oldtoken:=thiscode;
      while True do begin
        if not put(thiscode,1) then begin
          GifError:=errBadGifCode;
          exit;
        end;
        Inc(byt);
        if byt>=imgWidth then begin
          byt:=0;
          if Interlaced then begin
            line_nb:=line_nb+INCTABLE[pass];
            if line_nb>=imgHeight then begin
              Inc(pass);
              line_nb:=STARTTABLE[pass];
            end;
          end
          else
            Inc(line_nb);
        end;
        if u<=0 then break;
        dec(u);
        thiscode:=WorkSpace1[u];
      end;
      if (nextcode<sizeof(WorkSpace1)) and (oldcode<>-1) then begin
        WorkSpace3[nextcode]:=oldcode;
        WorkSpace2[nextcode]:=oldtoken;
        Inc(nextcode);
        if (nextcode>=codesize2) and (codesize<12) then begin
          Inc(codesize);
          codesize2:=1 shl codesize;
        end;
      end;
      Oldcode:=currentcode;
    end;
  end;  {UnpackImage}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure SkipExtension;
  var n,c:byte;
{-   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   }
    procedure getwhile;
    begin
      get(n,1);
      while n>0 do begin
        get(GifBlock,n);
        get(n,1);
      end;
    end;  {getwhile}
{-   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   }
  begin {SkipExtension}
    get(c,1);
    case c of
    $01:
      begin
        get(GifBlock,13);
        getwhile;
      end;
    $F9:
      get(GifBlock,6);
    $FE:
      getwhile;
    $FF:
      begin
        get(GifBlock,12);
        getwhile;
      end;
    else {case}
      begin
        get(n,1);
        get(GifBlock,n);
      end;
    end; {/case}
  end;  {SkipExtension}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
var
  backGround:byte;
  c:integer;
  ch:char;
  i:word;
  size:longint;
begin {loadGif}
  currentX:=0;
  fillchar(buf,sizeof(buf),0);
  GifError:=errImageOk;
  assign(f,filename);
{$IFOPT I+}
  {$I-}
  reset(f,1);
  {$I+}
{$ELSE}
  reset(f,1);
{$ENDIF}
  if IOResult<>0 then begin
    GifError:=errBadFile;
    exit;
  end;
{$IFOPT I+}
  {$I-}
  seek(f,fseek);
  {$I+}
{$ELSE}
  seek(f,fseek);
{$ENDIF}
  if IOResult<>0 then begin
    GifError:=errBadSeek;
    exit;
  end;
  repeat
    if not get(gifHeader,sizeof(gifHeader)) then begin {load gif header}
      GifError:=errBadGifCode;
      break;
    end;
    with GifHeader do
      if (Signature[0]<>'G') or (Signature[1]<>'I') or (Signature[2]<>'F') then begin
        GifError:=errNotAGifFile;
        break;
      end;
    ColorBits:=succ(GifHeader.Flags and 7);
    BackGround:=GifHeader.BackGround;
    if GifHeader.Flags and $80<>0 then begin {load palette}
      case ColorBits of
      4: get(GifPal,16*3);
      8: get(GifPal,PALETTESIZE);
      end;
    end;
    for i:=0 to $FF do
      SetPal(i,GifPal[i*3] shr 2,GifPal[i*3+1] shr 2,GifPal[i*3+2] shr 2);
    with GifHeader do begin {Get Image Size}
      lastGifDX:=GIFWidth;
      lastGifDY:=GIFHeight;
      size:=GIFHeight*GIFWidth;
      imgSize:=size;
    end;
    with buf do begin
      w:=GifHeader.GIFWidth;
      h:=GifHeader.GIFHeight;
      getmem(d,w*h);
    end;
    if buf.d=nil then begin
      GifError:=errBufferError;
      break;
    end;
    {the algorithm}
    ch:=#0;
    while (ch=',') or (ch='!') or (ch=#0) do begin
      get(ch,1);
      case ch of
      ',':
        begin
          if not get(imgBlock,SizeOf(imgBlock)) then begin
            GifError:=errBadGifCode;
            break;
          end;
          if imgBlock.flags and $80<>0 then begin {load palette too}
            colorBits:=(imgBlock.Flags and 7)+1;
            case colorBits of
            4: Get(GifPal,48);
            8: Get(GifPal,PALETTESIZE);
            end;
          end;
          with imgBlock do begin
            imgWidth :=Width;
            imgHeight:=Height;
          end;
          imgColorDepth:=ColorBits;
          imgPaletteSize:=1 shl ColorBits;
          with GifImage do begin
            Height   :=imgHeight;
            Width    :=imgWidth;
            colors   :=imgPaletteSize;
            bpp      :=ColorBits;
            size     :=imgSize;
            info     :=word(GifHeader.Signature[4]='7') {Gif 87a}
          end;
          Interlaced:=imgBlock.Flags and $40<>0;
          c:=0;
          if not get(c,1) then begin
            GifError:=errBadGifCode;
            break;
          end;
          UnpackImage(c);
        end;
      '!': SkipExtension;
      end; {/case}
    end; {/while}
  until true;
  if fseek=0 then close(f);
end;  {loadGif}
{----------------------------------------------------------------------------}
function  saveGif(filename:string80; x0,y0,x1,y1:longint):dword;
const
  HASH_FREE     =$FFFF;
  NEXT_FIRST    =$FFFF;
  BITS_PER_PIXEL=8;
  CODE_RESERVED =2;
  HASHSIZE      =9973;
  HASHSTEP      =2039;
var
  strchr:PTabByte;
  strnext,strhash:PTabWord;
  numstrings:word;
  outfile:file;
  buffer:array[0..$FF] of byte;
  index,bitsleft:integer;
  bitsperpixel,numcolors:integer;
  screenheight,screenwidth,relpixx,relpixy:integer;
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function hash(index, lastbyte:word):word;
  begin
    hash:=((safeshl(lastbyte,8)) xor index) mod HASHSIZE;
  end;  {hash}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function write(var buf;len:word):boolean;
  begin
    blockwrite(outfile, buf, len);
    write:=(IOResult=0);
  end;  {write}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function writebyte(b:byte):boolean;
  begin
    blockwrite(outfile, b, 1);
    writebyte:=(IOResult=0);
  end;  {writebyte}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function writeword(w:word):boolean;
  begin
    blockwrite(outfile, w, 2); (*In original code, it was splitted in 2 byte output to ensure portability*)
    writeword:=(IOResult=0);
  end;  {writeword}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure initbitfile;
  begin
    index:=0;
    buffer[0]:=0;
    bitsleft:=8;
  end;  {initbitfile}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function resetoutbitfile:boolean;
  var numbytes:byte;
  begin
    if bitsleft=8
    then numbytes:=index
    else numbytes:=index+1;
    if numbytes>0 then begin
      if not writebyte(numbytes) then begin
        resetoutbitfile:=false;
        exit;
      end;
      if not write(buffer, numbytes) then begin
        resetoutbitfile:=false;
        exit;
      end;
      index:=0;
      buffer[0]:=0;
      bitsleft:=8;
    end;
    resetoutbitfile:=true;
  end;  {resetoutbitfile}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function writebits(bits, numbits:integer):longint;
  var bitswritten, numbytes:integer;
  begin
    bitswritten:=0;
    numbytes:=255;
    repeat
      if ( (index=254) and (bitsleft=0) ) or (index>254) then begin
        if not writebyte(numbytes) then begin
          writebits:=-1;
          exit;
        end;
        if not write(buffer, numbytes) then begin
          writebits:=-1;
          exit;
        end;
        index:=0;
        buffer[index]:=0;
        bitsleft:=8;
      end;
      if (numbits<=bitsleft) then begin
        buffer[index]:=buffer[index] or ( safeshl( bits and ( ( safeshl(1,numbits) -1 ) ),( 8 - bitsleft )));
        inc(bitswritten, numbits);
        dec(bitsleft, numbits);
        numbits:=0;
      end else begin
        buffer[index]:=buffer[index] or ( safeshl( bits and ( ( safeshl(1,bitsleft) -1 ) ),(8 - bitsleft )));
        inc(bitswritten, bitsleft);
        bits:=safeshr(bits,bitsleft);
        dec(numbits, bitsleft);
        inc(index);
        buffer[index]:=0;
        bitsleft:=8;
      end;
    until ( numbits = 0 );
    writebits:=bitswritten;
  end;  {writebits}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure freestrtab;
  begin
    if strhash<>nil then begin
      freemem(strhash,HASHSIZE*sizeof(word));
      strhash:=nil;
    end;
    if strnext<>nil then begin
      freemem(strnext,SPACESIZE*sizeof(word));
      strnext:=nil;
    end;
    if strchr<>nil then begin
      freemem(strchr,SPACESIZE*sizeof(byte));
      strchr:=nil;
    end;
  end;  {freestrtab}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function allocstrtab:boolean;
  begin
    getmem(strchr,SPACESIZE*sizeof(byte));
    if strchr=nil then begin
      freestrtab;
      allocstrtab:=false;
      exit;
    end;
    getmem(strnext,SPACESIZE*sizeof(word));
    if strnext=nil then begin
      freestrtab;
      allocstrtab:=false;
      exit;
    end;
    getmem(strhash, HASHSIZE * sizeof(word));
    if strhash=nil then begin
      freestrtab;
      allocstrtab:=false;
      exit;
    end;
    allocstrtab:=true
  end; {allocstrtab}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function addcharstring(index:word;b:byte):word;
  var hshidx:word;
  begin
    if numstrings>=SPACESIZE then begin
      addcharstring:=$FFFF;
      exit;
    end;
    hshidx:=hash(index, b);
    while (strhash^[hshidx]<>$FFFF) do
      hshidx:=(hshidx + HASHSTEP) mod HASHSIZE;
    strhash^[hshidx]:=numstrings;
    strchr^[numstrings]:=b;
    if (index <> $FFFF)
    then strnext^[numstrings]:=index
    else strnext^[numstrings]:=NEXT_FIRST;
    addcharstring:=numstrings;
    inc(numstrings);
  end;  {addcharstring}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function findcharstring(index:word;b:byte):word;
  var hshidx, nextidx:word;
  begin
    if (index=$FFFF) then begin
      findcharstring:=b;
      exit;
    end;
    hshidx:=hash(index, b);
    nextidx:=strhash^[hshidx];
    while (nextidx<>$FFFF) do begin
      if (strnext^[nextidx]=index) and (strchr^[nextidx]=b) then begin
        findcharstring:=nextidx;
        exit;
      end;
      hshidx:=(hshidx+HASHSTEP) mod HASHSIZE;
      nextidx:=strhash^[hshidx];
    end;
    findcharstring:=$FFFF;
  end;  {findcharstring}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure clearstrtab(codesize:integer);
  var
    q,w:integer;
    wp:^word;
  begin
    numstrings:=0;
    wp:=@(strhash^[0]);
    for q:=0 to HASHSIZE-1 do begin
      wp^:=HASH_FREE;
      inc(wp, sizeof(word));
    end;
    w:=safeshl(1,codesize)+CODE_RESERVED;
    for q:=0 to w-1 do
      addcharstring($FFFF,q);
  end;  {clearstrtab}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function inputbyte:integer;
  var ret:integer;
  begin
    if (relpixy>=screenheight) then begin
      inputbyte:=-1;
      exit;
    end;
    ret:=byte(GetPixel(x0+relpixx, y0+relpixy));
    inc(relpixx);
    if relpixx>=screenwidth then begin
      relpixx:=0;
      inc(relpixy);
    end;
    inputbyte:=ret;
  end;  {inputbyte}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function writescreendescriptor(var sdesc:TScreenDescriptor;
    globalcolortableflag, colorresolution, sortflag,globalcolortablesize:integer):boolean;
  begin
    sdesc.flag:=safeshl(globalcolortableflag,7) or safeshl(colorresolution,4) or safeshl(sortflag,3) or globalcolortablesize;
    blockwrite(outfile,sdesc,sizeof(TScreenDescriptor));
    if IOResult<>0 then begin
      writescreendescriptor:=false;
      exit;
    end;
    writescreendescriptor:=true;
  end;  {writescreendescriptor}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function writeimagedescriptor(var idesc:TImageDescriptor; localcoltab,interlace,sort,reserved,localtabsize:integer):boolean;
  begin
    idesc.flag:=safeshl(localcoltab,7) or safeshl(interlace,6) or safeshl(sort,5) or safeshl(reserved,3) or localtabsize;
    blockwrite(outfile,idesc,sizeof(TImageDescriptor));
    if IOResult<>0 then begin
      writeimagedescriptor:=false;
      exit;
    end;
    writeimagedescriptor:=true;
  end;  {writeimagedescriptor}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function lzw_compress(codesize:integer):boolean;
  var
    index:word;
    prefix:word;
    clearcode,endofinfo,numbits,limit,errcode:integer;
    c:integer;
  begin
     prefix:=$FFFF;
     initbitfile;
     clearcode:=safeshl(1,codesize);
     endofinfo:=clearcode+1;
     numbits:=codesize+1;
     limit:=safeshl(1,numbits)-1;
     if not allocstrtab then begin
       lzw_compress:=false;
       exit;
     end;
     clearstrtab(codesize);
     writebits(clearcode, numbits);
     c:=inputbyte;
     while c<>-1 do begin
       index:=findcharstring(prefix, c);
       if index<>$FFFF
       then prefix:=index
       else begin
         writebits(prefix, numbits);
         if addcharstring(prefix,c)>limit then begin
           inc(numbits);
           if numbits>12 then begin
             writebits(clearcode, numbits-1);
             clearstrtab(codesize);
             numbits:=codesize+1;
           end;
           limit:=safeshl(1,numbits)-1;
         end;
         prefix:=c;
         end;
       c:=inputbyte;
     end;
     if prefix<>$FFFF then writebits(prefix, numbits);
     writebits(endofinfo, numbits);
     resetoutbitfile;
     freestrtab;
     lzw_compress:=true;
  end;  {lzw_compress}
{- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
var
  idesc:TImageDescriptor;
  sdesc:TScreenDescriptor;
  toto:string[8];
  temp:longint;
begin {saveGif}
  saveGif:=-1;
  numcolors:=safeshl(1,bitsperpixel);
  screenheight:=y1-y0+1;
  screenwidth:=x1-x0+1;
  assign(outfile,filename);
  filemode:=2;
  rewrite(outfile,1);
  if IOResult<>0 then exit;
  toto:=GIF87a;
  if not write(toto[1], 6) then exit;
  with sdesc do begin
    screenwidth:=screenwidth;
    screenheight:=screenheight;
    background:=0;
    pixelaspectratio:=0;
  end;
  if not writescreendescriptor(sdesc,BITS_PER_PIXEL-1,0,BITS_PER_PIXEL-1,BITS_PER_PIXEL-1) then exit;
  if not write(gifpal,PALETTESIZE) then exit;
  with idesc do begin
    separator:=',';
    leftpos:=0;
    toppos:=0;
    width:=ScreenWidth;
    height:=ScreenHeight;
  end;
  if not writeimagedescriptor(idesc,0,0,0,0,0) then exit;
  if not writebyte(BITS_PER_PIXEL) then exit;
  relpixx:=0; relpixy:=0;
  if not lzw_compress(BITS_PER_PIXEL) then exit;
  if not writebyte(0) then exit;
  idesc.separator:=';';
  if not writeimagedescriptor(idesc,0,0,0,0,0) then exit;
  saveGif:=filesize(outfile);
  close(outfile);
end;  {saveGif}
{----------------------------------------------------------------------------}
procedure freeBuf(var buf:TBuf);
begin
  with buf do freemem(d,w*h);
  fillchar(buf,sizeof(buf),0);
end;  {freeBuf}
{----------------------------------------------------------------------------}
begin
end.  {unit Gifs}
