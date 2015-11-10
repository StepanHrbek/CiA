{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{
---------------------------------------------------------------------------
                        Utility pro loadery
---------------------------------------------------------------------------

Pomocne funkce pouze pro interni potrebu loaderu.

}

Unit      LdUtil;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects, Dos,Sys,Vga,Loadery;

var InputStream:PStream;
    InputSize,InputPos:LongInt;
    InputName:PathStr;

    WorkSeg1:word absolute picSeg1;
    WorkSeg2:word absolute picSeg2;

procedure ldError(e:TError);

procedure InitBuffering;
procedure InputRead(var Data;Size:Word);
procedure InputReadXX(var Data;Size:Word;var X:Word);
procedure InputReadNoError(var Data;Size:Word);
procedure SeekInputRel(RelPos:LongInt);

procedure glInit(map:PBitmap;srcX,srcY,sir,vys,BitsToByte:word);

type
 thttblAC=record StartOfOnes:word;
       DecodeTable:array[0..512,0..1] of byte;
  end;
 thttblDC=record StartOfOnes:word;
       DecodeTable:array[0..32,0..1] of byte;
  end;
 tqtbl=array[0..63] of word;
 tColorSpace=(CS_UnKnown,CS_GrayScale,CS_YCbCr,CS_YIQ,CS_RGB,CS_CMYK);
 tCompInfo=record
   ComponentId,ComponentIndex,HSampFactor,VSampFactor,QuantTblNo,DCTblNo,ACTblNO,BlocksInMCU:Word;
  end;
 tTypeOfJPG=(JPG_UnKnown,JPG_Mono,JPG_1x1_1x1_1x1,JPG_2x1_1x1_1x1,JPG_2x2_1x1_1x1);
 TypPtr=record
   ofs1,seg1:word
  end;
 tChunk=record Size,Typ:LongInt end;
 thttblCL=record StartOfOnes:word;
       DecodeTable:array[0..40,0..1] of word;
  end;
 tLongs=array[0..285] of byte;


const
 cPNG=1;
 cJPG=2;
 cX=3;
 cPCX=4;
 cGIF=5;
 cFLC=6;
 cHSIJPG=26;

var
 Pal:array[0..255,0..2] of ShortInt;
 Buffer:array[0..2047] of byte;{2048 bytes}

 WorkArray:array[0..4*273+23*4+1,0..1] of Word; {4744b}
 YCbCr2RGBXlat:array[0..1,0..255] of LongInt; {2048 bytes}
 RoundXlat:array[-40..255+40] of byte;     {256+80 b}

 QuantTblPtrs:array[0..3,0..63] of word;   {512 b}
 CompInfo:array[0..3] of tCompInfo;        {64 b}
 CurCompInfo:array[0..3] of ^tCompInfo;    {16 b}
 LastDCVal:array[0..3] of word;            {8 b}

 MCUDataWords,MCUDataOut:array[0..63] of Integer; {2*128 b}
 

 GetLine:function(Line:Word):pointer;{fce na zmˆny palet}
 MoveToLine:function(Line:Word;p:pointer):pointer;

 l1,l2:LongInt;
{ TmpPtr2:^Byte;}
 TmpPtr,Buf:^Word;

 Chunk:tChunk;
 httbl:^thttblCL;


 Head:record
       case Integer of
        0:(PNG:record
                Sign1,Sign2:LongInt;
                IHDR:record
                     Length,Typ,Width,Height:Longint;
                     BitDepth,ColorType,Compression,Filter,Interlace:byte;
                     CRC:Longint
                    end;
	       end);
        1:(SOF:record
                DataPrecision:byte;
                Height,Width:Word;
                NumComponents:byte
               end);
        2:(X:record
              Width,Height:Word;
              UsedColors:Byte
             end);
        3:(PCX:record
	        Creator,Version,Encoding,BitPerPixel:byte;
                X1,Y1,X2,Y2:integer;
	        HRes,VRes:word;
                Palette:array[0..15,0..2] of byte;
                VMode,Planes:byte;
                BytesPerLine,PaletteInfo:word;
                Dummy:array[0..57] of byte
               end);
      4:(GIF:record
           Head:array[0..2] of Word;
           Width,Height:Word;
           Misc,BackGround,PixelAspectRatio:Byte
	  end);
      5:(GIF_GCL:record
           PackedFields:Byte;
           DelayTime:Word;
           TransparentIndex:Byte
          end);
      6:(BlkPictGIF:record {nepo‡¡t  se £vodn¡ znak 2ch}
	      x1,y1,width,height:word;
	      Misc:Byte
	     end);
          end;
 XlatSeg,
  Konverze,
  PosInBuffer,
  Strip,Strips,
  NextRestartNum,EC,IC,
  CurLine,RozsahX,RozsahY,TransparentIndex,Barev,BytesPerLine,
  a,aa,b,bb,c,d,i,Konec,Soubor,ErrorNo:word;
 tmp0,tmp1,tmp2,tmp3,tmp7,tmp11:Word;

 MaxHSampFactor,MaxVSampFactor,
  CompsInScan,
  MCURowsInScan,CurMCURow,MCUsPerRow,
  BitsLeft,InBuffer:Word;

 OldSP,OldBP,OldCS,OldIP:Word;

 ColorSpace:tColorSpace;
 Paleta,XlatYCbCr2Pal,ArithCode:Boolean;
 TypeOfJPG:tTypeOfJPG;

procedure CreateGrayPal;
procedure MulPal;

implementation

procedure ldError(e:TError);
begin
 erMsg(InputName+': '+_(e));
end;

procedure CreateGrayPal;assembler;
 asm             {defaultne odstiny sedi, nutne pro B/W JPG a PNG bez palety}
  xor di,di
  xor al,al
@1:mov byte ptr Pal[di],al
  mov byte ptr Pal[di+1],al
  mov byte ptr Pal[di+2],al
  add di,3
  inc al
  jnz @1
 end;

procedure MulPal;assembler;
 asm
  mov si,offset pal
  mov cx,768
 @@Loop:
  shl byte ptr [si],2
  inc si
  loop @@Loop
 end;

procedure InitBuffering;
 begin
  PosInBuffer:=2047-(InputPos mod 2048);
  if PosInBuffer=0 then PosInBuffer:=2048;
  InputReadNoError(Buffer[PosInBuffer],2048-PosInBuffer);
 end;

procedure InputRead(var Data;Size:Word);
 begin
  InputStream^.Read(data,size);
  Inc(InputPos,Size);
 end;

procedure InputReadXX(var Data;Size:Word;var X:Word);
 begin
  x:=minL(size,inputsize-inputpos);
  InputRead(data,x);
 end;

procedure InputReadNoError(var Data;Size:Word);
 begin
  InputRead(data,minL(size,inputsize-inputpos));
 end;

procedure SeekInputRel;
 begin
  Inc(InputPos,RelPos);
  InputStream^.Seek(InputPos);
 end;

     {glXXXX - GetLine}
var   glTab       :PLines;
      glX         :word;
      glVyska     :word;
      glByPL      :word;
      glBitsToByte:byte;{po kolika bitech to ladovat na vystup: 1,2,4,8}

{---------------------------------------------------------------------------
 Oznaci blok uvnitr bitmapy pro pouziti funkce GetLine.
 ---------------------------------------------------------------------------}
PROCEDURE glInit(Map:PBitmap;srcX,srcY,sir,vys,BitsToByte:word);
begin
 {$ifdef beta}
 if srcY>=map^.sizeY then erBetaMsg('glinit');
 {$endif}
 glTab       :=PLines(@map^.tab^[srcY]);
 glX         :=longint(srcX)*map^.BiPP shr 3;
 glByPL      :=longint(sir)*map^.BiPP shr 3;
 glVyska     :=vys;
 glBitsToByte:=BitsToByte;
end;

{---------------------------------------------------------------------------
 Vraci pointer na zadany radek vybraneho bloku uvnitr bitmapy.
 Po pripadnem preteceni vysky vyrezu wrapne na zacatek vyrezu.
 ---------------------------------------------------------------------------}
FUNCTION glGetLine(y:word):pointer;far;
begin
 glGetLine:=@glTab^[y mod glVyska]^[glX];
end;

{---------------------------------------------------------------------------
 Zkopci data do line y.
 move(p^,glGetLine(y)^,glByPL);
 ---------------------------------------------------------------------------}
FUNCTION glMoveToLine(y:word;p:pointer):pointer;far;assembler;
 asm
   PUSH DS
   push y
   call glGetLine
   mov es,dx
   mov di,ax
   mov cx,glByPL
   mov al,glBitsToByte
   lds si,p

   cmp al,8;je @8BitsToByte
   cmp al,4;je @4BitsToByte
   cmp al,2;je @2BitsToByte
   cmp al,1;je @1BitToByte
   jmp @end

  @8BitsToByte:
   call REP_MOVSB_di
   jmp @end

  @4BitsToByte:
   shr cx,1
   jcxz @4main0
   PUSHF
  @4main:
   lodsb
   mov ah,al
   shr al,4
   and ah,15
   stosw
   loop @4main
  @4main0:
   POPF
   jnc @end
   lodsb
   shr al,4
   stosb
   jmp @end

  @2BitsToByte:
   PUSH CX
   shr cx,2
   jcxz @2main0
  @2main:
   lodsb
   mov ah,al
   shr al,2
   mov bx,ax
   shr ax,4
   and ax,0303h
   stosw
   xchg ax,bx
   and ax,0303h
   stosw
   loop @2main
  @2main0:
   POP CX
   and cx,3
   jcxz @end
   lodsb
   shl ax,8
  @2last:
   rol ax,2
   and al,3
   stosb
   loop @2last
   jmp @end

  @1BitToByte:
   PUSH CX
   shr cx,3
   jcxz @1main0
  @1main:
   lodsb
   mov ah,al
   shr al,1
   mov bx,ax
   shr ax,6
   and ax,0101h
   stosw
   mov ax,bx
   shr ax,4
   and ax,0101h
   stosw
   mov ax,bx
   shr ax,2
   and ax,0101h
   stosw
   xchg ax,bx
   and ax,0101h
   stosw
   loop @1main
  @1main0:
   POP CX
   and cx,7
   jcxz @end
   lodsb
   shl ax,8
  @1last:
   rol ax,1
   and al,1
   stosb
   loop @1last
   jmp @end

  @end:
   POP DS
 end;

begin
  GetLine      :=glGetLine;
  MoveToLine   :=glMoveToLine;
end.