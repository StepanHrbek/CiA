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

Unit      LdX;
Interface {$i define.inc}
Implementation
Uses      Chyby, Objects, Vga,Fajly,Loadery,LdUtil;

const VelikostBufferuX1=65536;{musi zustat}
      VelikostBufferuX2=5000; {volitelne}

function GetInfoX:Boolean;
 begin
  Soubor:=cX;InputRead(Head.X,SizeOf(Head.x));
  with Head.X do
   begin
    GetInfoX:=(Width<2000) and (Height<2000);
    RozsahX:=Width;RozsahY:=Height;BytesPerLine:=RozsahX;
    TransparentIndex:=0;
    Barev:=256;
    Paleta:=True;
    FillChar(Pal,768,0);
    InputRead(Pal[(256-UsedColors)],UsedColors*3);
   end;
  MulPal;
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

procedure DeCompressX;
 begin
  Buf:=ptr(WorkSeg2,0);

  if LongInt(InputSize-InputPos)<VelikostBufferuX2 then IC:=InputSize-InputPos
   else IC:=VelikostBufferuX2;

  InputRead(buf^,IC);

  IC:=0;TmpPtr:=ptr(WorkSeg1,0);EC:=0;
  repeat
  asm
   les di,TmpPtr
   push ds
   mov ax,RozsahY
   sub ax,EC          {kolik radek jeste zbyva}
   mul BytesPerLine
   test dx,dx
   jnz @upravmez
   cmp ax,VelikostBufferuX1-300  {spocitej, kolik toho mame dekomprimovat}
   jbe @0
@upravmez:
   mov ax,VelikostBufferuX1-300
@0:mov bx,ax
   mov cx,IC                 {kolikrat zbyva opakovat bajt z minuleho kola z kodu 2}
   mov al,byte ptr d         {bajt, ktery budeme pripadne opakovat}
   cld
   lds si,Buf
   jcxz @loop                {nic -> skok}
   rep stosb


@loop:
   cmp di,bx
   ja @konec
   cmp si,VelikostBufferuX2-4 {musime nacist dalsi data?, s rezervou}
   jb @loop1
   pop ds
   mov word ptr TmpPtr,di
   mov word ptr Buf,si
   push bx
   push VelikostBufferuX2     {ano}
   push cs
   call near ptr CtiKusDat
   pop bx
   les di,TmpPtr
   push ds
   lds si,Buf
   xor cx,cx
   cld
@loop1:
   lodsb
   cmp al,2
   jbe @2
   stosb
   jmp @loop
@2:jb @1
   lodsw          {opakuj upto 65535x jeden bajt}
   mov cx,ax
@StoreMany:
   mov dx,di      {test, zda nepretecem pres segment}
   add dx,cx
   jc @NotOK      {not carry -> nepreteceme}
   lodsb
   rep stosb
   jmp @loop
@NotOK:
   mov dx,65535   {pretecem - nejdriv zopakujeme cast a priste zbytek}
   sub dx,di      {spocitej, kolik muzeme ulozit bez preteceni}
   sub cx,dx      {kolik potom zbyde na ulozeni}
   xchg cx,dx     {inicializuj citac na pocet, ktery ted muzeme ulozit}
   lodsb
   rep stosb
   mov cx,dx
   jmp @konec

@1:test al,al
   jz @transparent
   lodsb
   mov cl,al
   lodsb
   rep stosb
   jmp @loop
@transparent:
   stosb    {tady ma Dement inc di}
   jmp @loop
@konec:
   pop ds
   mov IC,cx      {to schovej do priste, <>0, mame-li opakovat bajt, jinak =0}
   mov byte ptr d,al {i s bajtem, ktery budeme ukladat, jinak smeti}
   mov word ptr TmpPtr,di
   mov word ptr Buf,si
  end;
   b:=TypPtr(TmpPtr).ofs1;{delka dekomprimovanych dat}
   TypPtr(TmpPtr).ofs1:=0;
   c:=EC+(b div BytesPerLine)-1;{do kolika radku}
   if c>RozsahY-1 then c:=RozsahY-1;{nepreteceme?}
   for a:=EC to c do
    begin
     MoveToLine(a,TmpPtr);Inc(TypPtr(TmpPtr).ofs1,BytesPerLine)
    end;
   EC:=a+1;
   Move(TmpPtr^,ptr(WorkSeg1,0)^,b-TypPtr(TmpPtr).ofs1);
                                         {presun nezpracovany zbytek na zacatek}
   TypPtr(TmpPtr).ofs1:=b-TypPtr(TmpPtr).ofs1;
  until EC>=RozsahY;
 end;

function GetInfo(s:PStream;var model,x,y:word):TError;far;
begin
 InputStream:=s;
 InputPos:=0;
 InputSize:=s^.GetSize;
 GetInfoX;
 model:=model_packed;
 x:=RozsahX;
 y:=RozsahY;
 GetInfo:=erOk;
end;

function Decompress(s:PStream;map:PBitmap):TError;far;
var c:byte;
begin
 Decompress:=erOk;
 glInit(map,0,0,map^.sizeX,map^.sizeY,8);
 DecompressX;
 with map^ do
  if pal<>nil then
   with pal^ do begin
    Setup(256-Head.X.UsedColors,255,pifUsed);
    for c:=256-Head.X.UsedColors to 255 do begin
      pal[c].r:=byte(ldutil.pal[c,0]) shr 2;
      pal[c].g:=byte(ldutil.pal[c,1]) shr 2;
      pal[c].b:=byte(ldutil.pal[c,2]) shr 2;
      end;
    end;
 map^.transparent:=true;
end;

function Compress(s:PStream;map:PBitmap):TError;far;
begin
 Compress:=erOk;
end;

begin
 picRegister('X',isLoadable+isGraphics+isFixedSize,GetInfo,Decompress,nil,'');
end.