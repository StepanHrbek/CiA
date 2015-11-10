{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 _rmCanceled=integer($FFFF);
 _rmLeft    =integer($FFFE);
 _rmRight   =integer($FFFD);
 _rmiDisabled=1;    {polozku nelze zvolit}
 _rmiTick    =2;    {zatrzeni}
 _rmiAutoTick=4;    {pri vyberu polozky zmen zatrzeni}
 _labInit    =1;
 _labShow    =2;
 _labDone    =4;
 {pripadne podmenu zobrazit relativne k pozici polozky, ktera ho vyvolala}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 string10=string[10];
 string20=string[20];
 string40=string[40];
 string80=string[80];
 TStatusLine= {Status lajna-radka,na ktere se objevuje kratky popisek akce}
  record
   x,y:integer; {umisteni status lajny}
   maxw:word;   {jeji maximalni delka (delsi text se orizne)}
  end;
 PMenuItem=^TMenuItem;
 TMenuItem=
  record
   name:string20;   {nazev polozky (to, co uvidi uzivatel)}
   stress:byte;     {kolikate pismeno nazvu se zvyrazni}
   keyseq:string10; {nazev klavesy nebo klavesove sekvence (objevi se vpravo)}
   key:byte;        {kod klavesy nebo udalosti, ktera vybira tuto polozku}
   command:longint; {udalost vybrani teto polozky ponese tento kod}
   flags:byte;      {priznaky chovani. bit: 0-disabled 1-checked}
   help:pchar;      {kratky popisek akce (pro status)}
   submenu:pointer; {ukazatel na submenu (na typ PMenuWindow)}
   next:PMenuItem;  {ukazatel na dalsi polozku nebo nil pro posledni}
  end;
 PMenuWindow=^TMenuWindow;
 TMenuWindow=
  record
   name:string20;       {nazev skupiny}
   stress:byte;         {kolikate pismeno nazvu se zvyrazni}
   key:byte;            {kterou klavesou se vyvola}
   w,h:byte;            {maximalni sirka a vyska okna}
   relx,rely:integer;   {relativni pozice od zacatku souradnic urcenych objektem}
   c1,c2:word;          {ukazatele na polozku}
   flags:byte;
   firstitem:PMenuItem; {ukazatel na prvni polozku}
   pdi:PDialog;         {ukazatel na nazev dialogu}
   next:PMenuWindow;    {ukazatel na dalsi okno nebo nil pro posledni}
  end;
 PRolMenu=^TRolMenu;
 TRolMenu=
  object
   root:PMenuWindow;    {ukazatel na prvni okno menu}
   default:PMenuWindow; {posledne vyvolane okno}
   x,y:integer;         {souradnice prvniho okna menu}
   key:byte;            {kterou klavesou se vyvola cele menu}
   event:TEvent;        {promenna udalosti}
   status:TStatusLine;  {informace o statuslejne}
   pds:PDialog;         {dialogove okno pro statusline}
   Constructor Init(_root:PMenuWindow; _x,_y:integer; _key:byte);
   Function  RunWindow(menuwindow:PMenuWindow):integer;
   Function  Run:integer;
   Function  WithLabelsDo(command:byte):integer;
   Procedure WithStatusLineDo(command:byte;item:PMenuItem);
   Destructor Done;
  public
   god,godmax:word;
   Function  GodWishes:boolean;
  end;
{StatusLajn - TRolMenu ma instanci status typu TStatus - to je jen record
o tom, kde ma statuslajna byt a jak ma bejt siroka. Potom, kazda polozka
muze mit promennou help typu PChar, ve ktere muze byt popis akce, ehm.}
procedure DisposeMenuWindow(var mw:PMenuWindow); forward;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Constructor TRolMenu.Init(_root:PMenuWindow; _x,_y:integer; _key:byte);
begin {TRolMenu.Init}
 root:=_root;
 default:=root;
 x:=_x;
 y:=_y;
 key:=_key;
 god:=1;
 godmax:=10;
end;  {TRolMenu.Init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE Items(menuwindow:PMenuWindow; var count,widest:word);
var
 pom:PMenuItem;
begin {Items}
 count:=0;
 widest:=0;
 if menuwindow<>nil then
  with menuwindow^ do
  begin
   pom:=firstitem;
   while pom<>nil do
    begin
     inc(count);
     widest:=maxW(length(pom^.name+pom^.keyseq)+byte(length(pom^.keyseq)<>0),widest);
     pom:=pom^.next;
    end;
  end;
end;  {Items}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  Ranged(n,min,max:longint; wrap:boolean):longint;
begin {Ranged}
 case wrap of
 false:
  if n>max then n:=min
  else if n<min then n:=max;
 true:
  if n>max then n:=max
  else if n<min then n:=min;
 end;
end;  {Ranged}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  TRolMenu.RunWindow(menuwindow:PMenuWindow):integer;
{vytvori okno, zobrazi polozky, da uzivateli moznost si vybrat
a pred ukoncenim da vsechno do puvodniho stavu
velikost okna:
 kdyz je vyska vetsi nez pocet polozek (ktere se vejdou na obrazovku), upravi se vyska okna
 pri vytvareni okna vypocita nejsirsi polozku - kdyz je zadana sirka vetsi, zmensi se sirka okna}
const
 _lista:string[5]='±þ*';
var
 pom:PMenuItem;
 count,widest:word;
 c1max,c2max:word;
 pd:PDialog; {dialogove okno pro menu}
 err:TError;
 i:integer;
 scroll:boolean;
 scrollpos:word;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure CursorVertically(down:boolean;howmanytimes:word);
 var i:word;
 begin {CursorVertically}
  {*zatim neni volitelne alebrz pevne wrapovani u okraju). To se upravi.}
  with menuwindow^ do
  case down of
  false: {takze nahoru}
   for i:=1 to howmanytimes do
    if c1=0 then
     if c2=0 then
      begin
       c1:=c1max;
       c2:=c2max;
      end
     else
      c2:=bounded(c2-1,0,c2max)
    else
     c1:=bounded(c1-1,0,c1max);
  true:
   for i:=1 to howmanytimes do
    if c1=c1max then
     if c2=c2max then
      begin
       c1:=0;
       c2:=0;
      end
     else
      c2:=bounded(c2+1,0,c2max)
    else
     c1:=bounded(c1+1,0,c1max);
  end; {case}
 end;  {CursorVertically}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure HandleMouseEvents;
 {zpracuje udalosti mysi, predpoklada ze v event bude udalost}
 begin {HandleMouseEvents}
  event:=pd^.GetEvent;
  with pd^ do
  case code(event) of
  mcLeftPressed:
   begin
    {klik mimo okno vyvola escape}
    if IsIn(press.x,0,chrX-1) and IsIn(press.y,0,chrY-1) then else
     begin
      event:=MakeEvent(kEsc,#27,#0);
     end;
    {klik do praveho rohu zpusobi dekrementaci c2 v mezich od 0 do c2max
    if press.x=chrX-1 then
     if press.y=0 then menuwindow^.c2:=bounded(menuwindow^.c2-1,0,c2max) else
     if press.y=chrY-1 then menuwindow^.c2:=bounded(menuwindow^.c2+1,0,c2max);}
   end;
  mcLeftHold:
   begin
    if IsIn(press.x,1,chrX-2-byte(scroll)) and IsIn(press.y,1,chrY-2) then
     begin
      {mys ukazuje na nejakou polozku}
     end;
    if scroll and GodWishes and (press.x=chrX-2) then {ukazuje na scroller}
     if press.y=1 then CursorVertically(false,1) else
     if press.y=chrY-2 then CursorVertically(true,1) else
     if IsIn(press.y-2,0,scrollpos-1) then CursorVertically(false,chrY-2) else
     if IsIn(press.y-2,scrollpos+1,chrY-5) then CursorVertically(true,chrY-2); {*hazi preteceni}
   end; {case mcLeftHold}
  end; {case}
 end;  {HandleMouseEvents}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin {TRolMenu.RunWindow}
 RunWindow:=_rmCanceled;
 Items(menuwindow,count,widest); {zjisti pocet polozek a nejsirsi z nich}
 if (menuwindow=nil) or (widest*count=0) then exit;
 {necha nebo upravi rozmery a vytvori dialogove okno}
 scroll:=(count>menuwindow^.h) and (menuwindow^.h>1);
 scrollpos:=0;
 new(pd,Init(MinW(widest,menuwindow^.w)+byte(scroll)+4,MinW(count,menuwindow^.h)+2,nil,0,err));
 if (err<>erOk) or (pd=nil) then
  begin
   ReportErr(_(_erDialogBig));
   exit;
  end;
 with pd^ do
 begin
  x1:=(x+menuwindow^.relx)*mulX;
  y1:=(y+menuwindow^.rely+1)*mulY;
 end;
 with menuwindow^ do
 begin
  c1max:=pd^.chrY-2-1;
  c2max:=MaxI(0,count-(pd^.chrY-2));
 end;
 pd^.Frame;
 if scroll then
  begin
   pd^.WriXY($70,pd^.chrX-2,1,_lista[2]);
   pd^.WriXY($70,pd^.chrX-2,pd^.chrY-2,_lista[3]);
  end;
 WithStatusLineDo(_labInit,nil);
 {hlavni smycka}
 with menuwindow^ do
 repeat
  {vykresli vsechny viditelne polozky}
  pom:=firstitem;
  if scroll and (h>2) then scrollpos:=(c1+c2)*(h-2) div count;
  for i:=1 to c2 do
   if pom<>nil then pom:=pom^.next; {* else chyba-narazil na nil};
  i:=0;
  while (pom<>nil) and (i<pd^.chrY-2) do
   begin
    with pom^ do
    if pom^.name<>'' then
     begin
      pd^.WriXY(either(i=c1,$10,$30)+either(pom^.flags and _rmiDisabled=0,$0E,$08),1,1+i
      ,eitherS(flags and _rmiTick<>0,'*',' ')
      +LeftRight(pom^.name,pom^.keyseq+eitherS(pom^.submenu=nil,'',#16),pd^.chrX-4)
      +eitherS(scroll,'',' '));
      if (pom^.flags and _rmiDisabled=0) and (pom^.stress>0)
      then pd^.WriXY(either(i=c1,$1A,$3A),1+pom^.stress,1+i,pom^.name[pom^.stress]);
     end
    else
     pd^.WriXY(either(i=c1,$10,$30),1,1+i,rep('Ä',pd^.chrX-2-byte(scroll)));
    if scroll and (i>0) and (i<c1max) then pd^.WriXY($70,pd^.chrX-2,i+1,_lista[1+byte(i=scrollpos+1)*3]);
    if i=c1 then WithStatusLineDo(_labShow,pom);
    pom:=pom^.next;
    inc(i);
   end;
  {cte a zpracuje udalost}
  pd^.FreshFull;
  HandleMouseEvents;
  case code(event) of
  kEsc: {vrati kod, ktery rika, ze byl stisknut Escape}
   begin
    RunWindow:=_rmCanceled;
    break;
   end;
  kUp,kDown,kPgUp,kPgDwn:
   CursorVertically(code(event) in [kDown,kPgDwn],either(code(event) in [kUp,kDown],1,pd^.chrY-2));
  kLeft:
   begin
    RunWindow:=_rmLeft;
    break;
   end;
  kRight:
   begin
    pom:=firstitem;
    i:=0;
    if c1+c2>0 then
     for i:=0 to c2+c1-1 do
      if pom<>nil then pom:=pom^.next; {* else chyba-narazil na nil;}
    with pom^ do
    if (flags and _rmiDisabled=0) then
     if (pom^.submenu<>nil) then
      begin
       i:=RunWindow(submenu);
       if (word(i)<>_rmCanceled) and (word(i)<>_rmLeft) then
        begin
         RunWindow:=i;
         break;
        end;
      end
     else
      begin
       RunWindow:=_rmRight;
       break;
      end;
   end;
  kHome:
   begin
    c1:=0;
    c2:=0;
   end;
  kEnd:
   begin
    c1:=c1max;
    c2:=c2max;
   end;
  kEnter: {vyber polozky}
   begin
    pom:=firstitem;
    i:=0;
    if c1+c2>0 then
     for i:=0 to c2+c1-1 do
      if pom<>nil then pom:=pom^.next; {* else chyba-narazil na nil;}
    with pom^ do
    if flags and _rmiDisabled=0 then
     begin
      if submenu<>nil then
       begin
        i:=RunWindow(submenu);
        if word(i)<>_rmCanceled then {*bude-li se upravovat navratovy typ funkce..}
         begin
          RunWindow:=i;
          break;
         end;
       end
      else
       begin
        RunWindow:=command;
        if flags and _rmiAutoTick<>0 then flags:=flags xor _rmiTick; {pripadne zameni zaskrtnuti}
        break;
       end;
     end;
   end;
  end;
  if char(event) in ['!'..'~'] then
   begin
    pom:=firstitem; i:=0;
    while pom<>nil do
     with pom^ do
     if (stress>0) and (upcase(name[stress])=upcase(char(event))) then
      begin
       RunWindow:=command;
       i:=1;
       break;
      end
     else
      pom:=pom^.next;
    if i=1 then break;
   end;
 until false;
 WithStatusLineDo(_labDone,nil);
 dispose(pd,done);
end;  {TRolMenu.RunWindow}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  TRolMenu.WithLabelsDo(command:byte):integer;
var
 pom:PMenuWindow;
 err:TError;
begin {TRolMenu.WithLabelsDo}
 pom:=root;
 if command and _labInit<>0 then
  while pom<>nil do
   begin
    if length(pom^.name)=0 then pom^.pdi:=nil
    else
     begin
      new(pom^.pdi,init(length(pom^.name)+2,1,nil,0,err));
      if (err<>erOk) or (pom^.pdi=nil) then
       begin
        ReportErr(_(_erDialogBig)); {*mas tam vubec hlasku "nemohl jsem otevrit dialogove okno!"?}
        exit;
       end;
     end;
    pom:=pom^.next;
   end;
 pom:=root;
 if command and _labShow<>0 then
  while pom<>nil do
   with pom^ do
   begin
    pdi^.x1:=(x+relx)*pdi^.mulX;
    pdi^.y1:=(y+rely)*pdi^.mulY;
    if name<>'' then
     begin
      pdi^.wriXY(either(pom=default,$20,$70),0,0,' '+name+' ');
      if stress>0 then pdi^.wriXY(either(pom=default,$24,$74),stress,0,name[stress]);
      pdi^.freshfull;
     end;
    pom:=pom^.next;
   end;
 pom:=root;
 if command and _labDone<>0 then
  while pom<>nil do
   begin
    if pom^.pdi<>nil then
     dispose(pom^.pdi,done);
    pom:=pom^.next;
   end;
end;  {TRolMenu.WithLabelsDo}

procedure xxx();
procedure PlaceStatus(var sir,vys:word;maxsir,maxvys,bp:word);
begin {PlaceStatus}
 vys:=1;
 sir:=maxsir div 10;{a-musi se shodovat s {b}
 with status do
 begin {** NASLEDUJICI KOD PASCAL NAPROSTO IGNORUJE!}
  maxw:=sir;
  x:=0;
  y:=maxvys-1;
 end;
end;  {PlaceStatus}
begin
 newDialog(pds,0,0,@PlaceStatus);
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure TRolMenu.WithStatusLineDo(command:byte;item:PMenuItem);
begin {TRolMenu.WithStatusLineDo}
 if command and _labInit<>0 then
  begin
   xxx;
   if pds<>nil then
    with pds^ do
    begin
{     x1:=status.x*mulX;
     y1:=status.y*mulY;}
    end;
  end;
 if command and _labShow<>0 then
  if (pds<>nil) and (item<>nil) then
   begin
    pds^.WriXY($70,0,0,Left(pc2str(item^.help),{status.maxw}8));
    pds^.FreshFull;
   end;
 if command and _labDone<>0 then
  if pds<>nil then
   begin
    Dispose(pds,done);
    pds:=nil;
   end;
end;  {TRolMenu.WithStatusLineDo}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  TRolMenu.Run:integer;
var
 i:integer;
 pom:PMenuWindow;
begin {TRolMenu.Run}
 if root=nil then exit;
 repeat
  WithLabelsDo(_labShow);
  i:=runWindow(default);
  Run:=i;
  if i=_rmLeft then
    if default=root then
     while default^.next<>nil do default:=default^.next
    else
     begin
      pom:=default;
      default:=root;
      while default^.next<>pom do default:=default^.next;
     end
   else
  if i=_rmRight then
   begin
    default:=default^.next;
    if default=nil then default:=root;
   end;
 until (i<>_rmLeft) and (i<>_rmRight);
end;  {TRolMenu.Run}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure DisposeMenuItem(var mi:PMenuItem);
begin {DisposeMenuItem}
 with mi^ do
 if submenu<>nil then DisposeMenuWindow(PMenuWindow(submenu));
 dispose(mi);
 mi:=nil;
end;  {DisposeMenuItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure DisposeMenuWindow(var mw:PMenuWindow);
var pom:PMenuItem;
begin {DisposeMenuWindow}
 with mw^ do
  {nejdriv musi zrusit polozky a potom cele okno}
  while firstitem<>nil do
   begin
    pom:=firstitem;
    firstitem:=firstitem^.next;
    DisposeMenuItem(pom);
   end;
end;  {DisposeMenuWindow}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  TRolMenu.GodWishes:boolean;
begin {TRolMenu.GodWishes}
 inc(god);
 if god=godmax then
  begin
   god:=0;
   GodWishes:=true;
  end
 else GodWishes:=false;
end;  {TRolMenu.GodWishes}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Destructor TRolMenu.Done;
var pom:PMenuWindow;
begin {TRolMenu.Done}
 {zrusi cele menu}
 while root<>nil do
  begin
   pom:=root;
   root:=root^.next;
   DisposeMenuWindow(pom);
  end;
end;  {TRolMenu.Done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION newMenuItem(_name:string20;{_help:string;}
         _stress:byte;_keyseq:string10;_key:byte;_command:longint;_flags:word;
         _help:string80;_submenu:PMenuWindow;_next:PMenuItem):PMenuItem;
var vysledek:PMenuItem;
begin {newMenuItem}
 vysledek:=nil;
 new(vysledek);
 if vysledek<>nil then
  with vysledek^ do
  begin
   name:=_name;
   help:=StrNewStr(_help);
   stress:=_stress;
   keyseq:=_keyseq;
   key:=_key;
   command:=_command;
   flags:=_flags;
   submenu:=_submenu;
   next:=_next;
  end
 else
  ReportErr(_(erLowMem));
 newMenuItem:=vysledek;
end;  {newMenuItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 rolmenuGlobalX:integer=0;
 rolmenuGlobalY:integer=0;
 rolmenuGlobalNewLine:byte=40;
FUNCTION newMenuWindow(_name:string20;_stress,_w,_h:byte;_relx,_rely:integer;
         _firstitem:PMenuItem;_next:PMenuWindow):PMenuWindow;
var vysledek:PMenuWindow;
begin {newMenuWindow}
 vysledek:=nil;
 new(vysledek);
 if vysledek<>nil then
  with vysledek^ do
  begin
   name:=_name;
   stress:=_stress;
   w:=_w;
   h:=_h;
   relx:=_relx;
   rely:=_rely;
   c1:=0;
   c2:=0;
   flags:=0;
   firstitem:=_firstitem;
   next:=_next;
   if (relx=0) and (rely=0) then
    begin
     inc(rolmenuGlobalX,length(_name)+byte(_name<>'') shl 1);
     if rolmenuGlobalX>=rolmenuGlobalNewLine then
      begin
       inc(rolmenuGlobalY);
       rolmenuGlobalX:=0;
      end;
     relx:=rolmenuGlobalX;
     rely:=rolmenuGlobalY;
    end;
  end
 else
  ReportErr(_(erLowMem));
 newMenuWindow:=vysledek;
end;  {newMenuWindow}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dlgRolMenu:integer; {pozdeji zmenit hlavicku na (_root:PMenuWindow)}
var
 menu:PRolMenu;
begin {dlgRolMenu}
 rolmenuGlobalX:=0;
 rolmenuGlobalY:=0;
 new(menu,
     init(newMenuWindow('File',1,10,6,0,0,
                        newMenuItem('New',1,'',5,6,254,'vytvo©¡ nov˜',nil,
                        newMenuItem('Save',1,'F2',7,8,15,'ulo‘¡',nil,
                        newMenuItem('Save as',6,'',7,8,16,'',nil,
                        newMenuItem('',0,'',7,8,16,'',nil,
                        newMenuItem('Change dir',1,'',7,8,16,'zmˆn¡',nil,
                        newMenuItem('Print',1,'',7,8,16,'',nil,
                        newMenuItem('Open..',1,'F3',9,10,254,'otev©e',
                                    newMenuWindow('',0,20,20,1,1,
                                                  newMenuItem('Your mind',6,'',11,12,0,'',nil,nil)
                                                 ,nil
                                                 )
                                   ,nil
                                   ))))))),
         newMenuWindow('Edit',1,8,2,0,0,
                        newMenuItem('Undo',1,'Alt+BkSp',7,8,16,'zpˆt',nil,
                        newMenuItem('Redo',1,'',7,8,16,'',nil
                                   ,nil
                                   ))
                       ,nil))
         ,0,0,28)
    );
 with menu^ do
 begin
  WithLabelsDo(_labInit);
  if default=nil then default:=root;
  dlgRolMenu:=Run;
 end;
 dispose(menu,done);
end;  {dlgRolMenu}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{þ momentalne se potim s nazvama oken menu
 TO DO:
 þ vyber z nazvu oken (jako po F10 v Pascalu)
 þ metoda Run
*  - vysvicovani nazvu u oken
     - flag pro viditelne a schovavatelne menu (sakra, co to je?)
 þ v metode RunWindow
*   - vyber polozky pres zvyraznene pismeno
   - ovladani mysi - MouseEvents
 þ v objektu udelat metody pro:
   - pridani polozky do specifikovaneho okna menu
   - ubrani polozky z okna nabidky
#þ status line (pracuje se na tom)
 þ zobecnit barvy
 þ projit vsechny {*

 ß viz problem s {**
 ß menu o dvou oknech plus 20tiznakovej status uz je problem pro pamet
 ß pri vstupu do submenu se "posasi" statuslajna}
vyresena chyba
