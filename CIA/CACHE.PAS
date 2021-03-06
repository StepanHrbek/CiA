{旼컴C.I.A.컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴훩erze 2.00컴커
 쿞 timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi�
 퀆 dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.�
 읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�}

Unit      Cache;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects, Stringy;
Function  Init:TError;
Procedure Done;

{
---------------------------------------------------------------------------
                                 Cache
---------------------------------------------------------------------------

TEORIE

 Pro cachovani objektu se nabizeji dve koncepce.
 Nejprve ale co maji spolecne.

 1. Musi existovat jednoznacny identifikator objektu ktery zadame.
    V nejtrivialnejsim pripade je to jmeno souboru,
    ve slozitejsim treba soubor a nejake parametry.
 2. Nekdo musi vedet kolikrat je objekt v obehu aby ho system mohl
    zrusit ve chvili kdy ho nikdo nepouziva a dojde pamet.

 Ted ony koncepce.

 A. Kazdy cachovatelny objekt ponese svuj 'identifikator' a 'pocet zivotu'.
 B. Objekty zustanou beze zmen, tyto udaje budou ulozeny kdesi stranou.

 Protoze koncepce A plytva pameti (necachovane objekty zbytecne obsahuji tyto
 atributy), CiA pouziva efektivnejsi B.


PRAXE S POCHOPENIM (abys mohl cachovat vlastni objekty)

 Kdyz pozadujes nejaky objekt, vytvoris identifikator toho co chces
 a zavolas cache. Ta hledany objekt bud hned najde ve svem seznamu
 nebo ho necha vytvorit metodou identifikatoru. Az ti objekt doslouzi,
 zahodis ho zpatky do cache. Tam zustane lezet do prvniho nedostatku pameti.

 Jak sis jiste vsiml, klicem ke vsemu je 'identifikator'. Je to potomek
 zde zavedeneho objektu TCacheId. V jeho dvou metodach musis
 naprogramovat vytvoreni objektu a porovnani dvou identifikatoru.

 Ukazky pouziti jsou v unitach fonty a loadery.


PRAXE BEZ NUTNOSTI POCHOPENI

 Podivej se na funkce cacheGetFont/cacheGetPic v unitach fonty/loadery.
 Funkcim predas jmeno souboru s fontem nebo obrazku a ony ti vrati
 hotovy nahrany objekt.
 Ten pak nesmis menit a az ho nebudes chtit, zahodis ho funkci caLeave.


---------------------------------------------------------------------------
                                HeapError
---------------------------------------------------------------------------

Cti jen pokud pouzivas unitu Memory (resp.cokoliv z TurboVision).

Pri nedostatku pameti vola pascal pointer HeapError. Tato unita nasmeruje
HeapError na sebe, ale zapamatuje si puvodni stav a po skonceni vse vrati
do puvodniho stavu. Ne tak slusne jsou TurboVision, ktere zmenou pointeru
zcela zlikviduji puvodni obsluhu chyb a to natrvalo. Proto si pred volanim
(resp.po volani) TurboVision stav HeapErroru zapamatuj (resp.obnov).
Pro lepsi orientaci se muzes podivat na mista kde je HeapError pouzit:
 memory.pas .. InitMemory, HeapNotify (Borlandi unita)
 memo.pas   .. GetMem
 cache.pas  .. UserInit, NewHeapError, UserDone
}

Type
 {identifikator cachovaneho objektu}
 PCacheId = ^TCacheId;
 TCacheId = object(TObject)
   function    Compare(id:PCacheId):boolean;virtual;
   function    Load:PObject;virtual;
 end;

Function  caGet(id:PCacheId;priority:integer):PObject;
Procedure caLeave(var p);{p musi byt PObject nebo potomek}
Function  caMakeRoom:boolean;far;
Procedure caFreeAllBelow(priority:integer);

var debugC:boolean;
var caching:boolean; {je cache zapnuta?}


{賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽賽�}
                          IMPLEMENTATION
{複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複複�}


Type
 {jedna polozka v cache}
 PCacheCell = ^TCacheCell;
 TCacheCell = object(TObject)
   thing      :PObject;
   identif    :PCacheId;
   fixes      :word;
   prior      :integer;
   destructor  Done;virtual;
 end;

{---------------------------------------------------------------------
 Porovna dva identifikatory.
 Implicitni porovnani je bajt po bajtu.
 ---------------------------------------------------------------------}
Function TCacheId.Compare(id:PCacheId):boolean;
begin
 Compare:=(sizeof(self)=sizeof(id^)) and CmpBlock(@self,id,sizeof(self));
end;

{---------------------------------------------------------------------
 Nahraje objekt prislusny identifikatoru.
 ---------------------------------------------------------------------}
Function TCacheId.Load:PObject;
begin
 Abstract;
end;

{---------------------------------------------------------------------
 Zrusi bunku cache.
 ---------------------------------------------------------------------}
Destructor TCacheCell.Done;
begin
 {$ifdef beta}
 if fixes<>0 then ReportErr('Killing '+stri(fixes)+'x used cache cell.');
 {$endif}
 KillObj(thing);
 KillObj(identif);
 inherited Done;
end;


Var
 caList:TCollection;

{---------------------------------------------------------------------
 Vraci objekt prislusny identifikatoru (nahrava ho jen pokud neni v cache).
 Puvodne jsem chtel mit prvni parametr "var id", ale to by znemoznilo
  volat caGet(New(PCacheId,Init),priority).
 Takze pocitej s tim, ze kdyz neuspeje=vrati nil, id je killnute.
 ---------------------------------------------------------------------}
Function caGet(id:PCacheId;priority:integer):PObject;
var   mycell:PCacheCell;
 function CompareIdsOk(Item:PCacheCell):boolean;far;
 begin
  CompareIdsOk:={(typeof(Item^.identif^)=typeof(id^))
                     and} Item^.identif^.Compare(id);
 end;
begin
 caGet:=nil;
 if id=nil then EXIT;{bad-nedostal jsem identifikator}
 if not caching then begin
   caGet:=id^.Load;
   KillObj(id);
   EXIT;{no caching}
   end;
 mycell:=caList.FirstThat(@CompareIdsOk);
 if mycell<>nil then
  with mycell^ do begin
   KillObj(id);{mam dva stejny identifikatory tak jeden killnu}
   caGet:=thing;
   inc(fixes);
   EXIT;{ok-objekt nalezen v cache}
   end;
 New(mycell,Init);
 if mycell=nil then begin KillObj(id);EXIT;end;{bad-malo pameti na mycell}
 with mycell^ do begin
   identif:=id;
   fixes:=1;
   prior:=priority;
   thing:=id^.Load;
   if thing=nil then begin fixes:=0;KillObj(mycell);EXIT;end;{bad-objekt nejde vytvorit}
   end;
 {prodlouzi caList - behem toho se muze neco z calistu uvolnit}
 if caList.count+10>caList.limit then caList.SetLimit(caList.count+100);
 {insertne 1 polozku - behem toho se urcite prodluzovat nebude}
 caList.Insert(mycell);
 caGet:=mycell^.thing;
 {ok-objekt vytvoren}
end;

{---------------------------------------------------------------------
 Timto ohlasujes ze se objektu zrikas.
 (dokud je dost pameti, zustane v cache)
 ---------------------------------------------------------------------}
Procedure caLeave(var p);
var   thing:PObject absolute p;
      mycell:PCacheCell;
 function CompareThingsOk(Item:PCacheCell):boolean;far;
 begin
  CompareThingsOk:=Item^.thing=thing;
 end;
begin
 if thing<>nil then begin
  mycell:=caList.FirstThat(@CompareThingsOk);
  if mycell<>nil
   then begin dec(mycell^.fixes);thing:=nil;end
   else KillObj(thing);
  end;
end;

{---------------------------------------------------------------------
 Pozadavek na uvolneni pameti, vyhodi objekt s nejnizsi prioritou.
 ---------------------------------------------------------------------}
Function caMakeRoom:boolean;
var minpr:integer;
    mince:PCacheCell;
 procedure TestPriority(Cell:PCacheCell);far;
 begin
  if (Cell^.fixes=0) and (Cell^.prior<minpr) then
   begin
    minpr:=Cell^.prior;
    mince:=Cell;
   end;
 end;
begin
 minpr:=32767;
 caList.ForEach(@TestPriority);
 if minpr<32767 then caList.Free(mince);
 caMakeRoom:=minpr<32767;
end;

{---------------------------------------------------------------------
 Uvolni vse s prioritou mensi nez zadanou.
 ---------------------------------------------------------------------}
Procedure caFreeAllBelow(priority:integer);
var i:integer;
begin
 if caList.count>0 then
  for i:=caList.Count-1 downto 0 do
   with PCacheCell(caList.At(i))^ do
    if (fixes=0) and (prior<priority) then caList.Free(caList.At(i));
end;

{---------------------------------------------------------------------
 HeapError volajici MakeRoom.
 ---------------------------------------------------------------------}
type
 THeapError=function(Size:Word):Integer;
var
 OldHeapError:pointer;
 OldHeapErrorFunc:THeapError absolute OldHeapError;

function NewHeapError(Size:Word):Integer;far;
begin
 if caMakeRoom then NewHeapError:=2 else
  if OldHeapError=nil then NewHeapError:=0 else
   NewHeapError:=OldHeapErrorFunc(size);
end;


{같같같같같같같같같같같같같같같같INIT/DONE같같같같같같같같같같같같같같같같같�}

const unita='cache';
var result:TError;

procedure UserInit;
 begin
  debugC:=false;
  caching:=true;
  if caList.Init(100,100) then begin
    OldHeapError:=HeapError;
    HeapError:=@NewHeapError;
    MakeRoom:=caMakeRoom;
    exit;
    end;
  result:=erLowMem;
 end;

procedure UserDone;
 begin
  caList.Done;
  HeapError:=OldHeapError;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.