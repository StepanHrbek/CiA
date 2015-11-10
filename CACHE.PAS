{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.50ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Cache;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects;
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                                 Cache
---------------------------------------------------------------------------

Filosofie je tato.
Kdyz pozadujes nejaky objekt, vytvoris 'identifikator' toho co chces
a zavolas cache. Ta hledany objekt bud hned najde ve svem seznamu
nebo ho necha vytvorit metodou identifikatoru. Az ti objekt doslouzi,
zahodis ho zpatky do cache. Tam zustane lezet do prvniho nedostatku pameti.

Jak sis jiste vsiml, klicem ke vsemu je 'identifikator'. Je to potomek
zde zavedeneho objektu TCacheId. V jeho dvou metodach musis
naprogramovat vytvoreni objektu a porovnani dou identifikatoru.

Ukazka pouziti je v unite fonty, funkce caFontGet.


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
 memory.pas .. InitMemory, HeapNotify
 memo.pas   .. UserInit, NewHeapError, UserDone
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


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}

{---------------------------------------------------------------------------
 Nekolik kousku zkopirovanych z jinych unit za ucelem snizeni poctu
 unit v uses.
 ---------------------------------------------------------------------------}
  FUNCTION MaxI(x,y:integer):integer;inline($58/$5b/$3b/$d8/$7e/$01/$93);


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
   if thing=nil then begin KillObj(mycell);EXIT;end;{bad-objekt nejde vytvorit}
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

type
 THeapError=function(Size:Word):Integer;
var
 OldHeapError:pointer;
 OldHeapErrorFunc:THeapError absolute OldHeapError;

function NewHeapError(Size:Word):Integer;far;
begin
 if caMakeRoom then NewHeapError:=2 else
  if OldHeapError=nil then NewHeapError:=1 else
   NewHeapError:=MaxI(OldHeapErrorFunc(size),1{1 aby nikdy nehazel runtimy});
end;


{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='cache';
var result:integer;

procedure UserInit;
 begin
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