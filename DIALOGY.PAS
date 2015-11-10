{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 2.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Dialogy;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Objects,Strings,
          Sys,Stringy,CS,Key,Vga,Fonty,Cache,Texty,Fajly;
Function  Init:TError;
Procedure Done;

{
  Dialogy (funkce s predponou dlg) lze volat az po nastaveni
  textoveho nebo grafickeho modu, jedno jestli TScreen nebo TScrolScreen.

  Architektura:
  -------------
   Vsechny dialogy stoji na objektu TDialog. Metody TDialogu jsou znakove
   orientovane - umoznuji do dialogoveho okna psat texty ale ne kreslit.
   Diky tomu dialogy funguji i v textmodu. Je velmi snadne napsat si
   dalsi dialogy podle potreby, staci podivat se rekneme na dlgExit.

  Jak probiha dialog:
  -------------------
   Inicializace:
    - Pokud jsi nastavil dlgPreInit, zavola se.
    - Dialog pracuje s jedinym fontem. Jeho jmeno ocekava v dlgFont.
      Implicitne je nastaven modern.fn.
      Kdyz pracujes ve vice rozlisenich a chces mit vzdy spravne velky
      font, idealni reseni je serizovat dlgFont v dlgPreInit.
    - Az tady, kdyz je nahran font, vime jak velky dialog se skutecne jeste
      vejde na obrazovku a co uz by bylo moc.
      Pokud byla jako parametr zadana procedure GetSize, zavola se.
      Je to vnorena procedura typu
        procedure(var sir,vys:word;maxsir,maxvys:word);far;
      Tato procedura na zaklade maxsir a maxvys urci definitivni
      sirku a vysku dialogu.
    - Je dost pameti?, vejde se dialog na obrazovku? apod.
      Pokud zde dojde k chybe, zobrazi se chybova hlaska. Kdyz selze i zobrazeni
      chybove hlasky, program skonci a hlaska se vypise v textmodu, v opacnem
      pripade muze program dal bezet.
    - Pokud jsi nastavil dlgPostInit, zavola se.
      Uvnitr dlgPostInit uz vis, ze vse je ok a dialog pobezi,
      v dlgPreInit bylo jeste riziko, ze dialogu neco zabrani v otevreni.
   Prubeh dialogu:
    - Pokud uzivatel behem dialogu stiskne F1 a tys nastavil dlgHelp, zavola se.
   Konec dialogu:
    - Pokud jsi nastavil dlgDone, zavola se.

  FileSelector a PathBrowser:
  ---------------------------
   Tyto dva dialogy jdou az neuveritelne prizpusobovat.
   Jejich vzhled a chovani ovlivnuji

    flags
     - viz dlgXXXX flagy deklarovane nize

    stdSort
    stdName
    stdItem
     - globalni promenne, ktere mohou nabyvat hodnot deklarovanych nize

    masc
     - parametr maska v PathBrowseru ma strukturu 'maska postfix'
       napr. davas-li uzivateli vybrat kam instalovat coolprog,
       pouzij masku '*.* coolprog', ta da moznost prochazet vsemi adresari
       odpovidajicimi *.* a pripoji za ne jeste podadresar coolprog
     - parametr maska ve FileSelectoru udava jake soubory nabidnout
       ma strukturu
         blok1;blok2;...blokK
       blok ma strukturu
         adresar1;adresar2;...adresarMfilemask1;filemask2...filemaskN
       a urcuje soubory odpovidajici vsem kombinacim adresaru a filemasek
       adresar muze byt treba '' 'c:' 'c:\' 'c:abc\' 'c:\abc\' '\abc\' 'abc\'
       filemask je souborova maska bez cesty, muze obsahovat ? a *
       priklady:
         *.*                    - vsechny soubory v aktualnim adresari
         c:\*.*                 - vsechny soubory v c:\
         c:\;d:\*.*             - vsechny soubory v c:\ nebo d:\
         c:\;*.*                - vsechny soubory v c:\ nebo aktualnim adresari
         *.pas;*.inc            - vsechny pas a inc v aktualnim
         e:\;*.pas;*.inc        - vsechny pas a inc v e:\ nebo aktualnim
         c:\*.*;e:\;*.pas;*.inc - vse na c:\ a pas a inc v e:\ nebo aktualnim

   Uvnitr FileSelectoru a PathBroseru lze dale vyvadet psi kusy, o kterych
   zatim vi jen Carlos. Nekdy ho prinutim sepsat k tomu help :)))
}

Type      PPChar  = ^PChar;
          PMenuCollection = ^TMenuCollection;
          TMenuCollection = object(TStrCollection)
            constructor Init(sort:boolean);
            function    KodOf(item:pointer):PLong;
            procedure   InsertSt(txt:string);
            procedure   InsertStr(txt:string;kod:longint);
            procedure   FreeItem(item:pointer);virtual;
            function    StrAndKod(st:string;kod:longint):pchar;
            function    Compare(key1,key2:pointer):integer;virtual;
           private
            sorted      :boolean;
            end;
          FGetMenuLine=function(p:pointer;w:word):pchar;

Const     dlgOverwrite        =1 shl 0;{pocatecni chovani kurzoru}
          dlgEscReturnsNothing=1 shl 1;{co vraci kdyz stisknes esc}
          dlgCursorToStart    =1 shl 2;{pocatecni umisteni kurzoru v dlgLine}
          dlgHideExt          =1 shl 3;{ve fileselectoru nezobrazuje koncovku}
          dlgForbidNew        =1 shl 4;{nedovoli zadani neexistujiciho souboru}
          dlgUpdateDir        =1 shl 5;{zustava na poslednim adresari/vraci se na puvodni}
          dlgRatherBig        =1 shl 6;{jestli ma byt dialog radsi mensi nebo vetsi}
          dlgShowQuickFindStr =1 shl 7;{zobrazovat "Quick-Find" string nebo nezobrazovat}
          dlgShowDirectory    =1 shl 8;{zobrazovat aktualni adresar}
          dlgShowDetailTab    =1 shl 9;{zobrazovat pod tabulkou detaily kazdeho souboru}
          dlgSearchFromCursor =1 shl 10;{rychle vyhledavani v selectoru od kurzoru/od zacatku}
          dlgNoEditLine       =1 shl 11;{zakaze/povoli editovaci radku v selectoru}
          dlgDontLoadFiles    =1 shl 12;{zakaze nacitat jmena souboru}
          dlgDontLoadDirs     =1 shl 13;{zakaze nacitat jmena adresaru}
          dlgPackNames        =1 shl 14;{necha jmeno souboru sbalene/posune tecku na pozici 9.znaku}
          dlgCanSelectDir     =1 shl 15;{povoli vyber adresare v selectoru}
          {podle áeho a jak ©adit soubory/adres†©e v selectoru}
          sortName            =1;   {©adit podle jmÇna}
          sortExt             =2;   {©adit podle p©°pony}
          sortSize            =3;   {©adit podle velikosti}
          sortDate            =4;   {©adit podle datumu}
          sortTime            =5;   {©adit podle áasu}
          sortYear            =6;   {©adit podle roku}
          sortMonth           =7;   {©adit podle màs°ce}
          sortDay             =8;   {©adit podle dne}
          sortDateAndTime     =9;   {©adit podle celkovÇho datumu a áasu}
          sortHour            =10;  {©adit podle hodiny}
          sortMinute          =11;  {©adit podle minuty}
          sortSecond          =12;  {©adit podle sekundy}
          sortAttr            =13;  {©adit podle atributñ}
          sortSeparate        =14;  {pouze oddàlit adres†©e od souborñ}
          sortFilesFirst      =$40; {za©adit adres†©e aë za soubory (defaultnà jsou adres†©e na zaá†tku)}
          sortFlipList        =$80; {obr†tit seznam od konce do zaá†tku}
          sortDefault:byte    =sortName;
          {udaje, ktere se zobrazi u kazdeho souboru (v selectoru)}
          itemName            =1 shl 0;
          itemExt             =1 shl 1;
          itemSize            =1 shl 2;
          itemDate            =1 shl 3; {den.mesic.posledni dvojcisli roku}
          itemTime            =1 shl 4; {hodina:minuta}
          itemAttr            =1 shl 5; {od '----' az do 'arhs'}
          itemDefault:byte    =itemName+itemExt;
          {typy scrollbary v selectoru}
          barNone             =0;
          barVertical         =1;
          barHorizontal       =2;
          barArrows           =3;
          barDefault:byte     =barHorizontal;

{Pomoci nasledujicich promennych muzes upravit chovani vsech dialogu.}
{Pokud ti vyhovyje standardni chovani, nemusis na ne ani sahnout.}
Var       dlgPreInit :TProc;     {co se zavola tesne pred otevrenim dialogu}
          dlgPostInit:TProc;     {co se zavola tesne po otevreni dialogu}
          dlgDone    :TProc;     {co se zavola pri zavirani dialogu}
          dlgHelp    :TProc;     {co se zavola pri stisku F1}
          dlgEvents  :string[10];{jake eventy se nezpracuji a ukonci dialog}
          dlgFont    :PathStr;   {jmeno fontu pro dialogy}
          dlgHotkeys :boolean;   {kod polozky v menu povazuje za kod klavesy a reaguje na ni}

FUNCTION  dlgMsg(msg:pchar):TEvent;
FUNCTION  dlgStr(msg:string):TEvent;
FUNCTION  dlgMsgOpen(msg:pchar):PObject;
FUNCTION  dlgStrOpen(msg:string):PObject;
FUNCTION  dlgError(errorcode:TError):TError;
FUNCTION  dlgChoice(popisek,tlacitka:string):word;
FUNCTION  dlgExit:char;
FUNCTION  dlgLine(flags:longint;popisek:string;preselect:string):string;
FUNCTION  dlgPathBrowser(flagy:longint;popisek,masc,preselect:string):string;
FUNCTION  dlgSelector(flagy:longint;popisek,masc,preselect:string):string;
FUNCTION  dlgChar:char;
{FUNCTION  dlgMenu(popisek:string;polozek:byte;p:ppchar;addofs,preselect:word):word;}
FUNCTION  dlgMenu(popisek:string;polozek:byte;f:FGetMenuLine;p:pointer;preselect:word):word;
FUNCTION  dlgMenuNdx(popisek:string;c:PStrCollection;preselect:word):word;
FUNCTION  dlgMenuKod(popisek:string;c:PMenuCollection;preselect:longint):longint;
FUNCTION  dlgSelectLanguage:boolean;


{$I GUI1.INC}

PROCEDURE erDialog(st:string);
PROCEDURE erStdoutAndDialog(st:string);

{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

Uses Dialog;

{---------------------------------------------------------------------------
 Vypise zpravu a necha ji viset na obrazovce.
 Zrusis ji prostym zrusenim vraceneho objektu.
 Pchar msg neuvolni.
 ---------------------------------------------------------------------------}
FUNCTION  dlgMsgOpen(msg:pchar):PObject;
var   d:PDialog;
      t:TText1;
      sir,vys,y:word;
begin
 dlgMsgOpen:=nil;
 if t.Init(msg) then begin
   t.ScanSize(sir,vys);
   if NewDialog(d,sir+4,vys+2,nil) then begin
     d^.Frame;
     for y:=1 to vys do
       d^.wrixy(textlo,2,y,t.nlRead);
     d^.FreshFull;
     dlgMsgOpen:=d;
     end;
   t.Done;
   end;
end;

{---------------------------------------------------------------------------
 Vypise zpravu a ceka na event.
 Pchar msg neuvolni.
 ---------------------------------------------------------------------------}
FUNCTION  dlgMsg(msg:pchar):TEvent;
var   event:TEvent;
      d:PDialog;
begin
 event:=0;
 {$ifdef debug}writeln('dlgMsg1=',pc2str(msg));msg:='dlgMsg1';readkey;{$endif}
 d:=PDialog(dlgMsgOpen(msg));
 {$ifdef debug}writeln('dlgMsg2=',pc2str(msg));msg:='dmgMsg2';readkey;{$endif}
 if d<>nil then begin
   repeat
     event:=d^.GetEvent;
   until not (code(event) in (mcHolds+mcReleases));
   d^.Free;
   end;
 dlgMsg:=event;
end;

FUNCTION  dlgStrOpen(msg:string):PObject;
begin
 dlgStrOpen:=dlgMsgOpen(Str2Pc(msg));
end;

FUNCTION  dlgStr(msg:string):TEvent;
begin
 dlgStr:=dlgMsg(Str2Pc(msg));
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
var full,cut:string;
    i:integer;
begin
 if not insideerror and (errorcode<>erOk) then begin
   full:=_(errorcode);
   {dlouhou hlasku rozdeli na dva radky}
   cut:=full;
   if length(full)>38 then begin
     for i:=0 to length(full) div 2 do
      if full[length(full) div 2+i]=' ' then begin i:=length(full) div 2+i;break;end else
      if full[length(full) div 2+1-i]=' ' then begin i:=length(full) div 2+1-i;break;end;
     cut:=copy(full,1,i-1)+#13#10+copy(full,i+1,255);
     end;
   insideerror:=true;
   if dlgStr(cut)=0 then erMsg(full);
   insideerror:=false;
   end;
 dlgError:=errorcode;
end;

{$I GUI2.INC}


{---------------------------------------------------------------------------
 Da na vyber z nekolika moznosti.
 Priklad: dlgChoice('Are you sure?','Yes;No;Dunno');
 ---------------------------------------------------------------------------}
FUNCTION dlgChoice(popisek,tlacitka:string):word;
var  P: PCollection;
     nadpis,nadpislines,j: integer;
     i,tlacitek,nejsirsi:integer;
     dlgside,butsir,mezibut,butside:word;
     stejnasire:boolean;
     x,fntwidth:word;
     le4nadp,le4butts,le4dlg:word;
label 1,2;
begin
  New(P,Init(20,20));

 {umisti nadpis}

  le4nadp:=0;
  nadpislines:=CharsIn(#13,popisek)+1;
  if popisek='' then nadpis:=0 else nadpis:=1+nadpislines;
  for j:=1 to 1+CharsIn(#13,popisek) do le4nadp:=MaxW(le4nadp,length(GetString(popisek,#13,j)));
  with P^ do
   for j:=1 to nadpis-1 do
    Insert(New(PGuiText,Init(-1,j,cutString(popisek,#13),$30)));
  nejsirsi:=0;
  for tlacitek:=1 to CharsIn(';',tlacitka)+1 do
   nejsirsi:=MaxI(nejsirsi,length(GetString(tlacitka,';',tlacitek)));

 {pocita kolik mista to nakonec zabere a kdyztak vse trochu srazi}

  dlgside:=2;{mista pred prvnim butt v dlg}
  butside:=1;{mista pred prvnim pismenem v butt}
  mezibut:=2;{mista mezi butts}
  stejnasire:=true;{vsechny butt stejne siroky}
 1:
  if stejnasire then begin
    butsir:=nejsirsi+2*butside+2;{zapocte kraje ve vyrazu "> slovo <"}
    le4butts:=tlacitek*(butsir+mezibut)-mezibut;
    end
  else begin
    le4butts:=length(tlacitka)+tlacitek*(2*butside+2+mezibut-1)-mezibut+1;
    end;
  le4dlg:=MaxW(le4nadp,le4butts)+2+2*dlgside;
  {jednoducha heuristika: typicky ma uzivatel nastaven font sirky 8
   a i kdyz ho v dlgPreInit zmeni, zas bude mit 8}
  if screen^.MapModel=model_text then fntwidth:=1 else fntwidth:=8;
  if le4dlg*fntwidth<=screen^.Xres then goto 2;
  if mezibut=2 then mezibut:=1 else
  if dlgside=2 then dlgside:=1 else
  if stejnasire then stejnasire:=false else
  if butside=1 then butside:=0 else
  goto 2;
  goto 1;
 2:

 {umisti tlacitka a pusti dialog}

  x:=1+dlgside+(MaxW(le4nadp,le4butts)-le4butts) div 2;
  i:=1;
  with P^ do
   while tlacitka<>'' do begin
     if not stejnasire
      then butsir:=length(GetString(tlacitka,';',1))+2*butside+2;
     Insert(New(PGuiButton,Init(x,nadpis+1,butsir,
      cutString(tlacitka,';'),MakeEvent(vcEndGui,#0,#0),i)));
     inc(x,butsir+mezibut);
     inc(i);
     end;
  dlgChoice:=dlgGUI(le4dlg,nadpis+3,p,i{jakakoliv promenna},nil);
  Dispose(P,Done);
end;

FUNCTION myDlgChoice(popisek,tlacitka:string):word;far;
begin
 if curscreen=nil
  then myDlgChoice:=0
  else myDlgChoice:=dlgChoice(popisek,tlacitka);
end;

{---------------------------------------------------------------------------
 Zepta se, pocka na reakci a vrati 'S', 'D' nebo 'C'.
 ---------------------------------------------------------------------------}
FUNCTION dlgExit:char;
const wid=51;
      line:array[0..4] of string[wid]=(
        '                                                   ',
        '   …ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ Edit ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª   ',
        '   ∫  You''ve made changes since the last save. ∫   ',
        '   ∫    Save   Don''t save   Continue editing   ∫   ',
        '   »ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº   ');
      x:array[1..3] of byte=(7,14,27);
{ verze zuzena tak, aby se ve®la do rozli®en° 360xVò®ka
const wid=44;
      line:array[0..4] of string[wid]=(
        '                                            ',
        '…ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ Edit ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª',
        '∫ You''ve made changes since the last save. ∫',
        '∫   Save   Don''t save   Continue editing   ∫',
        '»ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº');
      x:array[1..3] of byte=(3,10,23);}
      l:array[1..3] of byte=(6,12,18);
      c:array[1..3] of char=('S','D','C');
var   event:TEvent;
      ch:char;
      i,j:word;
      d:PDialog;
begin
 dlgExit:='C';
 if NewDialog(d,wid,6,nil) then begin
   for i:=0 to 5 do d^.wrixy($4f,0,i,line[i mod 5]);
   for i:=1 to 3 do
     d^.PutButton(x[i],3,$4f,$70,copy(line[3],x[i]+1,l[i]));
   d^.buttK:=1;
   repeat
     d^.FreshFull;
     event:=d^.GetEvent;
     ch:=UpCase(char(event));
     case code(event) of
       kEsc   :ch:='C';
       kLeft  :d^.buttK:=(d^.buttK+1) mod 3+1;
       kRight :d^.buttK:=d^.buttK mod 3+1;
       kEnter,
       kkEnter:ch:=c[d^.buttK];
       vcRepos:if d^.buttM<>0 then d^.buttK:=d^.buttM;
       mcLeftPressed
              :if d^.buttK=d^.buttM then ch:=c[d^.buttK];
       end;
   until ch in ['S','D','C'];
   dlgExit:=ch;
   d^.Free;
   end;
end;


{---------------------------------------------------------------------------
 Inputlajna.
 Popisek muze byt viceradkovy i prazdny, oddelovac je #13.
 Zatim nepodporuje dlgOverwrite.
 ---------------------------------------------------------------------------}
PROCEDURE dlgLine_Idle; far;
begin
  if Code(guiEvent) in [kEnter,kkEnter] then begin
    guiD^.s^.PushEvent(MakeEvent(vcEndGui,#0,#0));
    guiCommand:=kEnter;
    end;
end;

FUNCTION dlgLine(flags:longint;popisek:string;preselect:string):string;
var  P: PCollection;
     txt: string;
     le,nadpis,j: integer;
begin
  New(P,Init(20,20));
  le := 40-6;
  if popisek='' then nadpis:=0 else nadpis:=2+CharsIn(#13,popisek);
  for j:=1 to 1+CharsIn(#13,popisek) do le:=MaxW(le,length(GetString(popisek,#13,j)));
  with P^ do begin
    for j:=1 to nadpis-1 do
      Insert(New(PGuiText,Init(-1,j,cutString(popisek,#13),$30)));
    Insert(New(PGuiInputLine,Init(2,nadpis+1,le,255,preselect,True)));
    end;
  txt := preselect;
  case dlgGUI(le+6,nadpis+3,p,txt,dlgLine_Idle) of
    kEnter, kkEnter: dlgLine := txt;
    else if flags and dlgEscReturnsNothing<>0 then dlgLine := ''
          else dlgLine := preselect;
    end;
  Dispose(P,Done);
end;
(*
{---------------------------------------------------------------------------
 Stara inputlajna, delka stringu omezena velikosti obrazovky.
 ---------------------------------------------------------------------------}
FUNCTION dlgLine(flags:longint;popisek,preselect:string):string;
var   i,j,le,x2,maxlen:integer;
      path,popisek2:string;
      event:TEvent;
      ch:char;
      d:PDialog;
      konec:boolean;
begin
 dlgLine:=preselect;
 if (flags and dlgOverwrite>0) and (preselect='') then exit;
 path:=preselect;
 popisek2:=popisek;
 popisek:=CutString(popisek2,#13);
 maxlen:=36+40;
 le:=maxW(maxlen+2,maxW(length(popisek),length(popisek2)));
 x2:=(le-maxlen) div 2;
 if NewDialog(d,le+2,5,nil) then begin
   i:=length(path)+ord(flags and dlgOverwrite=0);
   if flags and dlgCursorToStart>0 then i:=1;
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
      kEsc      :begin if (flags and dlgEscReturnsNothing)=0 then path:=preselect else path:='';konec:=true;end;
      kBackspace:if (flags and dlgOverwrite=0) and (i>1)
                  then begin path:=copy(path,1,i-2)+copy(path,i,length(path));dec(i);end;
      kLeft     :if i>1 then dec(i);
      kRight    :if i<length(path)+ord(flags and dlgOverwrite=0) then inc(i);
      kDelete   :if (flags and dlgOverwrite=0) and (i<=length(path)) then path:=copy(path,1,i-1)+copy(path,i+1,length(path));
      kHome     :i:=1;
      kEnd      :i:=length(path)+ord(flags and dlgOverwrite=0);
      kInsert   :flags:=flags xor dlgOverwrite;
      kEnter,
      kkEnter   :konec:=true;
      mcLeftPressed,
      mcLeftHold
                :if d^.press.y=3 then begin
                   j:=d^.press.x-1;
                   if (j>=1) and (j<=length(path)+ord(flags and dlgOverwrite=0)) then i:=j;
                   end;
      else      begin
                 ch:=char(event);
                 if flags and dlgOverwrite>0
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
 Jednoduchy fileselector, pocet souboru omezen velikosti obrazovky.
 ---------------------------------------------------------------------------}
FUNCTION dlgFile(flags:longint;popisek,mask,preselect:string):string;
const qw=0;
var   list:TStringCollection;
      j,lines,newnamepos:integer;
      t:searchrec;
      st:string[50];
      st2:string;
      keyb:Boolean;
      f:file;
      d:PDialog;
      event:TEvent;
      namesir:byte;
      result:TError;

  procedure FindAll(mask:string);
  begin
   findfirst(mask,0,t);
   while doserror=0 do begin
    if (flags and dlgHideExt)>0 then{odstrani ".ext"}
      t.name:=GetString(t.name,'.',1);
    list.Insert(NewStr(LoCased(t.name)));
    findnext(t);
    end;
  end;

  function polozka(n:word):string;
  begin
   polozka:=PString(list.items^[n-1])^;
  end;

  procedure GetSize(var sir,vys:word;maxsir,maxvys:word);far;
  var maxslp:word;
  begin
    maxslp:=(maxsir-4) div namesir;
    lines:=minW(list.count,maxW(10,list.count div maxslp+1));
    sir:=maxI(60,(list.count+lines-1) div lines*namesir+3);
    vys:=lines+4;
  end;

label 2,3,restart,donee;
begin
 LoCasni(preselect);
 dlgFile:=preselect;
 list.Init(100,100);
 st:='';
 keyb:=false;
 if (flags and dlgHideExt)=0 then namesir:=13 else namesir:=9;

 restart:
 st2:=_(_msgNenalezAni1Soub)+#13#10+_(_msgKMasce)+' '+mask+'.';
 while mask<>'' do findall(cutstring(mask,';'));

 if list.count=0 then begin
  dlgFile:='';
  if (flags and dlgForbidNew)=0
    then dlgFile:=dlgLine(flags or dlgOverwrite-dlgOverwrite,popisek,preselect)
    else dlgStr(st2);
  goto donee;
  end;

 list.Search(@preselect,j);
 if j>=list.count then j:=list.count-1;

 if NewDialog(d,0,0,@GetSize) then begin
   newnamepos:=d^.chrX*2 div 3;
   d^.buttK:=j+1;
   d^.Frame;
   for j:=1 to d^.chrX-2 do d^.wrixy(frameline,j,2,'ƒ');
   d^.wrixy(textlo,maxI(1,newnamepos div 2-length(popisek) div 2),qw+1,copy(popisek,1,d^.sizeX*2 div 3-2));
   for j:=0 to list.count-1 do
     d^.PutButton(1+j div lines*namesir,qw+3+j mod lines,textlo,textbut,' '+Left(polozka(j+1),namesir-1)+' ');{v cyklu}
   d^.FreshFull;
   repeat
     if not keyb then st:=polozka(d^.buttK);
     d^.wrixy(texthi,newnamepos,qw+1,st);
     for j:=newnamepos+length(st) to d^.chrX-2 do d^.wrixy(texthi,j,qw+1,' ');
     d^.FreshFull;
     d^.gotoxy(newnamepos+length(st),qw+1);
     event:=d^.GetEvent;
     case code(event) of
       {zde zatim igoruje dlgForbidNew flag}
       kLeft     :begin dec(d^.buttK,lines);keyb:=false;end;
       kRight    :begin inc(d^.buttK,lines);keyb:=false;end;
       kUp       :begin dec(d^.buttK);      keyb:=false;end;
       kDown     :begin inc(d^.buttK);      keyb:=false;end;
       kHome     :begin d^.buttK:=1;        keyb:=false;end;
       kEnd      :begin d^.buttK:=list.count;keyb:=false;end;
       kPgUp     :begin d^.buttK:=d^.buttK-(d^.buttK-1) mod lines;keyb:=false;end;
       kPgDwn    :begin d^.buttK:=minW(d^.buttK+lines-(d^.buttK-1) mod lines-1,list.count);keyb:=false;end;
       kBackspace:if length(st)>0 then st[0]:=chr(length(st)-1);
       kTab      :dlgFile:=polozka(d^.buttK);
       kEnter,
       kkEnter   :dlgFile:=st;
       kEsc      :if flags and dlgEscReturnsNothing=0 then dlgFile:=preselect else dlgFile:='';
       mcRepos   :if d^.buttM<>0 then begin d^.buttK:=d^.buttM;keyb:=false;end;
       mcLeftPressed
                 :if (d^.buttM=d^.buttK) then begin dlgFile:=polozka(d^.buttK);break;end;
       else      if char(event) in ['!'..'@','_'..'z'] then
                  if keyb=true
                   then begin if length(st)<d^.chrX-newnamepos-2 then st:=st+char(event);end
                   else begin keyb:=true;st:=char(event);end;
       end;
     if keyb then begin
       list.Search(@st,integer(d^.buttK));
       d^.buttK:=minI(d^.buttK+1,list.count);
       end
      else d^.buttK:=(d^.buttK+5*list.count-1) mod list.count+1;
   until code(event) in [kEsc,kEnter,kkEnter,kTab];
   d^.Free;
   end;
 donee:
 list.Done;
end;
*)


type TPchars=array[0..16370] of pchar;
     PPchars=^TPchars;

function GetColItem(p:pointer;w:word):pchar;far;
begin
 GetColItem:=PPchars(p)^[w];
end;


{---------------------------------------------------------------------------
 Menu - zakladni low level verze... nemusis ji vubec pouzivat.
 Pokud seznam polozek vytvaris dynamicky (v kolekci),
 muzes pouzit pohodlnejsi dlgMenuNdx nebo dlgMenuKod.

 Zepta se, pocka na reakci a vrati
   0          - nevybrano nic, menu zruseno
   1..polozek - cislo vybrane polozky
 Parametry:
   popisek    - nadpis, lze i viceradkovy, pricemz oddelovac je #13
   polozek    - pocet polozek v menu
   f          - funkce vracejici pointer na n-tou polozku
   p          - pointer taky predavany fci f (cosi jako pointer na 1.polozku)
   preselect  - kolikata polozka je oznacena na zacatku
   dlgHotkeys - zda kody povazovat za kody hotkey klaves a reagovat na ne
 ---------------------------------------------------------------------------}
FUNCTION dlgMenu(popisek:string;polozek:byte;f:FGetMenuLine;p:pointer;preselect:word):word;
var   b,i,j,le:integer;
      event:TEvent;
      d:PDialog;
      nadpis:word;
      viditelnych:byte; {rozhodne program, podle toho, jestli se vsechny polozky vejdou na obrazovku nebo ne}
      segment,segmentmax:integer;

  function get(n:byte):pchar;
  begin
   get:=f(p,n-1);
   {get:=ppchar(ptr(PtrRec(p).Seg,PtrRec(p).Ofs+(n-1)*addofs))^;}
  end;

  function kod(n:byte):byte;
  begin
   kod:=pline(get(n))^[StrLen(get(n))+1];
  end;

  procedure GetSize(var sir,vys:word;maxsir,maxvys:word);far;
  begin
   if vys>maxvys then vys:=maxvys*7 shr 3;
   viditelnych:=vys-2-nadpis;
  end;

begin
 if polozek=0 then begin dlgMenu:=0;exit;end;
 le:=0;
 b:=0;
 segment:=0;
 if popisek='' then nadpis:=0 else nadpis:=2+CharsIn(#13,popisek);
 for i:=1 to polozek do le:=MaxW(le,StrLen(get(i)));
 for i:=1 to 1+CharsIn(#13,popisek) do le:=MaxW(le,length(GetString(popisek,#13,i)));
 if NewDialog(d,le+4,polozek+2+nadpis,@GetSize) then begin
   d^.Frame;
   if popisek<>'' then begin
     j:=1;
     while popisek<>'' do begin
       d^.wrixy(textlo,1,j,' '+cutString(popisek,#13));
       inc(j);
       end;
     d^.wrixy(framein,1,j,rep('ƒ',le+2));
     end;
   b:=-1;
   if polozek>viditelnych then segmentmax:=polozek-viditelnych else segmentmax:=0;
   if preselect>viditelnych then segment:=Bounded(preselect-viditelnych div 2,0,segmentmax);
   d^.buttK:=Bounded(preselect,1,polozek)-segment;
   repeat
     for i:=1 to viditelnych do
      d^.PutButton(1,i+nadpis,textlo,textbut,' '+Left(Pc2Str(get(segment+i)),le+1));
     d^.FreshFull;
     event:=d^.GetEvent;
     case code(event) of
       kEsc       :b:=0;
       kUp        :if d^.buttK=1 then segment:=MaxI(segment-1,0)
                   else d^.buttK:=(d^.buttK+polozek-2) mod polozek+1;
       kDown      :if d^.buttK=viditelnych then segment:=MinI(segment+1,segmentmax)
                   else d^.buttK:=d^.buttK mod polozek+1;
       kHome      :begin
                    segment:=0;
                    d^.buttK:=1;
                   end;
       kPgUp      :if segment>=viditelnych then
                    dec(segment,viditelnych)
                   else
                    begin
                     d^.buttK:=MaxI(integer(d^.buttK)+segment-viditelnych,1);
                     segment:=0;
                    end;
       kEnd       :begin
                    segment:=segmentmax;
                    d^.buttK:=viditelnych;
                   end;
       kPgDwn     :if segment+viditelnych>segmentmax then
                    begin
                     d^.buttK:=MinI(d^.buttK+viditelnych-(segmentmax-segment),viditelnych);
                     segment:=segmentmax;
                    end
                   else
                    inc(segment,viditelnych);
       kEnter,
       kkEnter    :b:=segment+d^.buttK;
       mcLeftPressed
                  :if (d^.buttM=d^.buttK) then b:=segment+d^.buttK;
       vcRepos    :if d^.buttM<>0 then d^.buttK:=d^.buttM;
       else        if dlgHotkeys then
                    for i:=1 to polozek do
                     if kod(i)=code(event) then b:=i;
       end;
     d^.DeleteButtons;
   until b>=0;
   d^.Free;
   end;
 dlgMenu:=b;
end;

{---------------------------------------------------------------------------
 Menu.
 Seznam polozek ocekavan v kolekci.
 Preselect i result jsou indexy do kolekce polozek, cislovano od 1.
 ---------------------------------------------------------------------------}
FUNCTION dlgMenuNdx(popisek:string;c:PStrCollection;preselect:word):word;
begin
 dlgMenuNdx:=dlgMenu(popisek,c^.count,GetColItem,pointer(c^.items),preselect);
end;

{---------------------------------------------------------------------------
 Menu.
 Seznam polozek ocekavan v kolekci.
 Preselect i result jsou kody polozek. Kod se polozkam dava v InsertStr.
 ---------------------------------------------------------------------------}
FUNCTION dlgMenuKod(popisek:string;c:PMenuCollection;preselect:longint):longint;
var index:integer;
 function KodMatches(item:pointer):boolean;far;
 begin
  inc(index);
  KodMatches:=c^.KodOf(item)^=preselect;
 end;
begin
 index:=0;
 if c^.FirstThat(@KodMatches)=nil then index:=0;
 index:=dlgMenuNdx(popisek,c,index);
 if index=0 then dlgMenuKod:=0 else dlgMenuKod:=c^.KodOf(c^.At(index-1))^;
end;

{---------------------------------------------------------------------------
 TMenuCollection pro dlgMenuKod.
 ---------------------------------------------------------------------------}
Constructor TMenuCollection.Init(sort:boolean);
begin
 inherited Init(50,50);
 sorted:=sort;
 duplicates:=false;
end;

Function TMenuCollection.StrAndKod(st:string;kod:longint):pchar;
var p:pointer;
begin
 GetMem(p,length(st)+1+sizeof(kod));
 if p=nil then Halt(erLowMem);
 {$ifdef beta}
 if pos(#0,st)>0 then erBetaMsg('TMenuCollection: #0 in str.');
 {$endif}
 Move(st[1],p^,length(st));
 (pchar(p)+length(st))^:=#0;
 Move(kod,(pchar(p)+length(st)+1)^,sizeof(kod));
 StrAndKod:=p;
end;

Function TMenuCollection.KodOf(item:pointer):PLong;
begin
 KodOf:=@meml[PtrRec(item).Seg:PtrRec(item).Ofs+StrLen(item)+1];
end;

Procedure TMenuCollection.InsertSt(txt:string);
begin
 InsertStr(txt,0);
end;

Procedure TMenuCollection.InsertStr(txt:string;kod:longint);
begin
 if sorted
  then TSortedCollection.Insert(StrAndKod(txt,kod))
  else TCollection.Insert(StrAndKod(txt,kod));
end;

Procedure TMenuCollection.FreeItem(item:pointer);
begin
 if item<>nil then FreeMem(item,StrLen(item)+5);
end;

Function TMenuCollection.Compare(key1,key2:pointer):integer;
begin
 Compare:=StrIComp(key1,key2);
end;


{---------------------------------------------------------------------------
 Necha uzivatele vybrat libovolny znak
 ---------------------------------------------------------------------------}
FUNCTION dlgChar:char;
var
 d:PDialog;
 event:TEvent;
 i:byte;
begin {dlgChar}
 dlgChar:=#0;
 if not(NewDialog(d,18,20,nil)) then exit;
 d^.Frame;
 with d^ do
 for i:=0 to $F do
  wrixy($30,1,1+i,
   chr(i shl 4+$0)+chr(i shl 4+$1)+chr(i shl 4+$2)+chr(i shl 4+$3)+
   chr(i shl 4+$4)+chr(i shl 4+$5)+chr(i shl 4+$6)+chr(i shl 4+$7)+
   chr(i shl 4+$8)+chr(i shl 4+$9)+chr(i shl 4+$A)+chr(i shl 4+$B)+
   chr(i shl 4+$C)+chr(i shl 4+$D)+chr(i shl 4+$E)+chr(i shl 4+$F));
 d^.wrixy($30,1,17,rep('ƒ',$10));
 i:=0;
 with d^ do
 repeat
  wrixy($30,1,18,WithZeroes(i,3)+' '+hex[i shr 4]+hex[i and $F]+'h '
  +hex[i shr 7]+hex[i shr 6 and 1]+hex[i shr 5 and 1]+hex[i shr 4 and 1]
  +hex[i shr 3 and 1]+hex[i shr 2 and 1]+hex[i shr 1 and 1]+hex[i and 1]);
  wrixy($70,1+i and 15,1+i shr 4,chr(i));
  FreshFull;
  wrixy($30,1+i and 15,1+i shr 4,chr(i));
  event:=GetEvent;
  case code(event) of
  kEsc:   begin d^.Free; exit; end;
  kkEnter,
  kEnter: break;
  kUp:    dec(i,$10);
  kDown:  inc(i,$10);
  kLeft:  dec(i);
  kRight: inc(i);
  kHome:  i:=either(i=i and $F0,$00,i and $F0);
  kEnd:   i:=either(i=i and $F0+$0F,$FF,i and $F0+$0F);
  kPgUp:  i:=i and $0F;
  kPgDwn: i:=i and $0F+$F0;
  mcLeftPressed:
          if i=(press.y-1) shl 4+press.x-1
          then break;
  mcLeftHold:
          while (code(GetEvent)=mcLeftHold) and IsIn(press.x,1,$10) and IsIn(press.y,1,$10) do
           begin
            i:=(press.y-1) shl 4+press.x-1;
            wrixy($30,1,18,WithZeroes(i,3)+' '+hex[i shr 4]+hex[i and $F]+'h '
            +hex[i shr 7]+hex[i shr 6 and 1]+hex[i shr 5 and 1]+hex[i shr 4 and 1]
            +hex[i shr 3 and 1]+hex[i shr 2 and 1]+hex[i shr 1 and 1]+hex[i and 1]);
            wrixy($70,1+i and 15,1+i shr 4,chr(i));
            FreshFull;
            wrixy($30,1+i and 15,1+i shr 4,chr(i));
           end;
  mcLeftReleased:
          if IsIn(press.x,1,$10) and IsIn(press.y,1,$10) then
           begin
            if i=(press.y-1) shl 4+press.x-1
            then break
            else i:=(press.y-1) shl 4+press.x-1;
            press.x:=0; press.y:=0;
           end;
  else    if event and $7F<>0 then i:=event and $7F;
  end; {/case}
 until false;
 d^.Free;
 dlgChar:=chr(i);
end;  {dlgChar}

{$i SELE.INC}

FUNCTION dlgSelectLanguage:boolean;
var c:TMenuCollection;
    mask:string;
    inserted,presel,sel:integer;
    ext:string[10];
    s:PScreen;
begin
 dlgSelectLanguage:=false;
 if CurScreen<>nil then s:=nil else New(s,Init(model_packed+model_gfx,640,480,0));
 if CurScreen<>nil then begin
   if c.Init(true) then begin
     mask:=fileMask(isLanguage);
     inserted:=0;
     presel:=1;
     while mask<>'' do begin
       ext:=LoCased(copy(CutString(mask,';'),3,255));
       if ext=language then presel:=inserted+1;
       if ext='cz' then ext:='Äesky';
       if ext='eng' then ext:='English';
       if ext<>'' then begin inc(inserted);c.InsertStr(ext,inserted);end;
       end;
     if s<>nil then with s^ do MouseSetPos(Xres*3 div 5,Yres div 2);
     CurScreen^.SetBright(255);{jeste nemusela byt fyzicky nastavena paleta sipky}
     CurScreen^.Sync;
     CurScreen^.ResetEvents;
     if c.count=1 then sel:=1 else sel:=dlgMenuKod('',@c,presel);
     mask:=fileMask(isLanguage);
     while mask<>'' do begin
       ext:=LoCased(copy(CutString(mask,';'),3,255));
       if ext<>'' then begin
         if sel=1 then begin
           language:=ext;
           dlgSelectLanguage:=true;
           end;
         dec(sel);
         end;
       end;
     c.Done;
     end;
   if s<>nil then begin
     s^.silentDone:=true;
     KillObj(s);
     end;
   end;
end;

{---------------------------------------------------------------------------
 Alternativni zpusoby hlaseni chyb.
 ---------------------------------------------------------------------------}
var insideErDialog:boolean;
PROCEDURE erDialog(st:string);
begin
 {$ifdef debug}writeln('erDialog1=',st);st:='erDialog1';readkey;{$endif}
 if insideErDialog then erWrite(st) else begin
   insideErDialog:=true;
   {$ifdef debug}writeln('erDialog2=',st);st:='erDialog2';readkey;{$endif}
   if (CurScreen=nil) then erWrite(st){vypis byl zakomentovan (hrozi ze je nastaven gfx.mod a psani dopadne jako 
     sypani caje), ale jeste vic mi vadilo, ze az do setmode nehlasi zadne chyby}
    else if (dlgStr(st)=0) then {erWrite(st)};{tady zakomentovani nechame, sypani caje by bylo temer jiste}
   insideErDialog:=false;
   end;
end;

PROCEDURE erStdoutAndDialog(st:string);
begin
 BiosWriteln(st);
 erDialog(st);
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='dialogy';
var result:TError;

procedure UserInit;
 begin
  dlgPreInit  :=nil;
  dlgPostInit :=nil;
  dlgDone     :=nil;
  dlgHelp     :=nil;
  dlgFont     :=fnDefaultNp;
  dlgEvents   :='';
  dlgHotkeys  :=false;
  insideerror :=false;
  ReportErr   :=erDialog;
  insideErDialog:=false;
  _dlgChoice  :=myDlgChoice;{unite fajly rekne cim se ptat v dlgCont}
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

FUNCTION dlgMenu(popisek:string;polozek:byte;f:FGetMenuLine;p:pointer;preselect:word):word;
var   b,i,j,le:integer;
      event:TEvent;
      d:PDialog;
      nadpis:word;

  function get(n:byte):pchar;
  begin
   get:=f(p,n-1);
   {get:=ppchar(ptr(PtrRec(p).Seg,PtrRec(p).Ofs+(n-1)*addofs))^;}
  end;

  function kod(n:byte):byte;
  begin
   kod:=pline(get(n))^[StrLen(get(n))+1];
  end;

begin
 if polozek=0 then begin dlgMenu:=0;exit;end;
 le:=0;
 b:=0;
 if popisek='' then nadpis:=0 else nadpis:=2+CharsIn(#13,popisek);
 for i:=1 to polozek do le:=MaxW(le,StrLen(get(i)));
 for i:=1 to 1+CharsIn(#13,popisek) do le:=MaxW(le,length(GetString(popisek,#13,i)));
 if NewDialog(d,le+4,polozek+2+nadpis,nil) then begin
   d^.Frame;
   if popisek<>'' then begin
     j:=1;
     while popisek<>'' do begin
       d^.wrixy(textlo,1,j,' '+cutString(popisek,#13));
       inc(j);
       end;
     d^.wrixy(framein,1,j,rep('ƒ',le+2));
     end;
   for i:=1 to polozek do
     d^.PutButton(1,i+nadpis,textlo,textbut,' '+Left(Pc2Str(get(i)),le+1));
   d^.FreshFull;
   d^.buttK:=MaxI(preselect,1);
   b:=-1;
   repeat
     event:=d^.GetEvent;
     case code(event) of
       kEsc       :b:=0;
       kUp        :d^.buttK:=(d^.buttK+polozek-2) mod polozek+1;
       kDown      :d^.buttK:=d^.buttK mod polozek+1;
       kHome,kPgUp:d^.buttK:=1;
       kEnd,kPgDwn:d^.buttK:=polozek;
       kEnter,
       kkEnter    :b:=d^.buttK;
       mcLeftPressed
                  :if (d^.buttM=d^.buttK) then b:=d^.buttK;
       vcRepos    :if d^.buttM<>0 then d^.buttK:=d^.buttM;
       else        if dlgHotkeys then
                    for i:=1 to polozek do
                     if kod(i)=code(event) then b:=i;
       end;
   until b>=0;
   d^.Free;
   end;
 dlgMenu:=b;
end;
