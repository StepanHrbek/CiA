{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Tools;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects, Sys,Key,Vga,Scrol;
Function  Init:TError;
Procedure Done;


Var       TxtRes:TPoint;{rozliseni pouzivana pri prohlizeni bitmap}
          GfxRes:TPoint;{pri 0x0 vybere nejblizi rozmerum bitmapy}

FUNCTION  Viewer(b:PBitmap):Boolean; {prohlizec bitmap}


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


{---------------------------------------------------------------------------
 Prohlizec bitmap. Zadanou bitmapu zobrazi, pokud je velka, necha te nad ni
 scrollovat, po odklepnuti skonci a vrati puvodni mod.
 Pamatuje si radku na ktere predchozi prohlizeni tehoz souboru skoncilo.
 Pozor, prohlizenou bitmapu zrusi.
 Pokud si ji chces ponechat, zavolej viewer s jeji kopii.
 ---------------------------------------------------------------------------}
FUNCTION  Viewer(b:PBitmap):Boolean;
var   oldScreen    :PScreen;
      s            :PScrolScreen;
      xlista       :PBitmap;
      cursor       :boolean;
      cY           :integer;
      slot         :byte;
      oldactivity  :TAct;
      oldp         :TSpocitej;
      event        :TEvent;
      pos          :TPoint;
      mdl,sir,vys  :word;
const slotu=8;
      memory:array[1..slotu,1..2] of word=((0,0),(0,0),(0,0),(0,0),(0,0),(0,0),(0,0),(0,0));
label 1;
Begin
 {nastavi ze je to spatny, pri chybe staci exitnout}
 Viewer:=false;
 if b=nil then exit;

 {pamatuje si radku pro 'slotu' ruznych souboru}
 cY:=0;
 for slot:=1 to slotu do if memory[slot,1]=b^.sizeY then begin cY:=memory[slot,2];goto 1;end;
 for slot:=1 to slotu do if memory[slot,1]=0 then begin memory[slot,1]:=b^.sizeY;goto 1;end;
 1:

 {pokud zustal po reinitu TScreeny nepravdivy udaj v ScrolScreen, smaze ho}
 if CurScreen<>PScreen(CurScrolScreen) then CurScrolScreen:=nil;

 {zalohuje CurScrolScreen a nastavi novou}
 xlista:=nil;
 if CurScrolScreen<>nil then
  with CurScrolScreen^ do begin
   oldactivity:=GetActivity;
   SetActivity(syncHolocaust);
   if (lista<>nil) and Convertable(lista^.MapModel,b^.MapModel)
    then xlista:=CurScrolScreen^.lista^.FulCopy;
   end;
 if CurScreen<>nil then CurScreen^.MouseHide;{puvodni stav je ulozen v oldactivity a obnovi se}
 oldScreen:=CurScreen;
 sir:=b^.sizeX;
 vys:=b^.sizeY;
 if b^.MapModel=model_text
  then begin mdl:=model_text ;if longint(TxtRes)<>0 then begin sir:=TxtRes.X;vys:=TxtRes.Y;end;end
  else begin mdl:=model_scrol;if longint(GfxRes)<>0 then begin sir:=GfxRes.X;vys:=GfxRes.Y;end;end;
 new(s,Init(mdl,sir,vys,0));

 if s=nil then b^.Free else
  {vsechno uvnitr se tyka CurScrolScreen}
  with s^ do begin

   MapInit(b,xlista,0,cY);

   {vyresetuje veci ktere mohly byt zdedeny z minule obrazovky}
   MouseSetPos(Xres div 2,Yres div 2);
   mouseActions:=0;
   ResetEvents;

   {skryje kurzor, zobrazi prvni screenu}
   cursor:=vga_HideCursor;
   MapRedraw;
   Fade(+0);

   {scrolling}
   oldp:=userSpocitej;
   userSpocitej:=nil;
   SetActivity(syncAllOn+syncKHandlerOn);
   repeat
    while not GetEvent(event,pos) do Sync;
   until code(event) in [kEnter,kkEnter,kEsc,mcLeftPressed,mcRightPressed];
   SetActivity(syncAllOff);
   userSpocitej:=oldp;

   {pamatuje si radku}
   memory[slot,2]:=(posCil.Y div charYres);

   {obnovi kurzor}
   if cursor then vga_ShowCursor;

   {je to dobry}
   Viewer:=true;

   {uvolni bitmapu a vrati puvodni mod}
   {Fade(-10);}
   KillObj(s);

   end;

 {restorne oldScreen
 if CurScreen<>oldScreen then oldScreen^.ReInit;}

 {pokud zustal po reinitu TScreeny nepravdivy udaj v ScrolScreen, smaze ho}
 if CurScreen<>PScreen(CurScrolScreen) then CurScrolScreen:=nil;

 if CurScrolScreen<>nil then CurScrolScreen^.SetActivity(oldactivity);
end;

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='tools';
var result:TError;

procedure UserInit;
 begin
  TxtRes.X         :=80;
  TxtRes.Y         :=25;
  GfxRes.X         :=0;
  GfxRes.Y         :=0;
 end;

procedure UserDone;
 begin
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.