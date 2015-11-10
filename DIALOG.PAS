{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 2.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Dialog;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Objects,Strings,
          Sys,Stringy,Key,Vga,Fonty,Cache,Texty,Fajly;
Function  Init:TError;
Procedure Done;

{
  Tato unita slouzi pouze k odkladani co nejvic kodu z unity Dialogy,
  jejiz code segment by jinak prekrocil 64KB.
  Nikdo krome Dialogy nema duvod davat Uses Dialog.
}

Const maxbuttons=200;

Type
 PGetSize=procedure(var sir,vys:word;maxsir,maxvys,bp:word);
 PDialog=^TDialog;
 TDialog=object(TBitmap)
   x1,y1     :integer;{pen_screen souradnice leveho horniho rohu dialogwindow}
   chrX,chrY :byte;   {rozmery dialogu ve znacich}
   mulX,mulY :byte;   {velikost jednoho znaku (v textmodu ve znacich, v grafice v pixelech)}
   eventpos  :TPoint; {souradnice znaku nad kterym prisel posledni event}
   press     :TPoint; {souradnice znaku nad kterym bylo stisknuto leve mysitko}
   stored    :PBitmap;
   font      :PFont;
   ownscreen :boolean;
   s         :PScreen;
   oldpen    :byte;
   oldcursor :boolean;
   oldmouse  :boolean;
   oldmoving :boolean;
   kurzor    :TPoint;
   kurzorOn  :boolean;
   constructor Init(sir,vys:word;GetSize:PGetSize;LocVar:word;var result:TError);
   procedure   WriXY(textattr:byte;x,y:word;st:string);
   procedure   Frame;
   procedure   StoreFull;
   procedure   FreshFull;
   procedure   Fresh(x,y,sir,vys:word);
   procedure   RestoreFull;
   procedure   Gotoxy(x,y:word);
   function    GetEvent:TEvent;
   procedure   LeaveScreen;
   destructor  Done;virtual;

  public
   {buttony, dialog je vubec nemusi vyuzit, muze si vsechno delat sam}
   buttons   :word;
   button    :array[0..maxbuttons-1] of record x,y,locol,hicol:byte; st:pstring end;
   buttM     :word; {button vybrany mysi, kod spolecny pro vsechny dialogy}
   buttK     :word; {button vybrany klavesnici, kod v dlgXXXX, vyssi priorita}
   buttfresh :boolean;
   noEventsYet:boolean;
   procedure   PutButton(x,y:word;locol,hicol:byte;st:string);
   procedure   Butt(but:word;hilight:boolean); {nedivejte se do slovniku, co to znamena :)}
   function    ButtUnder(pos:TPoint):word;
   procedure   DeleteButtons;
 end;

FUNCTION NewDialog(var d:PDialog;sir,vys:word;GetSize:pointer):boolean;

Const
 framelo  =1;         {barvy dialogu zadane jako textmodove atributy}
 framehi  =1;         {v grafice se konverti na RGB}
 framein  =$30;
 textbut  =$1F;
 texthi   =15+framein;
 textlo   =8 +framein;
 frameline=1 +framein;

 {vcXXXX - virtual code, nesmi kolidovat s kody klaves}
 vcRepos  =89;        {kod rikajici ze doslo k hilightnuti jineho buttonu}
 vcEndGui =90;        {kod normalne ukoncujici GUI dialog (kEsc abortne)}


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

Uses Dialogy;

Function WordNaBP:word;inline($8b/$46/$00);{mov ax,[bp]}

Constructor TDialog.Init(sir,vys:word;GetSize:PGetSize;LocVar:word;var result:TError);
var   mx,my  :byte;
      f      :PFont;
      i      :integer;
      maxSir :word;
      maxVys :word;

 function AvgSir:byte;
 var sir,
     sum1sir,sum1count,
     sum2sir,sum2count,max2sir:word;
     c:char;
 begin
  sum1sir:=0;
  sum2sir:=0;
  sum1count:=0;
  sum2count:=0;
  max2sir:=0;
  for c:=f^.firstchar to f^.lastchar do begin
    sir:=f^.tablo^[c].shift;
    inc(sum1sir,sir);
    inc(sum1count);
    if c in ['A'..'Z'] then begin
      inc(sum2sir,sir);
      inc(sum2count);
      max2sir:=maxW(max2sir,sir);
      end;
    end;
  if sum1count=0 then AvgSir:=(f^.sizeOver+f^.sizeUnder) div 2 else
  if sum2count=0 then AvgSir:=(sum1sir+sum1count-1) div sum1count else
                      AvgSir:=(sum2sir+sum2count-1) div sum2count;
 end;

 var owns:boolean;

 function InitOwnScreen:boolean;
 begin
  {kdyz je pozadavek na otevreni dialogu a nemame obrazovku,
   muzeme si udelat vlastni: New(s,Init(model_text,0,0,GetPrevMode));}
  {nebo taky ne:}s:=nil;
  owns:=s<>nil;
  InitOwnScreen:=s<>nil;
 end;

begin
 TObject.Init;
 owns:=false;
 if (CurScreen=nil) and not InitOwnScreen then begin
   result:=_erNoScreen;
   end
 else begin
   if @dlgPreInit<>nil then dlgPreInit;
   f:=cacheGetFont(dlgFont);
   if f=nil then result:=_erBadFont else begin
     if CurScreen^.MapModel=model_text
       then begin mX:=1;mY:=1;end
       else begin mX:=AvgSir;mY:=f^.sizeOver+f^.sizeUnder;end;
     maxSir:=CurScreen^.Xres div mX;
     maxVys:=CurScreen^.Yres div mY;
     if @GetSize<>nil then GetSize(sir,vys,maxSir,maxVys,LocVar);
     if (sir>maxSir) or (vys>maxVys) then result:=_erDialogBig else begin
       nextPal:=CurScreen^.pal;
       if not inherited Init(CurScreen^.MapModel,sir*mX,vys*mY) then result:=erLowMem else begin
         ownscreen:=owns;
         font:=f;
         f:=nil;
         s:=CurScreen;
         chrX:=sir;
         chrY:=vys;
         mulX:=mX;
         mulY:=mY;
         x1:=(s^.Xres-sizeX) div 2;
         y1:=(s^.Yres-sizeY) div 2;
         s^.SwapMoving(oldmoving);
         oldcursor:=vga_HideCursor;
         oldmouse:=s^.MouseShow;
         oldpen:=s^.pen;
         s^.pen:=PEN_SCREEN;
         New(stored,Init(s^.MapModel,sizeX,sizeY));
         if stored=nil then result:=erLowMem else begin
           StoreFull;
           Clr2Ful;
           result:=erOk;
           if @dlgPostInit<>nil then dlgPostInit;
           {kdyz je ztmavena paleta a ani PostInit ji nerozsvitil, udela to sam}
           if (s^.pal<>nil) and (s^.pal^.nowbright<100) then s^.pal^.SetBright(255);
           buttK:=0;
           buttM:=0;
           noEventsYet:=true;
           exit;
           end;
         Done;
         end;
       end;
     caLeave(f);
     end;
   LeaveScreen;
   end;
 Fail;
end;

{
 Toto je spravny postup pri inicializaci dialogu - do resultu dat nejdriv
 erLowMem. Kdyz selze uz alokace d^, vubec se nevola konstruktor.
 V resultu tak zustane erLowMem a chyba je pote ohlasena.
 ---
 Aby mela funkce GetSize pristup k lokalnim promennym nadrazene fce,
 je treba ji jako posledni parametr predat to, co je ted na adrese BP.
 Tenhle trik mam z metody ForEach v unite Objects.
}
FUNCTION NewDialog(var d:PDialog;sir,vys:word;GetSize:pointer):boolean;
var   result:TError;
begin
 result:=erLowMem;
 New(d,Init(sir,vys,PGetSize(GetSize),WordNaBP,result));
 if d=nil then dlgError(result);
 NewDialog:=d<>nil;
end;

Procedure TDialog.WriXY(textattr:byte;x,y:word;st:string);
var backcol,forecol:longint;
    proporc:byte;
    over:integer;
begin
 if MapModel=model_text then begin
   forecol:=textattr;
   over:=1;
   end
 else begin
   forecol:=s^.TextColor(textattr mod 16);
   backcol:=s^.TextColor(textattr div 16);
   Col2Box(x*mulX,y*mulY,length(st)*mulX,mulY,backcol);
   over:=font^.sizeOver;
   end;
 OutStr(st,@self,x*mulX,y*mulY+over,font,mulX,forecol);
end;

Procedure TDialog.Butt(but:word;hilight:boolean);
var col:byte;
begin
 if but=0 then exit;
 if hilight then col:=button[but].hicol else col:=button[but].locol;
 WriXY(col,button[but].x,button[but].y,button[but].st^);
 if buttfresh then Fresh(button[but].x*mulX,button[but].y*mulY,length(button[but].st^)*mulX,mulY);
end;

Procedure TDialog.PutButton(x,y:word;locol,hicol:byte;st:string);
begin
 if buttons=maxbuttons then exit;
 inc(buttons);
 button[buttons].x:=x;
 button[buttons].y:=y;
 button[buttons].locol:=locol;
 button[buttons].hicol:=hicol;
 button[buttons].st:=NewStr(st);
 Butt(buttons,false);
end;

Procedure TDialog.DeleteButtons;
var i:integer;
begin
 for i:=1 to buttons do DisposeStr(button[i].st);
 buttons:=0;
end;

{vraci cislo buttonu pod pozici pos (PEN_SCREEN)}
Function TDialog.ButtUnder(pos:TPoint):word;
var  i:integer;
begin
 for i:=buttons downto 0 do
  with button[i] do
   if (i=0) or ((y=(pos.y-y1) div mulY) and (x<=(pos.x-x1) div mulX)
    and (x+length(st^)>(pos.x-x1) div mulX))
     then begin
      ButtUnder:=i;
      exit;
      end;
 ButtUnder:=0;
end;

Procedure TDialog.Frame;
const cols=9;
      fram=2;

 function packedCol(i:integer):longint;
 var fore:byte;
 begin
  if i=cols then packedCol:=s^.TextColor(framein div 16) else begin
    {nasledujici radek zplosti ramecek}
    if i in [fram..cols-1-fram] then i:=cols div 2;
    {prevede intenzitu z 0..cols-1 nekam dovnitr 0..255}
    fore:=byte(255*(i+3) div (cols+1));
    packedCol:=s^.Color(fore,fore,fore,255);
    end;
 end;

var   i,x,y:word;
begin
 if MapModel=model_text then begin
   Col2Ful(256*framein+32);
   for i:=0 to chrY-1 do begin wrixy(framelo,0,i,'€');wrixy(framehi,chrX-1,i,'€');end;
   for i:=1 to chrX-2 do begin wrixy(framein+framelo,i,0,'ﬂ');wrixy(framein+framehi,i,chrY-1,'‹');end;
   end
 else begin
   for i:=0 to cols do begin
     x:=i*mulX div cols;
     y:=(i*mulX*longint(s^.Yres)*4) div (longint(s^.Xres)*cols*3);
     Col2Box(x,y,sizeX-2*x,sizeY-2*y,packedCol(i));
     end;
   end;
end;

Procedure TDialog.Fresh(x,y,sir,vys:word);
var   oldm:boolean;
begin
 oldm:=s^.MouseHide;
 s^.BtB2Box(@self,x,y,sir,vys,x1+x,y1+y);
 if oldm then s^.MouseShow;
end;

Procedure TDialog.StoreFull;
var   oldm:boolean;
begin
 if (stored<>nil) and (s<>nil) then begin
   oldm:=s^.MouseHide;
   s^.Box2BtF(stored,x1,y1);
   if oldm then s^.MouseShow;
   end;
end;

Procedure TDialog.FreshFull;
var   oldm:boolean;
begin
 oldm:=s^.MouseHide;
 s^.BtF2Box(@self,x1,y1);
 if oldm then s^.MouseShow;
 buttfresh:=true;
end;

Procedure TDialog.RestoreFull;
var   oldm:boolean;
begin
 if (stored<>nil) and (s<>nil) then begin
   oldm:=s^.MouseHide;
   s^.BtF2Box(stored,x1,y1);
   if oldm then s^.MouseShow;
   end;
end;

Procedure TDialog.Gotoxy(x,y:word);
var   oldm:boolean;
begin
 kurzorOn:=true;
 kurzor.x:=x;
 kurzor.y:=y;
 if MapModel=model_text
   then begin
        s^.Gotoxy(x1+x,y1+y);
        vga_ShowCursor;
        end
   else begin
        oldm:=s^.MouseHide;
        s^.Col2Box(x1+mulX*x,y1+mulY*y+mulY-2,mulX,2,s^.Color(255,255,255,255));
        if oldm then s^.MouseShow;
        end;
end;

Function TDialog.GetEvent:TEvent;

var   dlgHelpPtr:pointer absolute dlgHelp;
      event:TEvent;
      pos,pos2:TPoint;
      dlgRect:TRect;
      swapB:PBitmap;
      swapP:TPoint;
      oldm:boolean;
      dx,dy:integer;
      oldbuttfresh:boolean;
      i:word;
label 1,2;
begin
 if noEventsYet then buttM:=ButtUnder(s^.mouse);
 Butt(buttK,true);
 1:
 if kurzorOn then gotoxy(kurzor.x,kurzor.y);
 while not s^.GetEvent(event,pos) do begin
   s^.Sync;
   i:=ButtUnder(s^.mouse);
   if i<>buttM then begin
     buttM:=i;
     GetEvent:=MakeEvent(vcRepos,#0,#0);
     goto 2;
     end;
   end;
 dlgRect.Assign(x1,y1,x1+chrX*mulX,y1+chrY*mulY);
 eventpos.x:=(pos.x-x1) div mulX;
 eventpos.y:=(pos.y-y1) div mulY;
 case code(event) of
   kF1    :if dlgHelpPtr=nil then GetEvent:=event else begin
             RestoreFull;
             dlgHelp;
             FreshFull;
             goto 1;
             end;
   mcLeftPressed
          :begin
           press.x:=(pos.x-x1) div mulX;
           press.y:=(pos.y-y1) div mulY;
           if noEventsYet and (buttM>0) and (buttM<>buttK)
             then GetEvent:=MakeEvent(vcRepos,#0,#0)
             else GetEvent:=event;
           end;
   mcRightPressed
          :GetEvent:=MakeEvent(kEsc,#27,#0);
   mcCenterPressed
          :begin
           if dlgRect.Contains(pos) then begin
             if kurzorOn and (MapModel=model_text) then vga_HideCursor;
             RestoreFull;
             swapB:=@self;
             swapP.x:=pos.x-x1;
             swapP.y:=pos.y-y1;
             s^.MouseSwapPointer(swapB,0,0,swapP);
             oldm:=s^.MouseShow;
             repeat
               s^.Sync;
             until s^.GetEvent(event,pos2) and (code(event)=mcCenterReleased);
             if not oldm then s^.MouseHide;
             dx:=s^.mouse.x-pos.x;
             dy:=s^.mouse.y-pos.y;
             inc(x1,dx);
             inc(y1,dy);
             s^.MouseSwapPointer(swapB,0,0,swapP);
             StoreFull;
             FreshFull;
             end;
           goto 1;
           end;
   else    if system.pos(chr(code(event)),dlgEvents)=0 then GetEvent:=event else begin
             s^.PushEvent(event);
             GetEvent:=MakeEvent(kEsc,#27,#0);
             end;
   end;
 2:
 Butt(buttK,false);
 noEventsYet:=false;
end;

Procedure TDialog.LeaveScreen;
begin
 if ownscreen then begin
   KillObj(s);
   ownscreen:=true;
   end;
end;

Destructor TDialog.Done;
var i:integer;
begin
 for i:=1 to buttons do DisposeStr(button[i].st);
 RestoreFull;
 KillObj(stored);
 caLeave(font);
 if oldcursor then vga_ShowCursor else vga_HideCursor;
 if oldmouse then s^.MouseShow else s^.MouseHide;
 s^.pen:=oldpen;
 s^.SwapMoving(oldmoving);
 LeaveScreen;
 inherited Done;
 if @dlgDone<>nil then dlgDone;
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='dialog';
var result:TError;

procedure UserInit;
 begin
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