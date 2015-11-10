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

Unit      LdGIF;
Interface {$i define.inc}{$r-,q-,t-}
Uses      Chyby;
Function  Init:TError;
Procedure Done;

Implementation
Uses      Memo,Objects,Vga,Fajly,LdUtil,Loadery;

{
nase interni komentare pouze pro potrebu spravy a vyvoje:

 Alokace dalsi nezbytne pameti:

  Docasne naalokovane bloky pameti jsou v poli MCUDataWords, ale az od indexu 1!!
  Pocet techto bloku (kazdy ma 64KB) je v promenne Tmp3.

  Fce:

   InitGIFMem: vynuluje citac bloku Tmp3
   GiveMeMore: zkusi naalokovat dalsi blok, ulozi jej do MCUDataWord[++Tmp3]
   DoneGIFMem: dealokuje vsechny docasne bloky a vynuluje citac

  Pouziti:

  DeCompressGIF zavola ihned InitGIFMem

  Dojde-li k chybe behem DeCompressGIF, pred Error se zavola DoneGIFMem

  DeCompressGIF pred ukoncenim zavola DoneGIFMem

 Zmeny:
  11.5. 1998 [Patera]:
   - Zlepseno chovani (zmensen pocet GPF) u nekompletnich GIFu
  29.10.2001 [Dee]:
   - Zakomentovana radka kvuli ktere nesly nektere 2-barevne GIFy.
}

type
 MyArray=array[0..4096] of ^string;
 tpole=array[0..4743] of byte;
 tdeluk=array[0..4097] of Word;

var
 Ukazatele:^MyArray absolute httbl;
  {ufff, ze me tenhle trik nenapadl driv, nemusel bych silene prejmenovavat promenne...}

 DelUkazatele:^tdeluk;{odsunuto z DS pryc}

procedure InitGifMem;
 begin
  Tmp3:=0;
 end;

function GiveMeMore:Boolean;var p:pointer;
 begin
  if GetMem(p,65536) then
   begin
    inc(Tmp3);MCUDataWords[Tmp3]:=TypPtr(p).seg1;GiveMeMore:=True
   end
  else GiveMeMore:=False
 end;

procedure DoneGifMem;var p:pointer;
 begin
  for i:=1 to Tmp3 do
   begin
    p:=Ptr(MCUDataWords[i],0);
    FreeMem(p,65536);
   end;
  Tmp3:=0;
 end;


procedure DeLZW;external;{$l LdGIF.obj}

procedure PrehakniGIF256;
 begin
  for b:=Tmp0 to Head.GIF.Head[1] do
   begin
    MoveToLine(Konec,TmpPtr);inc(TypPtr(TmpPtr).ofs1,RozsahX);Inc(Konec,CompsInScan);
    if Konec>=RozsahY then {tuhle slozitost potrebujeme pro interlaced gifs}
     case CompsInScan of
       8:if Konec and 4=0 then Konec:=4
        else begin Konec:=2;CompsInScan:=4 end;
       4:begin Konec:=1;CompsInScan:=2 end;
      end
   end;
 end;

procedure PrehakniKus;
 begin
  a:=TypPtr(TmpPtr).ofs1;TypPtr(TmpPtr).ofs1:=0;
  if TypPtr(TmpPtr).seg1=WorkSeg1 then TypPtr(TmpPtr).ofs1:=4098*4;
  Dec(l2,RozsahX*(a div RozsahX));
  Head.GIF.Head[1]:=((a-TypPtr(TmpPtr).ofs1) div RozsahX)+Tmp0-1;PrehakniGIF256;Tmp0:=b+1;
  if l2=0 then i:=EC;
 end;

procedure InitLZW;
 begin
  a:=0;
{$ifdef Shrinking}FillChar(VESAModeInfo,8200,255);{$endif}
  if TypPtr(TmpPtr).ofs1>0 then
   begin
    PrehakniKus;Buf:=TmpPtr;Dec(a,TypPtr(Buf).ofs1);
    Move(Buf^,{ptr(WorkSeg1,300*4}Ukazatele^[300],a)
   end;
  bb:=1 shl Tmp1;DoneGifMem;
  TmpPtr:=@Buffer[2047-260];
  for b:=0 to bb+1 do
   begin
    Ukazatele^[b]:=pointer(TmpPtr);inc(TypPtr(TmpPtr).ofs1);
    Ukazatele^[b]^[0]:=chr(b);DelUkazatele^[b]:=1;
   end;
  if Barev=2 then Ukazatele^[1]^[0]:=#128;
  Ukazatele^[bb+1]^:='';{PocBit}Tmp11:=Tmp1+1;

  TmpPtr:=ptr(WorkSeg1,4098*4);c:=65520;
  NextRestartNum:=bb*2;Inc(bb,2);aa:=1;
  Strips:=(1 shl (Tmp11{PocBit}))-1;
  if a<>0 then
   begin
    Move({ptr(WorkSeg1,300*4}Ukazatele^[300],TmpPtr^,a);
    Inc(TypPtr(TmpPtr).ofs1,a);
   end;
 end;

procedure CteniGIF;var x:word;
 begin
  if Tmp2<CurMCURow then
   begin
    Strip:=Tmp2+1;inc(Tmp2,tPole(WorkArray)[1+Tmp2]+1);
   end
  else
   begin
    CurMCURow:=0;InputReadXX(tPole(WorkArray)[1+0],4740+2048-255,x);{nacti, co to da}
    while CurMCURow<x do
     begin
      if tPole(WorkArray)[1+CurMCURow]=0 then x:=CurMCURow else
      inc(CurMCURow,tPole(WorkArray)[1+CurMCURow]+1);
     end;
    if CurMCURow>4740-255 then {if nactn kus bloku, nacti zbytek bloku}
     begin
      InputReadXX(ptr(DSeg,Ofs(WorkArray)+1+4740+2048-255)^,CurMCURow-4740-2048+255,x);
     end;
    Tmp2:=tPole(WorkArray)[1+0]+1;Strip:=1;
   end;
 end;

procedure CtiSubBloky;
 begin
  repeat
   InputRead(a,1);SeekInputRel(a);
  until a=0
 end;

function GetInfoGIF:Boolean;
 begin
  Soubor:=cGIF;InputRead(Head.GIF,13);GetInfoGIF:=False;
  TransparentIndex:=65535;
  with Head.GIF do
   begin
    if (Head[0]=ord('G')+ord('I')*256) and (Head[1]=ord('F')+ord('8')*256)
     and ((Head[2]=ord('7')+ord('a')*256) or (Head[2]=ord('9')+ord('a')*256)) then
     begin
      IC:=1 shl ((Misc and 7)+1);Paleta:=Misc>127;a:=$2c;
      if Paleta then InputRead(Pal,IC*3);
      repeat
       if a<>$2c then
        if a<>$21 then Exit
        else
         begin
          InputRead(a,1);
          case a of
            $f9:begin {Graphics Control Label}
                 InputRead(a,1);
                 InputRead(LdUtil.Head.GIF_GCL,SizeOf(LdUtil.Head.GIF_GCL));
                 if LdUtil.Head.GIF_GCL.PackedFields and 1<>0 then
                  TransparentIndex:=LdUtil.Head.GIF_GCL.TransparentIndex;
                 SeekInputRel(a-4);CtiSubBloky;
                end;
            else CtiSubBloky
           end
	 end;
       a:=0;InputRead(a,1)
      until a=$2c;
      InputRead(LdUtil.Head.BlkPictGIF,SizeOf(LdUtil.Head.BlkPictGIF));
      RozsahX:=LdUtil.Head.BlkPictGIF.Width;RozsahY:=LdUtil.Head.BlkPictGIF.Height;
      BytesPerLine:=RozsahX;
      if LdUtil.Head.BlkPictGIF.Misc>127 then SeekInputRel(3*(1 shl ((LdUtil.Head.BlkPictGIF.Misc and 7)+1)));
       {vlastni paleta bloku}
      if LdUtil.Head.BlkPictGIF.Misc and 64=64 then CompsInScan:=8 else CompsInScan:=1; {interlaced}
      Konec:=0;Tmp1:=0;{nuluj horni bajt}InputRead(Tmp1,1);GetInfoGIF:=True;

      Barev:=1 shl Tmp1;

      (*29.10.2001 zakomentovano aby spravne cetl 2-barevne obrazky,
                   puvodni smysl mi neni znam
      if (Tmp1=2){StarBit} and (IC=2){BitDepth} then Barev:=2;*)
     end
   end
 end;

procedure PreteceniBloku;
	  begin
           asm
            mov di,i
	    shl di,2
            mov es,WorkSeg1
            les di,es:[di]{dword ptr Ukazatele[di]}
            mov al,es:[di]
            les di,TmpPtr
            mov es:[di],al
           end;
	   PrehakniKus;
{	   writeLn('preteceni...$');}
           if TypPtr(TmpPtr).seg1=WorkSeg1 then Buf:=Ptr(WorkSeg2,0)
            else
	     if GiveMeMore then Buf:=Ptr(MCUDataWords{GIFSeg}[Tmp3{Allocated}],0)
 	      else
	       begin
	        DoneGIFMem;ldError(erLowMem);
               end;
           Dec(a,TypPtr(TmpPtr).ofs1); {a je modifikovano fci PrehakniKus}
           Move(TmpPtr^,Buf^,a);TmpPtr:=Buf;
           Inc(TypPtr(TmpPtr).ofs1,a);
 end;

procedure DeCompressLZW;
 begin
  {PocBit}Tmp11:=Tmp1+1;CurMCURow:=0;Strip:=0{II};Tmp2:=0{MaxII};CteniGIF;
  bb{II}:=1 shl Tmp1;IC:=bb;EC:=bb+1;TypPtr(TmpPtr).ofs1:=0;
{*?}TmpPtr:=nil;
  BitsLeft:=0;Strips:=(1 shl Tmp11{Pocbit})-1;
  DeLZW;
  PrehakniKus;
 end;

procedure DecompressGIF;
 begin
  InitGifMem;
  asm mov ax,RozsahX;mul RozsahY;mov word ptr l2,ax;mov word ptr [l2+2],dx end;
  Tmp0:=0;Ukazatele:=ptr(WorkSeg1,0);
  DeCompressLZW;
  DoneGifMem
 end;

function GetInfo(s:PStream;var model,x,y:word):TError;far;
begin
 InputStream:=s;
 InputPos:=0;
 InputSize:=s^.GetSize;
 GetInfoGIF;
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
 DecompressGIF;
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
 map^.transparent:=TransparentIndex<256;
 if (TransparentIndex>0) and (TransparentIndex<256)
  then SwapIndexesIn(map,TransparentIndex,0);
end;

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='ldgif';
var result:TError;

procedure UserInit;
 begin
  New(DelUkazatele);
  picRegister('GIF',isLoadable+isGraphics+isFixedSize,GetInfo,Decompress,nil,'');
 end;

procedure UserDone;
 begin
  Dispose(DelUkazatele);
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.