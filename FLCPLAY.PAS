{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit  FlcPlay;

{
---------------------------------------------------------------------------
                             FLI/FLC playery
---------------------------------------------------------------------------
 TDirectFLCPlayer   - jednoduse animuje primo do vram
 TIndirectFLCPlayer - resizuje a mixuje s pozadim, lze i pruhlednou animaci

 Pouziti
 -------
  Oba playery jsou potomci TPlayer, tudiz
   - Jednou zavolas jejich Init, pak pravidelne Sync dokud nevrati true
     (=zadost o ukonceni) a na konci jednou Done.
   - Pripadne muzes po Initu objekt vlozit do TPlaylistu, ten se postara
     o volani Sync a Done.

  Sync se pri rozhodovani jaky snimek zobrazi ridi podle hodin.

 Pruhlednost
 -----------
  Pokud prvni snimek obsahuje vice nez tretinu pixelu 0, bude 0 povazovana
  za pruhlednou. Toto chovani lze pretizit:
  pokud v souboru na offsetu 21 bude 't', 0 jsou vzdy transparentni
  pokud v souboru na offsetu 21 bude 'n', 0 jsou vzdy nepruhledne.
}

Interface {$i define.inc}

Uses  Chyby,Memo,
      Objects,Memory,
      Cache,Stringy,Sys,Vga,Scrol,FlcDecod;

Const {umoznuje vypnout vsechny animace}
      animations:boolean=true;

Type  {jeden snimek animace}
      PFrame=^TFrame;
      TFrame=object(TObject)
        header         :TFrameHeader;
        flcFrame       :^TFullFrame;
        constructor    Init(stream:PStream);
        destructor     Done;virtual;
       end;

      {abstraktni FLC player}
      TFLCPlayer=object(TPlayer)
        flcHeader      :TFlcHeader;
        frame          :word;
        looping        :boolean;
        waitingto      :longint;
        constructor    Init(astream:PStream);
        procedure      Setup(alooping:boolean;alineoffset,ax,ay:word;asetpal:TFLCSetPalProc;asetbank:TFLCSetBankFunc);
        function       Sync:boolean;virtual;
        function       GetLength:longint;
        procedure      Error(msg:Pchar);
        destructor     Done;virtual;
       private
        fileId         :longint;
        flcFrame       :PFrame;
        flcPlayerData  :pointer;
        posInFile      :longint;
        frameinited    :boolean;
        updateTail     :word;
        updateRect     :TRect;
        function       IsFli:boolean;
        function       GetDelay:longint;
        procedure      LockFrame;
        procedure      DecodeFrame;
        procedure      UnlockFrame;
        procedure      Start;virtual;
        procedure      Frame_Init;
        procedure      Frame_Show;
        procedure      Frame_Update;
        procedure      Frame_Done;
        procedure      FramePhase1_Init;virtual;
        procedure      FramePhase2_Show(updating:boolean);virtual;
        procedure      FramePhase3_Done;virtual;
        function       ShowNextFrame:boolean;
       end;

      {jednoduchy rychly FLC player animujici primo do videopameti}
      PDirectFLCPlayer=^TDirectFLCPlayer;
      TDirectFLCPlayer=object(TFLCPlayer)
        screen         :PScreen;
        constructor    Init(astream:PStream;setPrevMode:boolean);
        destructor     Done;virtual;
       private
        procedure      FramePhase1_Init;virtual;
        procedure      FramePhase2_Show(updating:boolean);virtual;
        procedure      FramePhase3_Done;virtual;
       end;

      {FLC player mixujici pripadne i pruhlednou a resiznutou animaci s pozadim(=amap) a zapisujici do vram(=ascreen)}
      PIndirectFLCPlayer=^TIndirectFLCPlayer;
      TIndirectFLCPlayer=object(TFLCPlayer)
        destRect       :TRect;
        constructor    Init(astream:PStream;ascreen:PScreen;amap:PBitmap;dest:TRect);
        destructor     Done;virtual;
       private
        screen         :PScreen;
        map            :PBitmap;
        pal            :array[0..255] of TCol;
        color          :T256Longs;
        fakedPckVram   :PBitmap;
        fakedRealVram  :PBitmap;
        mixingBuf      :PBitmap;
        transp         :boolean;
        outputmodel    :word;
        convert        :boolean;
        procedure      Start;virtual;
        procedure      FramePhase1_Init;virtual;
        procedure      FramePhase2_Show(updating:boolean);virtual;
       end;

Implementation


{------------------------------FRAME CACHE----------------------------------}

Type
      TFileId = longint;{typ pouzity pro identifikaci streamu jeho delkou}

      PFrameId = ^TFrameId;
      TFrameId = object(TCacheId)
        constructor    Init(afileid:TFileId;apos:longint;astream:PStream);
        function       Compare(id:PCacheId):boolean;virtual;
        function       Load:PObject;virtual;
       private
        fileId         :TFileId;
        stream         :PStream;
        pos            :longint;
       end;


Procedure ReadLong(stream:Pstream;kam:pointer;toload:longint);
var  temptoload:word;
begin
 while toload>0 do begin
   temptoload:=Long2Word(MinL(toload,65536-PtrRec(kam).Ofs));
   stream^.Read(kam^,temptoload);
   dec(toload,temptoload);
   inc(PtrRec(kam).Ofs,temptoload);
   if PtrRec(kam).Ofs=0 then inc(PtrRec(kam).Seg,selectorInc);
   end;
end;


Constructor TFrameId.Init(afileid:TFileId;apos:longint;astream:PStream);
begin
 inherited Init;
 fileId:=aFileId;
 pos:=apos;
 stream:=astream;
end;

Function TFrameId.Compare(id:PCacheId):boolean;
begin
 Compare:=(fileId=PFrameId(id)^.fileId) and
          (pos=PFrameId(id)^.pos);
end;

Function TFrameId.Load:PObject;
begin
 stream^.Seek(pos);
 Load:=New(PFrame,Init(stream));
end;


Constructor TFrame.Init(stream:PStream);
begin
 inherited Init;
 stream^.Read(header,sizeof(header));
 if not GetMem(pointer(flcFrame),header.size) then Halt(erLowMem);
 flcFrame^.header:=header;
 Move(header,flcFrame^.header,sizeof(header));
 ReadLong(stream,@flcFrame^.data,header.size-sizeof(header));
end;

Destructor TFrame.Done;
begin
 if flcFrame<>nil then FreeMem(pointer(flcFrame),header.size);
 inherited Done;
end;



{---------------------------------PLAYER------------------------------------}

var sp_player:PIndirectFLCPlayer;

procedure RefreshColors(first,last:byte);
var   c:byte;
begin
 with sp_player^ do
  for c:=first to last do
   if (c=0) and (sp_player^.transp) then color[c]:=0 else
    color[c]:=map^.Color(pal[c].r shl 2,pal[c].g shl 2,pal[c].b shl 2,255);
end;

procedure AddPalette(sp_prvni, sp_pocet: Word; var sp_data);far;
var   c:byte;
begin
 Move(sp_data,sp_player^.pal[sp_prvni],3*sp_pocet);
 RefreshColors(sp_prvni,sp_prvni+sp_pocet-1);
end;

procedure SetPalette(sp_prvni, sp_pocet: Word; var sp_data);far;assembler;
 asm
  PUSH DS
  mov dx,3c8h
  mov al,byte ptr sp_prvni
  out dx,al
  inc dx
  mov cx,sp_pocet
  imul cx,cx,3
  lds si,dword ptr sp_data
  @1:
  outsb
  loop @1
  POP DS
end;

var   myPos:pointer;

procedure ReadData(sp_bajtu: Word; var sp_kam);far;
var   kam:pointer;
      vejdese:longint;
begin
 if sp_bajtu=0 then exit;
 kam:=@sp_kam;
 vejdese:=65536-PtrRec(myPos).Ofs;
 if sp_bajtu>=vejdese then begin
   Move(myPos^,kam^,vejdese);
   myPos:=ptr(PtrRec(myPos).Seg+selectorInc,0);
   dec(sp_bajtu,vejdese);
   inc(PtrRec(kam).Ofs,vejdese);
   end;
 Move(myPos^,kam^,sp_bajtu);
 inc(PtrRec(myPos).Ofs,sp_bajtu);
end;

Constructor TFLCPlayer.Init(astream:PStream);
begin
 if not animations then begin KillObj(astream);Fail;end;
 if not inherited Init(astream) then Fail;
 waitingto:=minLong;
 NewBuffer(flcPlayerData,flcData_Size);
 if flcPlayerData=nil then begin
   inherited Done;
   Fail;
   end;
 stream^.Read(flcHeader,sizeof(flcHeader));
end;

Procedure TFLCPlayer.Setup(alooping:boolean;alineoffset,ax,ay:word;asetpal:TFLCSetPalProc;asetbank:TFLCSetBankFunc);
var   pp:^TFLCSetPalProc;
begin
 looping:=alooping;
 if flcHeader.res1a=ord('l') then looping:=true else
 if flcHeader.res1a=ord('n') then looping:=false;
 Error(flcInit(@flcHeader,alineoffset,ax,ay,asetpal,asetbank,ReadData,PtrRec(flcPlayerData).Seg));
 fileId:=stream^.GetSize;
 if IsFli then posInFile:=stream^.GetPos
          else posInFile:=flcHeader.oframe1;
 frame:=1;
 Start;
end;

Function TFLCPlayer.IsFli:boolean;
begin
 IsFli:=flcHeader.magic=$af11
end;

Procedure TFLCPlayer.LockFrame;
begin
 flcFrame:=PFrame(caGet(New(PFrameId,Init(fileId,posInFile,stream)),-frame));
 inc(posInFile,flcFrame^.header.size);
end;

Procedure TFLCPlayer.DecodeFrame;
var   p:pointer;
      size:longint;
begin
 size:=flcFrame^.header.size;
 if (size<65520) and (PtrRec(flcFrame).Ofs=0)
  then p:=flcFrame^.flcFrame
  else begin
   {Frejmy delsi nez 65520 musi zkopcit do pracovniho bufferu
    protoze flcDecode prvni blok prepise dalsimi.
    Frejmy na offsetu<>0 musi zkopcit do bufferu kvuli pozadavku
    na nulovy offset.}
   myPos:=flcFrame^.flcFrame;
   p:=freeptr;
   size:=MinL(65520,size);
   Move(myPos^,p^,size);
   inc(PtrRec(myPos).Ofs,size);
   end;
 Error(flcDecodeFrame(p,PtrRec(flcPlayerData).Seg));
end;

Procedure TFLCPlayer.UnlockFrame;
begin
 caLeave(flcFrame);
end;

Procedure TFLCPlayer.Start;
begin
 frameinited:=false;
 Frame_Init;
end;

Procedure TFLCPlayer.Frame_Init;
begin
 if not frameinited then begin
   FramePhase1_Init;
   frameinited:=true;
   end;
end;

Procedure TFLCPlayer.Frame_Show;
begin
 if frameinited then begin
   AllNeedsUpdating(updateTail,updateRect);
   FramePhase2_Show(false);
   end;
end;

Procedure TFLCPlayer.Frame_Update;
begin
 if frameinited then begin
   while WhatNeedsUpdating(updateTail,updateRect) do FramePhase2_Show(true);
   end;
end;

Procedure TFLCPlayer.Frame_Done;
begin
 if frameinited then begin
   FramePhase3_Done;
   frameinited:=false;
   end;
end;

Procedure TFLCPlayer.FramePhase1_Init;
begin
end;

Procedure TFLCPlayer.FramePhase2_Show(updating:boolean);
begin
 Abstract;
end;

Procedure TFLCPlayer.FramePhase3_Done;
begin
end;

Function TFLCPlayer.ShowNextFrame:boolean;
begin
 Frame_Show;{*show muze byt i tam dole, }
 Frame_Done;
 if (frame=1) {and IsFli ..zakomentovano kvuli jednomu .FLC s vadnym oframe2} then flcHeader.oframe2:=posInFile;
 if frame<flcHeader.frames then inc(frame) else
  if not looping then begin ShowNextFrame:=true;exit;end else
   if frame=flcHeader.frames then inc(frame) else begin
     frame:=2;
     posInFile:=flcHeader.oframe2;
     end;
 Frame_Init;
{ Frame_Show;}
 ShowNextFrame:=false;
end;

Function TFLCPlayer.Sync:boolean;
begin
 if GetMs<waitingto then begin
   Frame_Update;
   Sync:=false;
   end
 else begin
   Sync:=ShowNextFrame;
   inc(waitingto,GetDelay);
   {pokud hodne zaostava, presteluje si hodinky}
   {napr kdyz playing pauznes, aby se to po pauze nesnazil dohnat}
   if GetMs>waitingto then waitingto:=GetMs+GetDelay;
   end;
end;

Function TFLCPlayer.GetDelay:longint;
begin
 if IsFli
  then GetDelay:=round(14.285*flcHeader.speed)
  else GetDelay:=flcHeader.speed;
end;

Function TFLCPlayer.GetLength:longint;
begin
 GetLength:=GetDelay*(flcHeader.frames-frame);
end;

Procedure TFLCPlayer.Error(msg:Pchar);
begin
 if msg<>nil then erMsg('FLC player: '+Pc2Str(msg));
end;

Destructor TFLCPlayer.Done;
begin
 Frame_Done;{UnlockFrame;}
 DisposeBuffer(flcPlayerData);
 inherited Done;
end;


{----------------------------DIRECT PLAYER----------------------------------}

var   myScreen:PScreen;

function SetBankDirect(sb_banka: Word):Word;far;
begin
 myScreen^.vesa_SetBank(sb_banka);
 SetBankDirect:=myScreen^.SegVram;
end;

Constructor TDirectFLCPlayer.Init(astream:PStream;setPrevMode:boolean);
var   mode:word;
      oldsux:integer;
begin
 if not inherited Init(astream) then Fail;
 oldsux:=lowerSux;
 lowerSux:=0;
 New(screen,Init(model_packed,flcHeader.width,flcHeader.height,0));
 lowerSux:=oldsux;
 if screen<>nil then begin
   screen^.silentDone:=not setPrevMode;
   Setup(false,screen^.lineOffset,0,0,SetPalette,SetBankDirect);
   exit;
   end;
 Done;
 Fail;
end;

Procedure TDirectFLCPlayer.FramePhase1_Init;
begin
 LockFrame;
end;

Procedure TDirectFLCPlayer.FramePhase2_Show(updating:boolean);
begin
 if not updating then begin
   myScreen:=screen;
   DecodeFrame;
   end;
end;

Procedure TDirectFLCPlayer.FramePhase3_Done;
begin
 UnlockFrame;
end;

Destructor TDirectFLCPlayer.Done;
begin
 KillObj(screen);
 inherited Done;
end;


{----------------------------INDIRECT PLAYER--------------------------------}

var   myFakedSegVram:word;

function SetBankIndirect(sb_banka: Word):Word;far;
begin
 SetBankIndirect:=myFakedSegVram;
end;

Constructor TIndirectFLCPlayer.Init(astream:PStream;ascreen:PScreen;amap:PBitmap;dest:TRect);
var   fakedPckVramPtr:pointer;
      fakedPckVramEnd:pointer;
begin
 if not inherited Init(astream) then Fail;
 destRect:=dest;
 New(fakedPckVram,Init(model_packed,flcHeader.width,flcHeader.height));
 if fakedPckVram=nil then Halt(erLowMem);
 fakedPckVramPtr:=fakedPckVram^.tab^[0];
 fakedPckVramEnd:=fakedPckVram^.tab^[fakedPckVram^.sizeY-1];
 if (PtrRec(fakedPckVramPtr).Seg<>PtrRec(fakedPckVramEnd).Seg) or
    (PtrRec(fakedPckVramPtr).Ofs+longint(fakedPckVram^.sizeX)*(fakedPckVram^.sizeY-1)<>PtrRec(fakedPckVramEnd).Ofs)
    then erMsg(_(ldTooBigAnim4Indir));
 screen:=ascreen;
 map:=amap;
 sp_player:=@self;
 Setup(true,flcHeader.width,PtrRec(fakedPckVramPtr).Ofs,0,AddPalette,SetBankIndirect);
end;

Procedure TIndirectFLCPlayer.Start;
var   nul:word;
      p:pointer;
      i,j:word;
begin
 sp_player:=@self;
 inherited Start;
 {detect transparency}
 nul:=0;
 i:=fakedPckVram^.sizeX;
 for j:=0 to fakedPckVram^.sizeY-1 do begin
   p:=fakedPckVram^.tab^[j];
   asm
     les di,p
     mov cx,i
     mov ax,0
     mov bx,0
     @1:
     scasb
     jnz @2
     inc bx
     @2:
     loop @1
     add nul,bx
   end;
   end;
 transp:=nul>word(fakedPckVram^.sizeX)*word(fakedPckVram^.sizeY) div 3;
 if flcHeader.res1b=ord('t') then transp:=true else
 if flcHeader.res1b=ord('n') then transp:=false;
end;

Procedure TIndirectFLCPlayer.FramePhase1_Init;
begin
 sp_player:=@self;
 LockFrame;
 myFakedSegVram:=PtrRec(fakedPckVram^.tab^[0]).Seg;
 DecodeFrame;
 UnlockFrame;
 convert:=true;
end;

Procedure TIndirectFLCPlayer.FramePhase2_Show(updating:boolean);
var   i:integer;
      s:PScreen;
      srcSize:TPoint;
      newSrcRect,newDestRect:TRect;
begin
 {hraje jen na SVE screene}
 if (ScrolScreen=nil) or (ScrolScreen^.map<>map) then exit;
 sp_player:=@self;
 {pri screen=nil pouzije aktualni screen}
 if screen=nil then s:=vga.Screen else s:=screen;
 if outputmodel<>s^.mapModel then begin
   outputmodel:=s^.MapModel;
   KillObj(fakedRealVram);
   KillObj(mixingBuf);
   New(fakedRealVram,Init(map^.MapModel,flcHeader.width,flcHeader.height));
   if fakedRealVram=nil then Halt(erLowMem);
   New(mixingBuf,Init(map^.MapModel,destRect.b.x-destRect.a.x,destRect.b.y-destRect.a.y));
   if mixingBuf=nil then Halt(erLowMem);
   RefreshColors(0,255);
   convert:=true;
   end;
 {clipping}
 srcSize.x:=fakedPckVram^.sizeX;
 srcSize.y:=fakedPckVram^.sizeY;
 {s^.GetClipping(destRng);}
 GetResizeBltClipping(srcSize,destRect,{destRng}updateRect,newSrcRect,newDestRect);
 if not newDestRect.Empty then begin
   {zmena modelu}
   if convert then begin
     ConvertPacked2Any(fakedPckVram,fakedRealVram,@color);
     fakedRealVram^.transparent:=transp;
     convert:=false;
     end;
   {copy s resizem a vyresenou transparenci}
   s^.SuperResizeBtB2Box(0,fakedRealVram,map,mixingBuf,newSrcRect,newDestRect);
   end;
end;

Destructor TIndirectFLCPlayer.Done;
begin
 KillObj(fakedPckVram);
 KillObj(fakedRealVram);
 KillObj(mixingBuf);
 inherited Done;
end;


END.

 Problem cachovani:
  Jedna animacka dohraje, pustim jinou.
  Potrebuju po dohrani nejak shodit prioritu aby se prednostne
  vypoustely snimky z dohrany a nechavaly z rozehrany.
 Pri scrolu nad vic animackama se obcas polozej frejmy tam kde nemaj.
