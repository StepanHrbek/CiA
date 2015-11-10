{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{
---------------------------------------------------------------------------
                                Loader
---------------------------------------------------------------------------

K praci s formatem Xxxx staci Uses Loadery,LdXxxx;
a dal pracovat s funkcemi z unity Loadery.

Ze zdejsi interface je prazdny neni chyba, loader se automaticky zaregistruje
a unita loadery o nem vi.

}

Unit      LdPcx;
Interface {$i define.inc}{$t-}
Implementation
Uses      Chyby, Objects, Vga,Fajly,Loadery,LdUtil;

const VelikostBufferuPCX1=65520;  {volitelne}
      VelikostBufferuPCX2=65520;  {volitelne}

function GetInfoPCX:Boolean;
 begin
  Soubor:=cPCX;InputRead(Head.PCX,SizeOf(Head.PCX));
  with Head.PCX do
   begin
    GetInfoPCX:=(Creator=10) and (Encoding=1);
    rozsahx:=x2-x1+1;rozsahy:=y2-y1+1;
    TransparentIndex:=65535;
    if bitperpixel=8 then
      if planes=1 then begin barev:=256;LdUtil.BytesPerLine:=RozsahX end
       else
        if Planes=3 then
         begin
          Barev:=65535;LdUtil.BytesPerLine:=RozsahX*3
         end
	else Barev:=32768
    else barev:=1 shl (Planes*BitPerPixel);
    Paleta:=(version=5) or (version=2);
{    if (BytesPerLine<>0) and (Barev<>65535) then LdUtil.BytesPerLine:=BytesPerLine
     else
      if Barev=256 then LdUtil.BytesPerLine:=RozsahX
       else
	if Planes>1 then LdUtil.BytesPerLine:=((RozsahX+7) shr 3);}
{    if LdUtil.Barev in [4..16] then LdUtil.BytesPerLine:=LdUtil.BytesPerLine shl 2;}
   end;
  if Paleta and (Barev=2) then
   asm                          {Nektere prgs ukladaji obe barvy cerne}
    mov ax,word ptr Head.PCX.Palette
    test ax,ax
    jnz @1
    cmp ax,word ptr [Head.PCX.Palette+2]
    jne @1
    cmp ax,word ptr [Head.PCX.Palette+4]
    jne @1
    dec ax
    mov word ptr [Head.PCX.Palette+4],ax
    mov byte ptr [Head.PCX.Palette+3],al
@1:end;
  if Paleta and (barev=256) then {256barevne imgs maji paletu na konci souboru}
   begin
    SeekInputRel(InputSize-769-SizeOf(Head.PCX));a:=0;inputread(a,1);
    if a=$0c then InputRead(Pal,768) else Paleta:=False;
    SeekInputRel(-(InputSize-128))
   end
  else Move(Head.PCX.Palette,Pal,48);
 end;

procedure CtiKUSDat(Delka:Word);far;
 begin
  b:=TypPtr(Buf).ofs1;
  Move(Buf^,Mem[TypPtr(Buf).seg1:0],Delka-TypPtr(Buf).ofs1);
  TypPtr(Buf).ofs1:=Delka-TypPtr(Buf).ofs1;

  if LongInt(InputSize-InputPos)<LongInt(b) then b:=InputSize-InputPos;
  InputRead(buf^,b);

  TypPtr(Buf).ofs1:=0
 end;

procedure DecompressPCX;var a:word;
 begin
  Buf:=ptr(WorkSeg2,0);

  if LongInt(InputSize-InputPos)<VelikostBufferuPCX2 then EC:=InputSize-InputPos
   else EC:=VelikostBufferuPCX2;

  InputRead(buf^,EC);

  TmpPtr:=ptr(WorkSeg1,0);EC:=0;

  repeat
     asm
      les di,TmpPtr
      mov ax,RozsahY
      push ds
      sub ax,EC          {kolik radek jeste zbyva}
      mul Head.PCX.BytesPerLine
      test dx,dx
      jnz @upravmez
      cmp ax,VelikostBufferuPCX1-300  {spocitej, kolik toho mame dekomprimovat}
      jbe @0
@upravmez:
      mov ax,VelikostBufferuPCX1-300
@0:   cld
      lds si,Buf
      mov bx,ax

@loop:
      cmp si,VelikostBufferuPCX2-4 {musime nacist dalsi data?, s rezervou}
      jb @loop1
      pop ds
      mov word ptr TmpPtr,di
      mov word ptr Buf,si
      push bx
      push VelikostBufferuPCX2
      call far ptr CtiKusDat
      pop bx
      les di,TmpPtr
      push ds
      lds si,Buf
      cld
@loop1: lodsb
      cmp al,0c0h    ;{je-li<0c0h, je to jeden datov˜ bajt}
      mov cx,1
      jb @@4
      and al,63       ;{jinak spodn¡ch 6 bit– ud v , kolikr t se dal¨¡ bajt bude opakovat}
      mov cl,al
      lodsb           ;{na‡ti opakovan˜ bajt}
@@4:  rep stosb
      cmp di,bx
      jb @Loop
      pop ds
      mov word ptr TmpPtr,di
      mov word ptr Buf,si
     end;
     b:=TypPtr(TmpPtr).ofs1;{delka dekomprimovanych dat}
     TypPtr(TmpPtr).ofs1:=0;
     c:=EC+(b div Head.PCX.BytesPerLine)-1;{do kolika radku}
     if c>RozsahY-1 then c:=RozsahY-1;{nepreteceme?}
     for a:=EC to c do
      begin
       MoveToLine(a,TmpPtr);Inc(TypPtr(TmpPtr).ofs1,Head.PCX.BytesPerLine)
      end;
     EC:=a+1;
     Move(TmpPtr^,ptr(WorkSeg1,0)^,b-TypPtr(TmpPtr).ofs1);
                                           {presun nezpracovany zbytek na zacatek}
     TypPtr(TmpPtr).ofs1:=b-TypPtr(TmpPtr).ofs1;
    until EC>=RozsahY;
  BytesPerLine:=RozsahX;
 end;

function GetInfo(s:PStream;var model,x,y:word):TError;far;
begin
 InputStream:=s;
 InputPos:=0;
 InputSize:=s^.GetSize;
 GetInfoPCX;
 model:=model_packed;
 x:=RozsahX;
 y:=RozsahY;
 GetInfo:=erOk;
 if (Barev<>256) or (Head.PCX.Planes<>1) then GetInfo:=ldOnly256IsSup;
end;

function Decompress(s:PStream;map:PBitmap):TError;far;
var c:byte;
begin
 Decompress:=erOk;
 glInit(map,0,0,map^.sizeX,map^.sizeY,8);
 DecompressPCX;
 with map^ do
  if pal<>nil then
   with pal^ do begin
    Setup(0,255,pifUsed);
    for c:=0 to 255 do begin
      pal[c].r:=byte(ldutil.pal[c,0]) shr 2;
      pal[c].g:=byte(ldutil.pal[c,1]) shr 2;
      pal[c].b:=byte(ldutil.pal[c,2]) shr 2;
      end;
    end;
 map^.transparent:=false;
end;

begin
 picRegister('PCX',isLoadable+isGraphics+isFixedSize,GetInfo,Decompress,nil,'');
end.
