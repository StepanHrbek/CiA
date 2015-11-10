{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.50ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Vga;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects,Dos, Stringy,Sys,Mys,Fajly{$ifdef dpmi},Dpmi{$endif};
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                            Uvod k VGA
---------------------------------------------------------------------------

Unita pro praci s 256color mody a textmody, vga i svga.

Pridat podporu hicolor a truecolor by nemel byt problem, bude-li to treba.
Staci dopsat bitblt operace a psani fontem, nakreslit sipku mysi.
Kdyz se ted pokusis nastavit hicolor/truecolor mod, selze na tom,
ze nema nakreslenou sipku mysi :)

Jako prvni akci v hlavnim programu doporucuji overit pritomnost VGA karty
funkci IsVga. Mimo VGA karty neni unita prilis pouzitelna.
Budes-li tvrde vyzadovat Vesa Bios, hned pote se podivej na promennou
VesaVersion, ta udava zjistenou verzi VESA BIOSu, 0=zadna.

Pri prohlizeni interface narazis na skupiny funkci zacinajich predponami:
 vga_    pracuji primo s vga registry, nemusi fungovat pod vesa biosem
 bios_   pracuji s vga biosem, vyjimecne se stava ze nefunguji pod vesa biosem

Objekt ˛TAbstractMap˛ je vychozi objekt pro vsechny mozne druhy 2d poli
pixelu. Pres virtualni metody umoznuje blokove presuny (tzv BitBlt)
mezi sebou a bitmapou a vyplne bloku jednou barvou.
Nazvy metod maji tvar Odkud2Kam, kde Odkud a Kam jsou z techto moznosti:

 Box  - obdelnikovy vyrez z objektu SELF (self nemusi byt bitmapa)
 Ful  - cely objekt SELF (odpada zadavani vyrezu)

 BtB  - bitmap box - obdelnikovy vyrez BITMAPY ZADANE PARAMETREM
 BtF  - bitmap full - cela BITMAPA ZADANA PARAMETREM (odpada zadavani vyrezu)

 Clr  - PRAZDNA PLOCHA (vyplnena barvou nula nebo znakem mezera)
 Col  - JEDNOBAREVNA PLOCHA (vyplnena zadanou barvou nebo znakem)

 Resize (predpona pred nazvem) - behem operace se blok zvetsuje/zmensuje

Objekt ˛TBitmap˛, potomek AbstractMapy, je bitmapa v systemove pameti.
V realmodu je pro bitmapy k dispozici pouze konvencni pamet, proto je
pri pouziti vetsich bitmap nutny protekt.

Objekt ˛TScreen˛, potomek AbstractMapy, je videopamet/obrazovka.
Inicializaci instance TScreen nastavis textovy/graficky mod,
uvolnenim instance vratis predchozi mod.


---
Pro low-level kutily, CRTC nemusi byt ve VESA modech fit (ATI MACH64).
Vyznamnejsi procedury pracujici s CRTC jsou tedy opatreny komentarem
've vesa modech nemusi fungovat'. Podobnym ucelum by mel slouzit
VESA BIOSem nabizeny flag registrove_kompatibilni_s_vga, ale prave kriticke
BIOSy ho ignoruji.

Pro hardcore VBE maniaky, unita NEvyuziva tyto moznosti nekterych karet:
 -granularita<>64K (emuluje 64KB banky)
 -nezavisle bankovani pro cteni a pro zapis (bankuje obe okna synchronne)
 -linearni adresace
 -moznost velikosti banku <> 64KB neni osetrena, ale btw 32K v textmodu projde
 -unita NIKDY nereaguje v zavislosti na nazvu vesa biosu (nektere biosy jsou
  znamy svymi chybami), pripadne detekce chyb jsou ciste, univerzalni
 -unita v textmodu nestrankuje (btw, kdybys moc chtel, doplnit strankovani je
  problem tak na 10 instrukci)

Rutiny funguji i na vice ci mene exotickych kartach, ktere
 -nesnesou nastavovani idexovanych vga registru pres out dx,ax
 -nesnesou nastavovani palety pres rep outsb

ResList je seznam nekterych podporovanych modu. K cemu je dobry?
 1) Pri nastavovani modu muzes zadat jen rozliseni a model, nastavi se
    nejblizsi mod z ResListu. Mody ktere nejdou nastavit se z ResListu smazou.
 2) V ResListu se pro kazdy mod ukladaji nektere udaje namerene pri jeho
    prvnim nastaveni, pri dalsich nastavenich se usetri cas.
Pozor, treba mod 320x200/256 lze mit na tri zpusoby: vga packed, vga unchained
a vesa packed. Co s tim? Do reslistu se zaradi jen jeden, prvni ktery prijde
na radu. Poradi zarazovani je toto: vesa mody, vga unchained, vga packed.
Nastavovat lze i mody nezarazene v ResListu, viz TScreen.Init.

---
Pri kazdem nastaveni textmodu se zavola uzivatelska procedura UserFont,
ktera unite rekne jaky font ma pouzit. Defaultne je volen ROM font,
ale muzes to zmenit, dalsi komentar je u dalsich vyskytu UserFont.
---

Projekt FLOW (vsechny identifikatory obsahujici slovo flow)
je hotov asi z 5% a vyvoj je zastaven (pokracuju v C++, knihovna FBI).
Jediny viditelnejsi prinos je ten, ze kazdy potomek TAbstractMap
 s implementovanymi virtualnimi metodami flowSet a flowNext muze
 byt nevirtualni metodou Store nebo Save ulozen do .TGA souboru.
 256barevne obrazky s vice lokalnimi paletami se ukladaji jako truecolor.

Poradi procedur a funkci v implementation neni moc logicke, sorry.
Je to kvuli mnozstvi vzajemnych odkazu, nechci psat kopec forwardu.
}




{---------------------------------------------------------------------------
 Modely ulozeni pixelu ve videopameti.
 ---------------------------------------------------------------------------}

CONST model_text             =0;             {pametove modely}
      model_cga              =1;             {cislovani podle standardu VESA}
      model_hercules         =2;
      model_ega              =3;
      model_packed           =4;             {obvykle 256bar. mody a 16 bar. mody 2 PixelsPerByte w/o planes}
                                             {nektere karty (ARK Logic) pouzivaji model_packed i u HC/TC!}
      model_unchained        =5;
      model_direct           =6;             {obecne libovolny Hi/TrueColor mod}
      model_yuv              =7;

      model_BGR15            =16;            {Nase vlastni oznaceni}
      model_RGB15            =17;            {pro rozliseni model_direct}
      model_BGR16            =18;
      model_RGB16            =19;
      model_BGR24            =20;
      model_RGB24            =21;
      model_BGRA32           =22;

      model_256              =255;           {Pouzivat jen pri nastavovani modu.
                                              Sam se rozhodne zda nastavi packed nebo unchained.}


{---------------------------------------------------------------------------
 Seznam podporovanych modu.
 ---------------------------------------------------------------------------}

      T80x25                 =25;            {textove VGA mody}
      T80x26                 =26;            {cislovani podle poctu radek}
      T80x28                 =28;
      T80x30                 =30;
      T80x33                 =33;
      T80x36                 =36;
      T80x40                 =40;
      T80x44                 =44;
      T80x50                 =50;

      T80x60                 =$108;          {textove SVGA mody}
      T132x25                =$109;          {cislovani podle standardu VESA}
      T132x43                =$10a;
      T132x50                =$10b;
      T132x60                =$10c;

      X320x200               =1;             {graficke 256color VGA Xmody}
      X320x240               =2;             {pro modely unchained i packed}
      X360x200               =3;
      X360x240               =4;
      X376x282               =5;
      X320x400               =6;
      X320x480               =7;
      X360x400               =8;
      X360x480               =9;
      X360x360               =10;
      X376x308               =11;
      X256x200               =12;
      X256x240               =13;
      X256x224               =14;
      X256x256               =15;
      X360x270               =16;
      X400x300               =17;
      X256x400               =18;
      X256x480               =19;
      X360x464               =20;

      P640x400               =$100;          {graficke 256color SVGA mody}
      P640x480               =$101;          {cislovani podle standardu VESA}
      P800x600               =$103;
      P1024x768              =$105;
      P1280x1024             =$107;

      HC15_320x200           =$10d;          {graficke SVGA mody, HiColor 15Bit, 32768 barev}
      HC15_640x480           =$110;          {cislovani podle standardu VESA}
      HC15_800x600           =$113;
      HC15_1024x768          =$116;
      HC15_1280x1024         =$119;

      HC16_320x200           =$10e;          {graficke SVGA mody, HiColor 16Bit, 65536 barev}
      HC16_640x480           =$111;          {cislovani podle standardu VESA}
      HC16_800x600           =$114;
      HC16_1024x768          =$117;
      HC16_1280x1024         =$11a;

      TC320x200              =$10f;          {graficke SVGA mody, TrueColor 24Bit, 16 777 216 barev}
      TC640x480              =$112;          {cislovani podle standardu VESA}
      TC800x600              =$115;
      TC1024x768             =$118;
      TC1280x1024            =$11b;



{---------------------------------------------------------------------------
 Globalni promenne nezavisle na modu.
 ---------------------------------------------------------------------------}

var   VesaVersion        :word;{cislo verze vbe: 0, 100h, 101h, 102h, 200h...}
      VesaID             :string[70];{identifikator VBE, copyright autoru, velikost vram}
      VesaBanksTotal     :byte;{pocet 64KB banku celkem na karte}

      mouseSpeed         :word;{rychlost pohybu mysi}
                               {vic zrychlit uz jde jedine snizenim Mys.jumpX,Y}



{---------------------------------------------------------------------------
 VGA porty
 ---------------------------------------------------------------------------}

PROCEDURE OutDxAx;
FUNCTION  vga_ReadCrtc(ndx:byte):byte;
FUNCTION  vga_ReadCrtcW(ndx:byte):word;
PROCEDURE vga_WriteCrtc(ndx,val:byte);
FUNCTION  vga_HideCursor:boolean;
FUNCTION  vga_ShowCursor:boolean;
PROCEDURE vga_EnableSplitScrol(scrol:boolean);
PROCEDURE vga_EnableBlinking(blink:boolean);
FUNCTION  vga_GetLineOffset:byte;
PROCEDURE vga_SetLineOffset(n:byte);


{---------------------------------------------------------------------------
 Paleta: cteni, nastaveni, jas, fadingy
 ---------------------------------------------------------------------------}

PROCEDURE SetHwCol(col,r,g,b:byte);
PROCEDURE BlackHwPal;
FUNCTION  PalIsBlack:boolean;
PROCEDURE RandomPal;

Const
      {pfXXXX - pal flags}
      pfStill    =1;{je tato paleta stale na obrazovce? (pokryva celou bitmapu)}
      pfOnscreen =2;{je tato paleta momentalne na obrazovce?}
      pfActive   =4;{je tato paleta aktivni=reaguje na setbright?}

Type
      PBitmap=^TBitmap;
      PScreen=^TScreen;

      PPalBody=^TPalBody;
      TPalBody=array[0..767] of byte;

      PPalCollection=^TPalCollection;
      TPalCollection=TCollection;

      PPal = ^TPal;
      TPal = object(TObject)
          pal           :TPalBody;      {RGB paleta 256 barev, obsahuje hodnoty 0..63}
          darkcolor     :array[0..2] of byte;{barva ke ktere smeruje snizovani jasu}
          nowbright     :byte;          {aktualni jas}
          first         :byte;          {prvni zpracovavana barva}
          last          :byte;          {posledni zpracovavana barva}
          flags         :byte;          {viz pfXXXX}
          place         :TRect;         {sfera vlivu lokalni palety}
          constructor   Init;
          constructor   InitMore(aflags,fromcol,tocol:byte);
          procedure     Take(p:PPal);virtual;
          procedure     ReadFromTo(fromcol,tocol:byte);
          procedure     ShowFromTo(fromcol,tocol:byte);
          procedure     Show;
          procedure     SetBrightFromTo(n,fromcol,tocol:byte);
          procedure     SetBright(n:byte);
          procedure     SetCol(col,r,g,b:byte);
          procedure     Fade(time:integer);
          procedure     SmoothCols(fromcol,r1,g1,b1,tocol,r2,g2,b2:byte);
          procedure     SmoothBright(fromcol,tocol:byte;how:integer;er,ge,be:boolean);
          procedure     SmoothContrast1(fromcol,tocol,ofs:byte;how:integer);
          procedure     SmoothContrast(fromcol,tocol:byte;how:integer;er,ge,be:boolean);
          procedure     rgb2BGR;
          procedure     BGR2rgb;
         end;

      TPalAllocType = (paDead,paStatic,paDynamic);
      PPalAlloc = ^TPalAlloc;
      TPalAlloc = object(TPal)
          constructor Init;
          procedure   Setup(fromindex,toindex:byte;settype:TPalAllocType);
          procedure   Take(p:PPal);virtual;
          function    Alloc(r,g,b:shortint):byte;
          procedure   AllocTxt(attr:byte;var fore,back:byte);
          destructor  Done;virtual;
         private
          Indexes     :array[0..255] of TPalAllocType;
          Count       :array[paDead..paDynamic] of word;
          TxtCache    :array[0..15] of byte;
          function    CachedAllocTxt(attr:byte):byte;
        end;


{---------------------------------------------------------------------------
 Objekt AbstractMap
 ---------------------------------------------------------------------------}

      Pbyte=^byte;

      TLine=array[0..65534] of byte;      {jedna linka bitmapy}
      PLine=^Tline;
      TLines=array[0..16382] of PLine;    {pole pointeru na linky}
      PLines=^TLines;


      PAbstractMap=^TAbstractMap;
      TAbstractMap=object(TObject)

          MapModel      :byte;            {packed,text..}
          SizeX         :integer;         {rozmery v pixelech}
          SizeY         :integer;
          BiPP          :byte;            {bits per pixel}
          SizeXb        :integer;         {rozmer v bytech}

          constructor   Init(newmodel,newBiPP,sir,vys:word);

          {---PALETA---}
          function      MainPal:PPal;virtual;

          {---BITBLT---}
          {cisteni obsahu self}
          procedure     Clr2Box(destX,destY,Sirka,Vyska:word);
          procedure     Clr2Ful;
          {vypln self jednou barvou}
          procedure     Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);virtual;
          procedure     Col2Ful(pixel:longint);
          {bitmapa -> self}
          procedure     BtB2Box(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     BtB2Ful(p:PBitmap;srcX,srcY:word);
          procedure     BtF2Box(p:PBitmap;destX,destY:word);
          procedure     ResizeBtB2Box(p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);virtual;
          procedure     ResizeBtB2Ful(p:PBitmap;srcX,srcY,srcSir,srcVys:word);
          procedure     ResizeBtF2Box(p:PBitmap;destX,destY,destSir,destVys:word);
          procedure     ResizeBtF2Ful(p:PBitmap);
          {self -> bitmapa}
          procedure     Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     Ful2BtB(p:PBitmap;destX,destY:word);
          procedure     Box2BtF(p:PBitmap;srcX,srcY:word);
          procedure     ResizeBox2BtB(p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);virtual;
          procedure     ResizeFul2BtB(p:PBitmap;destX,destY,destSir,destVys:word);
          procedure     ResizeBox2BtF(p:PBitmap;srcX,srcY,srcSir,srcVys:word);
          procedure     ResizeFul2BtF(p:PBitmap);
          {kopirovani}
          function      BoxCopy(srcX,srcY,Sirka,Vyska:word):PBitmap;virtual;
          function      FulCopy:PBitmap;
          function      ResizeBoxCopy(srcX,srcY,srcSir,srcVys,destSir,destVys:word):PBitmap;virtual;
          function      ResizeFulCopy(destSir,destVys:word):PBitmap;
          {self -> abstraktni (jakakoliv) mapa}
          procedure     Box2Box(p:PAbstractMap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     Box2Ful(p:PAbstractMap;srcX,srcY:word);
          procedure     Ful2Box(p:PAbstractMap;destX,destY:word);

          {---FLOW---}
          procedure     flowSet(x,y:word);virtual;
          function      flowNext(var bytes:word):pointer;virtual;

          {---LOAD/SAVE---}
          {save -> TGA}
          public
          storeModel    :byte;
          procedure     Store(var s:TStream);
          procedure     Save(s:PStream);
         end;


      {umozni provadet flow operace s vyrezem jine TAbstractMap}
      TBoxFlow=object(TAbstractMap)
          constructor   Init(source:PAbstractMap;box:TRect);
          procedure     flowSet(x,y:word);virtual;
          function      flowNext(var bytes:word):pointer;virtual;
                        private
                         map           :PAbstractMap;{zdrojova mapa}
                         start         :TPoint;{absolutni pozice boxu v mape}
                         flowY         :word;{relativni flow uvnitr boxu}
                         zbyvabajtu    :integer;{kolik zbyva do konce radku}
         end;


      {zajisti behem flow operaci v TBitmap spravnou globalni paletu v MainPal}
      TMergePalsFlow=object(TAbstractMap)
          constructor   Init(source:PBitmap);
          function      MainPal:PPal;virtual;
          procedure     flowSet(x,y:word);virtual;
          function      flowNext(var bytes:word):pointer;virtual;
                        private
                         map           :PBitmap;{mapa}
                         globalpal     :TPal;{sem se generuje globalni paleta}
                         pixels2rebuild:longint;{po kolika pixelech obnovit globalpal}
                         flow          :TPoint;{flow uvnitr mapy}
                         zbyvabajtu    :integer;{kolik zbyva do konce radku}
         end;

{---------------------------------------------------------------------------
 Objekt Bitmap
 ---------------------------------------------------------------------------}

      TBitmap=object(TAbstractMap)

          transparent   :boolean;         {pruhledne pozadi?}
          tab           :PLines;          {tabulka radek bitmapy}
          tabsize       :integer;         {delka tab (tabsize>=sizeY), na kolik radek se muzes odkazovat}
          mapsize       :integer;         {delka map (tabsize>=mapsize), kolik radek ma naalokovanou vlastni pamet}

          constructor   Init(newmodel:byte;sir,vys:word);
          destructor    Done;virtual;

          procedure     DelLines(firstline,lines:word);
          function      InsLines(firstline,lines:word):boolean;
          function      AddLines(lines:word):boolean;

          procedure     StaticMem(p:pointer;size:word);
          procedure     StaticTex(p:pointer);
          procedure     StaticMap(map:PBitmap;srcX,srcY:word);

          procedure     Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);virtual;
          procedure     BtB2Box(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     ResizeBtB2Box(p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);virtual;
          procedure     ResizeBox2BtB(p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);virtual;
          function      BoxCopy(srcX,srcY,Sirka,Vyska:word):PBitmap;virtual;
          function      ResizeBoxCopy(srcX,srcY,srcSir,srcVys,destSir,destVys:word):PBitmap;virtual;

          procedure     flowSet(x,y:word);virtual;
          function      flowNext(var bytes:word):pointer;virtual;

          function      MainPal:PPal;virtual;
          procedure     SetBright(n:byte);
          procedure     Fade(time:integer);
          function      AddPal(pal:PPal):PPal;
{          function      AddPal(pal:PPal;aflags,fromcol,tocol:byte;x1,y1,x2,y2:word):PPal;}
          procedure     SyncPal(scr:TRect;onscreen:boolean);

                        private
                         static        :boolean;         {nema pamet pri done uvolnit?}
                         flow          :TPoint;          {pozice v bitmape}
                         pals          :PPalCollection;  {palety}
                        public
         end;


{---------------------------------------------------------------------------
 Objekt Screen
 ---------------------------------------------------------------------------}

      TSetModeResult=(chaos,stillold,alreadyset,newset);
      TBankRegs=word;
      TMousePoint=object(TPoint) z:integer; end;

      TScreen=object(TAbstractMap)

         {atributy obrazovky}
          ModeID             :word;    {cislo modu}
          VesaMode           :boolean; {jsem prave ve VESA modu?}
          Xres,Yres          :integer; {rozliseni obrazovky (v pixelech nebo znacich)}
          vramXres,vramYres  :integer; {rozmery videopameti (v pixelech nebo znacich)}
          charXres,charYres  :integer; {rozmery znaku v textovem modu, v grafice 1, musi mit sizeof=2}
          lineOffset         :integer; {o kolik zvysit adresu ve vram pri posunu na dalsi radek}
          SegVram            :word;    {segment okna do videopameti}
          WinSizeKB          :word;    {velikost okna do videopameti v kilobytech}
          VramSizeKB         :word;    {velikost videopameti pouzitelne v soucasnem modu v kilobytech, musi mit sizeof=2}
          BiosOutput         :boolean; {je podporovan biosoutput?}
          SetvisYBug         :shortint;{ma vesa bios bug v setvisu (adr=x+y*Xres misto x+y*vramXres)? 1=ano, 0=ne, -1=nevim}
          GotoYBug           :shortint;{je v biosovem GotoXY chyba (nepocita s vramXres<>Xres) ? 1=ano, 0=ne, -1=nevim}


         {nastaveni modu}
          InitResult         :TSetModeResult;{vysledek po nastaveni modu}
          forbid_alreadyset  :boolean; {InitResult pri pristim nastavovani modu nesmi byt alreadyset,}
                                       { tj. urcite smaze obrazovku, resetne split, vramXres, setvis }
          SilentDone         :boolean; {silent done nevraci predchozi mod}
          constructor        Init(newModel,newSir,newVys,newMode:word);
          procedure          ReInit;virtual;
          destructor         Done;virtual;
          function           IsVesamode(testModel:byte;testMode:word):boolean;
          procedure          LoadCfg;virtual;
          procedure          GetParentFrom(s:PScreen);

                             private
                              ZadanaVyskaZnaku   :byte;
                              PrevScreen         :PScreen;
                              PrevModel          :word;
                              PrevMode           :word;
                              function           SetMode_VESA(newModel:byte;newMode:word):boolean;
                              function           SetMode_TEXT(newMode:word):boolean;
                              function           SetMode_X(newModel:byte;newMode:word):boolean;
                              function           SetMode(newModel:byte;newMode:word):boolean;
                             public

         {bitblts}
          pen                :byte;    {zpusob interpretace souradnic nasledujicimi metodami, viz pen_XXXX}
          procedure          Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);virtual;
          procedure          BtB2Box(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure          Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          function           ExpandFul(expand:boolean):boolean;
          procedure          GetClipping(var rect:TRect);virtual;

                             private
                              VesaBanking        :boolean; {funguje v aktualnim modu a smim tedy pouzivat vesabanking?}
                              VesaNowBank        :word;    {momentalne nastaveny 64KB bank}
                              VesaGranularity    :word;    {granularita v KB, musi byt word}
                              VesaUseWinA        :boolean; {je nutne bankovat v okne A?}
                              VesaUseWinB        :boolean; {je nutne bankovat v okne B?}
                              function           DetectRetraceLen:boolean;
                              procedure          DetectVesaBanking;
                              procedure          DetectVesaSetvisSync;
                             public{*}
                              procedure          VesaSetBank(n:byte);
                              procedure          VesaIncBank;
                              procedure          VesaDecBank;
                             public

         {flow}
          procedure          flowSet(x,y:word);virtual;
          function           flowNext(var bytes:word):pointer;virtual;

                             private
                              flowAdr            :longint; {pozice v bitmape}
                             public

         {paleta}
          procedure          Fade(time:integer);virtual;
          procedure          SyncPal;virtual;

         {kurzor}
          procedure          GotoXY(x,y:integer);virtual;

         {porty/retrace}
          public
          beziNahazovacRet   :boolean; {pri kazdym retrace muzes automaticky nahodit ret (obsluhu si }
          ret                :boolean;  {povesis na timer), toho vyuzije SyncRet k presnejsi synchronizaci}
          synced             :boolean; {jsem sesynchronizovan s paprskem?}
                                        {Setvis nekdy ceka na paprsek a nastavi synced,}
                                        {SyncRet pak ceka na paprsek jen pri not synced.}
          RetraceLen         :word;    {doba delsi nez vertical a kratsi nez horizontal retrace}
          VesaSetvisSyncuje  :boolean; {ceka VesaSetvis na parsek?}
          ScreenFreq         :word;    {obnovovaci frekv. modu, presnost plus minus 10Hz}
          TimerScrSync       :word;    {hodnota zjistena funkci tmrGetScrSync}
          procedure          WaitForRetrace;
          procedure          WaitForTrace;
          procedure          Refresh(n:byte);
          procedure          SyncRet;
          procedure          Sync;virtual;
          function           DetectTmrScrSync:word;virtual;
          function           GetBankRegs:TBankRegs;
          procedure          SetBankRegs(x:TBankRegs);

         {setvis/split a spol na urovni registru}
         public
          maxSplitY          :word;{nejmensi Y tak velke, ze ze splitu neni nic videt}
          nowSplitY          :word;{hodnta nastavena metodou splity}
          DoubleScan         :byte;{kolikrat prochazi paprsek kazdy pixel? (1 nebo 2)}
          procedure          SplitY(y:word);
          procedure          SetvisHi(a:word);
          procedure          PanLeft(x:byte);
          procedure          PanUp(y:byte);
          function           VesaSetvis(x,y:word):boolean;
          function           VesaSetvisSync(x,y:word):boolean;

         {setvis na uzivatelske urovni}
         public
          vramVisX           :word;{aktualni souradnice display start (PEN_VRAM)}
          vramVisY           :word;
          procedure          Setvis(x,y:word);
          function           SetVramXRes(virtualX:word):boolean;
          procedure          SwapMoving(var move:boolean);virtual;

         {mys}
         public
          mouseRng           :TRect;  {meze volneho pohybu}
          mouse              :TMousePoint;{relativni pozice (vzhledem k obrazovce)}
          mousePres          :TMousePoint;{relativni pozice posledniho stisku}
          mouseFlag          :boolean;{je mys prave nakreslena na obrazovce?}
          mouseWarning       :byte;   {mys se prave prekresluje}
          mouseRedrawFlag    :boolean;{flag ktery se nastavi pri kazdem vykresleni mysi,
                                       uzitecne pri boji proti redundantnim redrawum}
          procedure          MouseSetPointer(p:PBitmap;pointX,pointY:word);
          procedure          MouseSwapPointer(var b:PBitmap;var p:TPoint);
          function           MouseShow:boolean;
          function           MouseHide:boolean;
          procedure          MouseRescanState;
          procedure          MouseRescanPress;
          procedure          MouseSetRange;
          procedure          MouseSetPos(x,y:integer);
          procedure          MouseShift(dx,dy:integer);
          procedure          MouseRedraw;
          function           MousePal:PPal;
          procedure          MouseGetRect(var rect:TRect);virtual;

                             private
                              mouseActive        :boolean;{je aktivni handler <nebo> mam sledovat pohyb a prekreslovat sipku?}
                              mouseSipka         :TPoint; {absolutni pozice sipky nakreslene ve videopameti}
                              mouseBitmap        :PBitmap;{sipka mysi}
                              mouseBuffer        :PBitmap;{buffer pro ukladani pozadi za mysi}
                              mousePoint         :TPoint; {"hot spot", klicovy pixel v bitmape sipky}
                              procedure          MouseAdjustSpeed;
                              procedure          MouseKillPointer(kill:boolean);
                             public

         {eventy}
          procedure          ResetEvents;
          function           GetEvent(var event:TEvent;var pos:TPoint):boolean;virtual;
          procedure          PushEvent(e:TEvent);

                             private
                              eventbuf           :array[1..32] of TEvent;
                              events             :byte;
                              procedure          KeyboardRescan;virtual;
                             public

          end;

const     pen_vram           =1;{videopamet           [0,0]..[vramXres,vramYres] (vram=fyzicka linearni videopamet)}
          pen_virtual        =2;{virtualni videopamet [0,0]..[inf,inf] (virtual=podle pouzite metody zmorfovana videopamet)}
          pen_virt_area      =3;{oblast virtualni videopameti o velikosti bitmapy nad kterou se scrolluje}
          pen_screen         =4;{obrazovka            [0,0]..[Xres,Yres] (screen=blok nekde ve virtual)}


          mbLeft             =256-1;{mouse buttons jak je hlasi GetEvent}
          mbRight            =256-2;{kdybys tyto konstanty menil, zmen i GetEvent}
          mbMid              =256-4;


{---------------------------------------------------------------------------
 Seznam podporovanych modu (ResList)
 ---------------------------------------------------------------------------}

Type
 PResItem=^TResItem;
 TResItem=object(TObject)
   amodel             :byte;   {vzdy nastaveno}
   ax,ay              :word;   {vzdy nastaveno}
   amode              :word;   {vzdy nastaveno}
   optional           :boolean;{jsou nasledujici udaje platne?}
   aretracelen        :integer;
   ascreenfreq        :integer;
   avesasetvissyncuje :boolean;
   atimerscrsync      :word;
   constructor Init(model,x,y,mode:word);
 end;

 TResCollection=object(TSortedCollection)
   procedure Insert(Item:Pointer);virtual;
   function Compare(p1,p2:pointer):integer;virtual;
 end;

Var   ResList:TResCollection;

FUNCTION  ModeSupported(model,mode:word):boolean;
FUNCTION  ModeDoplnInfo(var model,sir,vys,mode:integer):boolean;
FUNCTION  GetPackedModeAtLeast(xx,yy:word):word;


{---------------------------------------------------------------------------
 Zbytky...
 ---------------------------------------------------------------------------}
var       CurScreen:PScreen;{aktualni screena, nemenit, jen cist}
          debugpal:boolean; {zapina debug mod v palete}
          UserFont:procedure(var name:PathStr;var p:pointer;var vyska:byte);
const     erBadMode = 80;
          erBadVBE  = 95;

FUNCTION  IsVga:boolean;
FUNCTION  DCV(presnost:word):word;
FUNCTION  InitStaticBitmap(model,sir,vys:integer;p:pointer;trans:boolean):PBitmap;
PROCEDURE MouseSetBaseColor(newbase:byte);
FUNCTION  LoadUserFont(fnt:pointer;vyska:byte):TError;
PROCEDURE GetResizeBltClipping(srcSize:TPoint;destRect:TRect;destRng:TRect;var newSrcRect:TRect;var newDestRect:TRect);



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{€€€€€€€€€€€€€€€€ P O R T Y €€€€€€€€€€€€€€€€}


const mingoodfreq        =40;           {minimalni a maximalni}
      maxgoodfreq        =170;          {obnovovaci frekvence, ktere jeste
                                         nejsou povazovany za chybu}
      zlomeksec          =5;            {takovy zlomek sekundy meri pocet retracu}
      maxfreqerror       =zlomeksec;    {maximalni mozna chyba v freq}


{---------------------------------------------------------------------------
 Nahrada instrukce OUT DX,AX, kterou na nekterych kartach nelze pouzit.
 Nemeni registry.
 ---------------------------------------------------------------------------}
PROCEDURE OutDxAx;assembler;
 asm
     out   dx,al
     inc   dx
     xchg  al,ah
     out   dx,al
     dec   dx
     xchg  al,ah
 end;


{---------------------------------------------------------------------------
 Ceka na beh paprsku dolu.
 Nemeni registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.WaitForTrace;assembler;
 asm
     push ax
     push dx
     @2:mov dx,3dah;in al,dx;test al,8;jnz @2
     pop dx
     pop ax
 end;

{---------------------------------------------------------------------------
 Ceka na beh paprsku nahoru.
 Nemeni registry.

 Vysvetlivka:
   Nektere karty v nekterych VESA modech pri kazdem horizontalnim navratu
   paprsku generuji signal urceny vertikalnimu navratu. Proto je nutne
   testovat _jak dlouho_ navrat trva a za vertikalni ho povazovat az kdyz
   je to dost dlouho. Nutna doba trvani je v promenne RetraceLen.
   Je-li nastaveno moc, refresh nikdy neskonci.
 ---------------------------------------------------------------------------}
Procedure TScreen.WaitForRetrace;assembler;
 asm
{trivialni, ale nefunkcni verze:
     push ax
     push dx
     @2:mov dx,3dah;in al,dx;test al,8;jz @2
     pop dx
     pop ax
(*komplikovana, lec funkcni nahrada:}
     pusha
     push ds
     lds si,self
     mov di,1200{nastavi ze po 1200 nedostatecne dlouhych navratech skonci}
     mov dx,3dah;
 @3: in al,dx;test al,8;jz @3{cyklit dokud se nevraci}
     dec di;jz @8
     {testovat ze jede pouze nahoru x krat za sebou, jinak skok na predchozi radek}
     mov bx,[si+RetraceLen]
 @5: dec bx;js @9
     in al,dx;test al,8;jnz @5
     jmp @3
 @8: {nasilne skonci kdyz uz to trva moc dlouho}
     cmp [si+RetraceLen],0;jz @9
     {zkusi snizit RetraceLen aby se vesel do vertical retrace}
     dec [si+RetraceLen]
 @9: pop ds
     popa
 (**)
 end;

{---------------------------------------------------------------------------
 N krat ceka na okamzik kdy se paprsek zacina vracet.
 Nemeni registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.Refresh(n:byte);assembler;
 asm
   @start:
     dec n
     js @end
     db 66h;push word ptr self;call WaitForTrace   {cekat dokud neni na ceste dolu}
     db 66h;push word ptr self;call WaitForRetrace {cekat dokud neni na navratu nahoru}
     jmp @start
   @end:
 end;

{---------------------------------------------------------------------------
 Synchronizuje se s paprskem - ceka na okamzik kdy zacina bezet nahoru.
 Bere v uvahu 'synced', takze neceka, kdyz predtim probehla jina funkce,
 ktera uz se zesynchronizovala.
 ---------------------------------------------------------------------------}
Procedure TScreen.SyncRet;
var s:TStopky;
begin
 if synced then synced:=false{uz syncnul Setvis} else
  if not beziNahazovacRet then Refresh(1){syncnu si sam} else
   begin
    if not ret then begin{cekam az pri zacatku (nebo konci?) retrace naskoci ret}
      s.Start;
      repeat until ret or (s.LookAt>1000){1 sekunda};
      if not ret then erMsg('Nenahazuje se ret, interni chyba.');
      end;
    ret:=false;
   end;
end;

{---------------------------------------------------------------------------
 Synchronizuje se s paprskem a provadi veci, ktere jsou nutne behem kazdeho
 navratu (prekreslit mys pokud nema handler a pohla se apod).
 ---------------------------------------------------------------------------}
Procedure TScreen.Sync;
begin
 SyncRet;
 KeyboardRescan;
 MouseRescanPress;
 MouseRescanState;
 MouseRedraw;
 IncMs(1000 div screenfreq);
end;

{---------------------------------------------------------------------------
 Chvili ceka, melo by to stacit kdyz je nekde psano ze se ma pockat 250ns.
 (250ns=50taktu na 200MHz CPU, tedy asi tak 50 instrukci)
 Zachova registry.
 ---------------------------------------------------------------------------}
PROCEDURE Wait250ns;assembler;
 asm
     push cx;mov cx,25;@1:nop;loop @1;pop cx;
 end;

{---------------------------------------------------------------------------
 Cte CRTC registr.
 ---------------------------------------------------------------------------}
FUNCTION  vga_ReadCrtc(ndx:byte):byte;assembler;
 asm
     mov al,ndx
     mov dx,3d4h
     out dx,al
     inc dx
     in  al,dx
 end;

{---------------------------------------------------------------------------
 Cte dva po sobe jdouci CRTC registry.
 ---------------------------------------------------------------------------}
FUNCTION  vga_ReadCrtcW(ndx:byte):word;assembler;
 asm
     mov  al,ndx
     mov  dx,3d4h
     out  dx,al
     inc  dx
     xchg al,ah
     in   al,dx
     dec  dx
     xchg ah,al
     inc  al
     out  dx,al
     inc  dx
     in   al,dx
 end;

{---------------------------------------------------------------------------
 Zapise do CRTC registru.
 ---------------------------------------------------------------------------}
PROCEDURE vga_WriteCrtc(ndx,val:byte);assembler;
 asm
     mov al,ndx
     mov ah,val
     mov dx,3d4h
     call OutDxAx
 end;

{---------------------------------------------------------------------------
 Vraci udaj z maskovacich registru v unchained modu.
 Ostatni registry nemeni.
 ---------------------------------------------------------------------------}
FUNCTION vga_GetXRegs:word;assembler;
 asm
     push dx
    {vga ports 2 ax}
     {write mask:}mov dx,3c4h;mov al,2;out dx,al;inc dx;in al,dx;mov ah,al
     {read mask:}mov dx,3ceh;mov al,4;out dx,al;inc dx;in al,dx
     pop dx
 end;

{---------------------------------------------------------------------------
 Udaj zapise do maskovacich registru v unchained modu.
 Zachova registry.
 ---------------------------------------------------------------------------}
PROCEDURE vga_SetXRegs(n:word);assembler;
 asm
     push dx
     push bx
     push ax
     mov bx,n
    {restore vga ports from bx}
     {write mask:}mov dx,3c4h;mov al,2;mov ah,bh;call OutDxAx
     {read mask:}mov dx,3ceh;mov al,4;mov ah,bl;call OutDxAx
     pop ax
     pop bx
     pop dx
 end;

{---------------------------------------------------------------------------
 Vypne ochranu dulezitych CRTC registru proti prepsani.
 ---------------------------------------------------------------------------}
PROCEDURE vga_EnableCrtc;assembler;
 asm
     mov dx,3d4h
     mov al,11h
     out dx,al
     inc dx
     in al,dx
     and al,7fh
     out dx,al
 end;

{---------------------------------------------------------------------------
 Zapne ochranu dulezitych CRTC registru proti prepsani.
 ---------------------------------------------------------------------------}
PROCEDURE vga_ProtectCrtc;assembler;
 asm
     mov dx,3d4h
     mov al,11h
     out dx,al
     inc dx
     in al,dx
     or al,80h
     out dx,al
 end;

{---------------------------------------------------------------------------
 Vraci vertical displayed end+1.
 Bezne by to mel byt pocet radek.
 ---------------------------------------------------------------------------}
FUNCTION  vga_GetVerticalDisplayedEnd:integer;assembler;
 asm
     mov dx,3d4h
     mov al,7;out dx,al;inc dx;in al,dx;dec dx
     shl ax,9;shr ax,3;shr ah,4;shl ax,1
     mov al,12h;out dx,al;inc dx;in al,dx
     inc ax
 end;

{---------------------------------------------------------------------------
 Nastavi vertical displayed end na n-1.
 Bezne by se tim mel nastavit pocet radek.
 ---------------------------------------------------------------------------}
PROCEDURE vga_SetVerticalDisplayedEnd(n:word);assembler;
 asm
     mov dx,3d4h
     mov al,12h;out dx,al;inc dx;mov ax,n;dec ax;out dx,al;dec dx
     shl ah,6;shr ax,7;shl ah,6;shl ax,1
     mov al,7;out dx,al;inc dx;in al,dx;and al,10111101b;out dx,al
 end;

{---------------------------------------------------------------------------
 Skryje textmod kurzor, vraci jeho puvodni stav (true=byl videt).
 ---------------------------------------------------------------------------}
FUNCTION  vga_HideCursor:boolean;assembler;
 asm
     mov dx,3d4h;mov al,0ah;out dx,al;inc dx;in al,dx;
     mov ah,al;or al,00010000b;out dx,al
     shl ah,3;shr ax,15;dec ax
 end;

{---------------------------------------------------------------------------
 Zobrazi textmod kurzor, vraci jeho puvodni stav.
 ---------------------------------------------------------------------------}
FUNCTION  vga_ShowCursor:boolean;assembler;
 asm
     mov dx,3d4h;mov al,0ah;out dx,al;inc dx;in al,dx;
     mov ah,al;and al,11101111b;out dx,al
     shl ah,3;shr ax,15;dec ax
 end;

{---------------------------------------------------------------------------
 Vraci vysku znaku v textovem modu.
 ---------------------------------------------------------------------------}
FUNCTION  vga_GetCharYres:byte;assembler;
 asm
     mov dx,3d4h
     mov al,9;out dx,al;inc dx;in al,dx
     and al,31;inc al
 end;

PROCEDURE vga_SetCharYres(vyska:byte);assembler;
 asm
     push 9
     call vga_ReadCrtc
     and al,0e0h
     add al,vyska
     dec al
     push 9
     push ax
     call vga_WriteCrtc
 end;

{---------------------------------------------------------------------------
 Vraci sirku znaku v textovem VGA modu v pixelech.
 ---------------------------------------------------------------------------}
FUNCTION  vga_GetCharXres:byte;assembler;
 asm
     mov dx,3c4h
     mov al,1;out dx,al;inc dx;in al,dx
     and al,1;xor al,1;add al,8
 end;

{---------------------------------------------------------------------------
 Nastavi sirku znaku v textovem VGA modu v pixelech.
 Pripustne hodnoty 8,9.
 ---------------------------------------------------------------------------}
PROCEDURE vga_SetCharXres(n:byte);assembler;
 asm
     mov dx,3c4h;mov al,1;out dx,al;inc dx;in al,dx
     mov ah,n;and ah,1;xor ah,1
     or al,ah;out dx,al
 end;

{---------------------------------------------------------------------------
 Nastavi jestli ma spodni obrazovka ve splitscreenu scrollovat o 0..8 pixelu
 do stran spolecne s horni. Defaultne byva nastaveno YES, praktictejsi je NO.
 ---------------------------------------------------------------------------}
PROCEDURE vga_EnableSplitScrol(scrol:boolean);assembler;
 asm
     mov dx,3dah;in al,dx
     mov dx,3c0h;mov al,30h;out dx,al
     inc dx
     in al,dx
     dec dx
     and al,11011111b
     cmp scrol,false;jnz @do
     or al,00100000b
     @do:
     call wait250ns
     out dx,al
 end;

{---------------------------------------------------------------------------
 V textmodu nastavi chovani 7.bitu atributu znaku.
 Muze zpusobovat blikani nebo byt 4.bitem barvy pozadi.
 Defaultne byva true, blikani.
 ---------------------------------------------------------------------------}
PROCEDURE vga_EnableBlinking(blink:boolean);assembler;
 asm
     mov dx,3dah;in al,dx
     mov dx,3c0h;mov al,30h;out dx,al
     inc dx
     in al,dx
     dec dx
     and al,11110111b
     cmp blink,false;jz @do
     or al,00001000b
     @do:
     call wait250ns
     out dx,al
 end;

FUNCTION  vga_GetLineOffset:byte;assembler;
 asm
     push 13h
     call vga_ReadCrtc
 end;

PROCEDURE vga_SetLineOffset(n:byte);assembler;
 asm
     push 13h
     push word ptr n
     call vga_WriteCrtc
 end;

FUNCTION  vga_GetDoubleScan:byte;assembler;
 asm
     push 9
     call vga_ReadCrtc
     shr al,7
 end;

{---------------------------------------------------------------------------
 Vraci obsah VGA registru vertical diaplay enable end+1,
 neboli pocet zobrazovanych scanlines.
 ---------------------------------------------------------------------------}
FUNCTION vga_GetScanlines:word;assembler;
 asm
      mov dx,3d4h
      mov al,12h;out dx,al;inc dx;in al,dx;dec dx;mov bl,al
      mov al,7;out dx,al;inc dx;in al,dx;
      shl ax,6;shr ah,4;shl ax,1;mov al,bl;and ah,3
      inc ax
 end;




{€€€€€€€€€€€€€€€€ P A L E T A €€€€€€€€€€€€€€€€}

Constructor TPal.Init;
begin
 inherited Init;
 last:=255;
end;

Constructor TPal.InitMore(aflags,fromcol,tocol:byte);
begin
 Init;
 flags:=aflags;
 first:=fromcol;
 last:=tocol;
end;

Procedure TPal.Take(p:PPal);
begin
 if p<>nil then begin
   move(p^.pal[3*p^.first],pal[3*p^.first],3*(integer(p^.last)+1-p^.first));
   first:=minI(first,p^.first);
   last:=maxI(last,p^.last);
   end;
end;

{---------------------------------------------------------------------------
 Do pole pal nacte z karty aktualni paletu 256 barev.
 ---------------------------------------------------------------------------}
Procedure TPal.ReadFromTo(fromcol,tocol:byte);assembler;
 asm
     les di,self
     add di,pal
     mov al,3;mul fromcol;add di,ax
     mov al,tocol;sub al,fromcol;jc @end;mov ah,0;inc ax
     mov cx,ax;add cx,ax;add cx,ax
     mov dx,3c7h;mov al,fromcol;out dx,al;add dx,2
     @1:insb;loop @1
     @end:
 end;

{---------------------------------------------------------------------------
 Zacerni celou paletu.
 ---------------------------------------------------------------------------}
PROCEDURE BlackHwPal;assembler;
 asm
     cmp debugpal,false;jne @end
     mov dx,3c8h;mov al,0;out dx,al;inc dx
     mov cx,100h
     @1:out dx,al;out dx,al;out dx,al;loop @1
     @end:
 end;

{---------------------------------------------------------------------------
 Vraci jestli je cela paleta cerna.
 ---------------------------------------------------------------------------}
FUNCTION  PalIsBlack:boolean;assembler;
 asm
     mov dx,3c7h;mov al,0;out dx,al;add dx,2
     mov cx,300h
     @1:in al,dx;or al,0;jnz @color;loop @1
     @black:mov al,1;jmp @end
     @color:mov al,0
     @end:
 end;

{---------------------------------------------------------------------------
 Nastavi nahodnou paletu.
 Urceno pro ladici ucely.
 ---------------------------------------------------------------------------}
PROCEDURE RandomPal;
var   i:byte;
begin
 for i:=0 to 255 do SetHwCol(i,random(64),random(64),random(64));
end;

(*
{---------------------------------------------------------------------------
 Vraci jestli je jas dole (cela paleta ztmavena na darkcolor).
 Udaje cte primo z karty, ne z pole pal.
 ---------------------------------------------------------------------------}
Function TPal.BrightIsDown:boolean;assembler;
 asm
     les di,self
     mov dx,3c7h;mov al,0;out dx,al;add dx,2;mov cx,256
     @1:
     in al,dx;or al,[es:di+offset darkcolor  ];jnz @color;
     in al,dx;or al,[es:di+offset darkcolor+1];jnz @color;
     in al,dx;or al,[es:di+offset darkcolor+2];jnz @color;
     loop @1
     @black:mov al,1;jmp @end
     @color:mov al,0
     @end:
 end;
*)

{---------------------------------------------------------------------------
 Nastavi jednu barvu jen na karte.
 ---------------------------------------------------------------------------}
PROCEDURE SetHwCol(col,r,g,b:byte);assembler;
 asm
     mov dx,3c8h;mov al,col;out dx,al;inc dx
     mov al,r;out dx,al
     mov al,g;out dx,al
     mov al,b;out dx,al
 end;

{---------------------------------------------------------------------------
 Nastavi jednu barvu na karte i v poli pal.
 ---------------------------------------------------------------------------}
Procedure TPal.SetCol(col,r,g,b:byte);assembler;
 asm
     les di,self
     mov dx,3c8h;mov al,col;out dx,al;inc dx
     mov bl,3;mul bl;mov bx,ax{bx=3*col}
     mov al,r;out dx,al;mov [es:di+bx+offset pal  ],al
     mov al,g;out dx,al;mov [es:di+bx+offset pal+1],al
     mov al,b;out dx,al;mov [es:di+bx+offset pal+2],al
 end;

{---------------------------------------------------------------------------
 Nastavi barvy od fromcol do tocol na karte i v poli pal tak,
 aby tvorily plynuly prechod.
 ---------------------------------------------------------------------------}
Procedure TPal.SmoothCols(fromcol,r1,g1,b1,tocol,r2,g2,b2:byte);
var   col:byte;
      cols:integer;
begin
 if fromcol=tocol then begin SetCol(tocol,r2,g2,b2);exit;end;
 if fromcol>tocol then asm
    mov al,fromcol;xchg tocol,al;mov fromcol,al
    mov al,r1;xchg r2,al;mov r1,al
    mov al,g1;xchg g2,al;mov g1,al
    mov al,b1;xchg b2,al;mov b1,al
   end;
 cols:=tocol-fromcol;
 for col:=fromcol to tocol do
  SetCol(col,
         ( r1*(tocol-col) + r2*(col-fromcol) ) div cols,
         ( g1*(tocol-col) + g2*(col-fromcol) ) div cols,
         ( b1*(tocol-col) + b2*(col-fromcol) ) div cols
        );
end;

{---------------------------------------------------------------------------
 Nastavi jas od fromcol do tocol na karte i v poli pal tak,
 ze u fromcol se zmeni o how, u tocol o 0. How je od -1000 do 1000.
 ---------------------------------------------------------------------------}
Procedure TPal.SmoothBright(fromcol,tocol:byte;how:integer;er,ge,be:boolean);
var   c,r,g,b:byte;
      hau:real;
begin
 for c:=minW(fromcol,tocol) to maxW(fromcol,tocol) do begin
   if fromcol=tocol
    then hau:=exp(how/1000)
    else hau:=exp(how*abs(c-tocol)/abs(fromcol-tocol)/1000);
   r:=pal[3*c  ];if er then r:=minW(63,round(r*hau));
   g:=pal[3*c+1];if ge then g:=minW(63,round(g*hau));
   b:=pal[3*c+2];if be then b:=minW(63,round(b*hau));
   SetCol(c,r,g,b);
   end;
end;

{---------------------------------------------------------------------------
 Nastavi kontrast od fromcol do tocol pouze v poli pal tak,
 ze u fromcol se zmeni o how, u tocol o 0. How je od -1000 do 1000.
 Nastaveni se tyka pouze jedne slozky r,g,b (podle ofs 0,1,2).
 ---------------------------------------------------------------------------}
Procedure TPal.SmoothContrast1(fromcol,tocol,ofs:byte;how:integer);
var   c:byte;
      delta:integer;
      hau:real;
      mid:longint;
begin
 mid:=0;
 delta:=abs(fromcol-tocol);
 if delta<>0 then begin
   for c:=minW(fromcol,tocol) to maxW(fromcol,tocol)
    do inc(mid,pal[3*c+ofs]*abs(c-tocol));
   mid:=mid*2 div delta div (delta+1);
   for c:=minW(fromcol,tocol) to maxW(fromcol,tocol) do begin
     hau:=exp(how*abs(c-tocol)/delta/400);
     pal[3*c+ofs]:=Bounded(round(mid+(pal[3*c+ofs]-mid)*hau),0,63);
     end;
   end;
end;

{---------------------------------------------------------------------------
 Nastavi kontrast od fromcol do tocol na karte i v poli pal tak,
 ze u fromcol se zmeni o how, u tocol o 0. How je od -1000 do 1000.
 ---------------------------------------------------------------------------}
Procedure TPal.SmoothContrast(fromcol,tocol:byte;how:integer;er,ge,be:boolean);
begin
 if er then SmoothContrast1(fromcol,tocol,0,how);
 if ge then SmoothContrast1(fromcol,tocol,1,how);
 if be then SmoothContrast1(fromcol,tocol,2,how);
 ShowFromTo(minW(fromcol,tocol),maxW(fromcol,tocol));
end;

{---------------------------------------------------------------------------
 Zobrazi zadany usek palety v plnem jasu.
 ---------------------------------------------------------------------------}
Procedure TPal.ShowFromTo(fromcol,tocol:byte);assembler;
 asm
     les si,self
     add si,pal
     mov al,3;mul fromcol;add si,ax
     mov al,tocol;sub al,fromcol;jc @end;mov ah,0;inc ax
     mov cx,ax
     mov dx,3c8h;mov al,fromcol;out dx,al;inc dx;
     @1:seges outsb;seges outsb;seges outsb;loop @1;
     @end:
 end;

{---------------------------------------------------------------------------
 Zobrazi paletu bitmapy v plnem jasu.
 ---------------------------------------------------------------------------}
Procedure TPal.Show;
begin
 ShowFromTo(first,last);
end;

{---------------------------------------------------------------------------
 Nastavi na karte jas 0..255.
 Vyuziva tyto promenne:
  pal          - odtud bere paletu jak by vypadala pri plnem jasu
  darkcolor    - odtud bere barvu jaka ma nastat pri nulovem jasu
  brightFromcol- prvni zpracovavana barva
  brightTocol  - posledni zpracovavana barva
 Do nowbright ulozi soucasny jas (nowbright:=n).
 ---------------------------------------------------------------------------}
Procedure TPal.SetBright(n:byte);
begin
 SetBrightFromTo(n,first,last);
 nowbright:=n;
end;

Procedure TPal.SetBrightFromTo(n,fromcol,tocol:byte);assembler;
 asm
     {pro jas 255 neni nutno nasobit}
     cmp n,255;jnz @notmax
     push word ptr fromcol
     push word ptr tocol
     db 66h;push word ptr self
     call TPal.ShowFromTo
     jmp @end
     @notmax:

     {if debug then n=max(n,128)}
     cmp debugpal,false;je @normal
     cmp n,128;ja @normal
     mov n,128
     @normal:

     {predpocita prirustky konstantni pro vsechny barvy}
     mov bl,n;mov bh,255;sub bh,bl
     les si,self
     mov al,[es:si+offset darkcolor  ];mul bh;mov cl,ah{+r}
     mov al,[es:si+offset darkcolor+1];mul bh;mov ch,ah{+g}
     mov al,[es:si+offset darkcolor+2];mul bh;mov bh,ah{+b}

     {posun barvy smerem k darkcolor a out}
     add si,pal
     mov al,3;mul fromcol;add si,ax
     mov al,tocol;sub al,fromcol;jc @end;mov ah,0;inc ax
     mov di,ax
     mov dx,3c8h;mov al,fromcol;out dx,al
     inc dx
     @1:
     seges lodsb;mul bl;mov al,ah;add al,cl;out dx,al{r}
     seges lodsb;mul bl;mov al,ah;add al,ch;out dx,al{g}
     seges lodsb;mul bl;mov al,ah;add al,bh;out dx,al{b}
     dec di
     jnz @1
     @end:
 end;

Procedure TPal.rgb2BGR;assembler;
 asm
     PUSH DS
     lds si,self;add si,pal
     les di,self;add di,pal
     mov cx,256
     @1:
     lodsw
     add ax,ax
     add ax,ax
     mov bl,al
     lodsb
     add al,al
     add al,al
     stosw
     mov al,bl
     stosb
     loop @1
     POP DS
 end;

Procedure TPal.BGR2rgb;assembler;
 asm
     PUSH DS
     lds si,self;add si,pal
     les di,self;add di,pal
     mov cx,256
     @1:
     lodsw
     shr al,2
     shr ah,2
     mov bl,al
     lodsb
     shr al,2
     stosw
     mov al,bl
     stosb
     loop @1
     POP DS
 end;

{---------------------------------------------------------------------------
 time>0 => behem time snimku rozsviti obraz (paletu)
 time<0 => behem -time snimku ztmavi obraz
 time=0 => okamzite rozsviti obraz
 ---------------------------------------------------------------------------}
Procedure TPal.Fade(time:integer);
var   i:integer;
begin
 if time=0 then SetBright(255) else begin
   i:=minI(0,time);
   repeat
    inc(i);
    if CurScreen<>nil then CurScreen^.SyncRet;
    SetBright(longint(i)*255 div time);
   until (i=0) or (i=time);
   end;
end;

{---------------------------------------------------------------------------
 Viz TPal.Fade, ale pracuje se vsemi paletami bitmapy.
 Pozn: zdrojak je 100% totozny s predchozi proc., lisi se volane metody.
 ---------------------------------------------------------------------------}
Procedure TBitmap.Fade(time:integer);
var   i:integer;
begin
 if time=0 then SetBright(255) else begin
   i:=minI(0,time);
   repeat
    inc(i);
    if CurScreen<>nil then CurScreen^.SyncRet;
    SetBright(longint(i)*255 div time);
   until (i=0) or (i=time);
   end;
end;

{---------------------------------------------------------------------------
 Viz TPal.Fade, ale paletu nacita z vga registru.
 ---------------------------------------------------------------------------}
Procedure TScreen.Fade(time:integer);
var   p:TPal absolute freeB;
begin
 p.Init;
 p.ReadFromTo(0,255);
 p.Fade(time);
 p.Done;
end;

{---------------------------------------------------------------------------
 Synchronizuje paletu tak, aby odpovidala poloze do ktere se zrovna
 doscrollovalo. Ma vyznam az u TScrolScreen, zde u TScreen nedela nic.
 ---------------------------------------------------------------------------}
Procedure TScreen.SyncPal;
begin
end;


{---------------------------------------------------------------------------
 Provadi bezpecnostni opatreni proti bliknuti tesne pred zmenou modu.
 ---------------------------------------------------------------------------}
PROCEDURE PreAntiBlik;
begin
 {Tady jsem mel driv spoustu fint, ale pote, co jsem si
  koupil solidni kartu, ktera neblika...}
end;

{---------------------------------------------------------------------------
 Provadi bezpecnostni opatreni proti bliknuti tesne po zmene modu.
 ---------------------------------------------------------------------------}
PROCEDURE PostAntiBlik;
begin
end;



{---------------------------------------------------------------------------
 TPalAlloc
 Tento objekt je urcen pro praci s paletou tam, kde je nedostatek barev.
 Reknes mu ktere indexy (0..255) jsou
   paDead - zcela nepouzitelne
   paStatic - uz maji prirazenou RGB barvu se kterou se nesmi hybat
   paDynamic - jeste nemaji svou RGB barvu.
 Potom muzes pouzivat metodu Alloc(R,G,B), ktera ti pro kazdou barvu vybere
 vhodny index tak, aby se jeho barva co nejvic blizila zadanemu RGB.
 Podle uvazeni bud nastavuje nove barvy nebo vraci nejblizsi z jiz nastavenych.
 ---------------------------------------------------------------------------}
Constructor TPalAlloc.Init;
begin
 inherited Init;
 ReadFromTo(0,255);
 fillchar(Indexes,sizeof(Indexes),paDynamic);
 Indexes[0]:=paStatic;
 Count[paDead]:=0;
 Count[paStatic]:=1;
 Count[paDynamic]:=255;
end;

Procedure TPalAlloc.Setup(fromindex,toindex:byte;settype:TPalAllocType);
var   i:byte;
begin
 for i:=fromindex to toindex do begin
   dec(Count[Indexes[i]]);
   Indexes[i]:=settype;
   inc(Count[Indexes[i]]);
   end;
end;

Procedure TPalAlloc.Take(p:PPal);
begin
 if p<>nil then begin
   inherited Take(p);
   Setup(p^.first,p^.last,paStatic);
   end;
end;

Function TPalAlloc.Alloc(r,g,b:shortint):byte;
var   best,someDynamic,delta,bestdelta,i:integer;
begin
 if Count[paStatic]+Count[paDynamic]=0 then Alloc:=random(255)
 else begin
   {najde nejblizsi barvu}
   someDynamic:=-1;
   bestdelta:=32000;
   for i:=0 to 255 do
    case Indexes[i] of
     paStatic:begin
       delta:=abs(r-pal[3*i])+abs(g-pal[3*i+1])+abs(b-pal[3*i+2]);
       if delta<bestdelta then begin
         best:=i;
         bestdelta:=delta;
         end;
       end;
     paDynamic:someDynamic:=i;
     end;
   {pokud je dost dobra, pouzije ji}
   if longint(bestdelta)*round(sqrt(Count[paDynamic]))<80 then Alloc:=best
   {jinak zalozi novou}
   else begin
     {$ifdef beta}
     if someDynamic=-1 then erBetaMsg('TPalAlloc.Alloc chaos');
     {$endif}
     SetCol(someDynamic,r,g,b);
     Setup(someDynamic,someDynamic,paStatic);
     Alloc:=someDynamic;
     end;
   end;
end;

const attrCol:array[0..15,0..2] of byte=(
       ( 0, 0, 0),
       ( 0, 0,40),
       ( 0,40, 0),
       ( 0,40,40),      {tohle je jen odhad jak vypadaji barvy v textmodu}
       (40, 0, 0),      {jestli muzete tak to nekdo zkontrolujte}
       (40, 0,40),
       (40,40, 0),
       (40,40,40),
       (20,20,20),
       (20,20,63),
       (20,63,20),
       (20,63,63),
       (63,20,20),
       (63,20,63),
       (63,63,20),
       (63,63,63));


Function TPalAlloc.CachedAllocTxt(attr:byte):byte;
begin
 if (attr<>0) and (TxtCache[attr]=0) then TxtCache[attr]:=Alloc(attrCol[attr,0],attrCol[attr,1],attrCol[attr,2]);
 CachedAllocTxt:=TxtCache[attr];
end;

Procedure TPalAlloc.AllocTxt(attr:byte;var fore,back:byte);
begin
 fore:=CachedAllocTxt(attr mod 16);
 back:=CachedAllocTxt(attr div 16);
end;

Destructor TPalAlloc.Done;
begin
 inherited Done;
end;



{€€€€€€€€€€€€€€€€ T E X T  /  B I O S €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Ziskani informaci o modu pres BIOS.
   Mode    - cislo modu
   TxSir   - sirka obrazovky ve znacich
   TxVys   - vyska obrazovky (ve znacich?)
   charYres - vyska znaku v pixelech
 Prace s kurzorem:
   Levy horni roh je v 0,0.
   LoByte(bios_GetXY) je souradnice X, HiByte(bios_GetXY) je Y.
 ---------------------------------------------------------------------------}
FUNCTION  bios_GetMode:byte;assembler;asm mov ah,0fh;int 10h;end;
FUNCTION  bios_GetXres:byte;assembler;asm mov ah,0fh;int 10h;mov al,ah;end;
FUNCTION  bios_GetYres:byte;assembler;asm mov ax,1130h;mov bh,0;push bp;int 10h;pop bp;mov al,dl;inc al;end;
FUNCTION  bios_GetCharYres:byte;assembler;asm mov ax,1130h;mov bh,0;push bp;int 10h;pop bp;mov al,cl;end;
PROCEDURE bios_GotoXY(x,y:byte);assembler;asm mov dl,x;mov dh,y;mov ah,2;mov bh,0;int 10h;end;
FUNCTION  bios_GetXY:word;assembler;asm mov ah,3;mov bh,0;int 10h;xchg ax,dx;end;

{---------------------------------------------------------------------------
 Nastavi pozici kurzoru (jako bios_GotoXY), ale poradi si s Ybugem.
 ---------------------------------------------------------------------------}
Procedure TScreen.GotoXY(x,y:integer);
var   a:integer;
begin
 if MapModel=model_text then begin
   if GotoYBug=1 then begin
     a:=x+y*vramXres;
     x:=a mod Xres;
     y:=a div Xres;
     end;
   bios_GotoXY(x,y);
   end;
end;

{---------------------------------------------------------------------------
 Zavede zadany font (na fnt^ ocekava 256 znaku sirky 8 a vysky vyska).
 Pri fnt=nil nahraje ROM font zadane vysky 8, 14 nebo 16.
 Nastavi odpovidajici pocet radek.
 Nemaze obrazovku.
 Pouze pro textmod.
 Pozor: pri loadovani se muze zmenit rozliseni a velikost znaku,
   je potreba opravit si Xres,Yres,charXres,charYres.
 ---------------------------------------------------------------------------}
FUNCTION LoadUserFont(fnt:pointer;vyska:byte):TError;
var   {$ifdef dpmi}
      dosfnt            :pointer;
      segment           :word;
      RealModeRegs      :dpmiRealCallRegs;
      {$endif}
      double            :byte;
begin
 {zapamatuje si doublescan}
 double:=vga_GetDoubleScan;

 {nastavi font}
 if fnt=nil then begin
   case vyska of
     16:asm mov bl,0;mov ax,1114h;int 10h;end;
     14:asm mov bl,0;mov ax,1111h;int 10h;end;
      8:asm mov bl,0;mov ax,1112h;int 10h;end;
     {$ifdef beta}
     else erBetaMsg('loadromfont size '+stri(vyska));
     {$endif}
     end;
   LoadUserFont:=erOk;
   end
 else begin
  {$ifndef dpmi}
    asm
        push bp
        mov ax,1110h;mov cx,256;mov dx,0;mov bl,0;mov bh,vyska
        les bp,fnt
        int 10h
        pop bp
        mov @result,true
    end;
    LoadUserFont:=erOk;
  {$else}
    {alokuje pamet}
    if not GetMemDos(segment,dosfnt,256*vyska) then begin
      LoadUserFont:=erLowDosMem;
      exit;
      end;
    {zkopci font do naalokovane dosove pameti}
    move(fnt^,dosfnt^,256*vyska);
    {zavede newfnt}
    with RealModeRegs do begin
       clr;
       rEAX:=$1110;
       rEBX:=vyska shl 8;
       rECX:=$0100;
       rES:=Segment;{adresa newfontu}
       end;
    LoadUserFont:=erDumb(dpmiRealModeInt($10,@RealModeRegs));
    {uvolni pamet}
    FreeMemDos(dosfnt,256*vyska);
  {$endif}
  end;

 {nastavi vysku znaku, starsi BIOSy to samy neudelaj}
 vga_SetCharYres(vyska);
 {kdyz se doublescan zmenil, ohlasi chybu}
 if double<>vga_GetDoubleScan then erMsg('Chyba v biosu, sluzba load user font.');
end;


{---------------------------------------------------------------------------
 Nahraje v textmodu ROM font zadane vysky 8 az 16 a nastavi pocet radek.
 Nemaze obrazovku.
 Kdyz to nejde nastavit presne (napr kdyz neni pamet),
 pokusi se o priblizne nastaveni s preferenci nizsich fontu.
 Vyslednou vysku fontu nelze 100% zarucit ani priblizne,
 vzhledem k existenci utilit typu VGA28.
 ---------------------------------------------------------------------------}
FUNCTION LoadResizedRomFont(vyska:byte):TError;far;
const romsize           :array[2..6] of byte=(14,8,8,14,16);
      param             :array[8..16] of byte=(3,3,3,3,3,3,2,2,6);
var   par               :byte;
      romsiz            :byte;
type  Tfntbuf           =array[0..4095] of byte;
var   romfnt            :^Tfntbuf;
      newfnt            :^Tfntbuf;
      {$ifdef dpmi}
      segment           :word;
      selector          :word;
      RealModeRegs      :dpmiRealCallRegs;
      {$endif}
      result            :TError;

   procedure expand;
   var i,c,top,bot:byte;
   begin
    {zkonverti font do cilove velikosti (z pole romfnt do pole newfnt)}
    fillchar(newfnt^,sizeof(newfnt^),0);
    top:=(vyska-romsiz+1) div 2;
    bot:=vyska-romsiz-top;
    for c:=0 to 255 do
     move(romfnt^[c*romsiz],newfnt^[c*vyska+top],romsiz);
    for c:=176 to 255 do begin
     if top>0 then
      if CmpByte(@romfnt^[c*romsiz],romfnt^[c*romsiz],2)
       then fillchar(newfnt^[c*vyska],top,romfnt^[c*romsiz])
       else
       if CmpBlock(@romfnt^[c*romsiz],@romfnt^[c*romsiz+4],4)
        then for i:=1 to top do newfnt^[c*vyska+top-i]:=romfnt^[c*romsiz+i mod 2]{};
     if bot>0 then
      if CmpByte(@romfnt^[c*romsiz+romsiz-3],romfnt^[c*romsiz+romsiz-1],3)
       then fillchar(newfnt^[c*vyska+top+romsiz],bot,romfnt^[c*romsiz+romsiz-1])
       else
       if CmpBlock(@romfnt^[c*romsiz+romsiz-4],@romfnt^[c*romsiz+romsiz-8],4)
        then for i:=1 to bot do newfnt^[c*vyska+top+romsiz-1+i]:=romfnt^[c*romsiz+romsiz-1-i mod 2]{};
     end;
   end;

Begin
 vyska:=Bounded(vyska,8,16);

 {prime nastaveni bez resizovani}
 if vyska in [8,14,16] then result:=LoadUserFont(nil,vyska) else

 {nastaveni s resizem}
 begin
   result:=erOk;
   par:=param[vyska];
   romsiz:=romsize[par];
   if not GetMem(pointer(newfnt),sizeof(newfnt^)) then result:=erLowMem else begin
     {najde adresu fontu z romky, velikost 8,14 nebo 16}
     {$ifdef dpmi}
      with RealModeRegs do begin
        clr;
        rEAX:=$1130;
        rEBX:=par shl 8;
        end;
      result:=dpmiRealModeInt($10,@RealModeRegs);
      if result=erOk then begin
        {zkonverti adresu romfontu na selektor}
        Seg2Desc(RealModeRegs.rES);
        romfnt:=ptr(RealModeRegs.rES,RealModeRegs.rEBP);
        end;
     {$else}
      asm
       push bp
       mov ax,1130h;mov bh,par
       int 10h
       mov ax,bp
       pop bp
       mov word ptr romfnt,ax;mov word ptr romfnt+2,es
      end;
     {$endif}
     if result=erOk then begin
       Expand;
       result:=LoadUserFont(newfnt,vyska);
       end;
     FreeMem(pointer(newfnt),sizeof(newfnt^));
     end;
   {nouzove priblizne nastaveni v pripade ze selhalo presne nastaveni}
   if result<>erOk then
    case vyska of
     15   :LoadUserFont(nil,14);
     9..13:LoadUserFont(nil,8);
     end;
   end;
 LoadResizedRomFont:=result;
End;

FUNCTION LoadDiskFont(fnt:PathStr;vyska:byte):TError;
var   p:pointer;
      datasize,freesize:longint;
      result:TError;
begin
 p:=nil;
 datasize:=0;
 freesize:=0;
 result:=LoadFile(fnt,p,datasize,freesize);
 if result=erOK then begin
   result:=LoadUserFont(p,vyska);
   FreeMem(p,datasize+freesize);
   end;
 LoadDiskFont:=result;
end;

{---------------------------------------------------------------------------
 Jen v textmodu: Zepta se uzivatelske procedury UserFont co by chtel
 uzivatel za font a nastavi ho.
 ---------------------------------------------------------------------------}
Procedure LoadFont(vyska:byte);
var   name:PathStr;
      p:pointer;
      result:TError;
begin
 name:='';
 p:=nil;
 {pokud jsi nastavil proceduru UserFont, zavola ji}
 if @UserFont<>nil then UserFont(name,p,vyska);
 {tvoje procedura UserFont ma vratit nastavene name,p,vyska}
 {efekt je videt na nasledujicich trech radkach}
 if name<>'' then result:=LoadDiskFont(name,vyska){nastavi .fnt font z disku} else
  if p<>nil then result:=LoadUserFont(p,vyska){nastavi .fnt font z pameti} else
   if vyska<>bios_GetCharYres then result:=LoadResizedRomFont(vyska){resizne a nastavi rom font} else
    result:=erOk;
 erDumb(result);
end;

{---------------------------------------------------------------------------
 Nastavi barevny textovy mod s co nejblizsim poctem radek.
 Textovy mod:
   bity 0..6     - pozadovany pocet radek
   bit  7        - nemazat videopamet
   bity 8..9     - oznacuje VESA mody
   bity 10..11   - 0 - necha defaultni sirku znaku
                   1 - nastavi sirku znaku na 8
                   2 - nastavi sirku znaku na 9
 ---------------------------------------------------------------------------}
Function TScreen.SetMode_TEXT(newmode:word):boolean;
var   radek,charsirka:byte;
      mazat:boolean;
begin
 {nastavi neuspech, pri neuspechu pak uz staci jen exitnout}
 SetMode_TEXT:=false;

 {rozlozi cislo v NewMode do tri slozek}
 radek:=newmode and $7f;
 mazat:=(newmode and $80)=0;
 case newmode shr 10 and 3 of 0:charsirka:=0;
                              1:charsirka:=8;
                              2:charsirka:=9;
                              3:exit;
                             end;

 {nastavi standardni textmod 3}
 {pred a po zmene modu provadi bezpecnostni opatreni proti bliknuti}
 PreAntiBlik;
 asm
     mov ax,3
     cmp mazat,0;jnz @mazat;or al,80h;@mazat:
     int 10h;
 end;
 PostAntiBlik;

 {okno do videopameti ve standardnim texmodu zacina vzdy na adrese SegB800}
 SegVram           :=SegB800;
 WinSizeKB         :=32;
 VramSizeKB        :=32;

 {ve standardnich textmodech lze psat pres Bios}
 BiosOutput        :=true;

 {ted je jiste ze neni nastaven VESA mod}
 VesaMode          :=false;
 VesaNowBank       :=0;
 VesaBanking       :=false;

 {nastavi pozadovany font}
 ZadanaVyskaZnaku  :=vga_GetScanlines div (vga_GetDoubleScan+1) div Bounded(radek,12,100);
 LoadFont(ZadanaVyskaZnaku);

 {na prani natvrdo setne sirku znaku v pixelech}
 case charsirka of 8:vga_SetCharXres(8);
                   9:vga_SetCharXres(9);
                   end;

 {nastavi promenny popisujici mod}
 MapModel          :=model_text;
 ModeID            :=newmode;
 Xres              :=bios_GetXres;
 Yres              :=bios_GetYres;
 charXres          :=vga_GetCharXres;
 charYres          :=vga_GetCharYres;
 BiPP              :=16;
 lineOffset        :=4*vga_GetLineOffset;

 {vraci uspech}
 SetMode_TEXT:=true;

end;




{€€€€€€€€€€€€€€€€ V E S A €€€€€€€€€€€€€€€€}


type
      {VESA record s obecnymi informacemi}
      PVesaInfoBlock = ^TVesaInfoBlock;
      TVesaInfoBlock = record
			Magic		: array[1..4] of char; {VESA/VBE2}
			Verze		: word;
			OEMStrPtr	: pchar;
			Capa		: array[1..4] of byte;
			VideoModePtr	: PInt;
			TotalMemory	: word;
                        {Zbytek poskytuje VBE 2.0 a vyssi}
                        OEMVersion      : word;
                        VendorStrPtr    : pchar;
                        ProductStrPtr   : pchar;
                        ProdRevStrPtr   : pchar;
			Reserved	: array[1..222+256] of byte;
                      end;

      {VESA record s informacemi o konkretnim modu}
      PModeInfoBlock = ^TModeInfoBlock;
      TModeInfoBlock = Record
			ModeAttributes	: word;
			WinAAttributes	: byte;
			WinBAttributes	: byte;
			WinGranularity	: word;
			WinSize		: word;
			WinASegment	: word;
			WinBSegment	: word;
			WinFuncPtr	: pointer;
			BytesPerScanLine: word;
{Zbytek je volitelny pro standardni mody VBE 1.0/1.1, vyzadovano pro OEM mody}
			XResolution	: word;
			YResolution	: word;
			XCharSize	: byte;
			YCharSize	: byte;
			NumOfPlanes	: byte;
			BitsPerPixel	: byte;
			NumOfBanks	: byte;
			MemoryModel	: byte;
			BankSize	: byte;
			NumOfImgPages	: byte;
			Reserved	: byte;
{Zbytek je poskytovan VBE 1.2 a vyssi}
                        RdMS            : byte;  {Red Mask Size}
                        RdFP            : byte;  {Red Field Position}
                        GMS             : byte;  {Green Mask Size}
                        GFS             : byte;  {Green Field Size}
                        BMS             : byte;  {Blue Mask Size}
                        BFS             : byte;  {Blue Field Size}
                        RsMS            : byte;  {Reserved Mask Size}
                        RsMP            : byte;  {Reserved Mask Position}
                        DirColorModeInfo: byte;  {Bit 0:Color ramp programmable}
                                                 {Bit 1:Reserved field useable by application}
{Zbytek je poskytovan VBE 2.0 a vyssi}
                        LinearVideoBuffer:LongInt; {Fyzicka adresa Linear Video Bufferu}
                        OffScreenMemory : LongInt; {Pointer to start of offscreen memory}
                        OffScrMemSize   : Word;    {KB size of offscreen memory}

			Reserved2       : array[1..206+256] of byte;
                      End;

      tDirectMode=record
                    BPP1            : byte;  {BitsPerPixel}
                    RdMS1           : byte;  {Red Mask Size}
                    RdFP1           : byte;  {Red Field Position}
                    GMS1            : byte;  {Green Mask Size}
                    GFS1            : byte;  {Green Field Size}
                    BMS1            : byte;  {Blue Mask Size}
                    BFS1            : byte;  {Blue Field Size}
                    RsMS1           : byte;  {Reserved Mask Size}
                    RsMP1           : byte;  {Reserved Mask Position}
                    MModel1         : byte;  {Type of MemoryModel}
                   end;

const
      KnownDirectModes=14;

      DirectModes:array[1..KnownDirectModes] of tDirectMode=(
        (BPP1:15; RdMS1:5; RdFP1:10; GMS1:5; GFS1:5; BMS1:5; BFS1:0;  RsMS1:1; RsMP1:15; MModel1:model_BGR15),
        (BPP1:15; RdMS1:5; RdFP1:10; GMS1:5; GFS1:5; BMS1:5; BFS1:0;  RsMS1:0; RsMP1:0;  MModel1:model_BGR15),
        (BPP1:15; RdMS1:5; RdFP1:10; GMS1:5; GFS1:5; BMS1:5; BFS1:0;  RsMS1:0; RsMP1:15; MModel1:model_BGR15),
        (BPP1:16; RdMS1:5; RdFP1:10; GMS1:5; GFS1:5; BMS1:5; BFS1:0;  RsMS1:1; RsMP1:15; MModel1:model_BGR15),

        (BPP1:15; RdMS1:5; RdFP1:0;  GMS1:5; GFS1:5; BMS1:5; BFS1:10; RsMS1:1; RsMP1:15; MModel1:model_RGB15),
        (BPP1:15; RdMS1:5; RdFP1:0;  GMS1:5; GFS1:5; BMS1:5; BFS1:10; RsMS1:0; RsMP1:0;  MModel1:model_RGB15),
        (BPP1:15; RdMS1:5; RdFP1:0;  GMS1:5; GFS1:5; BMS1:5; BFS1:10; RsMS1:0; RsMP1:15; MModel1:model_RGB15),
        (BPP1:16; RdMS1:5; RdFP1:0;  GMS1:5; GFS1:5; BMS1:5; BFS1:10; RsMS1:1; RsMP1:15; MModel1:model_RGB15),

        (BPP1:16; RdMS1:5; RdFP1:11; GMS1:6; GFS1:5; BMS1:5; BFS1:0;  RsMS1:0; RsMP1:0;  MModel1:model_BGR16),

        (BPP1:16; RdMS1:5; RdFP1:0;  GMS1:6; GFS1:5; BMS1:5; BFS1:11; RsMS1:0; RsMP1:0;  MModel1:model_RGB16),

        (BPP1:24; RdMS1:8; RdFP1:16; GMS1:8; GFS1:8; BMS1:8; BFS1:0;  RsMS1:0; RsMP1:0;  MModel1:model_BGR24),

        (BPP1:24; RdMS1:8; RdFP1:0;  GMS1:8; GFS1:8; BMS1:8; BFS1:16; RsMS1:0; RsMP1:0;  MModel1:model_RGB24),

        (BPP1:32; RdMS1:8; RdFP1:16; GMS1:8; GFS1:8; BMS1:8; BFS1:0;  RsMS1:0; RsMP1:0;  MModel1:model_BGRA32),
        (BPP1:32; RdMS1:8; RdFP1:16; GMS1:8; GFS1:8; BMS1:8; BFS1:0;  RsMS1:8; RsMP1:24; MModel1:model_BGRA32)
	);

      {pocet bitu na pixel v internim formatu (tj. 15bit mody zabiraji 16bitu apod)}
      BiPPlist:array[0..22] of byte=(16,0,0,0,8,8,0,0,0,0,0,0,0,0,0,0,16,16,16,16,24,24,32);

{---------------------------------------------------------------------------
 Nabankuje na 64KB bank (n mod VesaBanks).
 DS nemusi ukazovat na datasegment.
 Kvuli tomu je zde nutne vypnout stack checking (jinak nahodne haze overflowy).
 Nemeni registry.
 ---------------------------------------------------------------------------}
{$ifopt s+}{$define _stack_checking_}{$s-}{$endif}
Procedure TScreen.VesaSetBank(n:byte);assembler;
 asm
     push ds
     pusha

     lds si,self
     cmp [si+VesaBanking],false;je @bankend
     mov al,n
     xor ah,ah
     cmp [si+VesaNowBank],ax;je @bankend
     mov [si+VesaNowBank],ax
     shl ax,6
     xor dx,dx
     div [si+VramSizeKB]
     xchg ax,dx
     xor dx,dx
     div [si+VesaGranularity]

     xor bx,bx
     mov dx,ax
     cmp [si+VesaUseWinA],false;je @skipA
     mov ax,4f05h
     int 10h{nabankuje window A}
     @skipA:

     cmp [si+VesaUseWinB],false;je @skipB
     mov ax,4f05h
     inc bx
     int 10h{nekdy se musi banknout i window B}
     @skipB:

     @bankend:
     popa
     pop ds
 end;

{---------------------------------------------------------------------------
 Nabankuje na dalsi 64KB bank.
 DS nemusi ukazovat na datasegment.
 Nemeni registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.VesaIncBank;assembler;
 asm
     push ds
     push si
     push ax
      lds si,self
      mov ax,[si+VesaNowBank]
      inc ax
      push ax
      db 66h;push word ptr self;call VesaSetBank
     pop ax
     pop si
     pop ds
 end;

{---------------------------------------------------------------------------
 Nabankuje na predchozi 64KB bank (neni-li v nultem).
 DS nemusi ukazovat na datasegment.
 Nemeni registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.VesaDecBank;assembler;
 asm
     push ds
     push si
     push ax
      lds si,self
      mov ax,[si+VesaNowBank]
      or ax,ax
      jz @skip
      dec ax
      push seg @data;pop ds
      push ax
      db 66h;push word ptr self;call VesaSetBank
      @skip:
     pop ax
     pop si
     pop ds
 end;
{$ifdef _stack_checking_}{$undef _stack_checking_}{$s+}{$endif}

{---------------------------------------------------------------------------
 Vraci stav bankregistru.
 ---------------------------------------------------------------------------}
Function TScreen.GetBankRegs:TBankRegs;
begin
 if not VesaMode then GetBankRegs:=vga_GetXRegs else GetBankRegs:=VesaNowBank;
end;

{---------------------------------------------------------------------------
 Vrati bankregistry do puvodniho stavu.
 ---------------------------------------------------------------------------}
Procedure TScreen.SetBankRegs(x:TBankRegs);
begin
 if not VesaMode then vga_SetXRegs(x) else VesaSetBank(x);
end;

{---------------------------------------------------------------------------
 Ma zjistit kolik vraci tmrGetScrSync.
 TScreen to nepotrebuje, ale potomci muzou, proto je metoda virtualni.
 Tuhle metodu ignoruj, kdyby to slo tak je private.
 ---------------------------------------------------------------------------}
Function TScreen.DetectTmrScrSync:word;
begin
 DetectTmrScrSync:=0;
end;

{---------------------------------------------------------------------------
 Nastavi display address start (pozor: nevime jestli pri tom ceka na retrace).
 Vraci uspesnost.
 ---------------------------------------------------------------------------}
Function TScreen.VesaSetvis(x,y:word):boolean;assembler;
 asm
     {osetreni Ybugu v nekterych vesa biosech}
     les di,self
     cmp [es:di+SetvisYBug],1;jne @skipBug
     mov bx,[es:di+vramXres]
     mov cx,[es:di+Xres]
     cmp bx,cx;je @skipBug
     mov ax,y
     or ax,ax;jz @skipBug
      mul bx
      add ax,x
      adc dx,0
      div cx
      mov x,dx
      mov y,ax
     @skipBug:

     {standardni setvis}
     mov ax,4f07h;mov bx,0h{80h=behem retrace, 0=ihned nebo behem retrace}
     mov cx,x;
     mov dx,y;int 10h
     les di,self
     mov bl,[es:di+VesaSetvisSyncuje]
     mov [es:di+synced],bl
     cmp ax,4fh;mov al,0;jnz @end
     inc al
     @end:
 end;

{---------------------------------------------------------------------------
 Nastavi display address start a pocka na retrace.
 Vraci uspesnost.
 ---------------------------------------------------------------------------}
Function TScreen.VesaSetvisSync(x,y:word):boolean;
begin
 VesaSetvis(x,y);
 if not VesaSetvisSyncuje then begin
   WaitForTrace;
   WaitForRetrace;
   synced:=true;
   end;
end;


{---------------------------------------------------------------------------
 Naalokuje ModeInfo a nahraje do nej info o modu. Pri uspechu vrati true.
 ModeInfo si musis odalokovat sam (je-li <>nil).
 ---------------------------------------------------------------------------}
FUNCTION GetModeInfo(mode:word;var ModeInfo:PModeInfoBlock):boolean;
var   segment:word;
      {$ifdef dpmi}
      RealModeRegs:dpmiRealCallRegs;
      {$endif}
label freee;
begin
 GetModeInfo:=false;
 ModeInfo:=nil;

 {naalokuje pamet pro modeinfo}
 if not GetMemDos(segment,pointer(ModeInfo),sizeof(ModeInfo^)) then exit;
 fillchar(ModeInfo^,sizeof(ModeInfo^),0);

 {do modeinfa necha nahrat informace o modu}
 {$ifndef dpmi}
  asm
     mov ax,4f01h;mov cx,mode              {nastavi parametry pro getmodeinfo}
     les di,modeinfo;les di,[es:di]        {modeinfo je VAR! modeinfo}
     int 10h                               {vola vesabios}
     cmp ax,4fh;jnz freee                  {testuje zda bylo volani ok}
  end;
 {$else}
  with RealModeRegs do begin
   clr;
   rEAX:=$4f01;
   rECX:=mode;
   rES:=Segment;
   end;
  if erDumb(dpmiRealModeInt($10,@RealModeRegs))<>erOk then goto freee;
  {je sluzba vesa.getinfo podporovana ?}
  if word(RealModeRegs.rEAX)<>$4f then goto freee;
 {$endif}

 {ok}
 GetModeInfo:=true;

 freee:
end;

{---------------------------------------------------------------------------
 Vraci polozk reslistu obsahujici zadany mod.
 ---------------------------------------------------------------------------}
FUNCTION GetResItem(model,mode:word):PResItem;

  function ModeMatch(p:PResItem):boolean;far;
  begin
   ModeMatch:=(p^.amodel=model) and (p^.amode=mode);
  end;

begin
 GetResItem:=ResList.FirstThat(@ModeMatch);
end;

{---------------------------------------------------------------------------
 Nastavi pro soucasny mod nejvhodnejsi retraceLen.
 Vraci false kdyz je chovani karty prilis podivne.
 Pozorovani: chovani karty je prilis podivne pod Win95 ve druhem a dalsich
   DOS boxech. V prvnim z otevrenych boxu je ok. Neznam Windows, ale
   zkus se podivat po nejakem 'retrace emulation' switchi.
 Trva zhruba 0.1s, ale muze se protahnout.
 Kdyz jednou skonci neuspechem, skonci tak vzdycky.
 ---------------------------------------------------------------------------}
var   badretrace:array[false..true] of boolean;

Function TScreen.DetectRetraceLen:boolean;
var   fast:boolean;
label 1,9;
begin
 RetraceLen:=0;       
 1:
 screenfreq:=0;
 if badretrace[VesaMode] then goto 9;
 DelayStart(1000000 div maxfreqerror);
 repeat
  refresh(1);
  inc(screenfreq,maxfreqerror);
  fast:=screenfreq>maxgoodfreq;
 until DelayEnd or fast;
 if fast then begin
   if debug then BiosWrite('.');
   badretrace[VesaMode]:=RetraceLen>50;
   inc(RetraceLen,3);
   goto 1;
   end;
 9:
 DetectRetraceLen:=not badretrace[VesaMode];
end;

{---------------------------------------------------------------------------
 Zdetekuje VesaBanking.
 ---------------------------------------------------------------------------}
Procedure TScreen.DetectVesaBanking;
begin
 if (vesaversion>=$100) and (vesamode) and (VramSizeKB>64) then begin
   VesaBanking:=true;{nejdriv nastavi true aby VesaSetBank vubec bezel}
   mem[SegVram:0]:=1;
   VesaIncBank;
   mem[SegVram:0]:=0;
   VesaDecBank;
   VesaBanking:=mem[SegVram:0]=1;
   mem[SegVram:0]:=0;
   end
  else
   VesaBanking:=false;
end;

{---------------------------------------------------------------------------
 Zdetekuje jestli VesaSetvis ceka na paprsek.
 Trva zhruba 0.1s.
 ---------------------------------------------------------------------------}
Procedure TScreen.DetectVesaSetvisSync;
const snimku=15;{aby mereni trvalo nad 55ms i pri nejvetsi freq}
var   fast:boolean;
      setvisfreq:word;
      i:word;
      s:TStopky;
begin
 i:=0;
 setvisfreq:=0;
 if DelayStart(1000000 div zlomeksec) then begin
   {rychle mereni pomoci delayflagu}
   repeat
    i:=1-i;
    vesasetvis(0,i);
    inc(setvisfreq,zlomeksec);
    fast:=setvisfreq>screenfreq+3*maxfreqerror;{3* pro uplnou jistotu, teoreticky by melo stacit 2*}
   until DelayEnd or fast;
   VesaSetvisSyncuje:=not fast;
   end
 else begin
   {pomale mereni pomoci stopek}
   s.Start;
   for i:=1 to snimku do vesasetvis(0,i);
   VesaSetvisSyncuje:=s.LookAt>(snimku*1000 div maxgoodfreq);
   end;
 vesasetvis(0,0);
end;

{---------------------------------------------------------------------------
 Analyzuje info vracene sluzbou 'get mode info'
 a vraci jestli je mod podporovan.
 ---------------------------------------------------------------------------}
FUNCTION ModeInfoSupported(ModeInfo:PModeInfoBlock):boolean;
begin
 ModeInfoSupported:=false;
 with ModeInfo^ do begin
   if (ModeAttributes and 1)=0 then exit;{je mod podporovan?}
   if (ModeAttributes and 64)=64 then exit;{ma frame buffer?}
   if (ModeAttributes and 32)=32 then exit;{je registrove vga kompatibl?}
   if ((WinAAttributes or WinBAttributes) and 6)<>6 then exit;{umi read i write? :-)}
   end;
 ModeInfoSupported:=true;
end;


{---------------------------------------------------------------------------
 Nastavi pozadovany VESA mod a prislusne promenne.
 ---------------------------------------------------------------------------}
Function TScreen.SetMode_VESA(newModel:byte;newMode:word):boolean;

var   ModeInfo:PModeInfoBlock;
      ResItem:PResItem;
      optional:boolean;
      i,j:word;
label freee;
begin

 {nastavi neuspech, pri neuspechu pak uz staci jen exitnout}
 SetMode_VESA:=false;

 {hned se na to vykasle kdyz neni vesa}
 if VesaVersion=0 then exit;

 {hleda mod v seznamu modu; nenalezeno = nepodporovano}
 ResItem:=GetResItem(newModel,newMode);
 if ResItem=nil then exit;

 {nahraje info}
 if not GetModeInfo(newMode,ModeInfo) then exit;

 with ModeInfo^ do begin

   {testuje atributy}
   if not ModeInfoSupported(ModeInfo) then goto freee;
   optional          :=(ModeAttributes and 2)>0;{je k dispozici rozsirene info?}

   {pred zmenou modu provadi bezpecnostni opatreni proti bliknuti}
   {nutno zavolat jeste nez vznikne chaos, viz dalsi prikaz}
   PreAntiBlik;

   CurScreen         :=nil;{prechazi do chaoticke faze kdy cast promennych}
                           {popisuje stary mod, cast novy..}

   {z modeinfo nacte zakladni udaje do promennych}
   BiosOutput        :=(ModeAttributes and 4)>0;{je podporovan bios output?}
   VesaGranularity   :=WinGranularity;{jaka je granularita?}
   lineOffset        :=BytesPerScanLine;{jak jsou dlouhe radky ve videopameti?}
   VesaNowBank       :=0;{po nastaveni modu jsem v banku 0}
   ModeID            :=newMode;

   {nastavi MapModel,biPP,Xres,Yres,charXres,charYres}
   {kdyz to jde, nacte je z modeinfo}
   if optional then begin
     MapModel        :=MemoryModel;
     Xres            :=XResolution;
     Yres            :=YResolution;
     if MemoryModel=model_text
      then BiPP      :=16{v textmodu natvrdo 16 protoze nevim proc vsichni vraci 4}
      else BiPP      :=BitsPerPixel;
     if MemoryModel in [model_packed, model_direct] then
                                          {model_packed - ARK Logic pouziva i pro Hi/TrueColor}
                                          {model_direct - Jedna se o HiColor nebo TrueColor}
      for i:=1 to KnownDirectModes do     {Zanalyzuj umisteni barevnych kanalu}
       with DirectModes[i] do
        if (BitsPerPixel=BPP1)               {Odpovida BitsPerPixel?}
          and (RdMS=RdMS1) and (RdFP=RdFP1)  {cervena}
          and (GMS=GMS1) and (GFS=GFS1)      {zelena}
          and (BMS=BMS1) and (BFS=BFS1)      {modra}
          and (RsMS=RsMS1) and (RsMP=RsMP1)  {reserved, alfa-kanal}
         then begin
           MapModel:=MModel1;
           i:=KnownDirectModes;
           {nebude-li nalezena zadna shoda s tabulkou, jedna se o neznamy mod}
           end;
     end
   {kdyz nejsou parametry v modeinfo, prohleda vlastni tabulky}
   else{=if not optional}
     with ResItem^ do begin
      MapModel       :=aModel;
      BiPP           :=BiPPlist[MapModel];
      Xres           :=aX;
      Yres           :=aY;
      {naplneni charXres a charYres necha na pozdeji (po nastaveni modu)}
      end;
   charXres          :=1;
   charYres          :=1;


   asm
     {nastavi mod}
     mov ax,4f02h;mov bx,newMode           {nastavi parametry pro setmode}
     int 10h                               {vola vesabios}
     cmp ax,4fh;jnz freee                  {testuje zda bylo volani ok}
   end;

   PostAntiBlik;


   {v textmodu loadne font a znova zjisti Xres,Yres,charXres,charYres}
   if MapModel=model_text then begin
     {zkontroluje jestli udaje obyc biosu odpovidaji udajum vesa biosu}
     if bios_GetYres<>Yres then Halt(erBadVBE);
     {nastavi pozadovany font}
     if optional
      then ZadanaVyskaZnaku:=charYres
      else ZadanaVyskaZnaku:=vga_GetCharYres;
     LoadFont(ZadanaVyskaZnaku);
     {zjisti nove Xres,Yres,charXres,charYres}
     Xres            :=bios_GetXres;
     Yres            :=bios_GetYres;
     charXres        :=vga_GetCharXres;
     charYres        :=vga_GetCharYres;
     if (charYres<5) or (charYres>16) then goto freee;{detekce selhala}
     {detekuje chybu biosu (loaduserfont se chova jako by mel jiny pocet scanlines)}
     if (vga_GetScanlines>195) and (vga_GetScanlines<Yres*charYres)
      then Halt(erBadVBE);
     end;

   {adresu zacatku okna do videopameti ve vesamodech nactu z WinA/BSegment}
   if (WinAAttributes and 7)=7 then begin
     SegVram         :=WinASegment;
     VesaUseWinA     :=true;
     VesaUseWinB     :=false;
     VesaBanking     :=WinSize=64;
     end else
   if (WinBAttributes and 7)=7 then begin
     SegVram         :=WinBSegment;
     VesaUseWinA     :=false;
     VesaUseWinB     :=true;
     VesaBanking     :=WinSize=64;
     end else
   if (WinAAttributes and WinBAttributes and 1)=1 then begin
     if WinASegment<>WinBSegment then goto freee;
     SegVram         :=WinASegment;
     VesaUseWinA     :=true;
     VesaUseWinB     :=true;
     VesaBanking     :=WinSize=64;
     end else
   if (WinAAttributes and 6)=6 then begin
     SegVram         :=WinASegment;
     VesaUseWinA     :=true;
     VesaUseWinB     :=false;
     VesaBanking     :=false;
     end else
   if (WinBAttributes and 6)=6 then begin
     SegVram         :=WinBSegment;
     VesaUseWinA     :=false;
     VesaUseWinB     :=true;
     VesaBanking     :=false;
     end else
   goto freee;

   {detekuje a opravuje chybu vesa biosu (vraceni spatneho segmentu)}
   if (MapModel=model_text) and (SegVram=$a000) then begin
     i:=SegVram;
     Seg2Desc(i);
     mem[i:0]:=32;
     if mem[i:0]<>32 then begin
       SegVram       :=$b800;
       WinSize       :=32;
       end;
     end;

   Seg2Desc(SegVram);
   WinSizeKB         :=WinSize;
   VramSizeKB        :=VesaBanksTotal*64;

   end;

 {poznamena si ze je ve VESA modu; z toho plyne:
  -setvis se provadi volanim vesabiosu nezavisle na modelu
  -pokud mozno nepouzivat rutiny nedoporucovane pro vesamody}
 VesaMode            :=true;

 {v textmodu nepodporuju banking}
 if MapModel=model_text then VesaBanking:=false;
 {spolehlive overeni funkcnosti bankingu}
 if VesaBanking then DetectVesaBanking;
 if not VesaBanking then VramSizeKB:=WinSizeKB;
 if not VesaBanking and (longint(Xres)*Yres*BiPP shr 3 div 1024>WinSizeKB)
  then goto freee;{banking nefunguje a obrazovka je vetsi nez WinSize -> }
                  { -> zachova se jako kdyz mod nejde nastavit}

 {detekuje a opravuje chybu vesa biosu (dvakrat vetsi lineoffset)}
 if MapModel=model_text then begin
   {kdyz vrati dvakrat vetsi offset, predpokladam ze to je chyba a srovnam to}
   if lineOffset=4*Xres then lineOffset:=2*Xres;
   {kdyz je ale jeste jinej, uz ohlasim chybu}
   {ve skutecnosti to chyba byt nemusi, ale na 90% je}
   if lineOffset<>2*Xres then Halt(erBadVBE);
   end;

 {je to dobry}
 SetMode_VESA:=true;

 {skok sem kdyz uz je naalokovana pamet a doslo k chybe}
 freee:
  FreeMemDos(pointer(ModeInfo),sizeof(ModeInfo^));

end;






{€€€€€€€€€€€€€€€€ M O D E - X €€€€€€€€€€€€€€€€}

const XModes = 20;
      XModeRes : array[1..XModes,1..2] of Word = (
        (320,200), (320,240), (360,200), (360,240),
        (376,282), (320,400), (320,480), (360,400),
        (360,480), (360,360), (376,308), (256,200),
        (256,240), (256,224), (256,256), (360,270),
        (400,300), (256,400), (256,480), (360,464));

{---------------------------------------------------------------------------
 Tabulky registru pro nastaveni X-modu.
 Struktura jedne polozky:
  bajt EE (identifikator zacatku polozky)
  bajt: clock freq
  wordy: data do crtc
 ---------------------------------------------------------------------------}
procedure XModeInfo;assembler;
 asm
 {320x200}dw 000eeh
 {320x240}dw 0e3eeh,00D06h,03E07h,04109h,0EA10h,0AC11h,0DF12h,0E715h,00616h
 {360x200}dw 0e7eeh,06B00h,05901h,05A02h,08E03h,05E04h,08A05h
 {360x240}dw 0e7eeh,06b00h,05901h,05A02h,08E03h,5E04h,8A05h,0D06h,3E07h,4109h,0EA10h,0AC11h,0DF12h,2D13h,0E715h,616h
 {376x282}dw 0e7eeh,6e00h,5d01h,5e02h,9103h,6204h,8f05h,6206h,0f007h,6109h,310fh,3710h,8911h,3312h,2f13h,3C15h,5C16h
 {320x400}dw 0e3eeh,04009h
 {320x480}dw 0e3eeh,00D06h,03E07h,04009h,0EA10h,0AC11h,0DF12h,0E715h,00616h
 {360x400}dw 0e7eeh,06B00h,05901h,05A02h,08E03h,05E04h,08A05h,04009h
 {360x480}dw 0e7eeh,06B00h,05901h,05A02h,08E03h,5E04h,8A05h,0D06h,3E07h,4009h,0EA10h,0AC11h,0DF12h,2D13h,0E715h,616h
 {360x360}dw 0e7eeh,06b00h,05901h,05A02h,08E03h,05E04h,08A05h,04009h,08810h,08511h,06712h,02D13h,06D15h,0BA16h
 {376x308}dw 0e7eeh,06E00h,5D01h,5E02h,9103h,6204h,8F05h,6206h,0F07h,4009h,310Fh,3710h,8911h,3312h,2F13h,3C15h,5C16h
 {256x200}dw 0e3eeh,05f00h,03f01h,04202h,09f03h,04c04h,00005h
 {256x240}dw 0e3eeh,05f00h,03f01h,04202h,09f03h,04c04h,00005h,00d06h,03e07h,04109h,0ea10h,0ac11h,0df12h,0e715h,616h
 {256x224}dw 0e3eeh,05f00h,3f01h,4202h,8203h,4a04h,9a05h,0b06h,3e07h,08h,4109h,0da10h,9c11h,0bf12h,2013h,0c715h,416h
 {256x256}dw 0e3eeh,5f00h,3f01h,4002h,8203h,4a04h,9a05h,2306h,0b207h,08h,6109h,0a10h,0ac11h,0ff12h,2013h,0715h,1a16h
 {360x270}dw 0e7eeh,06b00h,5901h,5a02h,8e03h,5e04h,8a05h,3006h,0f007h,08h,6109h,2010h,0a911h,1b12h,2d13h,1f15h,2f16h
 {400x300}dw 0a7eeh,07100h,06301h,06402h,9203h,6504h,8205h,4606h,1f07h,08h,4009h,3110h,8011h,2b12h,3213h,2f15h,4416h
 {256x400}dw 0e3eeh,05f00h,03f01h,04202h,09f03h,04c04h,00005h,04009h
 {256x480}dw 0e3eeh,05f00h,03f01h,04202h,09f03h,04c04h,00005h,00d06h,03e07h,04009h,0ea10h,0ac11h,0df12h,0e715h,616h
 {360x464}dw 0e7eeh,06B00h,05901h,05A02h,08E03h,5E04h,8A05h,0D06h,3E07h,4009h,0EA10h,0AC11h,0cF12h,2D13h,0d715h,616h
 {end}    db 0eeh
 end;

{---------------------------------------------------------------------------
 Nastavi zadany Xmod na urovni registru.
 ---------------------------------------------------------------------------}
Procedure SetXMode(newModel:byte;newMode:word); assembler;
asm
 mov   ax,13h
 int   10h           {zacne modem 13h}

 mov   dx,03c4h
 mov   ax,0604h
 call  OutDxAx       {disable chain4}

 mov   ax,0f02h      {nastavi write do vsech bitplanu..}
 call  OutDxAx
 mov   es,SegA000
 xor   di,di
 db 66h;xor ax,ax
 mov   cx,4000h
 db 66h;rep stosw    {..a vymaze videopamet}

 cmp   newModel,model_packed   {if packed..}
 jnz   @un1
 mov   ax,0e04h
 call  OutDxAx       {..enable chain4}
 @un1:
 mov   ax,0100h
 call  OutDxAx       {reset}

 mov   bx,newMode
 lea   di,XModeInfo  {najde v tabulce registru prislusny mod}
 mov   al,0eeh
 mov   ch,0ffh
 push  cs
 pop   es
@dalsi:
 repne scasb
 dec   bx
 jnz   @dalsi
 mov   si,di

 segcs lodsb
 or    al,al
 jz    @@ndot
 mov   dx,03c2h
 out   dx,al         {nastavi clock frekvenci podle tabulky}
 @@ndot:

 mov   dx,03c4h
 mov   ax,0300h
 call  OutDxAx       {restart sequencer}

 call  vga_EnableCrtc{remove crtc protection}
 mov   dx,03d4h
 cld
@crtc:
 segcs lodsw
 cmp   al,0eeh
 jz    @crtcDone
 call  OutDxAx       {nastavi zbyvajici registry podle tabulky}
 jmp   @crtc
@crtcDone:

 cmp   newModel,model_packed   {if unchained..}
 jz    @un2
 mov   ax,14h
 call  OutDxAx       {..doubleword something}
 mov   ax,0e317h
 call  OutDxAx       {..byte something}
 @un2:

 mov   si,newMode    {nacte sirku obrazu z XModeRes..}
 shl   si,2
 mov   ax,[si+offset XModeRes-4]
 shr   ax,3
 push  13h
 push  ax
 call  vga_WriteCrtc {..a podle ni nastavi Offset}

end;


{---------------------------------------------------------------------------
 Nastavi zadany Xmod a prislusne promenne.
 ---------------------------------------------------------------------------}
Function TScreen.SetMode_X(newModel:byte;newMode:word):boolean;
begin
 {nastavi neuspech, pri neuspechu pak uz staci jen exitnout}
 SetMode_X:=false;

 {nepodporovany mod}
 if not (newMode in [1..XModes]) then exit;

 {nastavi mod}
 {pred a po zmene modu provadi bezpecnostni opatreni proti bliknuti}
 PreAntiBlik;
 SetXMode(newModel,newMode);
 PostAntiBlik;

 {videopamet v mutacich modu 13h zacina vzdy na adrese SegA000}
 SegVram           :=SegA000;
 WinSizeKB         :=64;
 if newModel=model_unchained
  then VramSizeKB  :=256
  else VramSizeKB  :=64;

 {v Xmodech neni vystup textu pres BIOS mozny}
 BiosOutput        :=false;

 {ted je jiste ze neni nastaven VESA mod}
 VesaMode          :=false;
 VesaNowBank       :=0;
 VesaBanking       :=false;

 {nastavi promenne popisujici mod}
 MapModel          :=newModel;
 ModeID            :=newMode;
 Xres              :=XModeRes[newMode,1];
 Yres              :=XModeRes[newMode,2];
 if newModel=model_unchained
  then lineOffset  :=Xres shr 2
  else lineOffset  :=Xres;
 charXres          :=1;
 charYres          :=1;
 BiPP              :=8;

 {mod uspesne nastaven}
 SetMode_X         :=true;
end;



{€€€€€€€€€€€€€€€€ S E T V I S  /  S C R O L €€€€€€€€€€€€€€€€}

{---------------------------------------------------------------------------
 Na scanline Y rozdeli obrazovku. Od scanline Y+1 se bude zobrazovat
 od adresy 0 nezavisle na nastaveni Display address start (viz Setvis).
 Zadne kontroly.
 Nemusi fungovat ve vesa modech.
 Zachova registry.
 ---------------------------------------------------------------------------}
PROCEDURE vga_SetLineCompare(y:word);assembler;
 asm
      push ax
      push dx
       mov dx,3d4h
       mov al,18h;mov ah,byte ptr y;call OutDxAx
       mov al,7;out dx,al;inc dx;in al,dx;and al,255-16;test byte ptr y+1,1;jz @no1;add al,16;@no1:out dx,al;dec dx
       mov al,9;out dx,al;inc dx;in al,dx;and al,255-64;test byte ptr y+1,2;jz @no2;add al,64;@no2:out dx,al
      pop dx
      pop ax
 end;

{---------------------------------------------------------------------------
 Na radce Y rozdeli obrazovku. Od radky Y se bude zobrazovat od adresy 0
 nezavisle na nastaveni Display address start (viz Setvis).
 Kdyz Y prekroci pocet radek na obrazovce, obraz rozdelen nebude.
 Nemusi fungovat ve vesa modech.
 Zachova registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.SplitY(y:word);assembler;
 asm push es
     push di
     push bx
     push ax
     les di,self
     mov bx,y
     {porovna s maximem a pripadne zarovna}
     cmp bx,[es:di+maxSplitY]
     jna @notoverflow
     mov bx,[es:di+maxSplitY]
     @notoverflow:
     {otestuje jestli uz neni nastaveno spravne}
     cmp bx,[es:di+nowSplitY]
     je @done
     mov [es:di+nowSplitY],bx
      {roznasobi doublescanem}
      cmp [es:di+DoubleScan],2
      jne @single
      add bx,bx
      inc bx
      @single:
      {nastavi to}
      push bx;call vga_SetLineCompare
    @done:
     pop ax
     pop bx
     pop di
     pop es
 end;

{---------------------------------------------------------------------------
 Hlavni cast Setvisu pro VGA mody.
 Zachova registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.SetvisHi(a:word);assembler;
 asm
     pusha
     push es
     les di,self
     mov dx,3d4h;mov al,0ch;mov ah,byte ptr a+1;call OutDxAx
     inc al;mov ah,byte ptr a;call OutDxAx
     pop es
     popa
 end;

{---------------------------------------------------------------------------
 Doplnek Setvisu pro VGA mody.
 V grafickem 256 color VGA modu umoznuje posun doleva az o 3 pixely.
 V textovem charXres=9 VGA modu umoznuje posun doleva az o 8 pixelu.
 Ve vsech ostatnich VGA modech umoznuje posun doleva az o 7 pixelu.
 Z parametru se berou jen prislusne bity, ostatni nemusi byt vynulovany.
 Ve VESA modech nemusi fungovat.
 Zachova registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.PanLeft(x:byte);assembler;
 asm
     pusha
     push es
     les di,self
     mov dx,3dah;in al,dx;mov dx,3c0h;mov al,33h;out dx,al;
     call wait250ns
     mov al,[es:di+MapModel]
     cmp al,model_text;jz @text
     cmp al,model_unchained;jz @256
     jmp @end

    @text:
     cmp [es:di+charXres],8;jz @others
     cmp [es:di+charXres],9;jz @txt9
     jmp @end

    @others:{ostatni VGA mody}
     mov al,x;and al,7;out dx,al
     jmp @end

    @txt9:{textove VGA mody se sirkou znaku 9}
     mov al,x;dec al;pushf;and al,7;popf;jns @do;or al,8;@do:out dx,al
     jmp @end

    @256:{graficke 256 color VGA mody}
     mov al,x;and al,3;shl al,1;out dx,al
     jmp @end

    @end:
    pop es
    popa
 end;

{---------------------------------------------------------------------------
 Doplnek Setvisu pro textovy mod, umoznuje posun nahoru az o 15 pixelu.
 Zachova registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.PanUp(y:byte);assembler;
 asm
     push ax
     push dx
     mov dx,3d4h
     mov al,8
     mov ah,y
     and ah,15
     call OutDxAx
     pop dx
     pop ax
 end;

{---------------------------------------------------------------------------
 Nastavi levy horni roh obrazu do souradnic x,y.
 Souradnice jsou v pixelech, a to i v textmodu.
 S vadnym vesa biosem nemusi fungovat.
 ---------------------------------------------------------------------------}
Procedure TScreen.Setvis(x,y:word);assembler;
 asm
     les di,self
     mov ax,x;mov [es:di+vramVisX],ax
     mov ax,y;mov [es:di+vramVisY],ax

     cmp [es:di+vesamode],0;jz @NOVESA

   @VESA:
     push x
     push y
     db 66h;push word ptr self;call vesasetvis
     jmp @DONE

   @NOVESA:
     mov al,[es:di+MapModel]
     cmp al,model_text;jz @TEXT
     cmp al,model_unchained;jz @UNCHAINED
     cmp al,model_packed;jz @PACKED
     jmp @DONE

   @TEXT:
     mov ax,x;xor dx,dx;div [es:di+charXres];mov bx,ax{bx=Hi(X),dx=LoX}
     push dx{push for panleft}
     mov ax,y;xor dx,dx;div [es:di+charYres]{ax=Hi(Y)/lineOffset,dx=LoY}
     push dx{push for panup}
     mov dx,[es:di+lineOffset];shr dx,1;mul dx;add ax,bx{ax=Hi(XY)}
     push ax{push for setvishi}
     db 66h;push word ptr self;call WaitForTrace
     {pushed before}db 66h;push word ptr self;call SetvisHi
     db 66h;push word ptr self;call WaitForRetrace
     {pushed before}db 66h;push word ptr self;call PanUp
     {pushed before}db 66h;push word ptr self;call PanLeft
     mov [es:di+synced],1
     jmp @DONE

   @UNCHAINED:
   @PACKED:
     mov ax,y;mov bx,[es:di+vramXres];shr bx,2;mul bx
     mov bx,x;shr bx,2;add ax,bx
     push ax{push for setvishi}
     db 66h;push word ptr self;call WaitForTrace
     {pushed before}db 66h;push word ptr self;call SetvisHi
     db 66h;push word ptr self;call WaitForRetrace
     push x;db 66h;push word ptr self;call PanLeft
     mov [es:di+synced],1
     jmp @DONE

   @DONE:
 end;





{€€€€€€€€€€€€€€€€ CLIPPING €€€€€€€€€€€€€€€€}

{---------------------------------------------------------------------------
 Kdyz chci namapovat blok velikosti srcSize do oblasti destRect lezici
 v destRng (zde je ten clipping, destRect nemusi byt uvnitr destRng),
 tato procedure spocita newSrcRect a newDestRect, ktere pouziji jako
 parametry pro src^.ResizeBtB2Box(dest,...).
 ---------------------------------------------------------------------------}
Procedure GetResizeClipping(srcSize,destA,destB,destRngA,destRngB:integer;var newSrcA,newSrcB,newDestA,newDestB:integer);
begin
 {checks}
  {$ifdef beta}
  if (srcSize<0) or (destRngB-destRngA<0) or (destA=destB) then erBetaMsg('getresizeclipping chaos 1');
  {$endif}
 {vysledky za predpokladu ze nic neclipuje}
  newSrcA:=0;
  newSrcB:=srcSize;
  newDestA:=destA;
  newDestB:=destB;
 {clipping}
  if newDestA<destRngA then begin
    inc(newSrcA,longint(newSrcB-newSrcA)*(destRngA-newDestA) div (newDestB-newDestA));
    newDestA:=destRngA;
    end;
  if newDestB>destRngB then begin
    newDestB:=destRngB;
    {nastavi newSrcB tak, aby platilo (newSrcB-newSrcA)/srcSize=(newDestB-newDestA)/(destB-destA)}
    newSrcB:=longint(newDestB-newDestA)*srcSize div (destB-destA)+newSrcA;
    end;
end;

Procedure GetResizeBltClipping(srcSize:TPoint;destRect:TRect;destRng:TRect;var newSrcRect:TRect;var newDestRect:TRect);
begin
 GetResizeClipping(srcSize.x,destRect.a.x,destRect.b.x,destRng.a.x,destRng.b.x,
                   newSrcRect.a.x,newSrcRect.b.x,newDestRect.a.x,newDestRect.b.x);
 GetResizeClipping(srcSize.y,destRect.a.y,destRect.b.y,destRng.a.y,destRng.b.y,
                   newSrcRect.a.y,newSrcRect.b.y,newDestRect.a.y,newDestRect.b.y);
end;



{€€€€€€€€€€€€€€€€ M Y S €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Vygeneruje bitmapy nekolika standardnich sipek.
 ---------------------------------------------------------------------------}
var   mouseBaseColor:byte;
const mouseColors=4;
      mousePalette:array[1..12] of byte=(18,18,0, 30,30,0, 45,45,0, 58,58,0);

      s=1;
      t=2;
      u=3;
      v=4;

      sipka0sir=7;
      sipka0vys=9;
      sipka0data:array[1..sipka0sir*sipka0vys] of byte=(
             u,t,t,s,0,0,0,
             t,v,u,t,t,s,0,
             t,v,v,v,u,t,0,
             t,v,v,u,t,0,0,
             t,v,u,v,t,0,0,
             t,u,t,u,v,s,0,
             t,0,0,t,u,t,0,
             0,0,0,0,t,v,s,
             0,0,0,0,0,t,s);

      sipka1sir=8;
      sipka1vys=16;
      sipka1data:array[1..sipka1sir*sipka1vys] of byte=(
             u,  s,  s,  0,  0,  0,  0,  0,
             u,  t,  t,  s,  s,  0,  0,  0,
             t,  v,  u,  t,  s,  s,  s,  0,
             t,  u,  v,  v,  t,  t,  s,  0,
             t,  u,  v,  u,  v,  t,  s,  0,
             t,  v,  u,  v,  t,  s,  0,  0,
             t,  u,  v,  u,  s,  0,  0,  0,
             t,  v,  u,  v,  t,  0,  0,  0,
             t,  u,  t,  u,  u,  s,  0,  0,
             t,  t,  s,  t,  u,  t,  0,  0,
             t,  s,  0,  s,  u,  u,  s,  0,
             t,  0,  0,  0,  t,  u,  t,  0,
             0,  0,  0,  0,  s,  u,  u,  s,
             0,  0,  0,  0,  0,  t,  u,  s,
             0,  0,  0,  0,  0,  s,  t,  s,
             0,  0,  0,  0,  0,  0,  s,  s);

      sipka2sir=15;
      sipka2vys=16;
      sipka2data:array[1..sipka2sir*sipka2vys] of byte=(
             0,s,s,s,s,s,0,0,0,0,0,0,0,0,0,
             s,s,t,t,t,t,s,s,s,0,0,0,0,0,0,
             s,t,t,u,u,u,u,t,t,s,s,0,0,0,0,
             s,t,u,v,v,v,v,v,u,u,t,s,0,0,0,
             s,t,u,v,v,v,v,v,u,u,t,s,0,0,0,
             s,t,u,v,v,v,v,u,t,s,s,0,0,0,0,
             s,t,u,v,v,u,u,t,s,s,0,0,0,0,0,
             s,t,u,v,t,v,v,u,s,s,0,0,0,0,0,
             s,t,u,u,t,t,t,u,u,t,s,0,0,0,0,
             s,t,u,t,s,s,s,t,u,u,t,s,0,0,0,
             s,t,t,s,0,0,0,s,t,v,u,t,s,0,0,
             s,t,s,0,0,0,0,0,s,u,v,u,t,s,0,
             s,s,0,0,0,0,0,0,0,s,u,v,u,t,s,
             0,0,0,0,0,0,0,0,0,s,t,u,u,t,s,
             0,0,0,0,0,0,0,0,0,0,s,t,t,s,s,
             0,0,0,0,0,0,0,0,0,0,0,s,s,s,0);

      sipka3sir=1;
      sipka3vys=1;
      sipka3data:array[1..sipka3sir*sipka3vys] of word=($0f00+ord('˛'));

{---------------------------------------------------------------------------
 Nastavi ktere barvy pouzije sipka mysi. Defaultne je nastaveno 1,
 tedy barvy 1..4.
 ---------------------------------------------------------------------------}
PROCEDURE MouseSetBaseColor(newbase:byte);
var   i:word;
begin
 for i:=ofs(sipka0data) to ofs(sipka2data)+sizeof(sipka2data)-1 do
  if mem[dseg:i]>0 then inc(mem[dseg:i],newbase-mouseBaseColor);
 mouseBaseColor:=newbase;
end;

{---------------------------------------------------------------------------
 Inicializuje sipku mysi = vybere vhodnou standardni sipku pro tohle rozliseni
 a naalokuje buffer pro ukladani pozadi pod sipkou.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseSetPointer(p:PBitmap;pointX,pointY:word);
var   oldmouse:boolean;
begin
 oldmouse:=MouseHide;
 MouseKillPointer(true);
 if p=nil then begin
   mousePoint.X       :=0;
   mousePoint.Y       :=0;
   case MapModel of
     model_text:         mouseBitmap:=InitStaticBitmap(model_text,sipka3sir,sipka3vys,@sipka3data,true);
     model_packed,
     model_unchained:
       if Yres>Xres then mouseBitmap:=InitStaticBitmap(model_packed,sipka1sir,sipka1vys,@sipka1data,true) else
       if Yres<350  then mouseBitmap:=InitStaticBitmap(model_packed,sipka0sir,sipka0vys,@sipka0data,true) else
                         mouseBitmap:=InitStaticBitmap(model_packed,sipka2sir,sipka2vys,@sipka2data,true);
     else erMsg('Pro tento model nen° k dispozici bitmapa my®i, dodej vlastn°.');
     end;
   if mouseBitmap^.MainPal<>nil then
    with mouseBitmap^.MainPal^ do begin
     first:=mouseBaseColor;
     last :=mouseBaseColor+mouseColors-1;
     move(mousePalette,pal[3*mouseBaseColor],3*mouseColors);
     end;
   end
  else begin
   mousePoint.X       :=pointX;
   mousePoint.Y       :=pointY;
   mouseBitmap        :=p;
   end;
 with mouseBitmap^ do begin
   new(mouseBuffer,Init(MapModel,sizeX,sizeY));
   mouseRng.Assign(0,0,Xres-sizeX,Yres-sizeY);
   mouseRng.Move(mousePoint.x,mousePoint.y);
   end;
 MouseSetRange;
 MouseRescanState;
 if oldmouse then MouseShow;
end;

{---------------------------------------------------------------------------
 Vymeni sipku.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseSwapPointer(var b:PBitmap;var p:TPoint);
var   oldB:PBitmap;
      oldP:TPoint;
      oldmouse:boolean;
begin
 oldmouse:=MouseHide;
 oldB:=mouseBitmap;
 oldP:=mousePoint;
 MouseKillPointer(false);
 MouseSetPointer(b,p.x,p.y);
 b:=oldB;
 p:=oldP;
 if oldmouse then MouseShow;
end;

{---------------------------------------------------------------------------
 Uvolni buffer pro ukladani bitmapy pod sipkou a volitelne i sipku.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseKillPointer(kill:boolean);
begin
 KillObj(mouseBuffer);
 if kill then KillObj(mouseBitmap) else mouseBitmap:=nil;
end;

{---------------------------------------------------------------------------
 Nastavi rychlost mysi podle aktualniho modu a promenne MouseSpeed.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseAdjustSpeed;
begin
 mouseSetSpeed(200000 div mouseSpeed div Xres,
               200000 div mouseSpeed div Yres);
end;

{---------------------------------------------------------------------------
 Zpristupni paletu mysi.
 ---------------------------------------------------------------------------}
Function TScreen.MousePal:PPal;
begin
 if mouseBitmap=nil then MousePal:=nil else MousePal:=mouseBitmap^.MainPal;
end;

{---------------------------------------------------------------------------
 Kresli sipku mysi.
 ---------------------------------------------------------------------------}
Function TScreen.MouseShow:boolean;
var   oldpen:byte;
begin
 {$ifdef beta}
 if debugpal then SetHWCol(0,0,0,63);
 if mouseWarning<>0 then erBetaMsg('chyba v synchronizaci mouseshow '+stri(mouseWarning));
 mouseWarning:=1;
 {$endif}
 MouseShow:=mouseflag;
 if not mouseflag then begin
   mouseSipka:=mouse;
   oldpen:=pen;
   pen:=PEN_SCREEN;
   Box2BtF(mouseBuffer,mouseSipka.X-mousePoint.X,mouseSipka.Y-mousePoint.Y);
   BtF2Box(mouseBitmap,mouseSipka.X-mousePoint.X,mouseSipka.Y-mousePoint.Y);
   pen:=oldpen;
   mouseflag:=true;
   mouseRedrawFlag:=true;
   end;
 {$ifdef beta}
 mouseWarning:=0;
 if debugpal then SetHWCol(0,0,0,0);
 {$endif}
end;

{---------------------------------------------------------------------------
 Maze sipku mysi. Vraci jeji puvodni stav.
 ---------------------------------------------------------------------------}
Function TScreen.MouseHide:boolean;
var   oldpen:byte;
begin
 {$ifdef beta}
 if debugpal then SetHWCol(0,63,0,0);
 if mouseWarning<>0 then erBetaMsg('chyba v synchronizaci mousehide '+stri(mouseWarning));
 mouseWarning:=2;
 {$endif}
 MouseHide:=mouseflag;
 if mouseflag then begin
   oldpen:=pen;
   pen:=PEN_SCREEN;
   BtF2Box(mouseBuffer,mouseSipka.X-mousePoint.X,mouseSipka.Y-mousePoint.Y);
   pen:=oldpen;
   mouseflag:=false;
   end;
 {$ifdef beta}
 mouseWarning:=0;
 if debugpal then SetHWCol(0,0,63,0);
 {$endif}
end;

{---------------------------------------------------------------------------
 Do rect nastavi jakou oblast na obrazovce zabira sipka (v PEN_SCREEN).
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseGetRect(var rect:TRect);
begin
 rect.a.x:=mouseSipka.X-mousePoint.X;
 rect.a.y:=mouseSipka.Y-mousePoint.Y;
 rect.b.x:=rect.a.x+mouseBitmap^.sizeX;
 rect.b.y:=rect.a.y+mouseBitmap^.sizeY;
end;

{---------------------------------------------------------------------------
 Do mouseX,Y nacte polohu mysi.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseRescanState;
begin;
 mouseGet(mouse.X,mouse.Y,mouse.Z);
end;

{---------------------------------------------------------------------------
 Do presX,Y,Z zapise souradnice posledniho stisku mysi byl-li, jinak nemeni.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseRescanPress;
begin
 mys.mouseRescanPress(mousePres.X,mousePres.Y,mousePres.Z);
end;

{---------------------------------------------------------------------------
 Nahrada mys.mouseSetRange.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseSetRange;
begin
 with mouseRng do mys.mouseSetRange(a.x,a.y,b.x,b.y);
end;

{---------------------------------------------------------------------------
 Nahrada mys.mouseSetPos.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseSetPos(x,y:integer);
begin
 mouse.X:=Bounded(x,mouseRng.a.x,mouseRng.b.x);
 mouse.Y:=Bounded(y,mouseRng.a.y,mouseRng.b.y);
 mys.mouseSetPos(mouse.X,mouse.Y);
end;

{---------------------------------------------------------------------------
 Posune sipku o dx,dy. Pri preteceni zarovna do povoleneho rozsahu.
 Neprekresluje sipku, na to pouzij redraw.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseShift(dx,dy:integer);
begin
 MouseSetPos(mouse.X+dx,mouse.Y+dy);
end;

{---------------------------------------------------------------------------
 Prekresli sipku do nove polohy v mouseX,Y.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseRedraw;
begin
 if (mouse.X<>mouseSipka.X) or (mouse.Y<>mouseSipka.Y) then
  if mouseFlag then begin
    MouseHide;
    MouseShow;
    end;
end;


{€€€€€€€€€€€€€€€€ E V E N T Y €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Zpracuje signaly z klavesnice, ovsem jen ty co jdou pres dos.
 ---------------------------------------------------------------------------}
Procedure TScreen.KeyboardRescan;
begin
 while keypressed do PushEvent(ReadEvent);
end;

{---------------------------------------------------------------------------
 Do vlastniho eventbufferu ulozi klavesu. Ta pri nejblizsi prilezitosti
 vyvola event.
 ---------------------------------------------------------------------------}
Procedure TScreen.PushEvent(e:TEvent);
begin
 if events<32 then begin
  inc(events);
  eventbuf[events]:=e;
  end;
end;

{---------------------------------------------------------------------------
 Vraci true a udalost se souradnicemi
  nebo false, kdyz se nic nedeje.
 Udalost je bud znak z klavesnice nebo neco z mbXXXX (stisk mysi).
 ---------------------------------------------------------------------------}
Function TScreen.GetEvent(var event:TEvent;var pos:TPoint):boolean;
begin
 if mousePres.Z>0 then begin
   event      :=MakeEvent(256-mousePres.Z,#0,#0);
   pos        :=mousePres;
   mousePres.Z:=0;
   GetEvent   :=true;
   end else
 if events>0 then begin
   event      :=eventbuf[1];
   dec(events);
   move(eventbuf[2],eventbuf[1],events*sizeof(TEvent));
   pos        :=mouse;
   GetEvent   :=true;
   end
 else
   GetEvent   :=false;
end;

{---------------------------------------------------------------------------
 Vymaze frontu udalosti.
 ---------------------------------------------------------------------------}
Procedure TScreen.ResetEvents;
begin
 events:=0;
end;


{€€€€€€€€€€€€€€€€ M O D €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Je karta VGA ?
 ---------------------------------------------------------------------------}
FUNCTION  IsVga:boolean;assembler;
 asm
     mov ax,1a00h;int 10h
     cmp al,1ah;jnz @novga
     cmp bl,7;jz @vga
     cmp bl,8;jz @vga
     @novga:mov al,0;jmp @end
     @vga:mov al,1
     @end:
 end;

{---------------------------------------------------------------------------
 Vraci DCV index karty (kolik stihne zobrazit frejmu v modu 13h).
 Presnost udava o kolik jednotek se smi zmylit. Presnost>=1.
 Mereni trva 1/presnost sekund.
 Zmeni mod na 13h.
 ---------------------------------------------------------------------------}
FUNCTION  DCV(presnost:word):word;
var   i:word;
Begin
 if presnost=0 then erMsg('Nelze mà©it DCV s p©esnost° 0.');
 CurScreen:=nil;
 asm mov ax,13h;int 10h;end;
 i:=0;
 DelayStart(1000000 div presnost);
 repeat
  asm
   mov es,SegA000
   xor si,si
   xor di,di
   mov cx,16000
   db 66h;rep stosw
   inc i
  end;
 until DelayEnd;
 DCV:=i*presnost;
end;

{---------------------------------------------------------------------------
 Je zadany mod VESA mod ?
 ---------------------------------------------------------------------------}
Function TScreen.IsVesamode(testModel:byte;testMode:word):boolean;
begin
 IsVesamode:=(testMode and $300)>0;
end;

{---------------------------------------------------------------------------
 Nastavi rozsah "Ful" (viz bitblt operace) na obrazovku nebo celou videopamet.
 Vraci jake bylo predchozi nastaveni.
 ---------------------------------------------------------------------------}
Function TScreen.ExpandFul(expand:boolean):boolean;
begin
 ExpandFul:=(sizeX=vramXres) and (sizeY=vramYres);
 if expand then begin
   SizeX    :=vramXres;
   SizeY    :=vramYres;
   if WinSizeKB=64 then inc(SizeY);{aby pri Clr2Ful smazal i posledni nekompletni radek videopameti}
      {pozor prasarna. urcite skodi pri winsize<>64, dalsi se ukaze casem..}
   end
  else begin
   SizeX    :=Xres;
   SizeY    :=Yres;
   end;
 SizeXb     :=longint(SizeX)*BiPP shr 3;
end;

{---------------------------------------------------------------------------
 Do rect nastavi jaky vyrez bitmapy je skutecne ve videopameti.
 U TScreen to nema vyznam, protoze je vzdy cela ve vram, ale u TScrolScreen
 jde o uzitecnou vec.
 ---------------------------------------------------------------------------}
Procedure TScreen.GetClipping(var rect:TRect);
begin
 rect.a.x:=0;
 rect.a.y:=0;
 rect.b.x:=sizeX;
 rect.b.y:=sizeY;
end;

{---------------------------------------------------------------------------
 Natahne nektere parametry aktualniho modu,
 ktere se musi zjistovat setupem a ukladat do konfiguracniho souboru.
 Zde jde pouze o SetvisYBug, ale pri scrollingu (v TScrolScreen) je potreba
 nastavit radu dalsich veci, proto je metoda virtualni.
 ---------------------------------------------------------------------------}
Procedure TScreen.LoadCfg;
begin
 setvisYbug:=-1;
 gotoYbug:=-1;
end;

{---------------------------------------------------------------------------
 Nastavi pozadovany mod a vsechny potrebne promenne.

 Mod jehoz cislo odpovida standardnim VESA modum je povazovan za VESA mod.
 Kazdy jiny graficky mod ma nadeklarovanou prislusnou konstantu.
 Textovy mod:
   bity 0..6     - pozadovany pocet radek
   bit  7        - nemazat videopamet
   bity 8..9     - oznacuje VESA mody
   bity 10..11   - 0 - necha defaultni sirku znaku
                   1 - nastavi sirku znaku na 8 (+1024)
                   2 - nastavi sirku znaku na 9 (+2048)
 ---------------------------------------------------------------------------}
Function TScreen.SetMode(newModel:byte;newMode:word):boolean;
begin
 inherited Init(newModel,BiPPlist[newModel],{rozmery zatim neznam}0,0);

 {zapamatuje si prevscreen}
 if CurScreen<>@self then
  if CurScreen<>nil then PrevScreen:=CurScreen else begin
    PrevModel:=model_text;
    if bios_GetMode=3 then PrevMode:=bios_GetYres
                      else PrevMode:=25;
    end;

 {nastavi mod}
 case newmodel of
   model_text:if IsVesamode(newModel,newMode)
                 then SetMode:=SetMode_VESA(newModel,newMode){VESA textmod}
                 else SetMode:=SetMode_TEXT(newMode);        {VGA textmod}
   model_unchained,
   model_packed:if IsVesamode(newModel,newMode)
                 then SetMode:=SetMode_VESA(newModel,newMode){VESA packed 256color}
                 else SetMode:=SetMode_X(newModel,newMode);  {VGA packed/unchained 256color}
   model_direct,                                        {Libovolny Hi/TrueColor}
   model_BGR15,                                         {standardni HiColor 15bit}
   model_RGB15,                                         {nestandardni HiColor 15bit,
                                                          v Cechach nepozorovan, jen u prastarych SVGA}
   model_BGR16,                                         {standardni HiColor 16bit}
   model_RGB16,                                         {nestandardni HiColor 16bit, viz RGB15}
   model_BGR24,                                         {standardni TrueColor 24bit}
   model_RGB24,                                         {nestandardni TrueColor 24bit, viz RGB24}
   model_BGRA32:      SetMode:=SetMode_VESA(newModel,newMode);{standardni TC 32bit}
   else               SetMode:=false;                        {nepodporovany mod}
  end;
end;

{---------------------------------------------------------------------------
 Obnovi stav obrazovky (rozliseni fyzicke i virtualni, split, mys...
  ale ne bitmapu a paletu).
 Pozor: kdyz pred reinitem zmenis LoadFont, muze se nastavit mod s jinym
  poctem radek nez byl prve, tim vznikne pekny chaos.
 ---------------------------------------------------------------------------}
Procedure TScreen.ReInit;
begin
 if CurScreen=@self then exit;
 if (CurScreen=nil) or (CurScreen^.ModeID<>ModeID) or (CurScreen^.MapModel<>MapModel)
  {znova nastavi mod, ale uz nemusi detekovat kdeco}
  then begin
    if VesaMode then begin
      asm les bx,self;mov bx,[es:bx+ModeID];or bx,8000h;mov ax,4f02h;int 10h;end;
      VesaNowBank:=0;
     end
    else
     case MapModel of
      model_packed,
      model_unchained:SetXMode(MapModel,ModeID);
      model_text:begin
                  asm mov ax,3;int 10h;end;
                  {na prani natvrdo setne sirku znaku v pixelech}
                  vga_SetCharXres(charXres);
                 end;
      end
    end
  {prevezme aktualni mod, ale pri tom musi opravit nowbank}
  else begin
    vesaNowBank:=CurScreen^.vesaNowBank;
    end;
 if MapModel=model_text then LoadFont(ZadanaVyskaZnaku);
 CurScreen:=@self;
 if MapModel<>model_text then BlackHWPal;{zcerna paletu protoze nasledujici
   radky muzou na obrazovku dostat nesmazanou vramku}
 SetVramXRes(vramXres);
 vga_SetLineCompare(DoubleScan*(nowSplitY+1)-1);
 SetVis(vramVisX,vramVisY);
 mouseSetRange;
 mouseSetPos(mouse.X,mouse.Y);
 mouseAdjustSpeed;
end;

{---------------------------------------------------------------------------
 Prevezme od jine obrazovky jejiho predka (jinou obrazovku),
 ktereho nastavi (ReInit) pri sve destrukci (Done).
 ---------------------------------------------------------------------------}
Procedure TScreen.GetParentFrom(s:PScreen);
begin
 prevScreen:=s^.prevScreen;
 prevModel :=s^.prevModel;
 prevMode  :=s^.prevMode;
end;

{---------------------------------------------------------------------------
 Nastavi sirku virtualni obrazovky v pixelech (resp znacich v textmodu),
 pripadne nejblizsi vyssi sirku.
 Opravi:
  - vramXres
  - vramYres
  - lineOffset
 Vraci true pokud se podarila nastavit zadana nebo vyssi hodnota.
 Pozor: pokud vadny vesa bios vraci uspech ale nic nenastavi, tato rutina
   se nemuze branit, nepozna to.
 ---------------------------------------------------------------------------}
Function TScreen.SetVramXRes(virtualX:word):boolean;
var   newcrtc:word;
      ret_vramXres,ret_lineOffset:word;
      exp:boolean;
label doneOk,doneBad;
begin
 {$ifdef beta}
 if CurScreen<>@self then erBetaMsg('setvramxres 1');
 {$endif}

 {nastavi neuspech, pri neuspechu pak uz staci jen exitnout}
 SetVramXRes:=false;

 exp:=sizeY>Yres;

 IF VesaMode then
  begin
   virtualX:=virtualX*charXres;{prevede udaj ze znaku na pixely}
   asm
       mov ax,4f06h;mov bl,0          {sluzba set virtual length}
       mov cx,virtualX                {nastavi parametry}
       int 10h                        {vola vesabios}
       cmp ax,4fh;jnz donebad         {probehla sluzba uspesne?}
       mov ax,4f06h;mov bl,1          {sluzba get virtual length}
       int 10h                        {vola vesabios}
       cmp ax,4fh;jnz donebad         {probehla sluzba uspesne?}
       mov ret_lineOffset,bx          {ulozi vysledky}
       mov ret_vramXres,cx
   end;
   virtualX:=virtualX div charXres;{prevede udaje z pixelu na znaky}
   ret_vramXres:=ret_vramXres div charXres;

   {if vbe daz heavy kaoz..}
   if (ret_lineOffset=lineOffset) xor (ret_vramXres=vramXres) then begin
     {try to return old state}
     virtualX:=vramXres*charXres;
     asm mov ax,4f06h;mov bl,0;mov cx,virtualX;int 10h;end;
     goto donebad;
     end;

   lineOffset:=ret_lineOffset;
   vramXres  :=ret_vramXres;
  end
 ELSE
  case MapModel of
   model_unchained:begin
                    newcrtc          :=(virtualX+7) shr 3;
                    vga_SetLineOffset(newcrtc);
                    lineOffset       :=newcrtc shl 1;
                    vramXres         :=newcrtc shl 3;
                   end;
   model_packed:   begin
                    newcrtc          :=(virtualX+7) shr 3;
                    vga_SetLineOffset(newcrtc);
                    lineOffset       :=newcrtc shl 3;
                    vramXres         :=newcrtc shl 3;
                   end;
   model_text:     begin
                    newcrtc          :=(virtualX+1) shr 1;
                    vga_SetLineOffset(newcrtc);
                    lineOffset       :=newcrtc shl 2;
                    vramXres         :=newcrtc shl 1;
                    memW[seg0040:$4a]:=vramXres;
                   end;
   else            exit;
   end;

 doneOk:
  {toto provadi po uspesnem nastaveni, presto jeste muze vratit false
   pokud vesa bios nastavil min nez mel (ma nastavovat nejblizsi VYSSI hodnotu)}
  SetVramXRes       :=vramXres>=virtualX;
  vramYres          :=longint(VramSizeKB)*1024*8 div (vramXres*BiPP);
  {udaj z vramX/Yres musi prenest do sizeX/Y}
  ExpandFul(exp);
 doneBad:
end;


{---------------------------------------------------------------------------
 Pokud je na Syncu povesena nejaka rutina, ktera scrolluje s obrazem,
 timhle ji muzes zapnout/vypnout. V move vraci puvodni stav flagu.
 ---------------------------------------------------------------------------}
Procedure TScreen.SwapMoving(var move:boolean);
begin
end;


{---------------------------------------------------------------------------
 Ukonci praci s modem a vrati se do predchoziho.
 ---------------------------------------------------------------------------}
Destructor TScreen.Done;
begin
 if not SilentDone then MouseHide;
 MouseKillPointer(true);
 if not SilentDone then
  if PrevScreen<>nil
    then PrevScreen^.ReInit
    else SetMode(PrevModel,PrevMode);
 inherited Done;
 if CurScreen=@self then CurScreen:=nil;
end;





{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ Object ABSTRACT MAP ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

Constructor  TAbstractMap.Init(newmodel,newBiPP,sir,vys:word);
begin
 inherited Init;
 MapModel   :=newmodel;
 storeModel :=newmodel;
 BiPP       :=newBiPP;
 SizeX      :=sir;
 SizeY      :=vys;
 SizeXb     :=longint(sir)*BiPP shr 3;
end;

Function TAbstractMap.MainPal:PPal;
begin
 MainPal:=nil;
end;

Procedure TAbstractMap.Clr2Box(destX,destY,Sirka,Vyska:word);
begin
 case MapModel of model_text:Col2Box(destX,destY,Sirka,Vyska,$720);
                  else       Col2Box(destX,destY,Sirka,Vyska,0);
                  end;
end;

Procedure TAbstractMap.Clr2Ful;
begin
 Clr2Box(0,0,sizeX,sizeY);
end;

Procedure TAbstractMap.Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);
begin
 Abstract;
end;

Procedure TAbstractMap.Col2Ful(pixel:longint);
begin
 Col2Box(0,0,sizeX,sizeY,pixel);
end;

Procedure TAbstractMap.BtB2Box(p:PBitmap;srcX,srcY,sirka,vyska,destX,destY:word);
begin
 Abstract;
end;

Procedure TAbstractMap.BtB2Ful(p:PBitmap;srcX,srcY:word);
begin
 BtB2Box(p,srcX,srcY,sizeX,sizeY,0,0);
end;

Procedure TAbstractMap.BtF2Box(p:PBitmap;destX,destY:word);
begin
 BtB2Box(p,0,0,p^.sizeX,p^.sizeY,destX,destY);
end;

Procedure TAbstractMap.Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);
begin
 Abstract;
end;

Procedure TAbstractMap.Ful2BtB(p:PBitmap;destX,destY:word);
begin
 Box2BtB(p,0,0,sizeX,sizeY,destX,destY);
end;

Procedure TAbstractMap.Box2BtF(p:PBitmap;srcX,srcY:word);
begin
 Box2BtB(p,srcX,srcY,p^.sizeX,p^.sizeY,0,0);
end;


Function TAbstractMap.BoxCopy(srcX,srcY,Sirka,Vyska:word):PBitmap;
var   map:PBitmap;
begin
 New(map,Init(MapModel,Sirka,Vyska));
 if map<>nil then Box2BtF(map,srcX,srcY);
 BoxCopy:=map;
end;

Function TAbstractMap.FulCopy:PBitmap;
begin
 FulCopy:=BoxCopy(0,0,sizeX,sizeY);
end;

Function TAbstractMap.ResizeBoxCopy(srcX,srcY,srcSir,srcVys,destSir,destVys:word):PBitmap;
var   map:PBitmap;
begin
 New(map,Init(MapModel,destSir,destVys));
 if map<>nil then ResizeBox2BtF(map,srcX,srcY,srcSir,srcVys);
 ResizeBoxCopy:=map;
end;

Function TAbstractMap.ResizeFulCopy(destSir,destVys:word):PBitmap;
begin
 ResizeFulCopy:=ResizeBoxCopy(0,0,sizeX,sizeY,destSir,destVys);
end;

Function TBitmap.BoxCopy(srcX,srcY,Sirka,Vyska:word):PBitmap;
var   map:PBitmap;
begin
 map:=inherited BoxCopy(srcX,srcY,Sirka,Vyska);
 if (map<>nil) and (MainPal<>nil) and (map^.MainPal<>nil) then map^.MainPal^:=MainPal^;
 BoxCopy:=map;
end;

Function TBitmap.ResizeBoxCopy(srcX,srcY,srcSir,srcVys,destSir,destVys:word):PBitmap;
var   map:PBitmap;
begin
 map:=inherited ResizeBoxCopy(srcX,srcY,srcSir,srcVys,destSir,destVys);
 {*zkopiruje jen jednu paletu, problem je kdyz jich je vic}
 if (map<>nil) and (MainPal<>nil) and (map^.MainPal<>nil) then map^.MainPal^:=MainPal^;
 ResizeBoxCopy:=map;
end;


Procedure TAbstractMap.Box2Box(p:PAbstractMap;srcX,srcY,Sirka,Vyska,destX,destY:word);
var   map:PBitmap;
begin
 map:=BoxCopy(srcX,srcY,Sirka,Vyska);
 if map=nil then Halt(erLowMem);{*muze kopcit po mensich blocich}
 BtF2Box(map,destX,destY);
 map^.Free;
end;

Procedure TAbstractMap.Ful2Box(p:PAbstractMap;destX,destY:word);
begin
 Box2Box(p,0,0,SizeX,SizeY,destX,destY);
end;

Procedure TAbstractMap.Box2Ful(p:PAbstractMap;srcX,srcY:word);
begin
 Box2Box(p,srcX,srcY,p^.SizeX,p^.SizeY,0,0);
end;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ FLOW ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

procedure TAbstractMap.flowSet(x,y:word);
begin
 Abstract;
end;

function TAbstractMap.flowNext(var bytes:word):pointer;
begin
 Abstract;
end;

procedure TBitmap.flowSet(x,y:word);
begin
 flow.x:=x;
 flow.y:=y;
end;

function TBitmap.flowNext(var bytes:word):pointer;
begin
 if flow.y>=sizeY then begin
   bytes:=0;
   flowNext:=nil;
   end
 else begin
   bytes:=longint(sizeX-flow.x)*BiPP shr 3;
   flowNext:=PLine(@tab^[flow.y]^[flow.x]);
   flow.x:=0;
   inc(flow.y);
   end;
end;

procedure TScreen.flowSet(x,y:word);
begin
 flowAdr:=y*lineOffset+x*BiPP shr 3;
 VesaSetBank(HiWord(flowAdr));
end;

function TScreen.flowNext(var bytes:word):pointer;
begin
 if flowAdr>=VramSizeKB*1024 then begin
   bytes:=0;
   flowNext:=nil;
   end
 else begin
   if LoWord(flowAdr)=0 then begin
     VesaSetBank(HiWord(flowAdr));
     bytes:=32768;
     end
   else
     bytes:=65536-LoWord(flowAdr);
   flowNext:=ptr(SegVram,LoWord(flowAdr));
   inc(flowAdr,bytes);
   end;
end;

Constructor TBoxFlow.Init(source:PAbstractMap;box:TRect);
begin
 if source=nil then Fail;
 if box.Empty then Fail;
 inherited Init(source^.mapModel,source^.BiPP,box.b.x-box.a.x,box.b.y-box.a.y);
 storeModel:=source^.storeModel;
 map:=source;
 start:=box.a;
end;

Procedure TBoxFlow.flowSet(x,y:word);
begin
 flowY:=y;
 zbyvabajtu:=longint(sizeX-x)*BiPP shr 3;
 map^.flowSet(start.x+x,start.y+y);
end;

Function TBoxFlow.flowNext(var bytes:word):pointer;
begin
 if flowY>=sizeY then begin
   bytes:=0;
   flowNext:=nil;
   end
 else begin
   flowNext:=map^.flowNext(bytes);
   dec(zbyvabajtu,bytes);
   if zbyvabajtu<=0 then begin
     inc(bytes,zbyvabajtu);
     flowSet(0,flowY+1);
     end;
   end;
end;

Constructor TMergePalsFlow.Init(source:PBitmap);
begin
 if source=nil then Fail;
 inherited Init(source^.mapModel,source^.BiPP,source^.sizeX,source^.sizeY);
 storeModel:=source^.storeModel;
 globalpal.Init;
 map:=source;
end;

Function TMergePalsFlow.MainPal:PPal;
begin
 MainPal:=@globalpal;
end;

Procedure TMergePalsFlow.flowSet(x,y:word);
begin
 flow.x:=x;
 flow.y:=y;
 zbyvabajtu:=longint(sizeX-x)*BiPP shr 3;
 pixels2rebuild:=0;
end;

Function TMergePalsFlow.flowNext(var bytes:word):pointer;
  procedure Copy2Global(item:PPal);far;
  var i:byte;
      pixels:longint;
  begin
   with item^ do begin
     {rebuildne pal}
     if ((flags and pfStill)=pfStill)
        or
        ( (flow.y>=place.a.y) and (flow.y<place.b.y) and
          (flow.x>=place.a.x) and (flow.x<place.b.x)
        ) then
       Move(item^.pal[3*first],globalpal.pal[3*first],3*(last+1-first));
     {a zaroven spocita za jak dlouho bude dalsi rebuild}
     if ((flags and pfStill)=0) then begin
       {teprv me ceka prvni setkani?}
       if (place.a.y>flow.y)
        or ((place.a.y=flow.y) and (place.a.x>flow.x))
         then pixels:=longint(sizeX)*(place.a.y-flow.y)+place.a.x-flow.x else
       {uz me neceka zadne setkani?}
       if (flow.y>place.b.y-1)
        or ((flow.y=place.b.y-1) and (flow.x>=place.b.x))
         then exit else
       {je paleta roztazena od okraje k okraji?}
       if (place.a.x=0) and (place.b.x=sizeX-1)
        {ano -> jedu az do konce palety}
        then pixels:=longint(sizeX)*(place.b.y-1-flow.y)+place.b.x-flow.x else
       {je pred paletou?}
       if (flow.x<place.a.x)
        then pixels:=place.a.x-flow.x else
       {je uvnitr palety?}
       if (flow.x<place.b.x)
        then pixels:=place.b.x-flow.x
       {je na radku za paletou}
        else pixels:=sizeX-flow.x+place.a.x;
       {preda vysledek}
       pixels2rebuild:=minL(pixels2rebuild,pixels);
       end;
     end;
  end;
var pixels:longint;
begin
 if flow.y>=sizeY then begin
   bytes:=0;
   flowNext:=nil;
   end
 else begin
   if pixels2rebuild=0 then begin
     pixels2rebuild:=$ffffff;
     map^.pals^.ForEach(@Copy2Global);
     globalpal.rgb2BGR;
     end;
   pixels:=minL(pixels2rebuild,sizeX-flow.x);
   dec(pixels2rebuild,pixels);
   flowNext:=PLine(@map^.tab^[flow.y]^[flow.x]);
   bytes:=pixels*BiPP shr 3;
   inc(flow.x,pixels);
   if flow.x=sizeX then begin
     inc(flow.y);
     flow.x:=0;
     end;
   end;
end;



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ SAVE ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

Procedure TAbstractMap.Save(s:PStream);
begin
 if s<>nil then Store(s^);
 KillObj(s);
end;

Procedure TAbstractMap.Store(var s:TStream);
var   i:integer;
      p:pointer;
      globpal:pointer;
      bytes:word;
      tgaHeader:array[0..8] of word;
label 1;
begin
 if mapModel in [model_packed,model_unchained] then
  if MainPal<>nil then begin
     fillchar(tgaHeader,sizeof(tgaHeader),0);
     tgaHeader[6]:=sizeX;
     tgaHeader[7]:=sizeY;
     case storeModel of
       model_packed:begin
         {zapise 8-BIT header}
         tgaHeader[0]:=$100;
         tgaHeader[1]:=1;
         tgaHeader[3]:=$1801;
         tgaHeader[8]:=$2008;
         s.Write(tgaHeader,sizeof(tgaHeader));
         {zapise paletu}
         flowSet(0,0);
         p:=flowNext(bytes);
         s.Write(MainPal^.pal,768);
         {zapise telo}
         while p<>nil do begin
           s.Write(p^,bytes);
           p:=flowNext(bytes);
           end;
         end;
       model_BGR24:begin
         {zapise 24-BIT header}
         tgaHeader[1]:=2;
         tgaHeader[8]:=$2018;
         s.Write(tgaHeader,sizeof(tgaHeader));
         {zapise telo}
         flowSet(0,0);
         1:
         p:=flowNext(bytes);
         globpal:=@MainPal^.pal;
         if (p<>nil) and (bytes<>0) then begin
           asm
            PUSH DS
            PUSH BP
            mov cx,bytes
            les di,freeptr
            segss;db 0fh,0b4h,9eh;dw offset p{LFS BX,BP+P}
            lds bp,globpal
            mov ah,0
            @1:
            db 64h{FS:};mov al,[bx]
            inc bx
            mov si,bp
            add si,ax
            add si,ax
            add si,ax
            movsw
            movsb
            loop @1
            POP BP
            POP DS
           end;
           s.Write(freeptr^,3*bytes);
           goto 1;
           end;
         end;
       end;
     {vse je ok}
     exit;
     end;
 if not dumb then erMsg('Selhalo ukl†d†n° bitmapy.');
end;
(*
Procedure TAbstractMap.Store(var s:TStream);
const tgaHeader:array[0..8] of word=($100,1,0,$1801,0,0,0,0,$2008);
var   i:integer;
      b:TBitmap;
begin
 if mapModel in [model_packed,model_unchained] then
  if MainPal<>nil then
   if b.Init(model_packed,sizeX,1) then begin
     {zapise header}
     tgaHeader[6]:=sizeX;
     tgaHeader[7]:=sizeY;
     s.Write(tgaHeader,sizeof(tgaHeader));
     {zapise paletu}
     with MainPal^ do
      for i:=0 to 255 do begin
        freeB[3*i  ]:=pal[3*i+2] shl 2+2;
        freeB[3*i+1]:=pal[3*i+1] shl 2+2;
        freeB[3*i+2]:=pal[3*i  ] shl 2+2;
        end;
     s.Write(freeB[0],768);
     {zapise telo}
     for i:=0 to sizeY-1 do begin
       Box2BtF(@b,0,i);
       s.Write(b.tab^[0]^,sizeXb);
       end;
     {vse je ok}
     b.Done;
     exit;
     end;
 if not dumb then erMsg('Selhalo ukl†d†n° bitmapy.');
end;
*)


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ ALOKACE BITMAP ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}


{---------------------------------------------------------------------------
 Uvolni obsah bitmapy.
 ---------------------------------------------------------------------------}
PROCEDURE FreeMap(tab:PLines;sir,usedvys:word);
var   delkabloku:word;
      startblok:pointer;
      line:word;
label 1;
begin
 {uvolneni nulove bitmapy}
 if (tab=nil) or (sir=0) or (usedvys=0) then exit;
 {uvolneni nenulove bitmapy}
 line:=0;
 1:
 delkabloku:=0;
 startblok:=tab^[line];
 while line<usedvys do begin
   inc(delkabloku);
   inc(line);
   if (line=usedvys)
   or (PtrRec(startblok).Seg<>PtrRec(tab^[line]).Seg)
   or (PtrRec(tab^[line]).Ofs<>PtrRec(tab^[line-1]).Ofs+sir) then begin
     FreeMem(startblok,sir*delkabloku);
     if line<usedvys then goto 1;{nejumpi aby nenacital tab^[max+1]}
     end;
   end;
end;

{---------------------------------------------------------------------------
 Alokuje obsah bitmapy (sir*vys bajtu).
 Na co nestaci pamet necha nedefinovane.
 Kdyz nestaci pamet ani na sir*minvys, nenaalokuje nic.
 Vraci pocet uspesne naalokovanych radek.
 ---------------------------------------------------------------------------}
FUNCTION  AllocMap(tab:PLines;sir,vys,minvys:word):word;
var   blocklines,i:word;
      pb:PLine;
      line:word;
begin
 {alokace nulove bitmapy}
 if (sir=0) or (vys=0) then begin AllocMap:=0;exit;end;
 {alokace nenulove bitmapy}
 line:=0;
 blocklines:=65520 div sir;
 while line<vys do begin
   if blocklines>vys-line then blocklines:=vys-line;
   if not GetMem(pointer(pb),blocklines*sir) then begin
     {skonci v okamziku kdy vi ze minvys nedosahne}
     if minvys{tolik chci}>=line+blocklines{tolik uz nemuzu} then begin
       FreeMap(tab,sir,line);
       AllocMap:=0;
       exit;
       end;
     if blocklines>1 then begin
       blocklines:=blocklines div 2;
       continue;
       end;
     AllocMap:=line;
     exit;
     end;
   for i:=0 to blocklines-1 do begin
     tab^[line]:=pb;
     inc(line);
     inc(PtrRec(pb).Ofs,sir);
     end;
   AllocMap:=vys;
   end;
end;




{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ Object BITMAP ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}


{---------------------------------------------------------------------------
 Alokuje bitmapu. Spodek bitmapy, na ktery nestacila pamet, zaplni
 posledni naalokovanou linkou.
 Kdyz nestaci pamet ani na minvys linek, nenaalokuje nic.
 ---------------------------------------------------------------------------}
Constructor TBitmap.Init(newmodel:byte;sir,vys:word);
var   i:word;
      p:PPal;
begin
 inherited Init(newmodel,BiPPlist[newmodel],sir,vys);
 {alokuje paletu}
 if newmodel in [model_packed,model_unchained] then
  if AddPal(new(PPal,InitMore(pfStill+pfOnscreen+pfActive,0,255)))=nil then begin Done;Fail;end;
 {alokuje tabulku linek}
 if not GetMem(pointer(tab),4*vys) then begin Done;Fail;end;
 tabsize:=vys;
 {alokuje linky}
 mapsize:=AllocMap(tab,sizeXb,vys,vys);
 if mapsize=0 then begin Done;Fail;end;
 {zajisti aby slo psat i do nenaalokovanejch linek}
 for i:=mapsize to vys-1 do tab^[i]:=tab^[mapsize-1];
end;

{---------------------------------------------------------------------------
 Uvolni bitmapu.
 ---------------------------------------------------------------------------}
Destructor TBitmap.Done;
begin
 {uvolni palety}
 KillObj(pals);
 {uvolni bitmapu}
 if not static then FreeMap(tab,sizeXb,mapsize);
 FreeMem(pointer(tab),4*word(tabsize));
 inherited Done;
end;


{---------------------------------------------------------------------------
 Vytvori PBitmap obsahujici bitmapu na kterou ukazuje tvuj pointer.
 Bezne pouzivano k vytvareni malych bitmapek, ktere nechces ukladat do
 extra souboru, ale naklepes do zdrojaku (pole pixelu)
 Ale lze pouzit treba i k vytvoreni bitmapy obsahujici videopamet v modu 13h
 (InitStaticBitmap(model_packed,320,200,SegA000,false)), pak lze treba psat
 fontem primo do vramky, coz jinak nejde.
 ---------------------------------------------------------------------------}
FUNCTION InitStaticBitmap(model,sir,vys:integer;p:pointer;trans:boolean):PBitmap;
var   b:PBitmap;
begin
 new(b,Init(model,sir,vys));
 if b=nil then Halt(erLowMem) else begin
   b^.StaticMem(p,65535);
   b^.transparent:=trans;
   end;
 InitStaticBitmap:=b;
end;


{---------------------------------------------------------------------------
 Z bitmapy vymazne nektere linky.
 Velmi rychle pri mazani konce (spodku) bitmapy, velmi pomale pri mazani
 zacatku (vrsku) bitmapy.
 Pozor: pamet se neuvolni ted, ale az pri Done.
 ---------------------------------------------------------------------------}
Procedure  TBitmap.DelLines(firstline,lines:word);
begin
 {checks}
 if firstline<sizeY then begin
   if firstline+lines>sizeY then lines:=sizeY-firstline;
   {doit}
   Box2BtB(@self,0,firstline+lines,sizeX,sizeY-firstline-lines,0,firstline);
   dec(sizeY,lines);
   end;
end;

{---------------------------------------------------------------------------
 Do bitmapy vlozi linky.
 Velmi rychle pri vkladani na konci (spodku) bitmapy, velmi pomale
 pri vkladani na zacatku (vrsku) bitmapy.
 ---------------------------------------------------------------------------}
Function TBitmap.InsLines(firstline,lines:word):boolean;
begin
 InsLines:=false;
 {checks}
 if firstline>sizeY then firstline:=sizeY;
 {doit}
 if not AddLines(lines) then exit;
 Box2BtB(@self,0,firstline,sizeX,lines,0,firstline+lines);
 InsLines:=true;
end;

{---------------------------------------------------------------------------
 Na konec (spodek) bitmapy prida linky.
 Velmi rychle.
 Pozor: pri nedostatku pameti muze prialokovat pouze tab, ne map.
 ---------------------------------------------------------------------------}
Function TBitmap.AddLines(lines:word):boolean;
var   rezerva:integer;
      toalloc:integer;
      i:integer;
      tab2:PLines;
begin
 AddLines:=false;
 {vyuziti rezervy v tabsize}
 rezerva:=tabsize-sizeY;
 if rezerva>0 then begin
   if rezerva>lines then rezerva:=lines;
   inc(sizeY,rezerva);
   dec(lines,rezerva);
   end;
 {pridavne alokovani tab}
 if lines>0 then begin
   GetMem(pointer(tab2),4*word(tabsize+lines));
   if tab2=nil then exit;
   Move(tab^,tab2^,4*word(tabsize));
   FreeMem(pointer(tab),4*word(tabsize));
   tab:=tab2;
   inc(tabsize,lines);
   inc(sizeY,lines);
   end;
 {pridavne alokovani map}
 toalloc:=sizeY-mapsize;
 if toalloc>0 then begin
   lines:=AllocMap(PLines(@tab^[mapsize]),sizeXb,toalloc,0);
   inc(mapsize,lines);
   if mapsize=0 then exit;
   for i:=mapsize to tabsize-1 do tab^[i]:=tab^[mapsize-1];
   end;
 AddLines:=true;
end;


{---------------------------------------------------------------------------
 Odalokuje dynamicky ziskanou pamet a misto ni dosadi zadany staticky blok.
 Ten se v zaveru neodalokovava.
 Je-li rawmapa vetsi nez blok, wrapne se (nasimuluje se opakovani bloku
 vickrat za sebou).
 ---------------------------------------------------------------------------}
Procedure  TBitmap.StaticMem(p:pointer;size:word);
var   i          :word;
      lines2wrap :word;
      oldp       :pointer;
begin
 if not static then FreeMap(tab,sizeXb,mapsize);
 static     :=true;
 oldp       :=p;
 lines2wrap :=size div sizeXb;
 for i:=0 to sizeY-1 do begin
   {wrap?}
   if (i mod lines2wrap)=0 then p:=oldp;
   {fill tab}
   tab^[i]:=p;
   inc(Pbyte(p),sizeXb);
   end;
end;

{---------------------------------------------------------------------------
 Odalokuje dynamicky ziskanou pamet a misto ni dosadi zadany staticky blok.
 Ten se v zaveru neodalokovava.
 Je-li rawmapa vetsi nez textura, wrapne se. P je pointer kamkoliv do textury,
 ale durazne se doporucuje davat ho tak, aby v bitmape nevznikaly linky
 obsahujici preteceni segmentu. Tj. sirka bitmapy mocnina dvou a offset P
 nastavit na nasobek sirky bitmapy. Nedodrzeni vede k hrouceni zavislemu
 na typu procesoru a modu v jakem se nachazi.
 ---------------------------------------------------------------------------}
Procedure  TBitmap.StaticTex(p:pointer);
var   i:word;
begin
 if not static then FreeMap(tab,sizeXb,mapsize);
 static     :=true;
 for i:=0 to sizeY-1 do begin
   {fill tab}
   tab^[i]:=p;
   inc(Pbyte(p),sizeXb);
   end;
end;

{---------------------------------------------------------------------------
 Odalokuje dynamicky ziskanou pamet a misto ni dosadi zadany staticky blok.
 Ten se v zaveru neodalokovava.
 Je-li rawmapa vetsi nez vyrez bitmapy, wrapne se (nasimuluje se opakovani
 vyrezu vickrat za sebou).
 ---------------------------------------------------------------------------}
Procedure  TBitmap.StaticMap(map:PBitmap;srcX,srcY:word);
var   i:word;
begin
 if not static then FreeMap(tab,sizeXb,mapsize);
 static     :=true;
 for i:=0 to sizeY-1 do tab^[i]:=PLine(@map^.tab^[(srcY+i) mod map^.sizeY]^[srcX]);
end;


{---------------------------------------------------------------------------
 Zpristupni paletu bitmapy.
 ---------------------------------------------------------------------------}
Function TBitmap.MainPal:PPal;
begin
 if (pals=nil) or (pals^.count=0) then MainPal:=nil
  else MainPal:=pals^.items^[0];
end;

{---------------------------------------------------------------------------
 Viz TPal.SetBright, ale pracuje se vsemi paletami bitmapy.
 ---------------------------------------------------------------------------}
Procedure TBitmap.SetBright(n:byte);
  procedure SetIt(p:PPal);far;
  begin
   with p^ do
    if ((flags and pfOnscreen)>0) and ((flags and pfActive)>0)
     then SetBright(n);
  end;
begin
 if pals<>nil then pals^.ForEach(@SetIt);
end;

{---------------------------------------------------------------------------
 Prida lokalni paletu.
 Jako vysledek vraci tutez paletu.
 ---------------------------------------------------------------------------}
Function TBitmap.AddPal(pal:PPal):PPal;
begin
 if pals=nil then begin
   new(pals,Init(1,1));
   if pals=nil then Halt(erLowMem);
   end;
 pals^.Insert(pal);
 if pals^.count>1 then storeModel:=model_BGR24;
 AddPal:=pal;
end;

{---------------------------------------------------------------------------
 Nastavi lokalni paletu odpovidajici zadane oblasti bitmapy.
 Onscreen znamena ze ji ma nastavit i na obrazovce (normalne
 lokalnim paletam jen nastavi flagy).
 ---------------------------------------------------------------------------}
Procedure TBitmap.SyncPal(scr:TRect;onscreen:boolean);
var   zmena:boolean;
  procedure CheckThisOut(p:PPal);far;
  var scr2:TRect;
      picmimo,palmimo:boolean;
  begin
   with p^ do
    if (flags and pfStill)=0 then begin
      scr2:=scr;
      scr2.Intersect(place);
      picmimo:=scr2.Empty;
      palmimo:=(flags and pfOnscreen)=0;
      if picmimo xor palmimo then begin
        if picmimo then flags:=flags and not pfOnScreen
                   else flags:=flags or      pfOnScreen;
        zmena:=true;
        end;
      end;
  end;
begin
 if (pals<>nil) and (pals^.count>1) then begin
   zmena:=false;
   pals^.ForEach(@CheckThisOut);
   if zmena and onscreen then SetBright(MainPal^.nowbright);
     {nektery palety nastavuje zdanlive zbytecne (uz jsou nastaveny),
     vyznam to ale ma pri kolizich vice palet}
   end;
end;

Procedure TBitmap.Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);assembler;
 asm
      cmp sirka,0;jz @end
      cmp vyska,0;jz @end

      les di,self
      mov al,[es:di+tbitmap.MapModel]
      db 26h,0fh,0b4h,9dh;dw tbitmap.tab{LFS BX,[ES:DI+bitmap.tab]}
      mov cx,destY
      shl cx,2
      add bx,cx

      cmp al,model_text;jz @MODEL_TEXT
      cmp al,model_unchained;jz @MODEL_256
      cmp al,model_packed;jz @MODEL_256
      jmp @END

     @MODEL_256:
      mov al,byte ptr pixel
      @next256line:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      mov cx,sirka
      call REP_STOSB
      dec Vyska
      jnz @next256line
      jmp @END

     @MODEL_TEXT:
      shl destX,1
      mov ax,word ptr pixel
      @nexttextline:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      mov cx,sirka
      call REP_STOSW_no
      dec Vyska
      jnz @nexttextline
      jmp @END

     @END:
 end;

{---------------------------------------------------------------------------
 Zkopci vyrez z jedne do druhe rawmapy (bitmapa s pixelem velikosti 1 byte).
 Pri kopceni do sebe sama za vysledek ani trochu nerucim :).
 ---------------------------------------------------------------------------}
PROCEDURE Raw2Raw(srcRawmap,destRawmap:PBitmap;srcX,srcY,sirka,vyska,destX,destY:word);assembler;
 asm
     push ds

     {checks}
     db 66h;cmp word ptr destRawmap,0;jz @done
     cmp sirka,0;jz @done
     cmp vyska,0;jz @done

     {load params}
     lds si,srcRawmap
     mov cl,[si+TBitmap.transparent]
     db 0fh,0b4h,9ch;dw TBitmap.Tab{LFS BX,[SI+TRawmap.Tab]}
     mov ax,srcY;shl ax,2;add bx,ax
     lds si,destRawmap
     db 0fh,0b5h,94h;dw TBitmap.Tab{LGS DX,[SI+TRawmap.Tab]}
     mov ax,destY;shl ax,2;add dx,ax

     cmp cl,false
     jne @transparent

     {full copy}
     @full:
     db 64h,0c5h,37h{lds si,[FS:BX]};add bx,4;xchg bx,dx;add si,srcX
     db 65h,0c4h,3fh{les di,[GS:BX]};add bx,4;xchg bx,dx;add di,destX
     mov cx,sirka
     call REP_MOVSB_di
     dec vyska
     jnz @full
     jmp @done

     {transparent copy}
     @transparent:
     db 64h,0c5h,37h{lds si,[FS:BX]};add bx,4;xchg bx,dx;add si,srcX
     db 65h,0c4h,3fh{les di,[GS:BX]};add bx,4;xchg bx,dx;add di,destX
     mov cx,sirka
     test di,1
     call REP_TransparentMOVSB_nz
     dec vyska
     jnz @transparent

    @DONE:
     pop ds
 end;

{---------------------------------------------------------------------------
 Namapuje jeden obdelnik do druheho. Pracuje s bajty, ne s pixely!
 Pri kopceni do sebe sama za vysledek ani trochu nerucim :).
 Pozn: Provadi na zacatku kazdeho radku stejne vypocty - prostor pro
  optimalizaci.
 ---------------------------------------------------------------------------}
PROCEDURE _ResizeRaw2Raw(srcRawmap,destRawmap:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);assembler;
 var transparent:byte;
 asm
     push ds

     {checks}
     db 66h;cmp word ptr destRawmap,0;jz @done
     cmp srcSir,0;jz @done
     cmp srcVys,0;jz @done
     cmp destSir,0;jz @done
     cmp destVys,0;jz @done

     {$ifdef beta}
     cmp srcX,0;js @beta
     cmp srcY,0;js @beta
     cmp destX,0;js @beta
     cmp destY,0;js @beta
     jmp @zabeta
     @beta:
      push cs
      push offset @msg1
      call chyby.erBetaMsg
      @msg1:
       db 16,'_resizeraw2raw 1'
     @zabeta:
     {$endif}

     {load params}
     lds si,srcRawmap
     mov cl,[si+TBitmap.transparent]
     mov transparent,cl
     db 0fh,0b4h,9ch;dw TBitmap.Tab{LFS BX,[SI+TRawmap.Tab]}
     mov ax,srcY;shl ax,2;add bx,ax
     lds si,destRawmap
     db 0fh,0b5h,94h;dw TBitmap.Tab{LGS DX,[SI+TRawmap.Tab]}
     mov ax,destY;shl ax,2;add dx,ax
     mov si,bx
     mov di,dx

     {doit}
      mov ax,srcVys
      xor dx,dx
      div destVys
      PUSH AX
      xor ax,ax
      div destVys
      POP DX
      {*cx=?}xor cx,cx
      xor bx,bx
     @full:
      pusha
        shl bx,2
        db 64h{FS};LDS SI,[SI+BX];add si,srcX
        db 65h{GS};LES DI,[DI];add di,destX
        mov cx,srcSir
        mov dx,destSir
        cmp transparent,false
        jnz @tr
        call MapBytesCX2DX_nz
        jmp @notr
        @tr:
        call TransparentMapBytesCX2DX_nz
        @notr:
      popa
      add cx,ax
      adc bx,dx
      add di,4
      dec destVys
      jnz @full

    @DONE:
     pop ds
 end;


Procedure TAbstractMap.ResizeBtB2Box(p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
var   b:PBitmap;
begin
 if (srcSir=destSir) and (srcVys=destVys)
  then BtB2Box(p,srcX,srcY,srcSir,srcVys,destX,destY)
  else begin
   new(b,Init(MapModel,destSir,destVys));
   if b=nil then Halt(erLowMem);
   {*zatim jde jen v modelu packed}
   _ResizeRaw2Raw(p,b,srcX,srcY,srcSir,srcVys,0,0,destSir,destVys);
   BtF2Box(b,destX,destY);
   KillObj(b);
   end;
end;

Procedure TAbstractMap.ResizeBtB2Ful(p:PBitmap;srcX,srcY,srcSir,srcVys:word);
begin
 ResizeBtB2Box(p,srcX,srcY,srcSir,srcVys,0,0,sizeX,sizeY);
end;

Procedure TAbstractMap.ResizeBtF2Box(p:PBitmap;destX,destY,destSir,destVys:word);
begin
 ResizeBtB2Box(p,0,0,p^.sizeX,p^.sizeY,destX,destY,destSir,destVys);
end;

Procedure TAbstractMap.ResizeBtF2Ful(p:PBitmap);
begin
 ResizeBtB2Box(p,0,0,p^.sizeX,p^.sizeY,0,0,sizeX,sizeY);
end;


Procedure TAbstractMap.ResizeBox2BtB(p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
var   b:PBitmap;
begin
 b:=BoxCopy(srcX,srcY,srcSir,srcVys);
 if b=nil then Halt(erLowMem);
 {*zatim jde jen v modelu packed}
 _ResizeRaw2Raw(b,p,0,0,srcSir,srcVys,destX,destY,destSir,destVys);
 KillObj(b);
end;

Procedure TAbstractMap.ResizeFul2BtB(p:PBitmap;destX,destY,destSir,destVys:word);
begin
 ResizeBox2BtB(p,0,0,sizeX,sizeY,destX,destY,destSir,destVys);
end;

Procedure TAbstractMap.ResizeBox2BtF(p:PBitmap;srcX,srcY,srcSir,srcVys:word);
begin
 ResizeBox2BtB(p,srcX,srcY,srcSir,srcVys,0,0,p^.sizeX,p^.sizeY);
end;

Procedure TAbstractMap.ResizeFul2BtF(p:PBitmap);
begin
 ResizeBox2BtB(p,0,0,sizeX,sizeY,0,0,p^.sizeX,p^.sizeY);
end;


Procedure TBitmap.BtB2Box(p:PBitmap;srcX,srcY,sirka,vyska,destX,destY:word);
begin
 if p^.MapModel=MapModel then
  Raw2Raw(p,@self,longint(srcX)*BiPP shr 3,srcY,sirka,vyska,longint(destX)*BiPP shr 3,destY);
end;

Procedure TBitmap.Box2BtB(p:PBitmap;srcX,srcY,sirka,vyska,destX,destY:word);
begin
 if p^.MapModel=MapModel then
  Raw2Raw(@self,p,longint(srcX)*BiPP shr 3,srcY,sirka*BiPP shr 3,vyska,longint(destX)*BiPP shr 3,destY);
end;

Procedure TBitmap.ResizeBtB2Box(p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
begin
 {*zatim jde jen v modelu packed}
 _ResizeRaw2Raw(p,@self,srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys);
end;

Procedure TBitmap.ResizeBox2BtB(p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
begin
 {*zatim jde jen v modelu packed}
 _ResizeRaw2Raw(@self,p,srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys);
end;




{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ SCREEN BITBLTS ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

Procedure TScreen.Col2Box(destX,destY,sirka,vyska:word;pixel:longint);assembler;
 var  bit:word;
      currentsir4:word;
      local_lineOffset:word;
 asm
     {
      ES:DI-videopamet
     }
     cmp Sirka,0;jz @done
     cmp Vyska,0;jz @done

     les di,self
     mov ax,[es:di+lineOffset];mov local_lineOffset,ax
     mov al,[es:di+MapModel]
     mov es,[es:di+SegVram]

     cmp al,model_unchained;jz @UNCHAINED
     cmp al,model_packed;jz @PACKED
     cmp al,model_text;jz @TEXT
     jmp @done


   @TEXT:
      mov ax,destY  {spocita cilovou adresu leveho horniho rohu}
      mul local_lineOffset
      mov di,ax
      add di,destX
      add di,destX

      mov dx,local_lineOffset {napraska to tam}
      sub dx,sirka
      sub dx,sirka
      @nexttextline:
      mov cx,Sirka
      mov ax,word ptr pixel
      call REP_STOSW_o
      add di,dx
      dec Vyska
      jnz @nexttextline
      jmp @done


   @PACKED:
      mov ax,destY  {spocita cilovou adresu leveho horniho rohu a bankne}
      mul local_lineOffset
      mov di,ax
      add di,destX
      adc dx,0
      push dx
      db 66h;push word ptr self;call VesaSetBank

      mov dx,Vyska
      jmp @packed_nextseg

   @PACKED_IncBank:
      db 66h;push word ptr self;call VesaIncBank
   @PACKED_NextSeg:
      {spocita do AX kolik radek muze kreslit bez bankingu, snizi Vyska}
      xor dx,dx
      mov ax,di
      neg ax
      sbb dx,-1
      div local_lineOffset
      cmp dx,Sirka
      sbb ax,-1
      sub Vyska,ax
      jnc @neni_posledni_blok
      add ax,Vyska
      mov Vyska,0
      @neni_posledni_blok:
      mov bx,ax{AX je potreba na pixel, proto obsah AX presouva do BX}
      mov al,byte ptr pixel
      {kresli AX radek v jednom banku}
      @next_packed_line:
      dec bx
      js @ax_lines_done
      mov cx,Sirka
      call REP_STOSB {kresli: Sirka}
      sub di,Sirka
      add di,local_lineOffset
      jmp @next_packed_line
      @ax_lines_done:
      {zbyvajici Vyska=0 -> konec}
      cmp Vyska,0
      jz @done
      {preteceni segmentu se odehralo mimo blok?}
      test di,8000h
      jz @packed_IncBank
      {kresli jeden radek ve kterem dochazi k preteceni banku}
      push di
      push di
      mov cx,di
      neg cx
      call REP_STOSB {kresli: 65536-di}
      push ax
      db 66h;push word ptr self;call VesaIncBank
      pop ax
      pop cx
      add cx,Sirka
      call REP_STOSB {kresli: Sirka+old_di}
      pop di
      add di,local_lineOffset
      {nebyl-li tento radek posledni, pokracuje}
      dec Vyska
      jnz @packed_nextseg
      jmp @done


   @UNCHAINED:
      mov ax,destY
      mul local_lineOffset
      mov di,ax
      mov ax,destX
      shr ax,2
      add di,ax

       {levy kraj plochy tvaru -XXX,--XX,---X}
       mov cx,destX
       and cx,3
       jz @vnitrek
        mov ax,0f02h;shl ah,cl;and ah,0fh
         add sirka,cx
         sub sirka,4
         jc @full
        mov dx,3c4h;call OutDxAx{set out bits}
         call near ptr @StosSlp
         inc di
       {vnitrek plochy tvaru XXXX}
       @vnitrek:
       mov si,sirka
       shr si,2
       jz @pravykraj
        mov ax,0f02h;mov dx,3c4h;call OutDxAx{set out bits}
         mov dx,Vyska
         mov bx,local_lineOffset;sub bx,si
         mov al,byte ptr pixel
         push di
         @next_unchained_line:
         mov cx,si
         call REP_STOSB
         add di,bx
         dec dx
         jnz @next_unchained_line
         pop di
         add di,si
         shl si,2
         sub sirka,si
       {pravy kraj plochy tvaru XXX-,XX--,X---}
       @pravykraj:
       mov cx,sirka
       jcxz @done
        mov ax,0102h;shl ah,cl;dec ah;mov dx,3c4h;call OutDxAx{set out bits}
         call near ptr @StosSlp
         jmp @done
       {cela plocha tvaru -X--,-XX-,--X-}
       @full:
        cmp sirka,-1;jz @jedna;and ah,3;@jedna:and ah,7
        mov dx,3c4h;call OutDxAx{set out bits}
         call near ptr @StosSlp
         jmp @done

     @StosSlp:
       push di
       mov al,byte ptr pixel
       mov dx,local_lineOffset;dec dx
       mov cx,vyska
       @1:
       stosb
       add di,dx
       loop @1
       pop di
       retn

     @DONE:
 end;


{$define smer1}
{$i bit2scr.inc}
{$undef smer1}
{$i bit2scr.inc}




{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ RES LIST ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

constructor TResItem.Init(model,x,y,mode:word);
begin
 inherited Init;
 amodel  :=model;
 ax      :=x;
 ay      :=y;
 amode   :=mode;
 optional:=false;
end;

procedure TResCollection.Insert(Item:Pointer);
var I:Integer;
begin
 if not Search(KeyOf(Item),I) or Duplicates then AtInsert(I,Item)
  {na rozdil od defaultniho insertu, co nezaradi, to killne}
  else KillObj(Item);
end;

function TResCollection.Compare(p1,p2:pointer):integer;
var   a,b,i:integer;
begin
 a:=PResItem(p1)^.amodel;
 b:=PResItem(p2)^.amodel;
 if a=model_unchained then a:=model_packed;
 if b=model_unchained then b:=model_packed;
 if a<>b then Compare:=ord(a>b)-ord(a<b) else begin
   a:=PResItem(p1)^.ax+PResItem(p1)^.ay;
   b:=PResItem(p2)^.ax+PResItem(p2)^.ay;
   i:=ord(a>b)-ord(a<b);
   if i<>0
    then Compare:=i
    else Compare:=integer(PResItem(p1)^.ax)-PResItem(p2)^.ax;
   end;
end;

{---------------------------------------------------------------------------
 Inicializuje VGA mody v ResListu.
 ---------------------------------------------------------------------------}
PROCEDURE InitVga;
var   i,lines:integer;
begin
 with ResList do begin
  {vlozi cga, ega nebo vga textmody (zdetekuje aktualni pocet scanlines
   a predpoklada ze v prubehu programu se nebude menit)}
  lines:=vga_GetScanlines div (vga_GetDoubleScan+1);
  if (lines<150) or (bios_GetMode<>3) then lines:=400;
  for i:=8 to 16 do
   Insert(New(PResItem,Init(model_text,80,lines div i,lines div i)));
  for i:=1 to XModes do begin
    {vlozi vga unchained}
    Insert(New(PResItem,Init(model_unchained,XModeRes[i,1],XModeRes[i,2],i)));
    {vlozi vga packed}
    if longint(XModeRes[i,1])*XModeRes[i,2]<=65536 then
     Insert(New(PResItem,Init(model_packed,XModeRes[i,1],XModeRes[i,2],i)));
    end;
  end;
end;

{---------------------------------------------------------------------------
 Vraci pointer na udaje o nejblizsim modu v ResListu.
 Pri neuspechu nil.
 ---------------------------------------------------------------------------}
FUNCTION GetBestMode(mm,xx,yy:word):PResItem;
var   i:word;
      d,mind:integer;

  procedure TestSimilarity(p:PResItem);far;
  const koefHi=1;{jak moc vadi kdyz vybere vetsi rozliseni}
        koefLo=3;{jak moc vadi kdyz vybere mensi rozliseni}
  begin
   with p^ do
    if ( (amodel=mm)
         or
         ((mm=model_256) and (amodel in [model_packed,model_unchained]))
       ) then begin
           d:=0;
           if ax>xx then inc(d,koefHi*(ax-xx)) else inc(d,koefLo*(xx-ax));
           if ay>yy then inc(d,koefHi*(ay-yy)) else inc(d,koefLo*(yy-ay));
           if d<mind then begin mind:=d;GetBestMode:=p;end;
           end;
  end;

begin
 GetBestMode:=nil;
 mind:=30000;
 ResList.ForEach(@TestSimilarity);
end;

{---------------------------------------------------------------------------
 Vraci packed mod o rozmerech minimalne xx krat yy.
 Pokud zadny neexistuje, vrati 0.

 Tato funkce by tu nemela byt, misto ni by mela stacit
 GetBestMode(model_packed,xx,yy). Ale problem je ten, ze v ResListu
 vetsinou chybi mod 320x200/packed - je vytlacen modem 320x200/unchained.

 Pokud se nekdy rozhodnu tuto osklivou funkci zlikvidovat, musim
 1) zaridit aby mohly v reslistu koexistovat 320x200 packed i unchained
    pricemz pri GetBestMode(model_256,...) bude mit vyssi prioritu ten mod,
    ktery dokaze adresovat vic vramky.
 2) prepracovat koefLo a koefHi v GetBestMode tak, aby si mohl programator
    sam urcit priority (napr zcela zakazat volbu nizsiho rozliseni tak jak
    to dela tato funkce).
 ---------------------------------------------------------------------------}
FUNCTION GetPackedModeAtLeast(xx,yy:word):word;
var   i:word;
      d,mind:integer;

  procedure TestSimilarity(p:PResItem);far;
  const koefHi=1;{jak moc vadi kdyz vybere vetsi rozliseni}
        koefLo=3;{jak moc vadi kdyz vybere mensi rozliseni}
  begin
   with p^ do
    if (amodel=model_packed) and (ax>=xx) and (ay>=yy) then begin
      d:=ax-xx+ay-yy;
      if d<mind then begin mind:=d;GetPackedModeAtLeast:=amode;end;
      end;
  end;

begin
 GetPackedModeAtLeast:=0;
 mind:=30000;
 {vyzkousi mody z reslistu}
 ResList.ForEach(@TestSimilarity);
 {vyzkousi 320x200/VGA packed}
 if (xx<=320) and (yy<=200) and (mind>320-xx+200-yy) then GetPackedModeAtLeast:=X320x200;
end;

{---------------------------------------------------------------------------
 Doplni chybejici udaje. Je-li mode=0, doplni nejblizsi mod k sir a vys,
 jinak doplni odpovidajici sir a vys k mode.
 ---------------------------------------------------------------------------}
FUNCTION ModeDoplnInfo(var model,sir,vys,mode:integer):boolean;
  function Matching(p:PResItem):boolean;far;
  begin
   with p^ do
    if amode=mode then begin
      model         :=amodel;
      sir           :=ax;
      vys           :=ay;
      Matching      :=true;
      ModeDoplnInfo :=true;
      end
    else
      Matching      :=false;
  end;
begin
 if mode=0 then begin
   ModeDoplnInfo:=true;
   with GetBestMode(model,sir,vys)^ do begin
     mode:=amode;
     model:=amodel;
     end;
   end
 else begin
   ModeDoplnInfo:=false;
   ResList.FirstThat(@Matching);
   end;
end;

FUNCTION ModeSupported(model,mode:word):boolean;
begin
 ModeSupported:=GetResItem(model,mode)<>nil;
end;

{---------------------------------------------------------------------------
 Pri nenulovem newMode nastavi presne tento mod.
 V opacnem pripade vybere z ResListu nejblizsi rozliseni k newSir*newVys.
 V InitResult vraci jak to dopadlo.

 Paleta, vramXres, setvis, split a obsah vram nemusi byt po nastaveni modu
 na defaultnich hodnotach. Treba jses-li v modu $101 a nechas nastavit
 mod $101, vsechna nastaveni i obraz ve videopameti zustanou beze zmen.
 Tomu lze zabranit pomoci forbid_alreadyset:=true.

 Poznamka: V ResListu je jen jeden z modu 320x200 packed, 320x200 unchained.
 Priklad: Teoreticky te nezajima model a na nastaveni pouzijes
  Init(tojefuk,320,200,0). Pokdu chces konkretne treba packed, nastav mod
  pomoci Init(model_packed,tojefuk,tojefuk,X320x200).
 ---------------------------------------------------------------------------}
Constructor TScreen.Init(newModel,newSir,newVys,newMode:word);

  {Je-li dany mod uz nastaven, nemaze obrazovku ani nemeni split,setvis...
   zkopci atributy do selfu (zfalsovany init) a vrati true.}
  function _AlreadySet(tryModel,trySir,tryVys,tryMode:word):boolean;
  begin
   _AlreadySet:=false;
   if (CurScreen<>nil) and
      (not CurScreen^.forbid_alreadyset) and
      (CurScreen^.MapModel=tryModel) and
      ( ((tryMode<>0) and (CurScreen^.ModeID=tryMode)) or
        ((CurScreen^.Xres=trySir) and (CurScreen^.Yres=tryVys)) ) then
     begin
      if @self<>CurScreen then begin
        inherited Init(tryModel,BiPPlist[tryModel],trySir,tryVys);
        self:=CurScreen^;
        PrevScreen:=CurScreen;
        CurScreen:=@self;
        {aby mel VLASTNI mousebitmap/mousebuffer}
        mouseBitmap:=nil;
        mouseBuffer:=nil;
        MouseSetPointer(nil,0,0);
        end;
      InitResult:=alreadyset;
      _AlreadySet:=true;
     end;
  end;

  function _NewSet(tryModel,tryMode:word):boolean;
  var ResItem:PResItem;
  begin
   _NewSet:=false;
   if SetMode(tryModel,tryMode) then begin
     {natahne udaje cachovane v reslistu}
     ResItem:=GetResItem(tryModel,tryMode);
     if (ResItem<>nil) and ResItem^.optional then with ResItem^ do begin
       {vytazeni z reslistu}
       retraceLen        :=aretracelen;
       screenfreq        :=ascreenfreq;
       vesasetvissyncuje :=avesasetvissyncuje;
       timerscrsync      :=atimerscrsync;
       end
     else begin
       {detekce}
       if not DetectRetraceLen then begin
         CurScreen:=nil;
         exit;
         end;
       if VesaMode then DetectVesaSetvisSync;
       timerscrsync      :=DetectTmrScrSync;{timer detekovat posledni, zavisi na predchozich}
       {ulozeni do reslistu}
       if ResItem<>nil then with ResItem^ do begin
         optional          :=true;
         aretracelen       :=retraceLen;
         ascreenfreq       :=screenfreq;
         avesasetvissyncuje:=vesasetvissyncuje;
         atimerscrsync     :=timerscrsync;
         end;
       end;
     {natahne udaje cachovane v cfg}
     LoadCfg;
     {velikost virtualni obrazovky rovna normalni obrazovce}
     vramXres  :=Xres;
     vramYres  :=longint(VramSizeKB)*1024*8 div (vramXres*BiPP);
     {odhadne doublescan, vga_GetDoubleScan=1 funguje jen v textmodu}
     if ( (not vesamode and (MapModel=model_text)) and (vga_GetDoubleScan=1) ) or
        ( (vesamode or (MapModel<>model_text))     and (charYres*Yres<300)   )
       then DoubleScan:=2 else DoubleScan:=1;
     {maximalni hodnota nastavitelna v SplitY}
     maxSplitY :=charYres*Yres-1;
     {pozor: nekdy v textmodu zustanou dole nevyuzity radky, maxsplity by mel byt vetsi
     if (MapModel=model_text) and (GetVerticalTotal>=maxSplitY)
      and (GetVerticalTotal<maxSplitY*4 div 3) then maxSplitY:=GetVerticalTotal;}
     nowSplitY :=maxSplitY;{zadny split}
     {setvis na zacatku videopameti}
     vramVisX  :=0;
     vramVisY  :=0;
     {nastavi pocatecni souradnice, rozsah a citlivost pro mys}
     if MapModel=model_text then mouseSetJump(8,8) else mouseSetJump(4,4);
     MouseSetPointer(nil,0,0);
     mouseSetPos(Xres div 2,Yres div 2);
     mouseAdjustSpeed;
     {uz znam rozmery, tak je nastavim do atributu abstractmap}
     ExpandFul(false);
     {aktivni jsem ted ja}
     CurScreen:=@self;
     InitResult:=newset;
     _NewSet:=true;
     end;
  end;

  function _AnySet(tryModel,trySir,tryVys,tryMode:word):boolean;
  var ok:boolean;
  begin
   ok:=_AlreadySet(tryModel,trySir,tryVys,tryMode) or
       _NewSet(tryModel,tryMode);
   if ok then pen:=PEN_VRAM;
   _AnySet:=ok;
  end;

var   bestmode:PResItem;
      wasinited:boolean;
begin
 wasinited:=CurScreen<>nil;

 if newMode<>0 then
   begin
    if _AnySet(newModel,newSir,newVys,newMode) then exit;
   end
 else
   while true do begin
    bestmode:=GetBestMode(newModel,newSir,newVys);
    if bestmode=nil then break;
    with bestmode^ do if _AnySet(amodel,ax,ay,amode) then exit;
    ResList.Free(bestmode);
   end;

 {mod nejde nastavit}
 if wasinited and (CurScreen<>nil)
  then InitResult:=stillold
  else InitResult:=chaos;
 Fail;
end;

{---------------------------------------------------------------------------
 Inicializuje funkce spojene s VESA BIOSem.
  -nastavi do VesaBanksTotal pocet 64KB banku, pri nepritomnosti vesy 0
  -nastavi VesaVersion, pri nepritomnosti vesy 0
  -nastavi VesaID
  -do ResListu prida vesa mody
 Kdyz narazi na "stub" VBE, nastavi VesaID a VesaBanksTotal, ale VesaVersion=0.
 ---------------------------------------------------------------------------}
PROCEDURE InitVesa;
      {Doplnek ModeInfobloku; obsahuje informace ktere nutne potrebuji,}
      {ale VESA mi je v get_mode_info nemusi dat}
type  TModeInfoShort = Record
                        VMode   : word;
			XSize	: word;
			YSize	: word;
			MModel	: byte;
                      End;
const
      ModesSupported=25;

      ModeInfoConst:array[1..ModesSupported] of TModeInfoShort=(
        (VMode:$100; XSize: 640; YSize: 400; MModel:model_packed),
        (VMode:$101; XSize: 640; YSize: 480; MModel:model_packed),
        (VMode:$103; XSize: 800; YSize: 600; MModel:model_packed),
        (VMode:$105; XSize:1024; YSize: 768; MModel:model_packed),
        (VMode:$107; XSize:1280; YSize:1024; MModel:model_packed),

        (VMode:$10d; XSize: 320; YSize: 200; MModel:model_BGR15),
        (VMode:$110; XSize: 640; YSize: 480; MModel:model_BGR15),
        (VMode:$113; XSize: 800; YSize: 600; MModel:model_BGR15),
        (VMode:$116; XSize:1024; YSize: 768; MModel:model_BGR15),
        (VMode:$119; XSize:1280; YSize:1024; MModel:model_BGR15),

        (VMode:$10e; XSize: 320; YSize: 200; MModel:model_BGR16),
        (VMode:$111; XSize: 640; YSize: 480; MModel:model_BGR16),
        (VMode:$114; XSize: 800; YSize: 600; MModel:model_BGR16),
        (VMode:$117; XSize:1024; YSize: 768; MModel:model_BGR16),
        (VMode:$11a; XSize:1280; YSize:1024; MModel:model_BGR16),

{Pozor: Novejsi chipsety CirrusLogic, s3 a Trident umi nasledujici mody jen jako 32bit, tj model_BGRA32.
        Nektere videokarty s s3 umi tyto mody i pri 24 bit, jejich cisla jsou v komentari.
        Trident a CirrusLogic neumeji 24bitove eqivalenty!}

        (VMode:$10f; XSize: 320; YSize: 200; MModel:model_BGR24),
        (VMode:$112; XSize: 640; YSize: 480; MModel:model_BGR24),{ $212}
        (VMode:$115; XSize: 800; YSize: 600; MModel:model_BGR24),
        (VMode:$118; XSize:1024; YSize: 768; MModel:model_BGR24),
        (VMode:$11b; XSize:1280; YSize:1024; MModel:model_BGR24),

        (VMode:$108; XSize:  80; YSize:  60; MModel:model_text),
        (VMode:$109; XSize: 132; YSize:  25; MModel:model_text),
        (VMode:$10a; XSize: 132; YSize:  43; MModel:model_text),
        (VMode:$10b; XSize: 132; YSize:  50; MModel:model_text),
        (VMode:$10c; XSize: 132; YSize:  60; MModel:model_text)
        );

var   VesaInfo:PVesaInfoBlock;
      ModeInfo:PModeInfoBlock;
      segment:word;
      {$ifdef dpmi}
      RealModeRegs:dpmiRealCallRegs;
      {$endif}

 procedure Analyza;
 var   i:word;
       sz,sc,ss:string[70];
       app:string[20];
 begin
  with vesainfo^ do
   if magic<>'VESA' then begin
     {neni tu}
     VesaVersion:=0;
     VesaBanksTotal:=0;
     VesaID:='NO VBE';
     end
    else begin
     {je tu}
     VesaVersion:=verze;
     VesaBanksTotal:=totalmemory;
     {$ifdef dpmi}
     Seg2Desc(PtrRec(OEMStrPtr).Seg);
     Seg2Desc(PtrRec(VideoModePtr).Seg);
     Seg2Desc(PtrRec(ProductStrPtr).Seg);
     {$endif}
     VesaID:=Pc2Str(OEMStrPtr);
     {vykickuje duplicitni slova}
     sz:=VesaID;sc:=' '+Pc2Str(ProductStrPtr);
     while sz<>'' do begin
       ss:=CutString(' ',sz);
       if pos(ss,sc)=0 then sc:=sc+' '+ss;
       end;
     for i:=1 to length(VesaID) do
      if (VesaID[i]<' ') then VesaID[i]:=' ';
     app:=' ('+stri(VesaBanksTotal*64)+')';
     if VideoModePtr^=-1 {"stub" vbe} then begin
       VesaVersion:=0;
       if pos('stub',LoCased(VesaID))=0 then app:=app+' stub';
       end
     else begin
       {*pocitat s biosy, ktere maji oem mody az za -1}
       while VideoModePtr^<>-1 do begin
         if VideoModePtr^>=256{jen vesa mody} then
          if GetModeInfo(VideoModePtr^,ModeInfo) then begin
            if ModeInfoSupported(ModeInfo) then
             with ModeInfo^ do
              if (ModeAttributes and 2)>0{je k dispozici rozsirene info}
               then ResList.Insert(new(PResItem,Init(MemoryModel,XResolution,YResolution,VideoModePtr^)))
               else for i:=0 to ModesSupported-1 do
                with ModeInfoConst[i] do
                 if VMode=VideoModePtr^ then
                  ResList.Insert(new(PResItem,Init(MModel,XSize,YSize,VideoModePtr^)));
            FreeMemDos(pointer(ModeInfo),sizeof(ModeInfo^));
            end;
         inc(VideoModePtr);
         end;
       end;
     VesaID:=copy(GetCore(VesaID),1,70-length(app))+app;
     end;
 end;

label freee;
Begin

 {nejprve nastavi neuspech}
 VesaVersion:=0;
 VesaBanksTotal:=0;

 {naalokuje pamet pro vesainfo}
 if not GetMemDos(segment,pointer(VesaInfo),sizeof(VesaInfo^)) then exit;
 fillchar(VesaInfo^,sizeof(VesaInfo^),0);
 vesainfo^.magic:='VBE2';

 {do vesainfa necha nahrat informace o vese a otestuje si je}
 {$ifndef dpmi}
  asm
     mov ax,4f00h;les di,vesainfo   {nastavi parametry pro getvesainfo}
     int 10h                        {vola vesabios}
     cmp ax,4fh;jnz freee           {prvni test pritomnosti vesy}
  end;
 {$else}
  with RealModeRegs do begin
   clr;
   rEAX:=$4f00;
   rES:=Segment;
   end;
  if erDumb(dpmiRealModeInt($10,@RealModeRegs))<>erOk then goto freee;
  {je sluzba vesa.getinfo podporovana ?}
  if word(RealModeRegs.rEAX)<>$4f then goto freee;
 {$endif}

 {analyzuje ziskane udaje}
 Analyza;

 {uvolni pamet}
 freee:
 FreeMemDos(pointer(VesaInfo),sizeof(VesaInfo^));
End;



{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='vga';
var result:integer;

procedure UserInit;
 begin
  BugList.Register(erBadMode,'Nejde nastavit zobrazovac° m¢d.');
  BugList.Register(erBadVBE,'Vadnò VESA BIOS. Po©iÉ si slu®nàj®° nebo pouëij VGA rozli®en°.');
  mouseSpeed       :=32;
  mouseBaseColor   :=1;
  debugpal         :=false;
  CurScreen        :=nil;
  UserFont         :=nil;
  badretrace[false]:=false;
  badretrace[true] :=false;
  if ResList.Init(100,100) then begin
    InitVesa;{nejdriv nahraje vesa mody}
    InitVga; {pak uz pridava jen ty vga mody, ktere vesa neumi}
    exit;
    end;
  result:=erLowMem;
 end;

procedure UserDone;
 begin
  ResList.Done;
  {if CurScreen<>nil then CurScreen^.Done;
   Ac by to vypadalo logicky, prikaz na minule radce nemuzeme provest.
   Proc? Protoze pri chybe prepne unita chyby do textmodu, vypise hlasku
   a az potom zavola mimo jine i tuto proceduru. Mohli bysme ho dat do
   ShutDownInts retezce (vola se jeste pred prepnutim do textmodu),
   ale to by nebylo uplne bezpecne a nac si komplikovat zivot.
   Proste si musis na konci sveho programu zabit graficky mod sam.}
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.

podporu pro monochrom textmod (7) a navrat do nej
disablovat praci s paletou v HC/TC
nektery veci podminit vesaverze>=102 apod
vesa get protected mode code
pri generovani romfontu12 zkazi spodek y,g..
nepocitat s 9x14 fontem
ask vesa:
 NumberOfPlanes in textmode ?
 BitsPerPixel in textmode ?
pouzit offscreenmemoffset, offscreenmemsize
pouzit getmaximumscanlinelength
zabranit alokaci palety u bitmap ktery ji nepotrebujou (mousebuffer apod)
co kdyz pouziva dve okna a ty jsou na ruznejch adresach? (to neni ohlidany!!!)

