{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.50ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Dialogy;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Objects,Strings, Sys,Stringy,Key,Vga,Fonty,Cache,Texty;
Function  Init:word;
Procedure Done;

{
  Dialogy (funkce s predponou dlg) lze volat az po nastaveni
  textoveho nebo grafickeho modu, jedno jestli TScreen nebo TScrolScreen.

  Jak probiha dialog:
  -------------------
   Zahajeni dialogu:
    - Pokud jsi nastavil dlgInit, zavola se.
   Kontroly:
    - Je dost pameti?, vejde se dialog na obrazovku? apod.
      Pokud zde dojde k chybe, zobrazi se chybova hlaska. Kdyz selze i zobrazeni
      chybove hlasky, program skonci a hlaska se vypise v textmodu, v opacnem
      pripade muze program dal bezet.
   Paleta:
    - Pokud jsi nenastavil dlgPal, pouzije se stavajici paleta beze zmen.
      V opacnem pripade si muze dialog ve tve palete alokovat nove barvy
      a dosahnout vernejsiho zobrazeni.
   Font:
    - Texty se pisi fontem dlgFont, implicitne je nastaven modern.fn.
   Help:
    - Pokud uzivatel behem dialogu stiskne F1 a tys nastavil dlgHelp, zavola se.
   Konec dialogu:
    - Pokud jsi nastavil dlgDone, zavola se.

  Architektura:
  -------------
   Vsechny dialogy stoji na objektu TDialog. Metody TDialogu jsou znakove
   orientovane - umoznuji do dialogoveho okna psat texty ale ne kreslit.
   Diky tomu dialogy funguji i v textmodu. Je velmi snadne napsat si
   dalsi dialogy podle potreby, staci podivat se rekneme na dlgExit.

}

Type      PPChar  = ^PChar;
          PdlgCollection = ^TdlgCollection;
          TdlgCollection = object(TCollection)
            procedure InsertStr(st:string;kod:byte);
            procedure FreeItem(item:pointer);virtual;
            end;

Const     dlgInsert       =1;    dlgOverwrite    =0;{pocatecni chovani kurzoru}
          dlgEscVraciNic  =2;    dlgEscVraciPre  =0;{co vraci kdyz stisknes esc}
          dlgKurzorNaStart=4;    dlgKurzorNaKonec=0;{pocatecni umisteni kurzoru v dlgLine}
          dlgHideExt      =8;    dlgShowExt      =0;{ve fileselectoru nezobrazuje koncovku}
          dlgDisableNew   =16;   dlgEnableNew    =0;{povoli ve fileselectoru zadani noveho jmena}
          dlgHotkeys      =100;

Var       dlgInit:TProc;   {zde si muzes nastavit co se zavola pri otvirani dialogu}
          dlgDone:TProc;   {zde si muzes nastavit co se zavola pri zavirani dialogu}
          dlgHelp:TProc;   {zde si muzes nastavit co se zavola pri stisku F1}
          dlgFont:PathStr; {zde si muzes nastavit jmeno fontu pro dialogy}
          dlgPal:PPalAlloc;{zde si muzes nastavit svou paletu. pokud ji
                            nenastavis, dialogy budou s paletou manipulovat
                            podle libosti}
FUNCTION  dlgMsg(msg:pchar):TEvent;
FUNCTION  dlgError(errorcode:TError):TError;
FUNCTION  dlgExit:char;
FUNCTION  dlgLine(flags:byte;popisek:string;maxlen:byte;preselect:string;deny:string):string;
FUNCTION  dlgFile(flags:byte;popisek,mask,preselect:string):string;
FUNCTION  dlgMenu(polozek:byte;p:ppchar;addofs,preselect:word):word;
FUNCTION  dlgMenuCol(c:PdlgCollection;preselect:word):word;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}



Const     erDialogBig=93;

Type
 PDialog=^TDialog;
 TDialog=object(TBitmap)
   x1,y1     :integer;{pen_screen souradnice leveho horniho rohu dialogwindow}
   chrX,chrY :byte;   {rozmery dialogu ve znacich}
   mulX,mulY :byte;   {velikost jednoho znaku (v textmodu ve znacich, v grafice v pixelech)}
   press     :TPoint; {souradnice znaku nad kterym bylo stisknuto tlacitko}
   stored    :PBitmap;
   font      :PFont;
   s         :PScreen;
   oldpen    :byte;
   oldcursor :boolean;
   oldmouse  :boolean;
   oldmoving :boolean;
   kurzor    :TPoint;
   kurzorOn  :boolean;
   mypal     :boolean;
   constructor Init(sir,vys:word;hidecurs:boolean;var result:TError);
   procedure   WriXY(textattr:byte;x,y:word;st:string);
   procedure   Frame;
   procedure   StoreFull;
   procedure   FreshFull;
   procedure   Fresh(x,y,sir,vys:word);
   procedure   RestoreFull;
   procedure   Gotoxy(x,y:word);
   function    GetEvent:TEvent;
   destructor  Done;virtual;
 end;

Const
 framelo  =1  ;       {barvy dialogu zadane jako textmodove atributy}
 framehi  =1  ;       {v grafice se konverti na RGB}
 framein  =3  *16;
 texthi   =15 +framein;
 textlo   =8  +framein;
 frameline=1  +framein;

Constructor TDialog.Init(sir,vys:word;hidecurs:boolean;var result:TError);
var   mx,my  :byte;
      f      :PFont;
      i      :integer;
begin
 TObject.Init;
 if CurScreen<>nil then begin
   f:=caFontGet(dlgFont);
   if f=nil then result:=erBadFont else begin
     if CurScreen^.MapModel=model_text
       then begin mX:=1;mY:=1;end
       else begin mX:=f^.tablo^['€'].sirB;mY:=f^.sizeOver+f^.sizeUnder;end;
     if not inherited Init(CurScreen^.MapModel,sir*mX,vys*mY) then result:=erLowMem else begin
       chrX:=sir;
       chrY:=vys;
       mulX:=mX;
       mulY:=mY;
       font:=f;
       s:=CurScreen;
       s^.SwapMoving(oldmoving);
       oldcursor:=hidecurs and vga_HideCursor;
       oldmouse:=((MapModel= model_text) and s^.MouseHide) or
                 ((MapModel<>model_text) and s^.MouseShow);
       oldpen:=s^.pen;
       s^.pen:=PEN_SCREEN;
       mypal:=(MapModel<>model_text) and (dlgPal=nil);
       if mypal then New(dlgPal,Init);
       if mypal and (dlgPal=nil) then result:=erLowMem else begin
         x1:=(s^.Xres-sizeX) div 2;
         y1:=(s^.Yres-sizeY) div 2;
         if (x1<0) or (y1<0) then result:=erDialogBig else begin
           new(stored,Init(s^.MapModel,sizeX,sizeY));
           if stored=nil then result:=erLowMem else begin
             StoreFull;
             Clr2Ful;
             result:=erOk;
             if @dlgInit<>nil then dlgInit;
             exit;
             end;
           end;
         end;
       Done;
       end;
     end;
   end;
 Fail;
end;

{
 Toto je spravny postup pri inicializaci dialogu - do resultu dat nejdriv
 erLowMem. Kdyz selze uz alokace d^, vubec se nevola konstruktor.
 V resultu tak zustane erLowMem a chyba je pote ohlasena.
}
FUNCTION NewDialog(var d:PDialog;sir,vys:word;hidecurs:boolean):boolean;
var   result:TError;
begin
 result:=erLowMem;
 New(d,Init(sir,vys,hidecurs,result));
 if d=nil then dlgError(result);
 NewDialog:=d<>nil;
end;

Procedure TDialog.WriXY(textattr:byte;x,y:word;st:string);
var backcol,forecol:byte;
    proporc:byte;
    over:integer;
begin
 over:=0;
 if MapModel=model_text then forecol:=textattr else begin
   dlgPal^.AllocTxt(textattr,forecol,backcol);
   Col2Box(x*mulX,y*mulY,length(st)*mulX,mulY,backcol);
   over:=font^.sizeOver;
   end;
 OutStr(st,@self,x*mulX,y*mulY+over,font,mulX,forecol);
end;

Procedure TDialog.Frame;
const cols=5;

  function packedCol(i:integer):integer;
  var fore,back:byte;
  begin
   if i=cols
    then begin dlgPal^.AllocTxt(framein,fore,back);packedCol:=back;end
    else begin fore:=63*(i+3) div (cols+1) mod 64;packedCol:=dlgPal^.Alloc(fore,fore,fore);end;
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
     y:=(i*mulX*s^.Yres*4) div (s^.Xres*cols*3);
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
 oldm:=s^.MouseHide;
 if stored<>nil then s^.Box2BtF(stored,x1,y1);
 if oldm then s^.MouseShow;
end;

Procedure TDialog.FreshFull;
var   oldm:boolean;
begin
 oldm:=s^.MouseHide;
 s^.BtF2Box(@self,x1,y1);
 if oldm then s^.MouseShow;
end;

Procedure TDialog.RestoreFull;
var   oldm:boolean;
begin
 oldm:=s^.MouseHide;
 if stored<>nil then s^.BtF2Box(stored,x1,y1);
 if oldm then s^.MouseShow;
end;

Procedure TDialog.Gotoxy(x,y:word);
var   oldm:boolean;
begin
 kurzorOn:=true;
 kurzor.x:=x;
 kurzor.y:=y;
 if MapModel=model_text
   then s^.Gotoxy(x1+x,y1+y)
   else begin
        oldm:=s^.MouseHide;
        s^.Col2Box(x1+mulX*x,y1+mulY*y+mulY-2,mulX,2,dlgPal^.Alloc(63,63,63));
        if oldm then s^.MouseShow;
        end;
end;

Function TDialog.GetEvent:TEvent;
var   dlgHelpPtr:pointer absolute dlgHelp;
      event:TEvent;
      pos:TPoint;
      dlgRect:TRect;
      swapB:PBitmap;
      swapP:TPoint;
      oldm:boolean;
      dx,dy:integer;
label 1;
begin
 1:
 if kurzorOn then gotoxy(kurzor.x,kurzor.y);
 if MapModel=model_text then
  if kurzorOn then vga_ShowCursor else vga_HideCursor;
 while not s^.GetEvent(event,pos) do s^.Sync;
 dlgRect.Assign(x1,y1,x1+chrX*mulX,y1+chrY*mulY);
 case code(event) of
   kF1    :if dlgHelpPtr=nil then GetEvent:=event else begin
             RestoreFull;
             dlgHelp;
             FreshFull;
             goto 1;
             end;
   mbLeft :begin
           press.x:=(pos.x-x1) div mulX;
           press.y:=(pos.y-y1) div mulY;
           GetEvent:=event;
           end;
   mbRight:GetEvent:=MakeEvent(kEsc,#13,#0);
   mbMid  :begin
           if dlgRect.Contains(pos) then begin
             if kurzorOn and (MapModel=model_text) then vga_HideCursor;
             RestoreFull;
             swapB:=@self;
             swapP.x:=pos.x-x1;
             swapP.y:=pos.y-y1;
             s^.MouseSwapPointer(swapB,swapP);
             oldm:=s^.MouseShow;
             repeat
               s^.Sync;
             until s^.mouse.z=0;
             if not oldm then s^.MouseHide;
             dx:=s^.mouse.x-pos.x;
             dy:=s^.mouse.y-pos.y;
             inc(x1,dx);
             inc(y1,dy);
             s^.MouseSwapPointer(swapB,swapP);
             StoreFull;
             FreshFull;
             end;
           goto 1;
           end;
   else    GetEvent:=event;
   end;
end;

Destructor TDialog.Done;
begin
 if mypal then KillObj(dlgPal);
 RestoreFull;
 KillObj(stored);
 caLeave(font);
 if oldcursor then vga_ShowCursor;
 if oldmouse then s^.MouseShow else s^.MouseHide;
 s^.pen:=oldpen;
 s^.SwapMoving(oldmoving);
 inherited Done;
 if @dlgDone<>nil then dlgDone;
end;




{---------------------------------------------------------------------------
 Vypise zpravu a ceka na event.
 Pchar msg neuvolni.
 ---------------------------------------------------------------------------}
FUNCTION  dlgMsg(msg:pchar):TEvent;
var   event:TEvent;
      d:PDialog;
      t:TText1;
      sir,vys,y:word;
begin
 event:=0;
 t.Init(msg);
 t.ScanSize(sir,vys);
 if NewDialog(d,sir+4,vys+2,true) then begin
   d^.Frame;
   for y:=1 to vys do
     d^.wrixy(textlo,2,y,t.nlRead);
   d^.FreshFull;
   event:=d^.GetEvent;
   d^.Free;
   end;
 t.Done;
 dlgMsg:=event;
end;

{---------------------------------------------------------------------------
 Ohlasi chybu.

 A co pripad kdy pri hlaseni chyby dojde k chybe? Nasleduje rozbor situace.

  Doslo k primarni chybe. Nekdo zavolal dlgError.
    1) vola dlgMsg
         1) vola NewDialog
              1) tady dojde k sekundarni chybe, treba uz je malo pameti
              2) zavola se dlgError(), ktery neudela nic
              3) vrati false
         2) vrati 0
    2) ohlasi primarni chybu pres erMsg a program skonci
 ---------------------------------------------------------------------------}
Var
 insideerror:boolean;

FUNCTION  dlgError(errorcode:TError):TError;
var st:string;
    i:integer;
begin
 if not insideerror and (errorcode<>erOk) then begin
   st:=BugList.Msg(errorcode);

   {dlouhou hlasku rozdeli na dva radky}
   if length(st)>38 then begin
     for i:=0 to length(st) div 2 do
      if st[length(st) div 2+i]=' ' then begin i:=length(st) div 2+i;break;end else
      if st[length(st) div 2+1-i]=' ' then begin i:=length(st) div 2+1-i;break;end;
     st:=copy(st,1,i-1)+#13#10+copy(st,i+1,255);
     end;

   insideerror:=true;
   if dlgMsg(Str2Pc(st))=0 then erMsg(st);
   insideerror:=false;
   end;
 dlgError:=errorcode;
end;


{---------------------------------------------------------------------------
 Zepta se, pocka na reakci a vrati 'S', 'D' nebo 'C'.
 ---------------------------------------------------------------------------}
FUNCTION dlgExit:char;
const line:array[0..4] of string[51]=(
        '                                                   ',
        '   …ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ Edit ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª   ',
        '   ∫  You''ve made changes since the last save. ∫   ',
        '   ∫    Save   Don''t save   Continue editing   ∫   ',
        '   »ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº   ');
      x:array[0..2] of byte=(7,14,27);
      l:array[0..2] of byte=(6,12,18);
      c:array[0..2] of char=('S','D','C');
var   event:TEvent;
      ch:char;
      a:byte;
      i,j:word;
      d:PDialog;
begin
 dlgExit:='C';
 if NewDialog(d,51,6,true) then begin
   a:=0;
   for i:=0 to 5 do d^.wrixy($4f,0,i,line[i mod 5]);
   repeat
     d^.wrixy($70,x[a],3,copy(line[3],x[a]+1,l[a]));
     d^.FreshFull;
     d^.wrixy($4f,x[a],3,copy(line[3],x[a]+1,l[a]));
     event:=d^.GetEvent;
     ch:=UpCase(char(event));
     case code(event) of
       kEsc   :ch:='C';
       kLeft  :a:=(a+2) mod 3;
       kRight :a:=(a+1) mod 3;
       kEnter,
       kkEnter:ch:=c[a];
       mbLeft :if d^.press.y=3 then
                for i:=0 to 2 do
                 if (d^.press.x>=x[i]) and (d^.press.x<x[i]+l[i]) then ch:=c[i];
       end;
   until ch in ['S','D','C'];
   dlgExit:=ch;
   d^.Free;
   end;
end;


{---------------------------------------------------------------------------
 Zepta se, pocka na reakci a vrati vysledek.
 ---------------------------------------------------------------------------}
FUNCTION dlgLine(flags:byte;popisek:string;maxlen:byte;preselect:string;deny:string):string;
var   i,j,le,x2:integer;
      path,popisek2:string;
      event:TEvent;
      ch:char;
      d:PDialog;
      konec:boolean;
begin
 dlgLine:=preselect;
 deny:=deny+#0;
 path:=preselect;
 popisek2:=popisek;
 popisek:=CutString(#13,popisek2);
 le:=maxW(maxlen+2,maxW(length(popisek),length(popisek2)));
 if NewDialog(d,le+2,5,false) then begin
   i:=length(path)+(flags and dlgInsert);if flags and dlgKurzorNaStart>0 then i:=1;
   x2:=(le-maxlen) div 2;
   d^.Frame;
   for j:=1 to le do d^.wrixy(textlo,j,1,' ');d^.wrixy(textlo,(le-length(popisek )) div 2+1,1,popisek );
   for j:=1 to le do d^.wrixy(textlo,j,2,' ');d^.wrixy(textlo,(le-length(popisek2)) div 2+1,2,popisek2);
   for j:=1 to le do d^.wrixy(textlo,j,3,' ');
   konec:=false;
   repeat
    d^.wrixy(textlo,x2+1,3,path+' ');
    d^.FreshFull;
    d^.Gotoxy(x2+i,3);
    event:=d^.GetEvent;
    case code(event) of
      kEsc      :begin if (flags and dlgEscVraciNic)=0 then path:=preselect else path:='';konec:=true;end;
      kBackspace:if ((flags and dlgInsert)=1) and (i>1) then begin path:=copy(path,1,i-2)+copy(path,i,length(path));dec(i);end;
      kLeft     :if i>1 then dec(i);
      kRight    :if i<length(path)+(flags and dlgInsert) then inc(i);
      kDelete   :if ((flags and dlgInsert)=1) and (i<=length(path)) then path:=copy(path,1,i-1)+copy(path,i+1,length(path));
      kHome     :i:=1;
      kEnd      :i:=length(path)+(flags and dlgInsert);
      kInsert   :flags:=flags xor dlgInsert;
      kEnter,
      kkEnter   :konec:=true;
      mbLeft    :if d^.press.y=3 then begin
                   j:=d^.press.x-1;
                   if (j>=1) and (j<=length(path)+(flags and dlgInsert)) then i:=j;
                   end;
      else      begin
                 ch:=char(event);
                 if (pos(ch,deny)=0) and (maxlen>0) then
                  if (flags and dlgInsert)=0
                   then begin path[i]:=ch;if i<length(path) then inc(i);end
                   else if (length(path)<maxlen) then
                         begin path:=copy(path,1,i-1)+ch+copy(path,i,length(path));inc(i);end;
                end;
      end;
   until konec;
   dlgLine:=path;
   d^.Free;
   end;
end;


{---------------------------------------------------------------------------
 Jednoduchy fileselector, pocet souboru omezen velikosti obrazovky!
 Radsi si napis vlastni, tohle je jen nouzovka.
 ---------------------------------------------------------------------------}
FUNCTION dlgFile(flags:byte;popisek,mask,preselect:string):string;
const qw=0;
var   list:TStringCollection;
      i,j,lines,newnamepos:integer;
      t:searchrec;
      st:string[50];
      st2:string;
      keyb:Boolean;
      f:file;
      d:PDialog;
      event:TEvent;

  procedure FindAll(mask:string);
  begin
   findfirst(mask,0,t);
   while doserror=0 do begin
    if (flags and dlgHideExt)>0 then{odstrani ".ext"}
      t.name:=GetString('.',t.name,1);
    list.Insert(NewStr(LoCased(t.name)));
    findnext(t);
    end;
  end;

  function polozka(n:word):string;
  begin
   polozka:=PString(list.items^[n])^;
  end;

label 2,3,restart,donee;
begin
 LoCasni(preselect);
 dlgFile:=preselect;
 list.Init(100,50);
 st:='';
 keyb:=false;
 restart:
 i:=0;
 st2:='Nebyl nalezen ani jeden soubor'#13#10'odpov°daj°c° masce '+mask+'.';
 while mask<>'' do findall(cutstring(';',mask));

 if list.count=0 then begin
  dlgFile:='';
  if (flags and dlgDisableNew)=0
    then dlgFile:=dlgLine(flags or dlgInsert,popisek,36,preselect,'!')
    else dlgMsg(Str2Pc(st2));
  goto donee;
  end;

 list.Search(@preselect,i);
 if i>=list.count then i:=list.count-1;

 lines:=minW(list.count+1,maxW(10,list.count div 6+1));
 if NewDialog(d,maxI(60,(list.count+lines-1) div lines*13+2),lines+4,false) then begin
   newnamepos:=d^.chrX*2 div 3;
   d^.Frame;
   for j:=1 to d^.chrX-2 do d^.wrixy(frameline,j,2,'ƒ');
   d^.wrixy(textlo,newnamepos div 2-length(popisek) div 2,qw+1,popisek);
   repeat
     if not keyb then st:=polozka(i);
     for j:=0 to list.count-1 do
       d^.wrixy(textlo,2+j div lines*13,qw+3+j mod lines,polozka(j));{v cyklu}
       d^.wrixy(texthi,2+i div lines*13,qw+3+i mod lines,polozka(i));{mimo cykl}
     d^.wrixy(texthi,newnamepos,qw+1,st);
     for j:=newnamepos+length(st) to d^.chrX-2 do d^.wrixy(texthi,j,qw+1,' ');
     d^.FreshFull;
     d^.gotoxy(newnamepos+length(st),qw+1);
     event:=d^.GetEvent;
     case code(event) of
       {*zde zatim igoruje dlgDisableNew flag}
       kLeft     :begin dec(i,lines);keyb:=false;end;
       kRight    :begin inc(i,lines);keyb:=false;end;
       kUp       :begin dec(i);      keyb:=false;end;
       kDown     :begin inc(i);      keyb:=false;end;
       kHome     :begin i:=0;        keyb:=false;end;
       kEnd      :begin i:=list.count-1;keyb:=false;end;
       kPgUp     :begin i:=i-i mod lines;keyb:=false;end;
       kPgDwn    :begin i:=minW(i+lines-1-i mod lines,list.count-1);keyb:=false;end;
       kBackspace:if length(st)>0 then st[0]:=chr(length(st)-1);
       kTab      :dlgFile:=polozka(i);
       kEnter,
       kkEnter   :dlgFile:=st;
       kEsc      :if (flags and dlgEscVraciNic)=0 then dlgFile:=st else dlgFile:='';
       else      if char(event) in ['!'..'@','_'..'z'] then
                  if keyb=true
                   then begin if length(st)<d^.chrX-newnamepos-2 then st:=st+char(event);end
                   else begin keyb:=true;st:=char(event);end;
       end;
     if keyb then begin
       list.Search(@st,i);
       if i>=list.count then i:=list.count-1;
       end
      else i:=(i+5*list.count) mod list.count;
   until code(event) in [kEsc,kEnter,kkEnter,kTab];
   d^.Free;
   end;
 donee:
 list.Done;
end;


{---------------------------------------------------------------------------
 Zepta se, pocka na reakci a vrati
   0          - esc
   1..polozek - cislo vybrane polozky
 Parametry:
   polozek    - pocet polozek v menu
   p          - pointer na prvni z nich
   addofs     - kolik pricist k pointeru p aby ukazoval na dalsi polozku
   preselect  - kolikata polozka je oznacena na zacatku

 Hotkeys
 -------
 Pokud je preselect zvysen o dlgHotkeys, znamena to, ze za kazdou polozkou
 je bajt udavajici kod hotkey klavesy. dlgMenu pak nevraci jen cislo vybrane
 polozky, ale cislo_polozky+256*kod_hotkey_klavesy.
 ---------------------------------------------------------------------------}
FUNCTION dlgMenu(polozek:byte;p:ppchar;addofs,preselect:word):word;
var   a,b,i,j,le:integer;
      event:TEvent;
      d:PDialog;

  function get(n:byte):pchar;
  begin
   get:=ppchar(ptr(PtrRec(p).Seg,PtrRec(p).Ofs+(n-1)*addofs))^;
  end;

  function kod(n:byte):byte;
  begin
   kod:=pline(get(n))^[StrLen(get(n))+1];
  end;

  procedure wriline(n,c:byte);
  begin
   d^.wrixy(c,1,n,' '+Pc2Str(get(n))+' ');
  end;

begin
 le:=0;
 b:=0;
 for a:=1 to polozek do le:=MaxW(le,StrLen(get(a)));
 if NewDialog(d,le+4,polozek+2,true) then begin
   d^.Frame;
   for i:=1 to polozek do wriline(i,textlo);
   a:=MaxI(preselect mod dlgHotkeys,1);
   b:=-1;
   repeat
     wriline(a,texthi);
     d^.FreshFull;
     event:=d^.GetEvent;
     wriline(a,textlo);
     case code(event) of
       kEsc       :b:=0;
       kUp        :a:=(a+polozek-2) mod polozek+1;
       kDown      :a:=a mod polozek+1;
       kHome,kPgUp:a:=1;
       kEnd,kPgDwn:a:=polozek;
       kEnter,
       kkEnter    :b:=a;
       mbLeft     :if (d^.press.y>=1) and (d^.press.y<=polozek) then begin b:=d^.press.y;break;end;
       else        if preselect>=dlgHotkeys then
                    for i:=1 to polozek do
                     if kod(i)=code(event) then b:=i;
       end;
   until b>=0;
   d^.Free;
   end;
 if (b=0) or (preselect<dlgHotkeys)
  then dlgMenu:=b
  else dlgMenu:=MakeWord(kod(b),b);
end;


{---------------------------------------------------------------------------
 dlgMenuCol je jako dlgMenu, ale polozky jsou v TdlgCollection.
 ---------------------------------------------------------------------------}
Procedure TdlgCollection.InsertStr(st:string;kod:byte);
var p:pointer;
begin
 GetMem(p,length(st)+2);
 if p=nil then Halt(erLowMem);
 {$ifdef beta}
 if pos(#0,st)>0 then erBetaMsg('TdlgCollection.InsertStr: string nesm° obsahovat znak #0.');
 if length(st)>253 then erBetaMsg('TdlgCollection.InsertStr: string nesm° byt delsi nez 253.');
 {$endif}
 st:=st+#0+chr(kod);
 Move(st[1],p^,length(st));
 Insert(p);
end;

Procedure TdlgCollection.FreeItem(item:pointer);
begin
 FreeMem(item,StrLen(item)+2);
end;

FUNCTION dlgMenuCol(c:PdlgCollection;preselect:word):word;
begin
 dlgMenuCol:=dlgMenu(c^.count,pointer(c^.items),4,preselect+dlgHotkeys);
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='dialogy';
var result:integer;

procedure UserInit;
 begin
  BugList.Register(erDialogBig,'DialogovÇ okno je vàt®° neë obrazovka, zkus vy®®° rozli®en°.');
  dlgInit:=nil;
  dlgDone:=nil;
  dlgHelp:=nil;
  dlgFont:=fnDefaultNp;
  insideerror:=false;
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