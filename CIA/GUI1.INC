{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{--------------------------------------------------------------------------
 Tuto cast je vyuzita pro objekty GUI dialogu.
 --------------------------------------------------------------------------}
var
 guiCommand: Word; { pouzito v objektu TGdiButton; vraci cislo prikazu
                     posledne stlaceneho tlacitka }
 guiIdle: TProc;   { je-li tato procedura definovana, je volana po kazdem
                     eventu. }
 guiEvent: TEvent; { event a pozice kurzoru mysi; urcene pro Idle procedurky }
 guiPos: TPoint;

{--------------------------------------------------------------------------
 Rodicovsky objekt vsech objektu GUI dialogu.
 --------------------------------------------------------------------------}
type
 PGuiObject = ^TGuiObject;
 TGuiObject = object(TObject)
   Active,             { je objekt aktivni (vybrany) ? }
   CanActive,          { muze byt aktivni }
   OldActive: Boolean;
   Id: Word;           { cislo objektu v kolekci, automaticky se prirazuje pri zobrazeni }
   constructor Init;
   procedure Draw; virtual;
   {- vykresleni objektu }
   procedure HandleEvent(var Event: TEvent); virtual;
   {- vykonova procedura objektu }
   procedure GetData(var Data); virtual;
   {- ulozi sve data, pokud nejake ma (! data objektu -> DATA !) }
   procedure SetData(var Data); virtual;
   {- nacte sve data, pokud nejake ma (! data objektu <- DATA !) }
   function DataSize: Word; virtual;
   {- vrati velikost dat }
 end;

{--------------------------------------------------------------------------
 Definice jednotlivych objektu.
 --------------------------------------------------------------------------}

{ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ TGuiText ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ}
{ obycejny text, ktery nejde vybrat }

 PGuiText = ^TGuiText;
 TGuiText = object(TGuiObject)
   X,Y: Integer; { pozice }
   Attr: Byte;   { atribut }
   Txt: String;  { zobrazeny text }
   constructor Init(aX,aY: Integer; S: String; aAttr: Byte);
   procedure Draw; virtual;
 end;

{ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ TGuiCheck ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ}
{ klasicky check box }

 PGuiCheck = ^TGuiCheck;
 TGuiCheck = object(TGuiObject)
   Checked: Boolean; { je zaskrtly? }
   X,Y: Byte;        { pozice }
   Txt: String;      { popisek }
   constructor Init(aX,aY: Integer; S: String; aChecked: Boolean);
   procedure Draw; virtual;
   procedure HandleEvent(var Event: TEvent); virtual;
   procedure GetData(var Data); virtual;
   procedure SetData(var Data); virtual;
   function DataSize: Word; virtual;
 end;

{ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ TGuiHorizScroll ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ}
{ horizontalni scrol bar na zmenu hlasitosti ci jinych veci }

 PGuiHorizScroll = ^TGuiHorizScroll;
 TGuiHorizScroll = object(TGuiObject)
   X,Y,Sirka: Byte;  { pozice objektu }
   Value: Byte;      { pozice posuvniku v rozmezi 1..Sirka }
   constructor Init(aX,aY,aSirka: Byte; aValue: Byte);
   procedure Draw; virtual;
   procedure HandleEvent(var Event: TEvent); virtual;
   procedure GetData(var Data); virtual;
   procedure SetData(var Data); virtual;
   function DataSize: Word; virtual;
 end;

{ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ TGuiButton ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ}
{ obycejne tlacitko }

 PGuiButton = ^TGuiButton;
 TGuiButton = object(TGuiObject)
   X,Y,Sirka: Byte; { pozice objektu }
   Txt: String;     { popisek }
   Command: Word;   { cislo prikazu, ktery se da do guiCommand }
   Ev: TEvent;      { tento event vlozi do fronty eventu pri stisku tlacitka }
   Downed: Boolean; { je tlacitko stisknute ? }
   constructor Init(aX,aY,aSirka: Byte; S: String; aEvent: TEvent; aCommand: Word);
   procedure Draw; virtual;
   procedure HandleEvent(var Event: TEvent); virtual;
 end;

{ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ TGuiPicture ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ}
{ obrazek; v textmodu se nic nezobrazi }
{ Upozorneni: Obrazek se pri ukonceni GUI dialogu necha v pameti. }
{ Pozn.: Kdyz date do aResizeX a/nebo do aResizeY hodnotu -1 tak se obrazek
         v dotycne ose neroztahne. }

 PGuiPicture = ^TGuiPicture;
 TGuiPicture = object(TGuiObject)
   Pic: PBitMap;             { obrazek }
   X,Y: Byte;                { pozice ve znacich }
   ResizeX,ResizeY: Integer; { velikost obrazku }
   constructor Init(aX,aY: Byte; aResizeX,aResizeY: Integer; aPic: PBitMap);
   procedure Draw; virtual;
 end;

{ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ TGuiInputLine ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ}
{ input line pro psani textu }

 PGuiInputLine = ^TGuiInputLine;
 TGuiInputLine = object(TGuiObject)
   X,Y,Sirka,MaxSirka,Cursor,Scroll: Byte; { pozice objektu, kurzoru, scrollu}
   Txt: String;         { popisek }
   Prvni: Boolean; { je prvni ze vsech objektu co pouzivaji kurzor? }
   constructor Init(aX,aY,aSirka,aMaxSirka: Byte; aTxt: String; aPrvni: Boolean);
   procedure Draw; virtual;
   procedure HandleEvent(var Event: TEvent); virtual;
   procedure GetData(var Data); virtual;
   procedure SetData(var Data); virtual;
   function DataSize: Word; virtual;
 end;

function dlgGUI(Sirka,Vyska: Byte; var P: PCollection; var Data; IdleProc: TProc):word;
{- hlavni funkce }
