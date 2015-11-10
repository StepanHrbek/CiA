{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 2.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}
{define a_ff} {do kanalu alpha davat vzdy ff}

Unit      Vga;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects,Dos, Stringy,Sys,Mys,Key,Fajly{$ifdef dpmi},Dpmi{$endif};
Function  Init:TError;
Procedure Done;

{
---------------------------------------------------------------------------
                            Uvod k VGA
---------------------------------------------------------------------------

Unita pro praci s mnoha vga i svga mody (text,256barev,hicolor,truecolor...).
Podporovany nejsou pouze historicke 2, 4 a 16-barevne graficke mody.

Unita funguje na VGA kartach bez nebo s VBE (Vesa Bios Extension)
a castecne i na VGA nekompatibilnich kartach s VBE.
Mimo ne nebyla testovana.
Z pohledu uzivatele CiA neni mezi ruznymi kartami a mody zadny rozdil.
Korektne napsany program funguje bez uprav na libovolnem hardwaru
s libovolnou barevnou hloubkou a pripadne i rozlisenim.
(prikladem muze byt Machina (dee.webpark.cz/machina) bezici na cemkoliv
od hires truecoloru pres mody s paletou az po textmod 40x12)

Pri prohlizeni interface narazis na skupiny funkci zacinajich predponami:
 vga_    pracuji s vga registry, nemusi fungovat pod vesa biosem
 bios_   pracuji s vga biosem, nemusi fungovat pod vesa biosem
 vesa_   pracuji s vesa biosem, nemaji smysl bez nej

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
pri pouziti vetsich bitmap nutny protected mode.

Objekt ˛TScreen˛, potomek AbstractMapy, je videopamet/obrazovka.
Inicializaci instance TScreen nastavis textovy/graficky mod,
uvolnenim instance vratis predchozi mod.

---
Pro low-level kutily, CRTC nemusi byt ve VESA modech fit (ATI MACH64).
K zjisteni podobne situace by mel slouzit VESA BIOSem nabizeny flag
registrove_kompatibilni_s_vga, ale prave kriticke BIOSy ho ignoruji.

Pro hardcore VBE maniaky, unita NEvyuziva tyto moznosti nekterych karet:
 -granularita<>64K (emuluje 64KB banky)
 -nezavisle bankovani pro cteni a pro zapis (bankuje obe okna synchronne)
 -linearni adresace (u me je stejne banking 1.5x rychlejsi nez lfb)
 -moznost velikosti banku <> 64KB neni osetrena, ale btw 32K v textmodu projde
 -unita NIKDY nereaguje v zavislosti na nazvu vesa biosu (nektere biosy jsou
  znamy svymi chybami), pripadne detekce chyb jsou ciste, univerzalni
 -unita v textmodu nebankuje (btw, kdybys moc chtel, doplnit strankovani je
  problem tak na 10 instrukci)

Rutiny funguji i na vice ci mene exotickych kartach, ktere
 -nesnesou nastavovani idexovanych vga registru pres out dx,ax
 -nesnesou nastavovani palety pres rep outsb
 -nesignalizuji vertikalni navrat paprsku
---

ResList je seznam podporovanych modu. K cemu je dobry?
 1) Pri nastavovani modu muzes zadat jen rozliseni a model, nastavi se
    nejblizsi mod z ResListu. To je take doporuceny postup.
    Mody ktere nejdou nastavit se z ResListu smazou.
 2) V ResListu se pro kazdy mod ukladaji nektere udaje namerene pri jeho
    prvnim nastaveni, pri dalsich nastavenich se usetri cas.

Pri kazdem nastaveni textmodu se zavola uzivatelska procedura UserFont,
ktera unite rekne jaky font ma pouzit. Defaultne je volen ROM font,
ale muzes to zmenit, dalsi komentar je u dalsich vyskytu UserFont.

Transparentni pozadi u bitmap je podporovano jen z 99%.
Pri nastaveni flagu transparency jsou pixely 0 povazovany za transparentni,
v models_8 to je index 0, v models_direct cerna barva.
Transparentni kopirovani mezi bitmapami v pameti je v poradku,
transparentni kopirovani cehokoliv do vram pracuje po bajtech, ne pixelech,
takze se muze stat, ze cast pixelu nakresli a cast preskoci.
Duvodem je prilisna slozitost prislusne rutiny, uz takhle musi zvladat
uprostred pixelu prebankovat (model_bgr24)...

}



{---------------------------------------------------------------------------
 Modely ulozeni pixelu ve videopameti.
 ---------------------------------------------------------------------------}

CONST model_text             =0;             {pametove modely}
      model_cga_             =1;             {cislovani podle standardu VESA}
      model_hercules_        =2;
      model_ega_             =3;
      model_packed           =4;             {obvykle 256bar. mody a 16 bar. mody 2 PixelsPerByte w/o planes}
                                             {nektere karty (ARK Logic) pouzivaji model_packed i u HC/TC!}
      model_unchained        =5;
      model_direct_          =6;             {obecne libovolny Hi/TrueColor mod}
      model_yuv_             =7;

      model_BGR15            =16;            {Nase vlastni oznaceni}
      model_RGB15            =17;            {pro rozliseni model_direct}
      model_BGR16            =18;
      model_RGB16            =19;
      model_BGR24            =20;
      model_RGB24            =21;
      model_BGRA32           =22;
      model_RGBA32           =23;

      {Nasledujici modely pouzivat jen pri nastavovani modu.}
      {Pri nem lze zadat
       -bud konkretni model z vyse uvedenych (pr. model_BGR16)
       -nebo mnozinu modelu z nize uvedenych (pr. model_direct)
       -nebo konkretni model+mnozinu (pr. model_BGR16+model_gfx)
         pri nastavovani modu se pak zkousi nejdriv konkretni model
          a az kdyz selze, dalsi modely z mnoziny}

      model_8                =$100;          {nejaky 8bit}
      model_15               =$200;          {nejaky 15bit}
      model_16               =$300;          {nejaky 16bit}
      model_24               =$400;          {nejaky 24bit}
      model_32               =$500;          {nejaky 32bit}
      model_hc               =$600;          {co nejkvalitnejsi hicolor (15,16)}
      model_tc               =$700;          {co nejkvalitnejsi truecolor (24,32)}
      model_direct           =$800;          {co nejkvalitnejsi directcolor (15,16,24,32)}
      model_gfx              =$900;          {co nejkvalitnejsi graficky model (8,15,16,24,32)}
      model_scrol            =$a00;          {gfx mod ve kterem bude pokud mozno dost pameti na hw scrol}

      models_8               =[model_packed,model_unchained];
      models_15              =[model_BGR15,model_RGB15];
      models_16              =[model_BGR16,model_RGB16];
      models_24              =[model_BGR24,model_RGB24];
      models_32              =[model_BGRA32,model_RGBA32];
      models_hc              =models_15+models_16;
      models_tc              =models_24+models_32;
      models_direct          =models_hc+models_tc;
      models_gfx             =models_8+models_direct;
      models_scrol           =models_gfx;

      ModelStr               :array[model_text..model_RGBA32] of string[3]=(
                               'TXT','','','','8','8.',
                               '','','','','','','','','','','15','15.',
                               '16','16.','24','24.','32','32.');

{---------------------------------------------------------------------------
 Seznam tech modu, ktere maji Z HISTORICKYCH DUVODU pevne urcene cislo.
 V praxi neni duvod je pouzivat.
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

var   VesaVersion        :word;{cislo verze vbe: 0, 100h, 101h, 102h, 200h, 300h...}
      VesaID             :string[70];{identifikator VBE, copyright autoru, velikost vram}
      vesa_BanksTotal    :word;{pocet 64KB banku celkem na karte}
      irq2_enabled       :boolean;{smi pouzivat irq2?}

      mouseSpeed         :byte;{rychlost pohybu mysi}
      mouseSize          :byte;{velikost mysi (faktor zvetseni)}
const mouseSpeedAvg      =30;
      mouseSizeAvg       =30;


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
FUNCTION  vga_IRQ:shortint;


{---------------------------------------------------------------------------
 Paleta: cteni, nastaveni, jas, fadingy
 ---------------------------------------------------------------------------}
Const
      {pifXXXX - palette index flag}
      pifDead       =0;{index neni a nesmi byt pouzit}
      pifUsed       =1;{index je pouzit, ma prirazenou RGB barvu}
      pifFree       =2;{index je volny, lze ho zabrat a dat mu barvu}

Type
      TCol          =record r,g,b:byte;end;
      TColor        =record b,g,r,a:byte;end;{hodnoty 0..63, struktura vynucena vesa biosem}
      PCol          =^TCol;
      PColor        =^TColor;
      TPalBody      =array[0..255] of TColor;
      PPalBody      =^TPalBody;

      PPal = ^TPal;
      TPal = object(TCat)
          pal           :TPalBody;      {RGB paleta 256 barev, obsahuje hodnoty 0..63}
          darkcolor     :TCol;          {barva ke ktere smeruje snizovani jasu}
          nowbright     :byte;          {aktualni jas}
          first         :byte;          {prvni zpracovavana barva}
          last          :byte;          {posledni zpracovavana barva}
          constructor   Init;
          procedure     MakeGrayscale;
          procedure     Take(p:PPal);
          procedure     ReadFromTo(fromcol,tocol:byte);
          procedure     ShowFromTo(fromcol,tocol:byte);
          procedure     Show;
          procedure     SetBrightFromTo(n,fromcol,tocol:byte);
          procedure     SetBright(n:byte);
          procedure     SetCol(col,r,g,b:byte);
          procedure     SmoothCols(fromcol,r1,g1,b1,tocol,r2,g2,b2:byte);
          procedure     SmoothBright(fromcol,tocol:byte;how:integer;er,ge,be:boolean);
          procedure     SmoothContrast1(fromcol,tocol,ofs:byte;how:integer);
          procedure     SmoothContrast(fromcol,tocol:byte;how:integer;er,ge,be:boolean);

          procedure     Setup(fromindex,toindex,settype:byte);
          function      Alloc(r,g,b:shortint):byte;
         private
          Count         :array[pifDead..pifFree] of word;
         end;

PROCEDURE SetHwCol(col,r,g,b:byte);
PROCEDURE BlackHwPal;
FUNCTION  PalIsBlack:boolean;
PROCEDURE RandomPal;
FUNCTION  vesa_Palette(nastavit:boolean;fromcol,tocol:byte;p:PColor):boolean;

Var       nextPal       :PPal;{pristi vytvarena bitmapa dostane tuto paletu}

   {volanim techto procedur nastavis parametry pro pristi pixModif/boxModif}
Procedure rgbSetBright(bright:word);
Procedure rgbBlendTo(blend:TCol;bright:word);


{---------------------------------------------------------------------------
 Objekt AbstractMap
 ---------------------------------------------------------------------------}
Type
      PBitmap       =^TBitmap;
      PScreen       =^TScreen;

      PLine=PBytes;                       {pointer na jednu linku bitmapy}
      TLines=array[0..16382] of PLine;    {pole pointeru na linky}
      PLines=^TLines;

      PAbstractMap=^TAbstractMap;
      TAbstractMap=object(TObject)

          MapModel      :word;            {packed,text..}
          SizeX         :integer;         {rozmery X,Y v pixelech}
          SizeY         :integer;
          BiPP          :byte;            {bits per pixel - kolik bitu v pixelu zabere barva - 15/16/24/24}
          ByPP          :byte;            {bytes per pixel - kolik bajtu zabere cely pixel - 2/2/3/4}
          SizeXb        :integer;         {rozmer X v bytech}
          pal           :PPal;            {zde muze byt paleta}

          constructor   Init(newmodel,sir,vys:word);
          destructor    Done;virtual;

          {---PALETA/BARVY---}
          procedure     Have(p:PPal);     {mej stejnou paletu (stejnou instanci)}
          procedure     Take(p:PPal);     {vem si tuhle paletu (stejna data v jine instanci)}
          procedure     SetBright(n:byte);virtual;
          procedure     Fade(time:integer);
          function      Color(r,g,b,a:byte):longint;
          function      TextColor(attr:byte):longint;
          procedure     RGB(pixel:longint;var r,g,b:byte);
          procedure     RGBA(pixel:longint;var r,g,b,a:byte);

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
          procedure     ResizeBtB2Box(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);virtual;
          procedure     ResizeBtB2Ful(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys:word);
          procedure     ResizeBtF2Box(method:byte;p:PBitmap;destX,destY,destSir,destVys:word);
          procedure     ResizeBtF2Ful(method:byte;p:PBitmap);
          {self -> bitmapa}
          procedure     Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     Ful2BtB(p:PBitmap;destX,destY:word);
          procedure     Box2BtF(p:PBitmap;srcX,srcY:word);
          procedure     ResizeBox2BtB(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);virtual;
          procedure     ResizeFul2BtB(method:byte;p:PBitmap;destX,destY,destSir,destVys:word);
          procedure     ResizeBox2BtF(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys:word);
          procedure     ResizeFul2BtF(method:byte;p:PBitmap);
          {kopirovani}
          function      BoxCopy(srcX,srcY,Sirka,Vyska:word):PBitmap;virtual;
          function      FulCopy:PBitmap;
          function      ResizeBoxCopy(method:byte;srcX,srcY,srcSir,srcVys,destSir,destVys:word):PBitmap;virtual;
          function      ResizeFulCopy(method:byte;destSir,destVys:word):PBitmap;
          {self -> abstraktni (jakakoliv) mapa}
          procedure     Box2Box(p:PAbstractMap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     Box2Ful(p:PAbstractMap;srcX,srcY:word);
          procedure     Ful2Box(p:PAbstractMap;destX,destY:word);

          {---RGB MODIFIERS---}
          function      GetPixel(x,y:word):longint;virtual;
          procedure     PutPixel(x,y:word;pix:longint);virtual;
          procedure     Col2Circ(destX,destY,r:word;pixel:longint);
          procedure     pixModify(x,y:word);
          procedure     boxModify(ax,ay,w,h:word);
         end;


{---------------------------------------------------------------------------
 Objekt Bitmap
 ---------------------------------------------------------------------------}

      TBitmap=object(TAbstractMap)

          allocatedX    :integer;         {bajtu naalokovanych pro kazdy radek}
          allocatedY    :integer;         {delka map (tabsize>=allocatedY), kolik radek ma naalokovanou vlastni pamet}
          transparent   :boolean;         {pruhledne pozadi?}
          tab           :PLines;          {tabulka radek bitmapy}
          tabsize       :integer;         {delka tab (tabsize>=sizeY), na kolik radek se muzes odkazovat}
          static        :boolean;         {nema pamet pri done uvolnit?}

          constructor   Init(newmodel,sir,vys:word);
          constructor   InitPart(newmodel,sir,vys:word);
          destructor    Done;virtual;

          procedure     DelLines(firstline,lines:word);
          function      InsLines(firstline,lines:word):boolean;
          function      AddLines(lines:word):boolean;

          procedure     StaticMem(p:pointer;size:word);
          procedure     StaticTex(p:pointer);
          procedure     StaticMap(map:PBitmap;srcX,srcY:word);

          function      GetPixel(x,y:word):longint;virtual;
          procedure     PutPixel(x,y:word;pix:longint);virtual;
          procedure     Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);virtual;
          procedure     BtB2Box(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure     ResizeBtB2Box(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);virtual;
          procedure     ResizeBox2BtB(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);virtual;
          function      BoxCopy(srcX,srcY,Sirka,Vyska:word):PBitmap;virtual;
          function      ResizeBoxCopy(method:byte;srcX,srcY,srcSir,srcVys,destSir,destVys:word):PBitmap;virtual;
         end;


{---------------------------------------------------------------------------
 Objekt Screen
 ---------------------------------------------------------------------------}

      TSetModeResult=(chaos,stillold,alreadyset,newset);
      TBankRegs=word;
      TMousePoint=object(TPoint) z:word; end;

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
          VramSizeKB         :longint; {velikost videopameti pouzitelne v soucasnem modu v kilobytech, musi mit sizeof=4}
          VgaCompat          :boolean; {je karta registrove VGA kompatibilni?}
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
          procedure          LoadCfg;virtual;
          procedure          GetParentFrom(s:PScreen);
          procedure          GetThisParent(s:PScreen);

                             private
                              ZadanaVyskaZnaku   :byte;
                              PrevScreen         :PScreen;
                              PrevModel          :word;
                              PrevMode           :word;
                              function           SetMode_VESA(newModel,newMode:word):boolean;
                              function           SetMode_TEXT(newMode:word):boolean;
                              function           SetMode_X(newModel,newMode:word):boolean;
                              function           SetMode(newModel,newMode:word):boolean;
                             public

         {bitblts}
          pen                :byte;    {zpusob interpretace souradnic nasledujicimi metodami, viz pen_XXXX}
          procedure          Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);virtual;
          procedure          BtB2Box(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure          Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure          SuperResizeBtB2Box(method:byte;srcMap:PBitmap;bkgMap:PAbstractMap;
                                   mixingBuf:PBitmap;srcRect,destRect:TRect);
          function           ExpandFul(expand:boolean):boolean;
          procedure          GetClipping(var rect:TRect);virtual;
          procedure          vesa_SetBank(n:byte);

                             private
                              vesa_Banking       :boolean; {funguje v aktualnim modu a smim tedy pouzivat vesabanking?}
                              vesa_NowBank       :word;    {momentalne nastaveny 64KB bank}
                              vesa_Granularity   :word;    {granularita v KB, musi byt word}
                              vesa_UseWinA       :boolean; {je nutne bankovat v okne A?}
                              vesa_UseWinB       :boolean; {je nutne bankovat v okne B?}
                              procedure          vga_DetectRetraceLen;
                              procedure          vesa_DetectSetvisSync;
                              procedure          vesa_DetectVramSizeAndBanking;
                              procedure          vesa_IncBank;
                              procedure          vesa_DecBank;
                             public

         {kurzor}
          procedure          GotoXY(x,y:integer);virtual;

         {porty/retrace}
          public
          beziNahazovacRet   :boolean; {pri kazdym retrace muzes automaticky nahodit ret (obsluhu si }
          ret                :boolean;  {povesis na timer), toho vyuzije SyncRet k presnejsi synchronizaci}
          synced             :boolean; {jsem sesynchronizovan s paprskem?}
                                        {Setvis nekdy ceka na paprsek a nastavi synced,}
                                        {SyncRet pak ceka na paprsek jen pri not synced.}
          RetraceLen         :word;    {65534=bezi irq2
                                        0=nebezi irq2 ale retrace je normalni
                                        1..65533=nebezi irq2 a retrace je vadny/ati a spol
                                                =doba delsi nez vertical a kratsi nez horizontal retrace
                                        65535=nebezi irq2 a retrace nezjisten/dosemu}

          vesa_SetvisSyncuje :boolean; {ceka VesaSetvis na parsek?}
          ScreenFreq         :word;    {obnovovaci frekv. modu, presnost plus minus 10Hz}
          TimerScrSync       :word;    {hodnota zjistena funkci tmrGetScrSync}
          userSync           :Procedure;{uzivatelska procedura volana pri syncu vzdy}
          procedure          ReadIrq2Enabled;
          procedure          WaitForTrace;
          procedure          WaitBeforeRetrace;
          procedure          WaitForRetrace;
          procedure          Refresh(n:byte);
          procedure          SyncRet;
          procedure          Sync;virtual;
          function           DetectTmrScrSync:word;virtual;
          function           GetBankRegs:TBankRegs;
          procedure          SetBankRegs(x:TBankRegs);

                             private
                              s_irq2_enabled     :boolean; {v jakem stavu se merilo retracelen}
                              stopky:TStopky;
                              procedure          WaitForClock;
                             public

         {setvis/split a spol na urovni registru}
         public
          maxSplitY          :word;{nejmensi Y tak velke, ze ze splitu neni nic videt}
          nowSplitY          :word;{hodnta nastavena metodou splity}
          DoubleScan         :byte;{kolikrat prochazi paprsek kazdy pixel? (1 nebo 2)}
          procedure          vga_SplitY(y:word);
          procedure          vga_SetvisHi(a:word);
          procedure          vga_PanLeft(x:byte);
          procedure          vga_PanUp(y:byte);
          function           vesa_Setvis(x,y:word):boolean;
          function           vesa_SetvisSync(x,y:word):boolean;

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
          mouse              :TMousePoint;{pozice mysi na obrazovce, i kdyz neni videt (PEN_SCREEN)}
          mousePress         :TMousePoint;{pozice posledniho stisku/uvolneni (PEN_SCREEN)}
          mouseActions       :word;   {popis posledniho stisku/uvolneni}
          mouseDrawnTo       :TPoint; {pozice nakreslene sipky na obrazovce (PEN_SCREEN)}
          mouseFlag          :boolean;{je mys prave nakreslena na obrazovce?}
          mouseWarning       :byte;   {0=ok, 1=prave se kresli mys, 2=maze}
          mouseRedrawFlag    :boolean;{flag ktery se nastavi pri kazdem vykresleni mysi,
                                       uzitecne pri boji proti redundantnim redrawum}
          procedure          MouseSetPointer(p:PBitmap;forXres,forYres,pointX,pointY:word);
          procedure          MouseSwapPointer(var b:PBitmap;forXres,forYres:word;var p:TPoint);
          function           MouseShow:boolean;
          function           MouseHide:boolean;
          procedure          MouseRescanState;
          procedure          MouseRescanPress;
          procedure          MouseSetRange;
          procedure          MouseGetPos(apen:byte;var x,y:integer);virtual;
          procedure          MouseSetPos(x,y:integer);
          procedure          MouseShift(dx,dy:integer);
          procedure          MouseRedraw;
          procedure          MouseGetRect(var rect:TRect);virtual;
          procedure          MouseAdjustSpeed;

                             private
                              mouseBitmap        :PBitmap;{sipka mysi}
                              mouseBuffer        :PBitmap;{buffer pro ukladani pozadi za mysi}
                              mouseActive        :boolean;{je aktivni handler <nebo> mam sledovat pohyb a prekreslovat sipku?}
                              mousePoint         :TPoint; {"hot spot", klicovy pixel v bitmape sipky}
                              mouseGenerateHold  :boolean;{smi generovat event ze je stiskle tlacitko?}
                              procedure          MouseAdjustJump;
                              function           MouseGenerateBitmap:PBitmap;
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


          {mcXXXX - mouse code}
          _mc                =240;{zvoleno aby nekolidovalo s kody klaves}
          {kody eventu jednorazove vygenerovanych stiskem/uvolnenim mysi}
          mcLeftPressed      =_mc+0;
          mcRightPressed     =_mc+1;
          mcCenterPressed    =_mc+2;
          mcLeftReleased     =_mc+3;
          mcRightReleased    =_mc+4;
          mcCenterReleased   =_mc+5;
          {kody eventu opakovane generovanych pri drzeni stiskle mysi}
          mcLeftHold         =_mc+6;
          mcRightHold        =_mc+7;
          mcCenterHold       =_mc+8;
          {zkratky}
          mcPresses          =[mcLeftPressed,mcRightPressed,mcCenterPressed];
          mcHolds            =[mcLeftHold,mcRightHold,mcCenterHold];
          mcReleases         =[mcLeftReleased,mcRightReleased,mcCenterReleased];
          mcAny              =mcPresses+mcHolds+mcReleases;

          sizeofTColor       =sizeof(TColor);

{---------------------------------------------------------------------------
 Seznam podporovanych modu (ResList)
 ---------------------------------------------------------------------------}

Type
 PResItem=^TResItem;
 TResItem=object(TObject)
   amodel             :word;   {vzdy nastaveno}
   ax,ay              :word;   {vzdy nastaveno}
   amode              :word;   {vzdy nastaveno}
   optional           :boolean;{jsou nasledujici udaje platne?}
   aretracelen        :word;
   as_irq2_enabled    :boolean;{stav pri mereni retracelen}
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
      maxByPP:shortint;{ModeDoplnInfo i nastaveni modu se budou snazit neprekrocit toto ByPP}

FUNCTION  ModeSupported(mode:word):boolean;
FUNCTION  Mode2Supported(model,mode:word):boolean;
FUNCTION  ModeDoplnInfo(var model:word;var sir,vys,mode:integer):boolean;

{---------------------------------------------------------------------------
 Konverze modelu, kvantizace, slucovani palet...
 ---------------------------------------------------------------------------}
Type  TMergeMaps=object
        destmodel   :byte;
        destpal     :PPal;
        constructor Init(adestmodel:byte;adestpal:PPal);
        procedure   Histogram(map:PBitmap);
        procedure   Kvantize;
        procedure   Convert(map:PBitmap);
        destructor  Done;
       private
        srctransp   :boolean;{je nektera z konvertenych map transparentni?}
        xlatok      :boolean;
        any2kvanti  :boolean;
      end;

      T256Longs = array[0..255] of longint;
      P256Longs = ^T256Longs;

PROCEDURE ChangeMapTo(map:PBitmap;newmodel:word);
PROCEDURE JoinMapTo(map:PBitmap;mainmap:PAbstractMap;kvanti:boolean);
PROCEDURE ConvertPacked2Any(srcmap,destmap:PBitmap;colors:P256Longs);
PROCEDURE MarkColorsIn(map:PBitmap);
FUNCTION  Convertable(srcmodel,destmodel:word):boolean;
PROCEDURE SwapIndexesIn(map:PBitmap;c1,c2:byte);

PROCEDURE RGB2HLS(r,g,b:real; var h,l,s:real);
PROCEDURE HLS2RGB(h,l,s:real; var r,g,b:real);

FUNCTION  _Color(model:word;pal:PPal;r,g,b,a:byte):longint;
PROCEDURE _RGBA(model:word;pal:PPal;pixel:longint;var r,g,b,a:byte);

{ukazka pouziti rgbXXXX}
Procedure ShadeBorder(b:PAbstractMap);
Procedure CastShadow(b:PAbstractMap;ax,ay,sir,vys:word);
Procedure WhiteBorder(b:PAbstractMap;ax,ay,sir,vys,power:word);

{---------------------------------------------------------------------------
 Zbytky...
 ---------------------------------------------------------------------------}
var       CurScreen:PScreen;{aktualni screena, nemenit, jen cist}
          debugpal:boolean; {zapina debug mod v palete}
          UserFont:procedure(var name:PathStr;var p:pointer;var vyska:byte);
          userDirty:boolean;{nastavenim vynulujes TimeFromLastEvent}
          higherSux:integer;{jak moc vadi kdyz vybere vetsi rozliseni, 0=nekonecne}
          lowerSux:integer; {jak moc vadi kdyz vybere mensi rozliseni, 0=nekonecne}
          retrace_clock:PLong;{hodiny odtikavajici neco jako retrace}

FUNCTION  screen:PScreen;
FUNCTION  IsVga:boolean;
FUNCTION  IsVesamode(testModel:byte;testMode:word):boolean;
FUNCTION  GetPrevMode:word;
PROCEDURE bios_ScreenOff;
PROCEDURE bios_ScreenOn;
FUNCTION  DCV(presnost:word):word;
FUNCTION  InitStaticBitmap(model,sir,vys:word;p:pointer;trans:boolean):PBitmap;
PROCEDURE GetResizeBltClipping(srcSize:TPoint;destRect:TRect;destRng:TRect;var newSrcRect:TRect;var newDestRect:TRect);
FUNCTION  TimeFromLastEvent:longint;

{---------------------------------------------------------------------------
 Fonty...
 ---------------------------------------------------------------------------}
FUNCTION  LoadUserFont(fnt:pointer;vyska:byte):TError;
VAR       _LoadDiskFont:function(fnt:PathStr;vyska:byte):TError;
PROCEDURE _ResizeChar(src:PLine;relX,relY:shortint;sirB,vysB:byte;
           dest:PLine;sizeOver,sizeUnder:shortint;
           disizbase,expanddis:boolean;var top,bot:shortint);

{---------------------------------------------------------------------------
 Updaty obrazu...
 ---------------------------------------------------------------------------}
PROCEDURE AddRect2Update(r:TRect);
PROCEDURE AddAll2Update;
FUNCTION  WhatNeedsUpdating(var uTail:word;var uRect:TRect):boolean;
PROCEDURE AllNeedsUpdating(var uTail:word;var uRect:TRect);


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


const minCharYres=5;
      maxCharYres=16;

Function screen:PScreen;
begin
 {$ifdef beta}
 if CurScreen=nil then Halt(_erNoScreen);
 {$endif}
 screen:=CurScreen;
end;



{€€€€€€€€€€€€€€€€ U P D A T Y €€€€€€€€€€€€€€€€}


const updateBufSize    =500; {delka kruhove fronty}
      NoAll            =updateBufSize+1;{libovolne cislo mimo rozsah}
type  updateArray      =array[0..updateBufSize-1] of TRect;{fronta}
var   updateHead       :word;{volne pole pred zacatkem fronty}
     {updateTail       :word;{posledni obsazene pole ve fronte}
      updateRect       :^updateArray;
      updateAll        :word;{kolikate pole nese informaci updatni vse}

{---------------------------------------------------------------------------
 Prida oblast k tem co potrebujou updatnout.
 ---------------------------------------------------------------------------}
PROCEDURE AddRect2Update(r:TRect);
begin
 if updateHead=updateAll then updateAll:=NoAll;
 updateRect^[updateHead]:=r;
 updateHead:=(updateHead+1) mod updateBufSize;
end;

{---------------------------------------------------------------------------
 Nastavi ze vse potrebuje updatnout.
 ---------------------------------------------------------------------------}
PROCEDURE AddAll2Update;
begin
 updateAll:=updateHead;
 updateHead:=(updateHead+1) mod updateBufSize;
end;

{---------------------------------------------------------------------------
 Vraci oblast, ktera byla v posledni dobe prekreslena a pokud jsi tam
 neco mel, je treba to updatnout. Souradnice jsou v PEN_VIRT_AREA.
 Kdyz vrati false, netreba updatovat nic.
 uTail je tvuj ukazatel na konec kruhove fronty (pred prvnim volanim teto
 fce ho inicializuj na 0).
 ---------------------------------------------------------------------------}
FUNCTION WhatNeedsUpdating(var uTail:word;var uRect:TRect):boolean;
begin
 if updateHead=uTail then
   WhatNeedsUpdating:=false
 else begin
   if (updateAll<>NoAll) and (
     ((uTail<=updateAll) and (updateAll<updateHead)                        ) or
     ((uTail<=updateAll)                            and (updateHead<uTail) ) or
     (                       (updateAll<updateHead) and (updateHead<uTail) ) )
   then AllNeedsUpdating(uTail,uRect)
   else begin
     uRect:=updateRect^[uTail];
     uTail:=(uTail+1) mod updateBufSize;
     end;
   WhatNeedsUpdating:=true;
{ with urect do ReportErr(stri(a.x)+' '+stri(a.y)+' '+stri(b.x)+' '+stri(b.y));}
   end;
end;

{---------------------------------------------------------------------------
 Vraci ze vse ma byt updatnuto a vymaze ti frontu.
 ---------------------------------------------------------------------------}
PROCEDURE AllNeedsUpdating(var uTail:word;var uRect:TRect);
begin
 uTail:=updateHead;
 screen^.GetClipping(uRect);
end;



{€€€€€€€€€€€€€€€€ P O R T Y €€€€€€€€€€€€€€€€}


const mingoodfreq        =40;           {minimalni a maximalni}
      maxgoodfreq        =200;          {obnovovaci frekvence, ktere jeste
                                         nejsou povazovany za chybu}
      zlomeksec          =10;           {takovy zlomek sekundy meri pocet retracu}
      maxfreqerror       =zlomeksec;    {maximalni mozna chyba v freq}
                                        {pri zmene zmenit i EWratio}

{---------------------------------------------------------------------------
 Nahrada instrukce OUT DX,AX, kterou nektere vadne karty neakceptuji.
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
     {na systemech s irq2 nebo bez retrace neceka na nic}
     push si
     push ds
     lds si,self
     cmp [si+RetraceLen],65534
     pop ds
     pop si
     jae @9 {...zakladni postup}
     {ja @9 {...waituje i pri irq2, mozna na voodoo3 zabrani cukani pri irq2
               ale chtelo by to testnout}
     {ale bacha, s ja @9 by to tu asi mohlo ztuhnout
       (pokud funguje irq2 ale nefungujou retrace bits na 3dah)}

     push ax
     push dx
     @2:mov dx,3dah;in al,dx;test al,8;jnz @2
     pop dx
     pop ax
 @9:
 end;

procedure irq2abort;
begin
 erMsg(_(_erKartaSeZblaznila));
end;

{---------------------------------------------------------------------------
 Ceka tesne pred zacatek navratu paprku.
 Nemeni registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.WaitBeforeRetrace;assembler;
 var changes:byte;
     old:word;
 asm
     {na systemech s bez irq2 neceka na nic}
     pusha
     push es

     les di,self
     cmp es:[di+RetraceLen],65534
     jne @end

 {pro systemy generujici irq2}
 {kdyz irq2 nahodou neprijde, mame zakys,
  ktery jde abortnout jedine tremi stisky cehokoliv,
  ale jsme-li zde, chodivost byla overena, nemelo by to nastat}
     mov es,seg0040
     mov changes,0
     mov ax,word ptr es:[1ch]
     mov old,ax
 @wait:
     mov ax,word ptr es:[1ch]
     mov bx,old
     cmp ax,bx
     jz @nochange
     inc changes
     cmp changes,6
     jne @nochange
     call irq2abort
     @nochange:
     mov old,ax

     call vga_IRQ
     or al,al
     jz @wait

 @end:
     pop es
     popa
 end;


{---------------------------------------------------------------------------
 Ceka na dalsi snimek podle stopek.
 Tato procedura je totiz volana pri retracelen=65535 (pevna frekvence).
 ---------------------------------------------------------------------------}
Procedure TScreen.WaitForClock;
var l:longint;
    tikuodminula:longint;
begin
 stopky.LookAt;
 tikuodminula:=stopky.mikro div (1000000 div screenfreq);
 if tikuodminula=0 then begin
   {vsechno se stiha, ted je treba cekat}
   for l:=0 to 65536 do begin
     stopky.LookAt;
     tikuodminula:=stopky.mikro div (1000000 div screenfreq);
     if tikuodminula>0 then break;
     end;
   stopky.Eat(tikuodminula*(1000000 div screenfreq));
   end
 else
   {nestihame. o dobrou dynamiku scrollingu se postara actualscreenfreq,
    my se muzeme nadale snazit treba o nerealnych 70Hz}
   stopky.Start;
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

   Nektere systemy (dosemu) vubec refresh nesignalizuji.
 ---------------------------------------------------------------------------}
Procedure TScreen.WaitForRetrace;assembler;
 asm
     db 66h;pusha
     push es

     les di,self
     mov bx,es:[di+RetraceLen]
     cmp bx,65535
     je  @all_useless
     cmp bx,65534
     jne @retrace_useful

 {pro systemy generujici irq2}
 @irq2_useful:
     jmp @end

 {pro systemy generujici horizontal retrace signal}
 @retrace_useful:
     mov cx,1280{nastavi ze po 1280 nedostatecne dlouhych navratech skonci}
     mov dx,3dah;
 @3: in  al,dx;test al,8;jz @3{cyklit dokud se nevraci}
     dec cx;jz @8
     {testovat ze jede pouze nahoru x krat za sebou, jinak skok na predchozi radek}
     mov bx,es:[di+RetraceLen]
 @5: dec bx;js @end
     in  al,dx;test al,8;jnz @5
     jmp @3
 @8: {nasilne skonci kdyz uz to trva moc dlouho}
     cmp es:[di+RetraceLen],0;jz @end
     {zkusi snizit RetraceLen aby se vesel do vertical retrace}
     dec es:[di+RetraceLen]
     jmp @end

 {pro systemy bez retrace.. ceka na nejblizsi tik hodin}
 {kdyz nahodou neprijde, cykleni skonci rekneme po 60*65536 pruchodech}
 @all_useless:
     {}
     db 66h;push word ptr self
     call WaitForClock
     {
     les di,retrace_clock
     mov ax,es:[di]
     mov bx,60
     mov cx,0
 @1: loop @2
     dec bx
     jz  @end
 @2: cmp ax,es:[di]
     je  @1
     {}
     jmp @end

 @end:
     pop es
     db 66h;popa
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
     db 66h;push word ptr self;call WaitForTrace
     db 66h;push word ptr self;call WaitBeforeRetrace
     db 66h;push word ptr self;call WaitForRetrace
     jmp @start
   @end:
 end;

{---------------------------------------------------------------------------
 Synchronizuje se s paprskem - ceka zhruba na okamzik kdy zacina bezet nahoru
 (nebo o chvili driv/pozdejc).
 Bere v uvahu 'synced', takze neceka, kdyz predtim probehla jina funkce,
 ktera uz si na paprsek pockala.
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
      if not ret then erMsg(_(_erNenahazujeRet));
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
 if @userSync<>nil then userSync;
 {IncMs(1000 div screenfreq);}
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

{---------------------------------------------------------------------------
 Vznasi VGA pozadavek na preruseni, ono legendami opredene IRQ2 generovane
 pri navratu paprsku?
 Pri prvnim zavolani po nastaveni modu vraci -1.
 Dokud nezacal retrace, vraci 0.
 Kdykoliv od konce genrovani obrazu (tesne pred zacatkem navratu, uz se
 kresli jen dolni border) do zavolani teto funkce vraci 1.
 (To je jen idealni stav, funkcnost musi byt pred pouzivanim otestovana.
  Pokud stale vraci -1, je dobre ji radsi nevolat.)
 ---------------------------------------------------------------------------}
var IRQ2_hit:boolean;

FUNCTION  vga_IRQ:shortint;assembler;
 asm
      {is irq2 enabled by user?}
      cmp irq2_enabled,false
      je @bad

      {is irq2 enabled by gfx card?}
      mov dx,3d4h
      mov al,11h
      out dx,al
      inc dx
      in  al,dx
      and al,16+32
      cmp al,16
      jz @enabled
      {disable irq2 in interrupt controller on motherboard}
      {danger: it corrupts running eventwait
      in  al,21h
      or  al,4
      out 21h,al
      {enable irq2 on vga}
      mov dx,3d4h
      mov al,11h
      out dx,al
      inc dx
      in  al,dx
      and al,not (16+32)
      out dx,al
      or  al,16
      out dx,al
      @bad:
      mov al,-1
      jmp @end
      @enabled:

      {test interrupt state}
      mov dx,3c2h
      in  al,dx
      and al,128
      jz  @end

      {clear interrupt state}
      mov dx,3d4h
      mov al,11h
      out dx,al
      inc dx
      in  al,dx
      and al,not (16+32)
      out dx,al
      or  al,16
      out dx,al
      mov al,1

     @end:
 end;


{€€€€€€€€€€€€€€€€ P A L E T A €€€€€€€€€€€€€€€€}

Constructor TPal.Init;
var i:byte;
begin
 inherited Init;
 last:=255;
 pal[0].a:=pifUsed;
 for i:=1 to 255 do pal[i].a:=pifFree;
 Count[pifDead]:=0;
 Count[pifUsed]:=1;
 Count[pifFree]:=255;
end;

Procedure TPal.MakeGrayscale;
var i:byte;
begin
 first:=0;
 last:=255;
 for i:=0 to 255 do begin
   pal[i].r:=i shr 2;
   pal[i].g:=i shr 2;
   pal[i].b:=i shr 2;
   pal[i].a:=pifUsed;
   end;
 Count[pifDead]:=0;
 Count[pifUsed]:=256;
 Count[pifFree]:=0;
end;

Procedure TPal.Take(p:PPal);
var c:byte;
begin
 if p<>nil then begin
   for c:=p^.first to p^.last do begin
     pal[c].r:=p^.pal[c].r;
     pal[c].g:=p^.pal[c].g;
     pal[c].b:=p^.pal[c].b;
     end;
   first:=minI(first,p^.first);
   last:=maxI(last,p^.last);
   Setup(p^.first,p^.last,pifUsed);
   end;
end;


{$IFDEF DOSMEM}
{---------------------------------------------------------------------------
 Nacte nebo nastavi paletu pres vesa bios.
 Az narazis na kartu, na ktere nepujde pracovat s paletou primo,
 zkus tuto funkci. Pro univezalni pouziti neni, vesa biosy tuto sluzbu
 zatim moc nepodporujou.
 ---------------------------------------------------------------------------}
Function vesa_Palette(nastavit:boolean;fromcol,tocol:byte;p:PColor):boolean;
{$ifndef dpmi}
assembler;
asm
       mov ax,4f09h
       mov bl,1
       cmp nastavit,false
       je @nacist
       dec bx
       @nacist:
       mov dl,fromcol
       mov dh,0
       mov cl,tocol
       mov ch,0
       sub cx,dx
       inc cx
       les di,p
       int 10h
       cmp ax,4fh
       je @ok
       xor ax,ax
       @ok:
end;
{$else}
var   RealModeRegs      :dpmiRealCallRegs;
begin
 if nastavit then move(p^,dosfree^,(tocol+1-fromcol)*sizeof(TColor));
 with RealModeRegs do begin
    ClrRegs(RealModeRegs);
    rEAX:=$4f09;
    if nastavit then rEBX:=0 else rEBX:=1;
    rEDX:=fromcol;
    rECX:=tocol+1-fromcol;
    rEDI:=PtrRec(dosfree).Ofs;
    rES:=dosfreeSeg;
    erCheck(TError(dpmiRealModeInt($10,@RealModeRegs)));
    vesa_Palette:=LoWord(rEAX)=$4f;
    end;
 if not nastavit then move(dosfree^,p^,(tocol+1-fromcol)*sizeof(TColor));
end;
{$endif}
{$ENDIF DOSMEM}

{---------------------------------------------------------------------------
 Do pole pal nacte z karty aktualni paletu 256 barev.
 ---------------------------------------------------------------------------}
Procedure TPal.ReadFromTo(fromcol,tocol:byte);assembler;
 asm
     les di,self
     add di,pal
     mov al,sizeofTColor;mul fromcol;add di,ax
     mov al,tocol;sub al,fromcol;jc @end;mov ah,0;inc ax
     mov cx,ax
     mov dx,3c7h;mov al,fromcol;out dx,al;add dx,2
     @1:
      in al,dx;mov [es:di+TColor.r],al
      in al,dx;mov [es:di+TColor.g],al
      in al,dx;mov [es:di+TColor.b],al
      add di,sizeofTColor
      loop @1
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
 Nastavi jednu barvu v poli a v odpovidajicim jasu (nowbright) i na karte.
 ---------------------------------------------------------------------------}
Procedure TPal.SetCol(col,r,g,b:byte);
begin
 pal[col].r:=r;
 pal[col].g:=g;
 pal[col].b:=b;
 if nowbright>0 then SetBrightFromTo(nowbright,col,col);
end;
(*assembler;
 asm
     les di,self
     mov dx,3c8h;mov al,col;out dx,al;inc dx
     mov bl,sizeofTColor;mul bl;mov bx,ax{bx=3*col}
     mov al,r;out dx,al;mov [es:di+bx+TPal.pal+TColor.r],al
     mov al,g;out dx,al;mov [es:di+bx+TPal.pal+TColor.g],al
     mov al,b;out dx,al;mov [es:di+bx+TPal.pal+TColor.b],al
 end;
*)

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
    else hau:=exp(longint(how)*abs(c-tocol)/abs(fromcol-tocol)/1000);
   r:=pal[c].r;if er then r:=minW(63,round(r*hau));
   g:=pal[c].g;if ge then g:=minW(63,round(g*hau));
   b:=pal[c].b;if be then b:=minW(63,round(b*hau));
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
    do inc(mid,PBytes(@pal[c])^[ofs]*abs(c-tocol));
   mid:=mid*2 div delta div (delta+1);
   for c:=minW(fromcol,tocol) to maxW(fromcol,tocol) do begin
     hau:=exp(how*abs(c-tocol)/delta/400);
     PBytes(@pal[c])^[ofs]:=Bounded(round(mid+(PBytes(@pal[c])^[ofs]-mid)*hau),0,63);
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
     mov al,sizeofTColor;mul fromcol;add si,ax
     mov al,tocol;sub al,fromcol;jc @end;mov ah,0;inc ax
     mov cx,ax

{bios
     mov di,offset freeb
     @1:
      mov al,[es:si+TColor.r];mov [di],al;inc di
      mov al,[es:si+TColor.g];mov [di],al;inc di
      mov al,[es:si+TColor.b];mov [di],al;inc di
      add si,sizeofTColor
      loop @1
     mov ax,1012h
     mov bl,fromcol
     mov bh,0
     mov cl,tocol
     mov ch,0
     inc cx
     sub cx,bx
     mov dx,offset freeb
     push ds
     pop es
     int 10h

{vga slow
     mov dx,3c8h
     mov ah,fromcol
     @1:
      mov al,ah
      out dx,al
      inc dx;
      mov al,[es:si+TColor.r];out dx,al
      mov al,[es:si+TColor.g];out dx,al
      mov al,[es:si+TColor.b];out dx,al
      add si,sizeofTColor
      dec dx
      inc ah
      loop @1

{vga fast}
     mov dx,3c8h
     mov al,fromcol
     out dx,al;inc dx;
     @1:
      mov al,[es:si+TColor.r];out dx,al
      mov al,[es:si+TColor.g];out dx,al
      mov al,[es:si+TColor.b];out dx,al
      add si,sizeofTColor
      loop @1

{}
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
     mov al,[es:si+TPal.darkcolor+TCol.r];mul bh;mov cl,ah{+r}
     mov al,[es:si+TPal.darkcolor+TCol.g];mul bh;mov ch,ah{+g}
     mov al,[es:si+TPal.darkcolor+TCol.b];mul bh;mov bh,ah{+b}

     {posun barvy smerem k darkcolor a out}
     add si,pal
     mov al,sizeofTColor;mul fromcol;add si,ax
     mov al,tocol;sub al,fromcol;jc @end;mov ah,0;inc ax
     mov di,ax
     mov dx,3c8h;mov al,fromcol;out dx,al
     inc dx
     @1:
      mov al,[es:si+TColor.r];mul bl;mov al,ah;add al,cl;out dx,al{r}
      mov al,[es:si+TColor.g];mul bl;mov al,ah;add al,ch;out dx,al{g}
      mov al,[es:si+TColor.b];mul bl;mov al,ah;add al,bh;out dx,al{b}
      add si,sizeofTColor
     dec di
     jnz @1
     @end:
 end;

{---------------------------------------------------------------------------
 time>0 => behem time snimku rozsviti obraz (paletu)
 time<0 => behem -time snimku ztmavi obraz
 time=0 => okamzite rozsviti obraz
 ---------------------------------------------------------------------------}
Procedure TAbstractMap.Fade(time:integer);
var   i:integer;
begin
 if pal=nil then exit;
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
 Oznaci zadane barvy zadanym flagem.
 ---------------------------------------------------------------------------}
Procedure TPal.Setup(fromindex,toindex,settype:byte);
var   i:byte;
begin
 for i:=fromindex to toindex do begin
   dec(Count[pal[i].a]);
   pal[i].a:=settype;
   inc(Count[settype]);
   end;
end;

{---------------------------------------------------------------------------
 Alloc(R,G,B) vybere vhodny index z palety tak, aby se jeho barva
 co nejvic blizila zadanemu RGB. Kdyz zadny vhodny nenajde, zkusi
 ho naalokovat (zabrat index s pifFree).
 ---------------------------------------------------------------------------}
Function TPal.Alloc(r,g,b:shortint):byte;
var   someFree:byte;i,delta,bestdelta:word;
label 1;
begin
 {najde nejblizsi barvu
 bestdelta:=32000;
 for i:=0 to 255 do
  if pal[i].a=pifUsed then begin
     delta:=abs(r-pal[i].r)+abs(g-pal[i].g)+abs(b-pal[i].b);
     if delta<bestdelta then begin
       Alloc:=i;
       bestdelta:=delta;
       end;
     end;{}
 asm
   {es:si=@pal,bx=mindelta,cl=actualcolor,ch=bestcolor}
   les si,self
   add si,pal
   mov bx,32000
   xor dx,dx
   xor cx,cx
   @1:
   cmp [es:si+TColor.a],pifUsed;jne @next
   mov dl,g;sub dl,[es:si+TColor.g];jnc @nepretekG;neg dl;@nepretekG:
   mov ax,dx;add ax,dx;add ax,dx{mulG=3};cmp ax,bx;jnc @next
   mov dl,r;sub dl,[es:si+TColor.r];jnc @nepretekR;neg dl;@nepretekR:
   add ax,dx;add ax,dx{mulR=2};cmp ax,bx;jnc @next
   mov dl,b;sub dl,[es:si+TColor.b];jnc @nepretekB;neg dl;@nepretekB:
   add ax,dx{mulB=1};cmp ax,bx;jnc @next
   mov bx,ax
   mov ch,cl
   @next:
   add si,sizeofTColor
   inc cl
   jnz @1
   mov @result,ch
   mov bestdelta,bx
 end;
(*
{}bioswriteln('');
{}bioswriteln('alloc('+stri(r)+','+stri(g)+','+stri(b)+')');
{}bioswriteln('free='+stri(Count[pifFree]));
{}bioswriteln('used='+stri(Count[pifUsed]));
{}bioswriteln('dead='+stri(Count[pifDead]));
{}bioswriteln('bestdelta='+stri(bestdelta));
{}bioswriteln('foundinpal='+stri(byte(longint(bestdelta)*round(sqrt(Count[pifFree]))<80)));
{}if (bestdelta>=35) then
   for i:=0 to 255 do with pal[i] do bioswriteln(' r='+stri(r)+' g='+stri(g)+' b='+stri(b)+'  a='+stri(a));
(**)
 {pokud je dost dobra, pouzije ji}
 if longint(bestdelta)*round(sqrt(Count[pifFree]))<80 then exit;
 {jinak zalozi novou}
 for someFree:=0 to 255 do
  if pal[someFree].a=pifFree then begin
    SetCol(someFree,r,g,b);
    Setup(someFree,someFree,pifUsed);
    Alloc:=someFree;
{bioswriteln('allocated='+stri(somefree));{}
    exit;
    end;
 {$ifdef beta}
 erBetaMsg('TPal.Alloc chaos');
 {$endif}
 Alloc:=random(255);
end;

const attrCol:array[0..15] of TCol=(
       (r:  0;g:  0;b:  0),
       (r:  0;g:  0;b:170),
       (r:  0;g:170;b:  0),  {takhle vypadaj barvy v textmodu}
       (r:  0;g:170;b:170),
       (r:170;g:  0;b:  0),
       (r:170;g:  0;b:170),
       (r:170;g:170;b:  0),
       (r:170;g:170;b:170),
       (r: 85;g: 85;b: 85),
       (r: 85;g: 85;b:255),
       (r: 85;g:255;b: 85),
       (r: 85;g:255;b:255),
       (r:255;g: 85;b: 85),
       (r:255;g: 85;b:255),
       (r:255;g:255;b: 85),
       (r:255;g:255;b:255));

Function TAbstractMap.TextColor(attr:byte):longint;
begin
 TextColor:=Color(attrCol[attr].r,attrCol[attr].g,attrCol[attr].b,255);
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
 Vypinani a zapinani zobrazovani na monitoru.
 ---------------------------------------------------------------------------}
FUNCTION  bios_GetMode:byte;assembler;asm mov ah,0fh;int 10h;end;
FUNCTION  bios_GetXres:byte;assembler;asm mov ah,0fh;int 10h;mov al,ah;end;
FUNCTION  bios_GetYres:byte;assembler;asm mov ax,1130h;mov bh,0;push bp;int 10h;pop bp;mov al,dl;inc al;end;
FUNCTION  bios_GetCharYres:byte;assembler;asm mov ax,1130h;mov bh,0;push bp;int 10h;pop bp;mov al,cl;end;
PROCEDURE bios_GotoXY(x,y:byte);assembler;asm mov dl,x;mov dh,y;mov ah,2;mov bh,0;int 10h;end;
FUNCTION  bios_GetXY:word;assembler;asm mov ah,3;mov bh,0;int 10h;xchg ax,dx;end;
PROCEDURE bios_ScreenOff;assembler;asm mov ax,1201h;mov bl,36h;int 10h;end;
PROCEDURE bios_ScreenOn;assembler;asm mov ax,1200h;mov bl,36h;int 10h;end;

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
   if x>255 then begin
     inc(y,x div vramXres);
     x:=x mod vramXres;
     end;
   {$ifdef beta}
   if (x<0) or (x>255) or (y<0) or (y>255)
    then BiosWriteln('TScreen.Gotoxy('+stri(x)+','+stri(y)+')');
   {$endif}
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
 (* kvuli podpore non-VGA karet vynecha operace pracujici s VGA registry
 {zapamatuje si doublescan}
 double:=vga_GetDoubleScan;
 *)

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
      LoadUserFont:=_erLowDosMem;
      exit;
      end;
    {zkopci font do naalokovane dosove pameti}
    move(fnt^,dosfnt^,256*vyska);
    {zavede newfnt}
    with RealModeRegs do begin
       ClrRegs(RealModeRegs);
       rEAX:=$1110;
       rEBX:=vyska shl 8;
       rECX:=$0100;
       rES:=Segment;{adresa newfontu}
       end;
    LoadUserFont:=erDumb(TError(dpmiRealModeInt($10,@RealModeRegs)));
    {uvolni pamet}
    FreeMemDos(dosfnt,256*vyska);
  {$endif}
  end;

 (* kvuli podpore non-VGA karet vynecha operace pracujici s VGA registry
 {nastavi vysku znaku, starsi BIOSy to samy neudelaj}
 vga_SetCharYres(vyska);
 {kdyz se doublescan zmenil, ohlasi chybu}
 if double<>vga_GetDoubleScan then erMsg(_(_erBiosZmenilDblscn));
 *)
end;


{---------------------------------------------------------------------------
 Inteligentne umisti znak do matice sirky 8 a vysky zadane.
 Pri disizbase si do top a bot ulozi udaje o velikosti puvodniho znaku.
 Pri expanddis je vyuzije a znak roztahne z puvodni do nove velikosti.
 Jinak proste umisti stred do stredu a pripadne precnivajici kraje orizne.
 ---------------------------------------------------------------------------}
Procedure _ResizeChar(src:PLine;relX,relY:shortint;sirB,vysB:byte;
                      dest:PLine;sizeOver,sizeUnder:shortint;
                      disizbase,expanddis:boolean;var top,bot:shortint);
var   i,j:integer;
begin
 for j:=MaxI(0,-sizeOver-relY) to MinI(vysB-1,sizeUnder-1-relY) do
  dest^[sizeOver+relY+j]:=src^[j*Bi2By(sirB)] shr relX;
 if disizbase then begin
   top:=sizeOver+relY; {kolik zustane nahore volnych radek}
   bot:=sizeUnder-relX;{kolik dole...muze byt i zaporne}
   end;
 if expanddis then begin
   if top>0 then
    if sizeOver+sizeUnder-top-bot>=2 then
    if CmpByte(@dest^[top],dest^[top],2)
     then fillchar(dest^[0],top,dest^[top])
     else
     if sizeOver+sizeUnder-top-bot>=4 then
     if CmpBlock(@dest^[top],@dest^[top+2],2)
      then for i:=1 to top do dest^[top-i]:=dest^[top+i mod 2]{};
   if bot>0 then
    if sizeOver+sizeUnder-top-bot>=2 then
    if CmpByte(@dest^[sizeOver+sizeUnder-bot-2],dest^[sizeOver+sizeUnder-bot-1],2)
     then fillchar(dest^[sizeOver+sizeUnder-bot],bot,dest^[sizeOver+sizeUnder-bot-1])
     else
     if sizeOver+sizeUnder-top-bot>=4 then
     if CmpBlock(@dest^[sizeOver+sizeUnder-bot-2],@dest^[sizeOver+sizeUnder-bot-4],2)
      then for i:=1 to bot do dest^[sizeOver+sizeUnder-bot-1+i]:=dest^[sizeOver+sizeUnder-bot-1-i mod 2]{};
   end;
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
      param             :array[minCharYres..maxCharYres] of byte=(3,3,3,3,3,3,3,3,3,2,2,6);
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
   var c:char;
       top,bot,sizeOver,sizeUnder,relY:shortint;
   begin
    {zkonverti font do cilove velikosti (z pole romfnt do pole newfnt)}
    fillchar(newfnt^,sizeof(newfnt^),0);
    relY     :=-romsiz*3 div 2;
    sizeOver :=vyska*3 div 2;
    sizeUnder:=vyska-sizeOver;
    for c:=#0 to #255 do
     _ResizeChar(PLine(@romfnt^[ord(c)*romsiz]),0,relY,8,romsiz,
                 PLine(@newfnt^[ord(c)*vyska]),sizeOver,sizeUnder,
                 c in ['∞']{base},c in ['∞'..'ﬂ']{expand},top,bot);
   end;

Begin
 vyska:=Bounded(vyska,minCharYres,maxCharYres);

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
        ClrRegs(RealModeRegs);
        rEAX:=$1130;
        rEBX:=par shl 8;
        end;
      result:=TError(dpmiRealModeInt($10,@RealModeRegs));
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
 {jejich efekt je videt na nasledujicich radkach}
  if (name<>'') and (@_LoadDiskFont<>nil) then result:=_LoadDiskFont(name,vyska){nastavi .fnt font z disku} else
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
   bit 12        - nastavit jen 40 sloupcu misto 80
 ---------------------------------------------------------------------------}
Function TScreen.SetMode_TEXT(newmode:word):boolean;
var   radek,charsirka:byte;
      biosmode:byte;
begin
 {nastavi neuspech, pri neuspechu pak uz staci jen exitnout}
 SetMode_TEXT:=false;

 {zanalyzuje jednotlive bity cisla NewMode}
 radek:=newmode and $7f;
 if (newmode and $1000)=0 then biosmode:=3 else biosmode:=1;
 biosmode:=biosmode or (newmode and $80);
 case newmode shr 10 and 3 of 0:charsirka:=0;
                              1:charsirka:=8;
                              2:charsirka:=9;
                              3:exit;
                             end;

 {nastavi standardni textmod 3}
 {pred a po zmene modu provadi bezpecnostni opatreni proti bliknuti}
 PreAntiBlik;
 asm
     mov ah,0
     mov al,biosmode
     int 10h;
 end;
 PostAntiBlik;

 {okno do videopameti ve standardnim texmodu zacina vzdy na adrese SegB800}
 SegVram           :=SegB800;
 WinSizeKB         :=32;
 VramSizeKB        :=32;

 {ve standardnich textmodech lze psat pres Bios a jsou VGA kompatibilni}
 BiosOutput        :=true;
 VgaCompat         :=true;

 {ted je jiste ze neni nastaven VESA mod}
 VesaMode          :=false;
 vesa_NowBank      :=0;
 vesa_Banking      :=false;

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
 ByPP              :=2;
 lineOffset        :=4*vga_GetLineOffset;
 {opravi chybu dosemu}
 if lineOffset=0 then lineOffset:=2*Xres;

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
                        RMS             : byte;  {Red Mask Size}
                        RFP             : byte;  {Red Field Position}
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

const
      BiPPlist:array[model_text..model_RGBA32] of byte=(16,0,0,0,8,8,0,0,0,0,0,0,0,0,0,0,15,15,16,16,24,24,24,24);
      ByPPlist:array[model_text..model_RGBA32] of byte=( 2,0,0,0,1,1,0,0,0,0,0,0,0,0,0,2, 2, 2, 2, 2, 3, 3, 4, 4);
                                                                                      {^to je kvuli histogramu}
{---------------------------------------------------------------------------
 Nabankuje na 64KB bank (n mod vesa_Banks).
 DS nemusi ukazovat na datasegment.
 Kvuli tomu je zde nutne vypnout stack checking (jinak nahodne haze overflowy).
 Nemeni registry.
 ---------------------------------------------------------------------------}
{$ifopt s+}{$define _stack_checking_}{$s-}{$endif}
Procedure TScreen.vesa_SetBank(n:byte);assembler;
 asm
     push ds
     pusha

     lds si,self
     cmp [si+vesa_Banking],false;je @bankend
     db 66h;xor ax,ax
     mov al,n
     cmp [si+vesa_NowBank],ax;je @bankend
     mov [si+vesa_NowBank],ax
     db 66h;shl ax,6
     db 66h;xor dx,dx
     db 66h;div word ptr [si+VramSizeKB] {modulo vramsize, ochrana proti kartam padajicim pri preteceni}
     xchg ax,dx
     xor dx,dx
     div [si+vesa_Granularity]  {serizeni podle granularity}

     xor bx,bx
     mov dx,ax
     cmp [si+vesa_UseWinA],false;je @skipA
     mov ax,4f05h
     int 10h{nabankuje window A}
     @skipA:

     cmp [si+vesa_UseWinB],false;je @skipB
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
Procedure TScreen.vesa_IncBank;assembler;
 asm
     push ds
     push si
     push ax
      lds si,self
      mov ax,[si+vesa_NowBank]
      inc ax
      push ax
      db 66h;push word ptr self;call vesa_SetBank
     pop ax
     pop si
     pop ds
 end;

{---------------------------------------------------------------------------
 Nabankuje na predchozi 64KB bank (neni-li v nultem).
 DS nemusi ukazovat na datasegment.
 Nemeni registry.
 ---------------------------------------------------------------------------}
Procedure TScreen.vesa_DecBank;assembler;
 asm
     push ds
     push si
     push ax
      lds si,self
      mov ax,[si+vesa_NowBank]
      or ax,ax
      jz @skip
      dec ax
      push seg @data;pop ds
      push ax
      db 66h;push word ptr self;call vesa_SetBank
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
 if not VesaMode then GetBankRegs:=vga_GetXRegs else GetBankRegs:=vesa_NowBank;
end;

{---------------------------------------------------------------------------
 Vrati bankregistry do puvodniho stavu.
 ---------------------------------------------------------------------------}
Procedure TScreen.SetBankRegs(x:TBankRegs);
begin
 if not VesaMode then vga_SetXRegs(x) else vesa_SetBank(x);
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
Function TScreen.vesa_Setvis(x,y:word):boolean;assembler;
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
     mov bl,[es:di+vesa_SetvisSyncuje]
     mov [es:di+synced],bl
     cmp ax,4fh;mov al,0;jnz @end
     inc al
     @end:
 end;

{---------------------------------------------------------------------------
 Nastavi display address start a pocka na retrace.
 Vraci uspesnost.
 ---------------------------------------------------------------------------}
Function TScreen.vesa_SetvisSync(x,y:word):boolean;
begin
 vesa_Setvis(x,y);
 if not vesa_SetvisSyncuje then begin
   Refresh(1);
   synced:=true;
   end;
end;


{---------------------------------------------------------------------------
 Pokud je ModeInfo nil, naalokuje pro nej kus konvencni pameti, jinak
 predpoklada ze uz naalokovana a pripravena je.
 Vrati true kdyz se podari ModeInfo naplnit spravnymi udaji o modu.
 ModeInfo si pote musis odalokovat sam (je-li <>nil).
 ---------------------------------------------------------------------------}
FUNCTION GetModeInfo(mode:word;var ModeInfo:PModeInfoBlock;var segment:word):boolean;
      {$ifdef dpmi}
var   RealModeRegs:dpmiRealCallRegs;
      {$endif}
label freee;
begin
 GetModeInfo:=false;

 {naalokuje pamet pro modeinfo}
 if (ModeInfo=nil) and not GetMemDos(segment,pointer(ModeInfo),sizeof(ModeInfo^))
  then exit;
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
    ClrRegs(RealModeRegs);
    rEAX:=$4f01;
    rECX:=mode;
    rES:=Segment;
    if erDumb(TError(dpmiRealModeInt($10,@RealModeRegs)))<>erOk then goto freee;
    {je sluzba vesa.getinfo podporovana ?}
    if LoWord(rEAX)<>$4f then goto freee;
    end;
 {$endif}

 {ok}
 GetModeInfo:=true;

 {if ModeInfo^.MemoryModel=5 then ModeInfo^.MemoryModel:=4;{dosemu fix}

 freee:
end;

PROCEDURE LeaveModeInfo(var ModeInfo:PModeInfoBlock);
begin
 if ModeInfo<>nil then FreeMemDos(pointer(ModeInfo),sizeof(ModeInfo^));
end;

{---------------------------------------------------------------------------
 Vraci polozku reslistu obsahujici zadany mod.
 ---------------------------------------------------------------------------}
FUNCTION GetResItem(mode:word):PResItem;
  function ModeMatch(p:PResItem):boolean;far;
  begin
   ModeMatch:=(p^.amode=mode);
  end;
begin
 GetResItem:=ResList.FirstThat(@ModeMatch);
end;

FUNCTION GetResItem2(model,mode:word):PResItem;
  function ModeMatch(p:PResItem):boolean;far;
  begin
   ModeMatch:=(p^.amodel=model) and (p^.amode=mode);
  end;
begin
 GetResItem2:=ResList.FirstThat(@ModeMatch);
end;


{---------------------------------------------------------------------------
 Zpravi screenu o stavu globalni promenne irq2_enable.
 ---------------------------------------------------------------------------}
Procedure TScreen.ReadIrq2Enabled;
begin
 if s_irq2_enabled<>irq2_enabled then begin
   vga_detectRetraceLen;
   s_irq2_enabled:=irq2_enabled;
   end;
end;

{---------------------------------------------------------------------------
 Nastavi pro soucasny mod nejvhodnejsi retraceLen (zpusob detekovani retrace).
 Zaroven zjisti screenfreq.
 Kdyz funguje EventWait, trva zhruba 0.1s, ale muze se protahnout.
 Kdyz nefunguje EventWait, trva zhruba 0.5s, ale muze se protahnout.
 Kdyz jednou v danem modu skonci neuspechem, skonci tak vzdycky.
 ---------------------------------------------------------------------------}
var   badretrace:array[false..true] of boolean;

Procedure TScreen.vga_DetectRetraceLen;
var   t:TStopky;
      msgshown:boolean;
      prevRetraceLen:word;
      r:shortint;
const EWratio=5;{kolikrat dyl merit bez EventWaitu, pri zmene zmenit i zlomeksec}
label 1,3,9;
begin
 RetraceLen:=0;
 msgshown:=false;

 {funguje nam nejlepsi metoda: vga_IRQ?}
 {rovnou vynechame pokud o sobe karta prohlasi, ze neni VGA kompatibilni}
 if VgaCompat and irq2_enabled then begin
   vga_IRQ;
   if (vga_IRQ=0) and (vga_IRQ=0) then begin
     t.Start;
     repeat
       r:=vga_IRQ;
     until (r<>0) or (t.LookAt>100);
     if r=1 then RetraceLen:=65534;
     end;
   end;

 {at uz to IRQ pujde nebo ne, musime jeste spocitat screenfreq}
 {kdyz IRQ nepujde, jeste se ted seridi RetraceLen}
 1:
 prevRetraceLen:=RetraceLen;
 screenfreq:=0;
 if badretrace[VesaMode] then goto 9;

 3:
 if EventWaitOk
  then DelayStart(1000000 div maxfreqerror)
  else t.Start;
 repeat
  refresh(1);
  if EventWaitOk
   then inc(screenfreq,maxfreqerror)
   else inc(screenfreq,maxfreqerror div EWratio);

  if screenfreq>maxgoodfreq then
   {pojistka proti divnemu irq2 ci nespolehlivym hodinam}
   if RetraceLen=65534 then begin
     if EventWaitOk then begin
       if debug then BiosWriteln('irq2+eventwait: freq high');
       EventWaitOk:=false{selhava pouze pri soucasnem pouziti irq2, ale selhava}
       end
     else begin
       if debug then BiosWriteln('irq2+clock: freq high');
       RetraceLen:=0;{zdalo se ze irq2 pujde ale neslo, musime zkusit jinou metodu}
       end;
     goto 1;
     end
   {serizeni RetraceLen pokud to je zapotrebi}
   else begin
     if not msgshown then begin
       if debug then BiosWrite('shift to abort');
       msgshown:=true;
       end;
     if debug then BiosWrite('.');
     if RetraceLen<prevRetraceLen then begin
       if debug then BiosWriteln('retrace chaos');
       badretrace[VesaMode]:=true;
       end;
     if RetraceLen>50 then begin
       if debug then BiosWriteln('strange retrace');
       badretrace[VesaMode]:=true;
       end;
     if mem[Seg0040:$17] and 3>0 then begin
       if debug then BiosWriteln('aborted');
       badretrace[VesaMode]:=true;
       end;
     if not badretrace[VesaMode] then inc(RetraceLen,3);
     goto 1;
     end;
 until (EventWaitOk and DelayEnd) or
       (not EventWaitOk and (t.LookAt div EWratio>=1000 div maxfreqerror));

 if screenfreq<mingoodfreq then
   {pojistka proti divnemu irq2 ci nespolehlivym hodinam}
   if RetraceLen=65534 then begin
     if EventWaitOk then begin
       if debug then BiosWriteln('irq2+eventwait: freq low');
       EventWaitOk:=false{selhava pouze pri soucasnem pouziti irq2, ale selhava}
       end
     else begin
       if debug then BiosWriteln('irq2+clock: freq low');
       RetraceLen:=0;{zdalo se ze irq2 pujde ale neslo, musime zkusit jinou metodu}
       end;
     goto 1;
     end
 else
   badretrace[VesaMode]:=true;
 9:
 {pojedeme bez retrace}
 if badretrace[VesaMode] then{} begin
   screenfreq:=70;
   RetraceLen:=65535;
   end;
end;

{---------------------------------------------------------------------------
 Zdetekuje VesaBanking.
 ---------------------------------------------------------------------------}
Procedure TScreen.vesa_DetectVramSizeAndBanking;
var result:boolean;
    i:longint;
begin
 if (VesaVersion>=$100) and (vesamode) and (VramSizeKB>64) then begin
   vesa_Banking:=true;{nejdriv nastavi true aby vesa_SetBank vubec bezel}
   i:=1;
   while i*64<VramSizeKB do begin
     vesa_SetBank(0);
     mem[SegVram:0]:=0;
     vesa_SetBank(i);
     mem[SegVram:0]:=1;
     vesa_SetBank(0);
     if mem[SegVram:0]<>0 then break;
     mem[SegVram:0]:=1;
     vesa_SetBank(i);
     if mem[SegVram:0]<>1 then break;
     i:=i shl 1;
     end;
   VramSizeKB:=MinL(VramSizeKB,64*i);
   if VramSizeKB<=64 then vesa_Banking:=false;
   end
 else
   vesa_Banking:=false;
end;

{---------------------------------------------------------------------------
 Zdetekuje jestli vesa_Setvis ceka na paprsek.
 Trva zhruba 0.1s.
 ---------------------------------------------------------------------------}
Procedure TScreen.vesa_DetectSetvisSync;
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
    vesa_Setvis(0,i);
    inc(setvisfreq,zlomeksec);
    fast:=setvisfreq>screenfreq+3*maxfreqerror;{3* pro uplnou jistotu, teoreticky by melo stacit 2*}
   until DelayEnd or fast;
   vesa_SetvisSyncuje:=not fast;
   end
 else begin
   {pomale mereni pomoci stopek}
   s.Start;
   for i:=1 to snimku do vesa_Setvis(0,i);
   vesa_SetvisSyncuje:=s.LookAt>(snimku*1000 div maxgoodfreq);
   end;
 vesa_Setvis(0,0);
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
   if ((WinAAttributes or WinBAttributes) and 6)<>6 then exit;{umi read i write? :-)}
   end;
 ModeInfoSupported:=true;
end;


{---------------------------------------------------------------------------
 Nastavi pozadovany VESA mod a prislusne promenne.
 ---------------------------------------------------------------------------}
Function TScreen.SetMode_VESA(newModel,newMode:word):boolean;

var   ModeInfo:PModeInfoBlock;
      ModeInfoSeg:word;
      ResItem:PResItem;
      optional:boolean;
      i,j:word;
label freee;
begin
 {$ifdef testvga}bioswriteln('setmode_vesa(mdl='+stri(newmodel)+',mode='+stri(newmode)+')');{$endif}

 {nastavi neuspech, pri neuspechu pak uz staci jen exitnout}
 SetMode_VESA:=false;

 {hned se na to vykasle kdyz neni vesa}
 if VesaVersion=0 then exit;

 {hleda mod v seznamu modu; nenalezeno = nepodporovano}
 ResItem:=GetResItem2(newModel,newMode);
 if ResItem=nil then exit;

 {nahraje info}
 ModeInfo:=nil;
 ModeInfoSeg:=0;
 if not GetModeInfo(newMode,ModeInfo,ModeInfoSeg) then goto freee;

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
   VgaCompat         :=(ModeAttributes and 32)=0;{je registrove vga kompatibl?}
   vesa_Granularity  :=WinGranularity;{jaka je granularita?}
   vesa_NowBank      :=0;{po nastaveni modu jsem v banku 0}
   lineOffset        :=BytesPerScanLine;{jak jsou dlouhe radky ve videopameti?}
   ModeID            :=newMode;
   MapModel          :=ResItem^.aModel;{model a rozliseni cte z reslistu}
   Xres              :=ResItem^.aX;
   Yres              :=ResItem^.aY;
   BiPP              :=BiPPlist[MapModel];
   ByPP              :=ByPPlist[MapModel];

   {naplneni charXres a charYres necha na pozdeji (po nastaveni modu)}

   {$ifdef testvga}bioswriteln(' before set');{$endif}
   asm
     {nastavi mod}
     mov ax,4f02h;mov bx,newMode           {nastavi parametry pro setmode}
     int 10h                               {vola vesabios}
     cmp ax,4fh;jnz freee                  {testuje zda bylo volani ok}
   end;
   {$ifdef testvga}bioswriteln(' after set');{$endif}

   PostAntiBlik;

   if MapModel<>model_text then begin
     charXres        :=1;
     charYres        :=1;
     end
   else if optional then begin
     charXres        :=XCharSize;
     charYres        :=YCharSize;
     end
   else if VgaCompat then begin
     charXres        :=vga_GetCharXres;
     charYres        :=vga_GetCharYres;
     end
   else begin
     charXres        :=8;
     charYres        :=16;
     end;

   {v textmodu loadne font a znova zjisti Xres,Yres,charXres,charYres}
   if VgaCompat and (MapModel=model_text) then begin
     {zkontroluje jestli udaje obyc biosu odpovidaji udajum vesa biosu}
     if bios_GetYres<>Yres then Halt(_erBadVBE);
     {nastavi pozadovany font}
     ZadanaVyskaZnaku:=charYres;
     LoadFont(ZadanaVyskaZnaku);
     {zjisti nove Xres,Yres,charXres,charYres}
     Xres            :=bios_GetXres;
     Yres            :=bios_GetYres;
     charXres        :=vga_GetCharXres;
     charYres        :=vga_GetCharYres;
     if (charYres<5) or (charYres>16) then goto freee;{detekce selhala}
     {detekuje chybu biosu (loaduserfont se chova jako by mel jiny pocet scanlines)}
     if (vga_GetScanlines>195) and (vga_GetScanlines<Yres*charYres)
      then Halt(_erBadVBE);
     end;

   {$ifdef testvga}bioswriteln(' after loadfont');{$endif}

   {adresu zacatku okna do videopameti ve vesamodech nactu z WinA/BSegment}
   if (WinAAttributes and 7)=7 then begin
     SegVram         :=WinASegment;
     vesa_UseWinA     :=true;
     vesa_UseWinB     :=false;
     vesa_Banking     :=WinSize=64;
     end else
   if (WinBAttributes and 7)=7 then begin
     SegVram         :=WinBSegment;
     vesa_UseWinA     :=false;
     vesa_UseWinB     :=true;
     vesa_Banking     :=WinSize=64;
     end else
   if (WinAAttributes and WinBAttributes and 1)=1 then begin
     if WinASegment<>WinBSegment then goto freee;
     SegVram         :=WinASegment;
     vesa_UseWinA     :=true;
     vesa_UseWinB     :=true;
     vesa_Banking     :=WinSize=64;
     end else
   if (WinAAttributes and 6)=6 then begin
     SegVram         :=WinASegment;
     vesa_UseWinA     :=true;
     vesa_UseWinB     :=false;
     vesa_Banking     :=false;
     end else
   if (WinBAttributes and 6)=6 then begin
     SegVram         :=WinBSegment;
     vesa_UseWinA     :=false;
     vesa_UseWinB     :=true;
     vesa_Banking     :=false;
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
   VramSizeKB        :=vesa_BanksTotal*64;

   end;

 {poznamena si ze je ve VESA modu; z toho plyne:
  -setvis se provadi volanim vesabiosu nezavisle na modelu
  -pokud mozno nepouzivat rutiny nedoporucovane pro vesamody}
 VesaMode            :=true;

 {$ifdef testvga}bioswriteln(' before detections');{$endif}

 {v textmodu nepodporuju banking}
 if MapModel=model_text then vesa_Banking:=false;
 {spolehlive overeni funkcnosti bankingu}
 if vesa_Banking then vesa_DetectVramSizeAndBanking;
 if not vesa_Banking then VramSizeKB:=WinSizeKB;
 if not vesa_Banking and (longint(Xres)*Yres*ByPP div 1024>WinSizeKB)
  then goto freee;{banking nefunguje a obrazovka je vetsi nez WinSize -> }
                  { -> zachova se jako kdyz mod nejde nastavit}

 {$ifdef testvga}bioswriteln(' after detections');{$endif}

 {detekuje a opravuje chybu vesa biosu (dvakrat vetsi lineoffset)}
 if MapModel=model_text then begin
   {kdyz vrati dvakrat vetsi offset, predpokladam ze to je chyba a srovnam to}
   if lineOffset=4*Xres then lineOffset:=2*Xres;
   {kdyz je ale jeste jinej, uz ohlasim chybu}
   {ve skutecnosti to chyba byt nemusi, ale na 90% je}
   {pripustme ale radsi spatnej obraz na spatnym VBE nez krivy obvineni,
    takze kricet uz nebudeme
   if lineOffset<>2*Xres then Halt(_erBadVBE);}
   end;

 {je to dobry}
 SetMode_VESA:=true;

 {skok sem kdyz uz je naalokovana pamet a doslo k chybe}
 freee:
 LeaveModeInfo(ModeInfo);
 {$ifdef testvga}bioswriteln(' done');{$endif}
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
Procedure SetXMode(newModel,newMode:word); assembler;
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
Function TScreen.SetMode_X(newModel,newMode:word):boolean;
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

 {v Xmodech neni vystup textu pres BIOS mozny, ale jsou VGA kompatibilni}
 BiosOutput        :=false;
 VgaCompat         :=true;

 {ted je jiste ze neni nastaven VESA mod}
 VesaMode          :=false;
 vesa_NowBank      :=0;
 vesa_Banking      :=false;

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
 ByPP              :=1;

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
Procedure TScreen.vga_SplitY(y:word);assembler;
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
Procedure TScreen.vga_SetvisHi(a:word);assembler;
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
Procedure TScreen.vga_PanLeft(x:byte);assembler;
 asm
     pusha
     push es
     les di,self
     mov dx,3dah;in al,dx;mov dx,3c0h;mov al,33h;out dx,al;
     call wait250ns
     mov al,byte ptr [es:di+MapModel]
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
Procedure TScreen.vga_PanUp(y:byte);assembler;
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
     db 66h;push word ptr self;call vesa_setvis
     jmp @DONE

   @NOVESA:
     mov al,byte ptr [es:di+MapModel]
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
     db 66h;push word ptr self;call WaitBeforeRetrace
     {pushed before}db 66h;push word ptr self;call vga_SetvisHi
     db 66h;push word ptr self;call WaitForRetrace
     {pushed before}db 66h;push word ptr self;call vga_PanUp
     {pushed before}db 66h;push word ptr self;call vga_PanLeft
     mov [es:di+synced],1
     jmp @DONE

   @UNCHAINED:
   @PACKED:
     mov ax,y;mov bx,[es:di+vramXres];shr bx,2;mul bx
     mov bx,x;shr bx,2;add ax,bx
     push ax{push for setvishi}
     db 66h;push word ptr self;call WaitForTrace
     db 66h;push word ptr self;call WaitBeforeRetrace
     {pushed before}db 66h;push word ptr self;call vga_SetvisHi
     db 66h;push word ptr self;call WaitForRetrace
     push x;db 66h;push word ptr self;call vga_PanLeft
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

{---------------------------------------------------------------------------
 Uznavam ze je to naprosta silenost. Sam nechapu co to dela.
 Ale je to nekde pouzity a funguje to!
 Zatim nikdo nenabid nic lepsiho.
 ---------------------------------------------------------------------------}
Procedure GetResizeBltClipping(srcSize:TPoint;destRect:TRect;destRng:TRect;var newSrcRect:TRect;var newDestRect:TRect);
begin
 GetResizeClipping(srcSize.x,destRect.a.x,destRect.b.x,destRng.a.x,destRng.b.x,
                   newSrcRect.a.x,newSrcRect.b.x,newDestRect.a.x,newDestRect.b.x);
 GetResizeClipping(srcSize.y,destRect.a.y,destRect.b.y,destRng.a.y,destRng.b.y,
                   newSrcRect.a.y,newSrcRect.b.y,newDestRect.a.y,newDestRect.b.y);
end;


{€€€€€€€€€€€€€€€€ HI/TRUE COLOR €€€€€€€€€€€€€€€€}

FUNCTION _Color(model:word;pal:PPal;r,g,b,a:byte):longint;
begin
 case model of
   model_packed,
   model_unchained:_Color:=pal^.Alloc(r shr 2,g shr 2,b shr 2);
   model_BGR15    :_Color:=b shr 3+(g and word($f8)) shl 2+(r and word($f8)) shl 7+(a shr 7 shl 15);
   model_RGB15    :_Color:=r shr 3+(g and word($f8)) shl 2+(b and word($f8)) shl 7+(a shr 7 shl 15);
   model_BGR16    :_Color:=b shr 3+(g and word($fc)) shl 3+(r and word($f8)) shl 8;
   model_RGB16    :_Color:=r shr 3+(g and word($fc)) shl 3+(b and word($f8)) shl 8;
   model_BGR24    :_Color:=MakeLong(r,MakeWord(g,b));
   model_RGB24    :_Color:=MakeLong(b,MakeWord(g,r));
   model_BGRA32   :_Color:=MakeLong(MakeWord(a,r),MakeWord(g,b));
   model_RGBA32   :_Color:=MakeLong(MakeWord(a,b),MakeWord(g,r));
   else {$ifdef beta}erBetaMsg('_color(unknown model)'){$else}_Color:=0{$endif};
   end;
end;

var rndseed:byte;
function rnd4:byte;assembler;
asm
  mov al,rndseed
  inc al
  mov rndseed,al
  and al,3
end;
function rnd8:byte;assembler;
asm
  mov al,rndseed
  inc al
  mov rndseed,al
  and al,7
end;

PROCEDURE _RGBA(model:word;pal:PPal;pixel:longint;var r,g,b,a:byte);
var   a1:byte absolute pixel;
      a2:word absolute pixel;
      a4:longint absolute pixel;
begin
 {$define rnd}
 {pomoci randomu rozptyli mozne ostre hranice treba v ShadeBorder}
 {jen je to nepatrne pomalejsi}
 case model of
   model_packed:begin r:=pal^.pal[a1].r shl 2{$ifdef rnd}+rnd4{$endif};
                      g:=pal^.pal[a1].g shl 2{$ifdef rnd}+rnd4{$endif};
                      b:=pal^.pal[a1].b shl 2{$ifdef rnd}+rnd4{$endif};
                      a:=pal^.pal[a1].a;end;
   model_BGR15 :begin b:=byte(a2 shl 3){$ifdef rnd}+rnd8{$endif};
                      g:=byte((a2 shr 2) and $f8){$ifdef rnd}+rnd8{$endif};
                      r:=byte((a2 shr 7) and $f8){$ifdef rnd}+rnd8{$endif};
                      if a2>=$8000 then a:=255 else a:=0;end;
   model_RGB15 :begin r:=byte(a2 shl 3){$ifdef rnd}+rnd8{$endif};
                      g:=byte((a2 shr 2) and $f8){$ifdef rnd}+rnd8{$endif};
                      b:=byte((a2 shr 7) and $f8){$ifdef rnd}+rnd8{$endif};
                      if a2>=$8000 then a:=255 else a:=0;end;
   model_BGR16 :begin b:=byte(a2 shl 3){$ifdef rnd}+rnd8{$endif};
                      g:=byte((a2 shr 3) and $fc){$ifdef rnd}+rnd4{$endif};
                      r:=byte((a2 shr 8) and $f8){$ifdef rnd}+rnd8{$endif};
                      a:=255;end;
   model_RGB16 :begin r:=byte(a2 shl 3){$ifdef rnd}+rnd8{$endif};
                      g:=byte((a2 shr 3) and $fc){$ifdef rnd}+rnd4{$endif};
                      b:=byte((a2 shr 8) and $f8){$ifdef rnd}+rnd8{$endif};
                      a:=255;end;
   model_BGR24 :begin b:=a1;g:=HiByte(LoWord(a4));r:=LoByte(HiWord(a4));a:=255;end;
   model_RGB24 :begin r:=a1;g:=HiByte(LoWord(a4));b:=LoByte(HiWord(a4));a:=255;end;
   model_BGRA32:begin b:=a1;g:=HiByte(LoWord(a4));r:=LoByte(HiWord(a4));a:=HiByte(HiWord(a4));end;
   model_RGBA32:begin r:=a1;g:=HiByte(LoWord(a4));b:=LoByte(HiWord(a4));a:=HiByte(HiWord(a4));end;
   else {$ifdef beta}erBetaMsg('rgb(unknown model)'){$endif};
   end;
 {$undef rnd}
end;

PROCEDURE RGB2HLS(r,g,b:real; var h,l,s:real);
var
 minim,maxim,r2,g2,b2:real;
begin {RGB2HLS}
 if r<g then
  if r<b then minim:=r
  else minim:=b
 else
  if g<b then minim:=g
  else minim:=b;
 if r>g then
  if r>b then maxim:=r
  else maxim:=b
 else
  if g>b then maxim:=g
  else maxim:=b;
 l:=(minim+maxim)/2;
 if l=1 then
  begin
   h:=0;
   s:=0;
   exit
  end;
 if minim=maxim then
  begin
   h:=0;
   s:=0;
   exit
  end
 else
  s:=(1-minim)/(1-l)-1;
 if l>0.5 then
  begin
   r2:=1+(r-1)/(2-2*l);
   g2:=1+(g-1)/(2-2*l);
   b2:=1+(b-1)/(2-2*l)
  end
 else
  begin
   r2:=r;
   g2:=g;
   b2:=b
  end;
 if maxim=r then
  if g2=b2
  then h:=g2/b2
  else h:=6-b2/g2;
 if maxim=g then
  if r2=b2
  then h:=2-r2/g2
  else h:=2+b2/g2;
 if maxim=b then
  if g2=r2
  then h:=4-g2/b2
  else h:=4+r2/b2;
 h:=h*60;
 if h<0
 then h:=h+360
end;  {RGB2HLS}

PROCEDURE HLS2RGB(h,l,s:real; var r,g,b:real);
{Hue,Lightness,Saturation (vlnova delka,svetlost,sytost)->red,green,blue}
var
 a,f:word;
 r1,g1,b1,r2,g2,b2:real;
begin {HLS2RGB}
 if s=0 then
  begin
   r:=l;
   g:=l;
   b:=l;
   exit
  end
 else
  begin
   h:=h/60;
   a:=round(h) div 60;
   f:=round(h) mod 60
  end;
 case a of
 0: begin  r1:=1;   g1:=f;   b1:=0   end;
 1: begin  r1:=1-f; g1:=1;   b1:=0   end;
 2: begin  r1:=0;   g1:=1;   b1:=f   end;
 3: begin  r1:=0;   g1:=1-f; b1:=1   end;
 4: begin  r1:=f;   g1:=0;   b1:=1   end;
 5: begin  r1:=1;   g1:=0;   b1:=1-f end;
 end;
 r2:=0.5+s*(r1-0.5);
 g2:=0.5+s*(g1-0.5);
 b2:=0.5+s*(b1-0.5);
 if l<0.5 then
  begin
   r:=r2*l/0.5;
   g:=g2*l/0.5;
   b:=b2*l/0.5;
   exit
  end;
 if l>0.5 then
  begin
   r:=r2*(2-2*l)+(2*l-1);
   g:=g2*(2-2*l)+(2*l-1);
   b:=b2*(2-2*l)+(2*l-1);
   exit
  end;
 r:=r2;
 g:=g2;
 b:=b2
end;  {HLS2RGB}

{---------------------------------------------------------------------------
 Rutiny na konverze bitmap a par globalnich promennych (musi byt v DS).
 ---------------------------------------------------------------------------}

var   rol1,rol2,rol3:byte;
      and1,and2,and3:longint;
      srcsize1,destsize1:byte;
      freepal:T256Longs absolute freeB;

PROCEDURE SpocitejRotace(srcmodel,destmodel:byte);
type  TFields=record
               Rpl            : shortint;  {Red Position Left}
               Rpr            : shortint;  {Red Position Right}
               Gpl            : shortint;  {Green}
               Gpr            : shortint;  {Green}
               Bpl            : shortint;  {Blue}
               Bpr            : shortint;  {Blue}
              end;
const Fields:array[model_BGR15..model_RGBA32] of TFields=(
        (Rpl:5+10; Rpr:10; Gpl:5+5; Gpr:5; Bpl:5+ 0; Bpr:0  ),
        (Rpl:5+ 0; Rpr: 0; Gpl:5+5; Gpr:5; Bpl:5+10; Bpr:10 ),
        (Rpl:5+11; Rpr:11; Gpl:6+5; Gpr:5; Bpl:5+ 0; Bpr:0  ),
        (Rpl:5+ 0; Rpr: 0; Gpl:6+5; Gpr:5; Bpl:5+11; Bpr:11 ),
        (Rpl:8+16; Rpr:16; Gpl:8+8; Gpr:8; Bpl:8+ 0; Bpr:0  ),
        (Rpl:8+ 0; Rpr: 0; Gpl:8+8; Gpr:8; Bpl:8+16; Bpr:16 ),
        (Rpl:8+16; Rpr:16; Gpl:8+8; Gpr:8; Bpl:8+ 0; Bpr:0  ),
        (Rpl:8+ 0; Rpr: 0; Gpl:8+8; Gpr:8; Bpl:8+16; Bpr:16 ));
begin
 rol1:=byte(Fields[destmodel].rpl-Fields[srcmodel].rpl) and 31;
 rol2:=byte(Fields[destmodel].gpl-Fields[srcmodel].gpl) and 31;
 rol3:=byte(Fields[destmodel].bpl-Fields[srcmodel].bpl) and 31;
 and1:=longint(1) shl Fields[destmodel].rpl-longint(1) shl Fields[destmodel].rpr;
 and2:=longint(1) shl Fields[destmodel].gpl-longint(1) shl Fields[destmodel].gpr;
 and3:=longint(1) shl Fields[destmodel].bpl-longint(1) shl Fields[destmodel].bpr;
 srcsize1:=ByPPlist[srcmodel];
 destsize1:=ByPPlist[destmodel];
end;

PROCEDURE ConvertInit(srcpal,destpal:PPal;srcmodel,destmodel:byte;transp:boolean);
var c:byte;
    sum:longint;
    old0a:byte;
begin
 {pro konverzi packed->* si pripravi pole 256 pixelu}
 if srcmodel=model_packed then begin
   {osetri transparenci}
   if transp then
    if destpal<>nil then begin
      {packed->packed}
      {poznamena si puvodni stav pal[0].a a docasne ho zmeni na dead,}
      {aby se nic krome transp. barvy nekonvertilo na 0}
      old0a:=destpal^.pal[0].a;
      destpal^.Setup(0,0,pifDead);
      end;
   {hleda nejblizsi barvy}
   fillchar(freepal,sizeof(freepal),0);
   for c:=0 to 255 do
    with srcpal^.pal[c] do
     if (c=0) and transp then freepal[c]:=0 else
      if a=pifUsed then begin
       freepal[c]:=_Color(destmodel,destpal,r shl 2,g shl 2,b shl 2,255);
       if transp and (freepal[c]=0) then
        {po osetreni packed->packed muze toto nastat jen v packed->direct:
        cernou (s vyznamem pruhledna) zmeni na skoro cernou}
        freepal[c]:=1;
       end;
   {sum:=0;
   for c:=0 to 255 do begin
     inc(sum,2*abs(integer(srcpal^.pal[c].r)-integer(destpal^.pal[freepal[c]].r)));
     inc(sum,3*abs(integer(srcpal^.pal[c].g)-integer(destpal^.pal[freepal[c]].g)));
     inc(sum,1*abs(integer(srcpal^.pal[c].b)-integer(destpal^.pal[freepal[c]].b)));
     end;}
   {vrati puvodni stav}
   if transp then
    if destpal<>nil then
      {packed->packed}
      destpal^.Setup(0,0,old0a);
   end
 else
 {pro konverzi direct->direct si pripravi o kolik rotovat slozky}
 if destmodel in models_direct then SpocitejRotace(srcmodel,destmodel)
 else
 {pro konverzi direct->packed uz je vse pripraveno}
end;

PROCEDURE ConvertLine(srcline,destline:pointer;pixelu,kod:word;colors:P256Longs);assembler;
 asm
     PUSH DS
     mov cx,pixelu
     {fs:edx=colors}push colors.word[2];db 0fh,0a1h{pop fs};db 66h;xor dx,dx;mov dx,colors.word[0]
     {gs=freeseg}push freeseg;db 0fh,0a9h{pop gs}
     {eax=0}db 66h;xor ax,ax
     les di,destline
     lds si,srcline
     mov bx,kod
     jmp word [cs:bx+@offsety]

   @OFFSETY:
     dw @PACKED_PACKED,@PACKED_BGR15,@PACKED_RGB15,@PACKED_BGR16
     dw @PACKED_RGB16,@PACKED_BGR24,@PACKED_RGB24,@PACKED_BGRA32,@PACKED_RGBA32
     dw @BGR15__PACKED,@BGR15__BGR15,@BGR15__RGB15,@BGR15__BGR16
     dw @BGR15__RGB16,@BGR15__BGR24,@BGR15__RGB24,@BGR15__BGRA32,@BGR15__RGBA32
     dw @RGB15__PACKED,@RGB15__BGR15,@RGB15__RGB15,@RGB15__BGR16
     dw @RGB15__RGB16,@RGB15__BGR24,@RGB15__RGB24,@RGB15__BGRA32,@RGB15__RGBA32
     dw @BGR16__PACKED,@BGR16__BGR15,@BGR16__RGB15,@BGR16__BGR16
     dw @BGR16__RGB16,@BGR16__BGR24,@BGR16__RGB24,@BGR16__BGRA32,@BGR16__RGBA32
     dw @RGB16__PACKED,@RGB16__BGR15,@RGB16__RGB15,@RGB16__BGR16
     dw @RGB16__RGB16,@RGB16__BGR24,@RGB16__RGB24,@RGB16__BGRA32,@RGB16__RGBA32
     dw @BGR24__PACKED,@BGR24__BGR15,@BGR24__RGB15,@BGR24__BGR16
     dw @BGR24__RGB16,@BGR24__BGR24,@BGR24__RGB24,@BGR24__BGRA32,@BGR24__RGBA32
     dw @RGB24__PACKED,@RGB24__BGR15,@RGB24__RGB15,@RGB24__BGR16
     dw @RGB24__RGB16,@RGB24__BGR24,@RGB24__RGB24,@RGB24__BGRA32,@RGB24__RGBA32
     dw @BGRA32_PACKED,@BGRA32_BGR15,@BGRA32_RGB15,@BGRA32_BGR16
     dw @BGRA32_RGB16,@BGRA32_BGR24,@BGRA32_RGB24,@BGRA32_BGRA32,@BGRA32_RGBA32
     dw @RGBA32_PACKED,@RGBA32_BGR15,@RGBA32_RGB15,@RGBA32_BGR16
     dw @RGBA32_RGB16,@RGBA32_BGR24,@RGBA32_RGB24,@RGBA32_BGRA32,@RGBA32_RGBA32

   {z PACKED kamkoliv}
   @PACKED_PACKED:
     lodsb
     db 64h,67h,8ah,04h,82h{mov al,[fs:edx+4*eax]}
     stosb
     loop @PACKED_PACKED
     jmp @end

   @PACKED_BGR15:
   @PACKED_RGB15:
   @PACKED_BGR16:
   @PACKED_RGB16:
     db 66h;xor ax,ax
     lodsb
     db 64h,67h,8bh,04h,82h{mov ax,[fs:edx+4*eax]}
     stosw
     loop @packed_bgr15
     jmp @end

   @PACKED_BGR24:
   @PACKED_RGB24:
     db 66h;xor ax,ax
     lodsb
     db 64h,66h,67h,8bh,04h,82h{mov eax,[fs:edx+4*eax]}
     stosw
     db 66h;shr ax,16
     stosb
     loop @packed_bgr24
     jmp @end

   @PACKED_BGRA32:
   @PACKED_RGBA32:
     db 66h;xor ax,ax
     lodsb
     db 64h,66h,67h,8bh,04h,82h{mov eax,[fs:edx+4*eax]}
     db 66h;stosw
     loop @packed_bgra32
     jmp @end

   {z BGR24 kamkoliv}
   @BGR24__BGRA32:
     mov al,255
    @1:
     movsw
     movsb
     {$ifdef a_ff}
     stosb
     {$else}
     inc di
     {$endif}
     loop @1{BGR24__BGRA32}
     jmp @end

   @BGR24__BGR16:
     lodsw
     shr ah,2
     db 66h;ror ax,6+8
     lodsb
     shr al,3
     db 66h;rol ax,6+5
     stosw
     loop @BGR24__BGR16
     jmp @end

   @BGR24__BGR15:
     lodsw
     shr ah,3
     db 66h;ror ax,5+8
     lodsb
     shr al,3
     db 66h;rol ax,5+5
     stosw
     loop @BGR24__BGR15
     jmp @end

   {z BGRA32 kamkoliv}
   @BGRA32_RGBA32:
     lodsw
     xchg al,ah
     movsb
     stosw
     movsb
     loop @BGRA32_RGBA32
     jmp @end

   @BGRA32_BGR24:
     movsw
     movsb
     inc si
     loop @BGRA32_BGR24
     jmp @end

   @BGRA32_BGR16:
     lodsw
     shr ah,2
     db 66h;ror ax,6+8
     lodsw
     shr al,3
     db 66h;rol ax,6+5
     stosw
     loop @BGRA32_BGR16
     jmp @end

   @BGRA32_BGR15:
     lodsw
     shr ah,3
     db 66h;ror ax,5+8
     lodsw
     shr al,3
     db 66h;rol ax,5+5
     stosw
     loop @BGRA32_BGR15
     jmp @end

   {do stejneho modelu}
   @BGR15__BGR15:
   @RGB15__RGB15:
   @BGR16__BGR16:
   @RGB16__RGB16:
     add cx,cx
     call REP_MOVSB_si
     jmp @end

   @BGR24__BGR24:
   @RGB24__RGB24:
     mov ax,cx
     add cx,ax
     add cx,ax
     call REP_MOVSB_si
     jmp @end

   @BGRA32_BGRA32:
   @RGBA32_RGBA32:
     db 66h;rep movsw
     jmp @end

   {z direct do palety}
   @RGB15__PACKED:
   @RGB16__PACKED:
   @RGB24__PACKED:
   @RGBA32_PACKED:
   @UNI____PACKED:
     push cx
     {load}
     db 64h;cmp srcsize1,2;je @size2
     db 64h;cmp srcsize1,4;je @size4
     @size3:mov ah,[si+2];db 66h;shl ax,8;lodsw;inc si;jmp @size3b
     @size4:db 66h
     @size2:lodsw
     @size3b:
     {convert 2 model_histo}
     db 66h;mov bx,ax
     db 66h;mov dx,ax
     db 64h;mov cl,rol1;db 66h;rol ax,cl;db 64h,66h;and ax,word ptr and1
     db 64h;mov cl,rol2;db 66h;rol bx,cl;db 64h,66h;and bx,word ptr and2;db 66h;or ax,bx
     db 64h;mov cl,rol3;db 66h;rol dx,cl;db 64h,66h;and dx,word ptr and3;db 66h;or ax,dx
     {convert via bigxlattab}
     db 65h,67h,8ah,4h,45h,0,0,0,0{mov al,[gs:2*eax]}
     {store}
     stosb
     {loop}
     pop cx
     loop @UNI____PACKED
     jmp @end

   @BGR15__PACKED:
     lodsw
     db 65h,67h,8ah,4h,45h,0,0,0,0{mov al,[gs:2*eax]}
     stosb
     loop @BGR15__PACKED
     jmp @end

   @BGR16__PACKED:
     mov bx,[si]
     mov al,bl
     and al,00011111b
     and bl,11000000b
     add bl,al
     add bl,al
     db 65h;mov al,[bx]
     stosb
     add si,2
     loop @BGR16__PACKED
     jmp @end

   @BGR24__PACKED:
     mov bx,[si]
     mov al,[si+2]
     shr bh,3
     shr bx,2
     and al,11111000b
     and bl,11111110b
     or bh,al
     db 65h;mov al,[bx]
     stosb
     add si,3
     loop @BGR24__PACKED
     jmp @end

   @BGRA32_PACKED:
     mov bx,[si]
     mov al,[si+2]
     shr bh,3
     shr bx,2
     and al,11111000b
     and bl,11111110b
     or bh,al
     db 65h;mov al,[bx]
     stosb
     add si,4
     loop @BGRA32_PACKED
     jmp @end

   {z BGR15 kamkoliv}
   @BGR15__BGR16:
   @BGR15__BGR24:
   @BGR15__BGRA32:

   {z BGR16 kamkoliv}
   @BGR16__BGR15:
   @BGR16__BGR24:
   @BGR16__BGRA32:

   {vse co souvisi s nestandardnim razenim RGB}
   @BGR15__RGB15:
   @BGR15__RGB16:
   @BGR15__RGB24:
   @BGR15__RGBA32:

   @RGB15__BGR15:
   @RGB15__BGR16:
   @RGB15__RGB16:
   @RGB15__BGR24:
   @RGB15__RGB24:
   @RGB15__BGRA32:
   @RGB15__RGBA32:

   @BGR16__RGB15:
   @BGR16__RGB16:
   @BGR16__RGB24:
   @BGR16__RGBA32:

   @RGB16__BGR15:
   @RGB16__RGB15:
   @RGB16__BGR16:
   @RGB16__BGR24:
   @RGB16__RGB24:
   @RGB16__BGRA32:
   @RGB16__RGBA32:

   @BGR24__RGB15:
   @BGR24__RGB16:
   @BGR24__RGB24:
   @BGR24__RGBA32:

   @RGB24__BGR15:
   @RGB24__RGB15:
   @RGB24__BGR16:
   @RGB24__RGB16:
   @RGB24__BGR24:
   @RGB24__BGRA32:
   @RGB24__RGBA32:

   @BGRA32_RGB15:
   @BGRA32_RGB16:
   @BGRA32_RGB24:
   @BGRA32_RGBA24:

   @RGBA32_BGR15:
   @RGBA32_RGB15:
   @RGBA32_BGR16:
   @RGBA32_RGB16:
   @RGBA32_RGB24:
   @RGBA32_BGR24:
   @RGBA32_BGRA32:

   {univerzalni konverze}
   @UNI:
     push cx
     {load}
     db 64h;cmp srcsize1,2;je @xsize2
     db 64h;cmp srcsize1,4;je @xsize4
     @xsize3:mov ah,[si+2];db 66h;shl ax,8;lodsw;inc si;jmp @xsize3b
     @xsize4:db 66h
     @xsize2:lodsw
     @xsize3b:
     {convert}
     db 66h;mov bx,ax
     db 66h;mov dx,ax
     db 64h;mov cl,rol1;db 66h;rol ax,cl;db 64h,66h;and ax,word ptr and1
     db 64h;mov cl,rol2;db 66h;rol bx,cl;db 64h,66h;and bx,word ptr and2;db 66h;or ax,bx
     db 64h;mov cl,rol3;db 66h;rol dx,cl;db 64h,66h;and dx,word ptr and3;db 66h;or ax,dx
     {store}
     db 64h;cmp destsize1,2;je @xsiz2
     db 64h;cmp destsize1,4;je @xsiz4
     @xsiz3:stosw;db 66h;shr ax,16;stosb;jmp @xsiz3b
      {$ifdef a_ff}
     @xsiz4:stosw;db 66h;shr ax,16;mov ah,255
      {$else}
     @xsiz4:db 66h
      {$endif}
     @xsiz2:stosw
     @xsiz3b:
     {loop}
     pop cx
     loop @UNI
     jmp @end

   {konec}
   @END:
     POP DS
 end;

const models=9;
      tablo=chr(model_packed)+chr(model_BGR15)+chr(model_RGB15)+chr(model_BGR16)+
            chr(model_RGB16)+chr(model_BGR24)+chr(model_RGB24)+chr(model_BGRA32)+chr(model_RGBA32);

PROCEDURE ConvertMap(srcmap,destmap:PBitmap;destmodel:byte;destpal:PPal);
var   y:word;
      kod:word;
      srcmodel:byte;
begin
 destmap^.transparent:=srcmap^.transparent;
 srcmodel:=srcmap^.MapModel;
 kod:=2*(models*(pos(chr(srcmodel),tablo)-1)+pos(chr(destmodel),tablo)-1);
 ConvertInit(srcmap^.pal,destpal,srcmodel,destmodel,srcmap^.transparent);
 for y:=0 to srcmap^.sizeY-1 do
  ConvertLine(srcmap^.tab^[y],destmap^.tab^[y],srcmap^.sizeX,kod,@freepal);
 destmap^.MapModel:=destmodel;
 destmap^.ByPP:=ByPPlist[destmodel];
end;

PROCEDURE ConvertPacked2Any(srcmap,destmap:PBitmap;colors:P256Longs);
var   y:word;
      kod:word;
begin
 destmap^.transparent:=srcmap^.transparent;
 kod:=2*(models*(pos(chr(srcmap^.MapModel),tablo)-1)+pos(chr(destmap^.MapModel),tablo)-1);
 for y:=0 to srcmap^.sizeY-1 do
  ConvertLine(srcmap^.tab^[y],destmap^.tab^[y],srcmap^.sizeX,kod,colors);
end;

{----------------------------------------------------------------------------
 Rutiny na tvorbu histogramu.
 Histogram je uvnitr freesegu jako pole 32768 wordu.
 Je-li b barva v model_bgr15, pak memw[freeseg:2*b] udava cetnost barvy.
 ----------------------------------------------------------------------------}

var smallhist:array[0..255] of longint absolute freeB;

Procedure Add2SmallHist(map:PBitmap);assembler;
 asm
      les di,map
      mov dx,[es:di+TBitmap.sizeY]
      mov bx,[es:di+TBitmap.sizeX]
      les di,[es:di+TBitmap.tab]
      db 66h;xor ax,ax
     @nextline:
      db 26h,0fh,0b4h,35h{lfs si,[es:di]}
      add di,4
      mov cx,bx
     @nextpixel:
      db 64h;lodsb
      db 66h,67h,0ffh,4,85h;dd offset smallhist{inc dword ptr [4*eax+offset smallhist]}
      loop @nextpixel
      dec dx
      jnz @nextline
 end;


Procedure AddLine2BigHist(src:pointer;pixels,model:word);assembler;
 asm
     PUSH DS
     mov cx,pixels
     {fs=ds}push ds;db 0fh,0a1h{pop fs}
     {gs=freeseg}push freeseg;db 0fh,0a9h{pop gs}
     {eax=0}db 66h;xor ax,ax
     lds si,src
     mov al,byte ptr model
     cmp al,model_BGR15;je @BGR15
     cmp al,model_BGR16;je @BGR16
     cmp al,model_BGR24;je @BGR24
     cmp al,model_BGRA32;je @BGRA32

    @UNI:
     push cx
     {load}
     db 64h;cmp srcsize1,2;je @size2
     db 64h;cmp srcsize1,4;je @size4
     @size3:mov ah,[si+2];db 66h;shl ax,8;lodsw;inc si;jmp @size3b
     @size4:db 66h
     @size2:lodsw
     @size3b:
     {convert}
     db 66h;mov bx,ax
     db 66h;mov dx,ax
     db 64h;mov cl,rol1;db 66h;rol ax,cl;db 64h,66h;and ax,word ptr and1
     db 64h;mov cl,rol2;db 66h;rol bx,cl;db 64h,66h;and bx,word ptr and2;db 66h;or ax,bx
     db 64h;mov cl,rol3;db 66h;rol dx,cl;db 64h,66h;and dx,word ptr and3;db 66h;or ax,dx
     {inc histo}
     db 65h,67h,0ffh,04h,45h;dd 0{inc word ptr [gs:2*eax]}
     jno @nepreteklo
     db 65h,67h,0ffh,0ch,45h;dd 0{dec word ptr [gs:2*eax]}
     @nepreteklo:
     {loop}
     pop cx
     loop @UNI
     jmp @end

    @BGR15:
     mov bx,[si]
     add bx,bx
     db 65h;inc word ptr [bx]
     jno @nepreteklo15
     db 65h;dec word ptr [bx]
     @nepreteklo15:
     add si,2
     loop @BGR15
     jmp @end

    @BGR16:
     mov bx,[si]
     mov al,bl
     and al,00011111b
     and bl,11000000b
     add bl,al
     add bl,al
     db 65h;inc word ptr [bx]
     jno @nepreteklo16
     db 65h;dec word ptr [bx]
     @nepreteklo16:
     add si,2
     loop @BGR16
     jmp @end

    @BGR24:
     mov bx,[si]
     mov al,[si+2]
     shr bh,3
     shr bx,2
     and al,11111000b
     and bl,11111110b
     or bh,al
     db 65h;inc word ptr [bx]
     jno @nepreteklo24
     db 65h;dec word ptr [bx]
     @nepreteklo24:
     add si,3
     loop @BGR24
     jmp @end

    @BGRA32:
     mov bx,[si]
     mov al,[si+2]
     shr bh,3
     shr bx,2
     and al,11111000b
     and bl,11111110b
     or bh,al
     db 65h;inc word ptr [bx]
     jno @nepreteklo32
     db 65h;dec word ptr [bx]
     @nepreteklo32:
     add si,4
     loop @BGRA32
     jmp @end

    @END:
     POP DS
end;

Procedure Add2BigHist(map:PBitmap);
var y:word;
begin
 SpocitejRotace(map^.MapModel,model_BGR15);
 with map^ do
  for y:=0 to sizeY-1 do AddLine2BigHist(tab^[y],sizeX,MapModel);
end;

{----------------------------------------------------------------------------
 Lokalni promenne procedury Kvantizuj presunute do DS,
 pri jejich zpetnem prevodu do SS je treba opravit nekolik asm procedur
 ----------------------------------------------------------------------------}
type  Tkvadr=record
               {nutno zachovat presne toto poradi promennych
                nebo opravit proc SpocitejVhodnost}
               r2,r1,g2,g1,b2,b1:byte;
               hmotnost:word;
               vhodnost_k_deleni:longint;
             end;

var   kvadr    :array[1..255] of Tkvadr;{pro kazdou barvu jeden kvadr v rgb prostoru}
      r,g,b    :array[1..255] of byte;{nove generovana paleta, hodnoty 0..63}
      platek   :array[0..31] of word;{hmotnosti 'platku' kvadru}
      kvadru   :word;{pocet vytvorenych kvadru=barev pri kvantizaci}
                  {~ musi byt ve stejnem segmentu jako r,g,b}

  {-------------------------------------------------------------------------
   Obarvi kvadr v RGB prostoru (v segmentu workseg) danou barvou (wordem).
   -------------------------------------------------------------------------}
  procedure ObarviKvadr(r1,r2,g1,g2,b1,b2,barva:word);assembler;asm

     {pro zadavani hodnot je lepsi system R1,R2
      ale pro interni potrebu je lepsi R1,deltaR
      takze provede konverzi ve stylu R2:=deltaR}
     mov ax,1;sub ax,r1;add r2,ax
     mov ax,1;sub ax,g1;add g2,ax
     mov ax,1;sub ax,b1;add b2,ax

     {spocita do BX a SI o kolik zvetsit adresu na konci Green a Blue cyklu}
     mov bx,32;sub bx,b2;shl bx,1
     mov si,32;sub si,g2;shl si,6

     {nastavi vychozi hodnoty}
     mov ax,barva{ax=barva, resp al=barva}
     mov es,freeseg{es=segment s 64KB paletou}
     mov di,r1;shl di,5;add di,g1;shl di,5;add di,b1;add di,di{di=r1<11+bx<6+b1<1}

     {obarvi kvadr v osach red,green,blue}
     mov cx,r2
     @red:
     push cx

      {obarvi obdelnik v osach green,blue}
      mov dx,g2
      @green:

       {obarvi usecku v ose blue}
       mov cx,b2
       rep stosw

      add di,bx
      dec dx
      jnz @green

     add di,si
     pop cx
     loop @red

     end;

{--------------------------------------------------------------------
 Podle velkeho histogramu vytvori novou paletu,
 a bude-li to zapotrabi tak i velkou xlattabuku.
 Vystup: vraci vysledny pocet barev 1..255 (muze vyjit mene nez bylo
         pozadovano na vstupu) nebo 0 v pripade chyby.
 --------------------------------------------------------------------}
FUNCTION Kvantizuj(chci_barev:byte):byte;


const mulR=2;{vliv jednotlivych slozek barvy na vizualni odlisnost dvou barev}
      mulG=3;{nutno zachovat tyto hodnoty nebo opravit proc SpocitejVhodnost}
      mulB=1;{a Nejblizsi_barva_k}

  {-------------------------------------------------------------------------
   Spocita celkovou hmotnost zadaneho kvadru v RGB prostoru, tj pocet pixelu
   lezicich v onom kvadru. Pouziva promennou workseg ve ktere je segment
   64KB histogramu. Do kvadru se pocitaji i okraje (kdyz r1=r2, tak tloustka=1).
   -------------------------------------------------------------------------}
  function HmotnostKvadru(r1,r2,g1,g2,b1,b2:word):longint;assembler;asm

     {pro zadavani hodnot je lepsi system R1,R2
      ale pro interni potrebu je lepsi R1,deltaR
      takze provede konverzi ve stylu R2:=deltaR}
     mov ax,1;sub ax,r1;add r2,ax
     mov ax,1;sub ax,g1;add g2,ax
     mov ax,1;sub ax,b1;add b2,ax

     {spocita do BX a DI o kolik zvetsit adresu na konci Green a Blue cyklu}
     mov bx,32;sub bx,b2;shl bx,1
     mov di,32;sub di,g2;shl di,6

     {nastavi vychozi hodnoty}
     xor ax,ax;xor dx,dx{hmotnost=0}
     mov es,freeseg{es=segment s 64KB histogramem}
     mov si,r1;shl si,5;add si,g1;shl si,5;add si,b1;add si,si{si=r1<11+bx<6+b1<1}

     {pricte kvadr v osach red,green,blue}
     mov cx,r2
     @red:
     push cx

      {pricte obdelnik v osach green,blue}
      mov cx,g2
      @green:
      push cx

       {pricte usecku v ose blue}
       mov cx,b2
       @blue:
       add ax,[es:si];adc dx,0{pricte hmotnost jednoho bodu}
       add si,2
       loop @blue

      pop cx
      add si,bx
      loop @green

     pop cx
     add si,di
     loop @red
     end;


  {--------------------------------------------------------------------
   Najde median pole Platek mezi indexy x1 a x2.
   Pro presnost: najde M takove, ze Suma(x1..M)~Suma(M+1..x2), vraci M.
   --------------------------------------------------------------------}
  function Median(x1,x2:word):byte;assembler;
   asm
    {spocita celkovou hmotnost}
    mov si,x1;add si,si;add si,offset platek
    {~ push ds}
    {~ mov ds,seg(platek)}
    {~ add si,[bp+4] k offsetu pricte bazi lokalnich vars v nadrazene proc.}
    mov cx,x2;sub cx,x1;inc cx
    xor ax,ax
    xor bx,bx
    xor dx,dx
    @1:lodsw
       add bx,ax;adc dx,0{do bx:dx scita celkovou hmotnost}
       loop @1
    {stepuje zpatky dokud nenajde pulku hmotnosti}
    mov cx,x2;inc cx
    @2:sub si,2
       mov ax,[si]
       sub bx,ax{od celkove hmotnosti v bx:dx odecita dvojnasobek}
       jnc @nepretek1
       dec dx
       js @stred{dokud se nedostane pod nulu}
       @nepretek1:
       sub bx,ax
       jnc @nepretek2
       dec dx
       js @stred
       @nepretek2:
       loop @2
    @stred:
    {~ pop ds}
    dec cx
    mov ax,cx
    end;


  {-----------------------------------------------------
   Zvazi jednotlive platky zadaneho kvadru,
   hmotnosti zapise do pole platek.
   Parametr c udava ve kterem smeru se ma kvadr rezat.
   -----------------------------------------------------}
  procedure ZvazPlatky(kv:word;c:char);
  var   i:byte;
  begin
   with kvadr[kv] do
    case c of 'r':for i:=r1 to r2 do platek[i]:=Long2Word(HmotnostKvadru(i,i,g1,g2,b1,b2));
              'g':for i:=g1 to g2 do platek[i]:=Long2Word(HmotnostKvadru(r1,r2,i,i,b1,b2));
              'b':for i:=b1 to b2 do platek[i]:=Long2Word(HmotnostKvadru(r1,r2,g1,g2,i,i));
              end;
  end;


  {-----------------------------------------------------
   Zvazi zadany kvadr a hmotnost ulozi do prislusne
   promenne v poli kvadr.
   -----------------------------------------------------}
  procedure SpocitejHmotnost(kv:word);
  begin
   with kvadr[kv] do hmotnost:=Long2Word(HmotnostKvadru(r1,r2,g1,g2,b1,b2));
  end;


  {-----------------------------------------------------
   Oseka prazdne kraje zadaneho kvadru.
   Vraci boolean zda je vsechno v poradku.
   -----------------------------------------------------}
  function OsekejKvadr(kv:word):boolean;
  begin
   with kvadr[kv] do begin
     if hmotnost=0 then begin
       {internal error: prazdny kvadr}
       OsekejKvadr:=false;
       exit;
       end;
     while HmotnostKvadru(r1,r1,g1,g2,b1,b2)=0 do inc(r1);
     while HmotnostKvadru(r2,r2,g1,g2,b1,b2)=0 do dec(r2);
     while HmotnostKvadru(r1,r2,g1,g1,b1,b2)=0 do inc(g1);
     while HmotnostKvadru(r1,r2,g2,g2,b1,b2)=0 do dec(g2);
     while HmotnostKvadru(r1,r2,g1,g2,b1,b1)=0 do inc(b1);
     while HmotnostKvadru(r1,r2,g1,g2,b2,b2)=0 do dec(b2);
     end;
   OsekejKvadr:=true;
  end;


  {-----------------------------------------------------
   Spocita vhodnost kvadru kv k deleni.
   Kriterium: musi byt rozlehly, ale zaroven dost tezky.
   Je-li kvadr velky 1x1x1, musi nastavit vhodnost 0.
   -----------------------------------------------------}
  procedure SpocitejVhodnost(kv:word);
  var   i:word;
  begin
   i:=ofs(kvadr[kv]);
   asm mov si,i
       {~ push ds}
       {~ mov ds,seg(kvadr)}
       lodsw;sub al,ah;mul al;mov bx,ax;add bx,ax{mulR=2}
       lodsw;sub al,ah;mul al;add bx,ax;add bx,ax;add bx,ax{mulG=3}
       lodsw;sub al,ah;mul al;add bx,ax{mulB=1}
       lodsw;mul bx
       mov [si],ax
       mov [si+2],dx
       {~ pop ds}
       end;
  end;
  {
  procedure SpocitejVhodnost(kv:word);
  begin
   vhodnost_k_deleni:=longint(hmotnost)*(mulR*sqr(r2-r1)+mulG*sqr(g2-g1)+mulB*sqr(b2-b1));
  end;
  }


{-----------------------------------------------------
                 K V A N T I Z A C E
 -----------------------------------------------------}
var   rez:byte;
      src,colorWord,i:word;
      smer:char;
      m1,m2    :byte;{dolni a horni mez kvadru v nekterem smeru}
Begin
 Kvantizuj:=0;{kvantizace zatim neprobehla,
               dojde-li k chybe, staci EXITnout}

 {test korektniho vstupu}
 if (chci_barev<1) or (chci_barev>255) then exit;


 {€€ vytvori prvni kvadr do ktereho spadaji vsechny pixely €€}

 kvadru:=1;
 with kvadr[kvadru] do begin
   r1:=0;r2:=31;
   g1:=0;g2:=31;
   b1:=0;b2:=31;
   SpocitejHmotnost(kvadru);
   if not OsekejKvadr(kvadru) then exit;
   SpocitejVhodnost(kvadru);
   end;


 {€€ vytvori vsechny ostatni kvadry delenim jiz existujicich €€}

 for kvadru:=2 to chci_barev do begin

   {najde jiz existujici kvadr vhodny k deleni, jeho cislo je SRC}
   src:=1;
   for i:=2 to kvadru-1 do if kvadr[i].vhodnost_k_deleni>kvadr[src].vhodnost_k_deleni then src:=i;

   {testne jestli je jeste vubec co delit}
   if kvadr[src].vhodnost_k_deleni=0 then begin
     dec(kvadru);
     break;{Ukonci cyklus vytvarejici nove kvadry, vsechno ostatni za cyklem
            uz probiha jako pri redukci na mensi pocet barev.}
     end;

   {--- Rozdeli SRC na dva kusy ktere da do SRC a KVADRU. ---}

   {nejdriv nastavi SRC i KVADRU na puvodni velikost}
   kvadr[kvadru]:=kvadr[src];

   {zmeri ve kterem smeru je kvadr nejdelsi (r nebo g nebo b)
    a konkretni meze teto barvy prevede do obecnych promennych m1,m2}
   with kvadr[src] do
     if (mulR*(r2-r1)>=mulG*(g2-g1)) and
        (mulR*(r2-r1)>=mulB*(b2-b1)) then begin smer:='r';m1:=r1;m2:=r2;end else
     if (mulG*(g2-g1)>=mulB*(b2-b1)) then begin smer:='g';m1:=g1;m2:=g2;end else
                                          begin smer:='b';m1:=b1;m2:=b2;end;

   {zmeri si hmotnosti 'platku' kvadru}
   ZvazPlatky(src,smer);

   {Najde misto mezi r1 a r2 vhodne k rozriznuti kvadru.
    Druha pulka zacne v platku REZ+1, prvni skonci v REZ.}
   rez:=median(m1,m2);
   if rez=m2 then dec(rez);


   {Nastaveni velikosti dvou nove vzniklych kvadru (SRC a KVADRU).}

   {Odsekne prazdne platky z nove vzniklych kvadru.
    M1 a m2 ted uz nejdou meze velkeho kvadru ale dolni mez horniho
    a horni mez dolniho maleho kvadru.}
   m2:=rez  ;while platek[m2]=0 do dec(m2);
   m1:=rez+1;while platek[m1]=0 do inc(m1);

   {zkonvertuje udaje z obecnych m1,m2 do konkretnich barev r,g,b}
   case smer of 'r':begin kvadr[kvadru].r1:=m1;kvadr[src].r2:=m2;end;
                'g':begin kvadr[kvadru].g1:=m1;kvadr[src].g2:=m2;end;
                'b':begin kvadr[kvadru].b1:=m1;kvadr[src].b2:=m2;end;
                end;


   {Nastaveni ostatnich zmenenych udaju v SRC a KVADRU
    tj. hmotnost, vhodnost, pripadne zmensi rozmery.}
   SpocitejHmotnost(src);
   SpocitejHmotnost(kvadru);
   if not OsekejKvadr(src)    then exit;
   if not OsekejKvadr(kvadru) then exit;
   SpocitejVhodnost(src);
   SpocitejVhodnost(kvadru);

   end;


 {€€ Pro kazdy kvadr spocita stredni barvu, vysledek ulozi do poli R,G,B €€}

 for i:=1 to kvadru do with kvadr[i] do begin
     ZvazPlatky(i,'r');r[i]:=2*Median(r1,r2)+1;
     ZvazPlatky(i,'g');g[i]:=2*Median(g1,g2)+1;
     ZvazPlatky(i,'b');b[i]:=2*Median(b1,b2)+1;
     end;

 {hleda teziste ze vsech bodu v kvadru, ale nektere body mohou pozdeji
  pripadnout jinemu kvadru, takze zde namerena barva muze byt i velmi
  nepresna}


 Kvantizuj:=kvadru;{kvantizace uspesne skoncila}
End;


PROCEDURE MakeBigXlat(pal:PPal);
var   i:word;
      pixel:word;
begin

 {€€ Vygeneruje velkou xlat pro rychly prevod True/Hi pixelu do 256 barev €€}

 {maximalni rychlost: vsem bodum v kvadru priradi stejnou barvu
   for i:=1 to kvadru do with kvadr[i] do ObarviKvadr(r1,r2,g1,g2,b1,b2,i);

 {maximalni kvalita: pro kazdy bod v rgb prostoru hleda nejblizsi barvu
   z nove palety (nebot nekdy ma barva u okraje velkeho kvadru bliz ke
   stredu/tezisti sousedniho maleho kvadru)
  staci pocitat pouze pro barvy ktere maji v histogramu alespon 1 pixel}
   for pixel:=0 to 32767 do
    if (memw[freeseg:2*pixel]>0) then
      mem[freeseg:2*pixel]:=pal^.Alloc(
        (pixel shr 9) and 62+1,
        (pixel shr 4) and 62+1,
        (pixel shl 1) and 62+1);

 {3D FloodFill: je nutny protoze pri konverzi direct2pevnapaleta
  se nevytvari histogram a tak nevime pro ktere pixely alokovat barvy}

End;


{---------------------------------------------------------------------------
 Vymeni bajty v poli... misto c1 da c2 a misto c2 c1.
 ---------------------------------------------------------------------------}
procedure SwapBytesIn(data:pointer;bytes:word;byte1,byte2:byte);assembler;
asm
     les di,data
     mov cx,bytes
     mov bl,byte1
     mov bh,byte2
     mov ah,bl
     xor ah,bh
    @1:
     cmp [es:di],bl
     je @swap
     cmp [es:di],bh
     je @swap
     inc di
     loop @1
     jmp @end
    @swap:
     xor [es:di],ah
     inc di
     loop @1
    @end:
end;

{---------------------------------------------------------------------------
 Vymeni pixely dvou barev v bitmape... misto c1 da c2 a misto c2 c1.
 Pouze pro packed mapy s paletou.
 ---------------------------------------------------------------------------}
PROCEDURE SwapIndexesIn(map:PBitmap;c1,c2:byte);
var y:word;
begin
 for y:=0 to map^.sizeY-1 do
  SwapBytesIn(map^.tab^[y],map^.sizeX,c1,c2);
 Xchg(map^.pal^.pal[c1],map^.pal^.pal[c2],SizeOf(TColor));
end;


{---------------------------------------------------------------------------
 Objekt na konverze vice bitmap do jednoho modelu a jedne palety.
 Pouziva freeseg pro histogram a prekladovou tabulku.

 Zde zadas cilovy model a volitelne i ukazatel na paletu, ktera muze byt
 dalsimi metodami obohacena o nove barvy, ale neni zrusena.
 ---------------------------------------------------------------------------}
Constructor TMergeMaps.Init(adestmodel:byte;adestpal:PPal);
begin
 destmodel:=adestmodel;
 if destmodel=model_unchained then destmodel:=model_packed;
 destpal:=PPal(NewCat(adestpal));
 xlatok:=false;
 any2kvanti:=false;
 if destmodel=model_packed then begin
   asm
    mov es,freeseg
    db 66h;xor ax,ax
    xor di,di
    mov cx,16384
    db 66h;rep stosw
    end;
   end;
end;

{---------------------------------------------------------------------------
 Udela si histogram bitmapy. Histogram je tabulka cetnosti jednotlivych barev.
 Nutno provest se vsemi bitmapami pred kvantizaci.
 ---------------------------------------------------------------------------}
Procedure TMergeMaps.Histogram(map:PBitmap);
var pixel:word;
    c:byte;
begin
 if map=nil then exit;
 if destmodel<>model_packed then exit;
 if debugpal then SetHwCol(0,63,63,63);
 srctransp:=srctransp or map^.transparent;
 if map^.MapModel=model_packed
  then begin
    if map^.pal<>destpal then begin
      {vybuduje maly histogram}
      fillchar(smallhist,sizeof(smallhist),0);
      Add2SmallHist(map);
      {zanese udaje z nej do velkeho histogramu}
      for c:=0 to 255 do
       if smallhist[c]>0 then
        with map^.pal^ do begin
         pixel:=2*_Color(model_BGR15,nil,pal[c].r shl 2,pal[c].g shl 2,pal[c].b shl 2,0);
         memw[freeseg:pixel]:=Long2Word(memw[freeseg:pixel]+smallhist[c]);
         end;
      {poznamena si ze je co kvantizovat}
      any2kvanti:=true;
      end;
    end
  else begin
    {zanese udaje z bitmapy do velkeho histogramu}
    Add2BigHist(map);
    {poznamena si ze je co kvantizovat}
    any2kvanti:=true;
    end;
 if debugpal then SetHwCol(0,0,0,0);
end;

{---------------------------------------------------------------------------
 Kvantizace - na zaklade histogramu vygeneruje vhodnou paletu.
 Pokud nechces hledat nejvhodnejsi paletu, ale zadas vlastni uz v Initu,
 muzes Histogram a Kvantizaci vynechat.
 ---------------------------------------------------------------------------}
Procedure TMergeMaps.Kvantize;
var srccol,destcol:word;
    old0a:byte;
begin
 if destmodel<>model_packed then exit;
 if not any2kvanti then exit;
 if destpal=nil then begin
   New(destpal,Init);
   if destpal=nil then Halt(erLowMem);
   end;
 if debugpal then SetHwCol(0,58,58,58);
 with destpal^ do begin
   {poznamena si puvodni stav pal[0].a a docasne ho zmeni na dead,}
   {aby dalsi rutiny vedely ze maj mozna o barvu min}
   if srctransp then begin
     old0a:=pal[0].a;
     Setup(0,0,pifDead);
     end;
   {kdyz je hodne pouzitych a malo volnych barev, nekvantizuje
    a rovnou vytvori bigxlat z pouzitych barev}
   if count[pifUsed]>2*count[pifFree] then begin
     {destpal uz je pripravena}
     end
   {kdyz je hodne volnych a malo pouzitych barev, kvantizuje do 1/2 volnych
    a presne je vyplni, nealokuje}
   else if count[pifFree]>2*count[pifUsed] then begin
     srccol:=Kvantizuj(count[pifFree] div 2);
     destcol:=0;
     while srccol>0 do begin
       while pal[destcol].a<>pifFree do inc(destcol);
       SetCol(destcol,r[srccol],g[srccol],b[srccol]);
       Setup(destcol,destcol,pifUsed);
       {Alloc(r[srccol],g[srccol],b[srccol]);{proc zakomentovano?}
       dec(srccol);
       end;
     end
   {kdyz je hodne pouzitych i volnych barev, kvantizuje do vic kvadru
    a pak je do palety prialokuje}
   else begin
     srccol:=Kvantizuj(minW(255,count[pifFree]+count[pifUsed]));
     destcol:=0;
     while srccol>0 do begin
       Alloc(r[srccol],g[srccol],b[srccol]);
       dec(srccol);
       end;
     end;
   {vrati puvodni pal[0].a}
   if srctransp then Setup(0,0,old0a);
   end;
 if debugpal then SetHwCol(0,0,0,0);
end;

{---------------------------------------------------------------------------
 Konvertuje bitmapu do noveho modelu.
 ---------------------------------------------------------------------------}
Procedure TMergeMaps.Convert(map:PBitmap);
var pal:PPal;
    nezvetsuju:boolean;
    b:PBitmap;
begin
 if map=nil then exit;
 {pokud neni nutna konverze, skonci hned}
 if (map^.MapModel=destmodel) and (destmodel<>model_packed) then exit;
 {pokud se zdrojova a cilova paleta shoduji, skonci hned}
 if (destpal<>nil) and (map^.pal=destpal) then exit;
 {je konverze vubec mozna?}
 {$ifdef beta}
 if not Convertable(map^.MapModel,destmodel) then erBetaMsg('Convert(text<->gfx)');
 {$endif}
 {pokud jeste neni a je treba, vytvori tabulku pro konverzi bitmapy}
 if debugpal then SetHwCol(0,40,40,40);
 if (map^.MapModel in models_direct) and (destmodel in models_8)
  and not xlatok then begin
   MakeBigXlat(destpal);
   xlatok:=true;
   end;
 {konvertuje bitmapu}
 nezvetsuju:=ByPPlist[map^.mapmodel]>=ByPPlist[destmodel];
 if {}nezvetsuju{ByPPlist[destmodel]=map^.ByPP{} then ConvertMap(map,map,destmodel,destpal) else begin
   New(b,Init(destmodel,map^.sizeX,map^.sizeY));
   if b=nil then Halt(erLowMem);
   ConvertMap(map,b,destmodel,destpal);
   Xchg(map^.MapModel,b^.MapModel,sizeof(TBitmap)-sizeof(TObject));
   KillObj(b);
   end;
 {vymeni bitmape paletu}
 map^.Have(destpal);
 if debugpal then SetHwCol(0,0,0,0);
end;

{---------------------------------------------------------------------------
 Odalokuje pracovni promenne.
 ---------------------------------------------------------------------------}
Destructor TMergeMaps.Done;
begin
 KillCat(destpal);
end;

{---------------------------------------------------------------------------
 Zmeni model bitmapy.
 ---------------------------------------------------------------------------}
PROCEDURE ChangeMapTo(map:PBitmap;newmodel:word);
var m:TMergeMaps;
begin
 if map=nil then exit;
 if newmodel=model_unchained then newmodel:=model_packed;
 if map^.MapModel=newmodel then exit;
 m.Init(newmodel,nil);
 m.Histogram(map);
 m.Kvantize;
 m.Convert(map);
 m.Done;
end;

{---------------------------------------------------------------------------
 Prizpusobi nasi bitmapu tak, aby mela stejny model a paletu jako mainmap.
 Kvanti=false: smi vynechat pomalou tvorbu histogramu a kvantizaci.
 Cim vetsi a vice barevny obrazek, tim dulezitejsi je kvantizace pro vyslednou
 kvalitu. U malych obrazku jako treba sipky mysi je uplne zbytecna.
 ---------------------------------------------------------------------------}
PROCEDURE JoinMapTo(map:PBitmap;mainmap:PAbstractMap;kvanti:boolean);
var m:TMergeMaps;
begin
 if map=nil then exit;
 if (map^.MapModel=model_text) and (mainmap^.MapModel=model_text) then exit;
 m.Init(mainmap^.MapModel,mainmap^.pal);
 if kvanti{pan si preje kvantizaci}
 or ((map^.MapModel in models_direct) and (mainmap^.MapModel in models_8))
    {konverze direct->packed se bez histogramu proste neobejde
     a pak uz se fakt vyplati provest rovnou i tu kvantizaci}
  then begin
   m.Histogram(map);
   m.Kvantize;
   end;
 m.Convert(map);
 m.Done;
end;

{---------------------------------------------------------------------------
 Oznaci v palete ktere barvy jsou v bitmape pouzite a ktere nepouzite.
 Pozor: pokud paletu pouziva vice bitmap, muze vyhodit jinde pouzitou barvu.
 ---------------------------------------------------------------------------}
PROCEDURE MarkColorsIn(map:PBitmap);
var c:byte;
begin
 if (map=nil) or (map^.pal=nil) then exit;
 {vybuduje maly histogram}
 fillchar(smallhist,sizeof(smallhist),0);
 Add2SmallHist(map);
 {zanese udaje z nej do palety}
 with map^.pal^ do
  for c:=0 to 255 do
   if pal[c].a<>pifDead then
    if (c<>0) and (smallhist[c]=0) then Setup(c,c,pifFree) else Setup(c,c,pifUsed);
end;

{---------------------------------------------------------------------------
 Vraci zda jde bitmapa zkonvertovat ze srcmodel do destmodel.
 ---------------------------------------------------------------------------}
FUNCTION  Convertable(srcmodel,destmodel:word):boolean;
begin
 Convertable:=(srcmodel=model_text)=(destmodel=model_text);
end;


{€€€€€€€€€€€€€€€€ M Y S €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Vygeneruje bitmapy nekolika standardnich sipek.
 ---------------------------------------------------------------------------}
const mouseColors=4;
      mousePalette:array[1..4] of TColor=(
       (b:1;g:18;r:18;a:pifFree),
       (b:1;g:30;r:30;a:pifFree),
       (b:1;g:45;r:45;a:pifFree),
       (b:1;g:58;r:58;a:pifFree));

      s=1;
      t=2;
      u=3;
      v=4;
{
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
}
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
 Vygeneruje nejakou sipku mysi.
 ---------------------------------------------------------------------------}
Function TScreen.MouseGenerateBitmap:PBitmap;
var  b:PBitmap;
begin
 if MapModel=model_text
   then b:=InitStaticBitmap(model_text,sipka3sir,sipka3vys,@sipka3data,true)
   else begin
     {if Yres>Xres then b:=InitStaticBitmap(model_packed,sipka1sir,sipka1vys,@sipka1data,true) else
     if Yres<350  then b:=InitStaticBitmap(model_packed,sipka0sir,sipka0vys,@sipka0data,true) else
                       }b:=InitStaticBitmap(model_packed,sipka2sir,sipka2vys,@sipka2data,true);
     with b^.pal^ do begin
       first:=1;
       last :=mouseColors;
       move(mousePalette,pal[1],Sizeof(TColor)*mouseColors);
       Setup(first,last,pifUsed);
       end;
     end;
 MouseGenerateBitmap:=b;
end;

{---------------------------------------------------------------------------
 Inicializuje sipku mysi
  - jako sipku pouzije tvoji bitmapu nebo nejakou vygeneruje
  - naalokuje buffer pro ukladani pozadi pod sipkou
  - nastavi range
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseSetPointer(p:PBitmap;forXres,forYres,pointX,pointY:word);
var   oldmouse:boolean;
      b:PBitmap;
begin
 {$ifdef testvga}bioswriteln('priprava mysi-get');{$endif}
 oldmouse:=MouseHide;
 MouseKillPointer(true);
 if (p=nil) or not Convertable(p^.MapModel,MapModel) then begin
   KillObj(p);
   mousePoint.X       :=0;
   mousePoint.Y       :=0;
   mouseBitmap        :=MouseGenerateBitmap;
   forXres            :=640;
   forYres            :=480;
   end
  else begin
   mousePoint.X       :=pointX;
   mousePoint.Y       :=pointY;
   mouseBitmap        :=p;
   end;
 {$ifdef testvga}bioswriteln('priprava mysi-resize');{$endif}
 if MapModel<>model_text then
  with mouseBitmap^ do
   if (forXres<>0) and (forYres<>0) then begin
     b:=ResizeFulCopy(0,
       Bounded(longint(Xres)*sizeX*mouseSize div forXres div mouseSizeAvg,1,Xres div 2),
       Bounded(longint(Yres)*sizeY*mouseSize div forYres div mouseSizeAvg,1,Yres div 2));
     KillObj(mouseBitmap);
     mouseBitmap:=b;
     mousePoint.X:=longint(Xres)*mousePoint.X*mouseSize div forXres div mouseSizeAvg;
     mousePoint.Y:=longint(Yres)*mousePoint.Y*mouseSize div forYres div mouseSizeAvg;
     end;
 {$ifdef testvga}bioswriteln('priprava mysi-joinmap');{$endif}
 JoinMapTo(mouseBitmap,@self,false);
 {$ifdef testvga}bioswriteln('priprava mysi-newbuf');{$endif}
 with mouseBitmap^ do begin
   new(mouseBuffer,Init(MapModel,sizeX,sizeY));
   {$ifdef testvga}bioswriteln('priprava mysi-assign');{$endif}
   mouseRng.Assign(0,0,Xres-sizeX,Yres-sizeY);
   {$ifdef testvga}bioswriteln('priprava mysi-move');{$endif}
   mouseRng.Move(mousePoint.x,mousePoint.y);
   end;
 {$ifdef testvga}bioswriteln('priprava mysi-setrange');{$endif}
 MouseSetRange;
 {$ifdef testvga}bioswriteln('priprava mysi-rescanstate');{$endif}
 MouseRescanState;
 if oldmouse then MouseShow;
 {$ifdef testvga}bioswriteln('priprava mysi-done');{$endif}
end;

{---------------------------------------------------------------------------
 Vymeni sipku.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseSwapPointer(var b:PBitmap;forXres,forYres:word;var p:TPoint);
var   oldB:PBitmap;
      oldP:TPoint;
      oldmouse:boolean;
begin
 {$ifdef testvga}bioswriteln('swappointer-init');{$endif}
 oldmouse:=MouseHide;
 oldB:=mouseBitmap;
 oldP:=mousePoint;
 MouseKillPointer(false);
 MouseSetPointer(b,forXres,forYres,p.x,p.y);
 b:=oldB;
 p:=oldP;
 if oldmouse then MouseShow;
 {$ifdef testvga}bioswriteln('swappointer-done');{$endif}
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
 "Obsoleted" diky nove mys.pas.
 Nastavi mousejump tak, aby se mys pohybovala plynule ale pritom zustalo
 dost prostoru na serizovani citlivosti.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseAdjustJump;
begin
 if MapModel=model_text then mouseSetJump(16,16) else
  if not VesaMode then mouseSetJump(2,1) else
   if Xres+Yres<1024+768 then mouseSetJump(4,4) else mouseSetJump(2,2);
end;

{---------------------------------------------------------------------------
 Nastavi rychlost mysi podle aktualniho modu a promenne MouseSpeed.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseAdjustSpeed;
begin
 {bioswriteln(stri(mouseSpeed)+' '+stri(xres)+'x'+stri(yres));}
{ mouseSetSpeed(144186 div (mouseSpeed+1) div Xres,
               144186 div (mouseSpeed+1) div Yres);}
 mouseSetSpeed((mouseSpeed*mouseSpeed+1)/5120/50*Xres,
               (mouseSpeed*mouseSpeed+1)/3840/50*Yres);
end;

{---------------------------------------------------------------------------
 Kresli sipku mysi.
 ---------------------------------------------------------------------------}
Function TScreen.MouseShow:boolean;
var   oldpen:byte;
begin
 {$ifdef beta}
 if mouseWarning<>0 then erBetaMsg('syncproblem mouseshow '+stri(mouseWarning));
 {$endif}
{ if mouseBitmap=nil then exit;}
 if debugpal then SetHWCol(0,0,0,63);
 MouseShow:=mouseflag;
 if not mouseflag then begin
   mouseDrawnTo:=mouse;
   oldpen:=pen;
   pen:=PEN_SCREEN;
   {kdyz behem snimani backgroundu nebo kresleni sipky odscrolne,
    SetvisPhase4 posune mouseDrawnTo aby pozice odpovidala tomu co se kresli}
   mouseWarning:=1;
    if kpressed[klshift] then begin
     asm nop end
     end;
    Box2BtF(mouseBuffer,mouseDrawnTo.X-mousePoint.X,mouseDrawnTo.Y-mousePoint.Y);
    BtF2Box(mouseBitmap,mouseDrawnTo.X-mousePoint.X,mouseDrawnTo.Y-mousePoint.Y);
    mouseflag:=true;
    mouseRedrawFlag:=true;
   mouseWarning:=0;
   pen:=oldpen;
   end;
 if debugpal then SetHWCol(0,0,0,0);
end;

{---------------------------------------------------------------------------
 Maze sipku mysi. Vraci jeji puvodni stav.
 ---------------------------------------------------------------------------}
Function TScreen.MouseHide:boolean;
var   oldpen:byte;
begin
 {$ifdef beta}
 if mouseWarning<>0 then erBetaMsg('syncproblem mousehide '+stri(mouseWarning));
 {$endif}
{ if mouseBitmap=nil then exit;}
 if debugpal then SetHWCol(0,63,0,0);
 MouseHide:=mouseflag;
 if mouseflag then begin
   oldpen:=pen;
   pen:=PEN_SCREEN;
   {kdyz behem mazani odscrolne, ve vetsine method to nevadi}
   mouseWarning:=2;
    BtF2Box(mouseBuffer,mouseDrawnTo.X-mousePoint.X,mouseDrawnTo.Y-mousePoint.Y);
    mouseflag:=false;
   mouseWarning:=0;
   pen:=oldpen;
   end;
 if debugpal then SetHWCol(0,0,63,0);
end;

{---------------------------------------------------------------------------
 Do rect nastavi jakou oblast na obrazovce zabira sipka (v PEN_SCREEN).
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseGetRect(var rect:TRect);
begin
 rect.a.x:=mouseDrawnTo.X-mousePoint.X;
 rect.a.y:=mouseDrawnTo.Y-mousePoint.Y;
 rect.b.x:=rect.a.x+mouseBitmap^.sizeX;
 rect.b.y:=rect.a.y+mouseBitmap^.sizeY;
end;

{---------------------------------------------------------------------------
 Do mouseX,Y nacte polohu mysi.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseRescanState;
begin;
 mouseGet(mouse.X,mouse.Y,mouse.Z);
 mouseGenerateHold:=true;
 {windowsi okenni driver vraci i souradnice out of range, tady se zpacifikujou}
 mouse.X:=Bounded(mouse.X,mouseRng.a.x,mouseRng.b.x);
 mouse.Y:=Bounded(mouse.Y,mouseRng.a.y,mouseRng.b.y);
end;

{---------------------------------------------------------------------------
 Do presX,Y,Z zapise souradnice posledniho stisku mysi byl-li, jinak nemeni.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseRescanPress;
begin
 mys.mouseRescanPress(mousePress.X,mousePress.Y,mousePress.Z,mouseActions);
end;

{---------------------------------------------------------------------------
 Nahrada mys.mouseSetRange.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseSetRange;
begin
 with mouseRng do mys.mouseSetRange(a.x,a.y,b.x,b.y);
end;

{---------------------------------------------------------------------------
 Vraci pozici mysi (TScreen.mouse) pro dany pen.
 ---------------------------------------------------------------------------}
Procedure TScreen.MouseGetPos(apen:byte;var x,y:integer);
begin
 x:=mouse.x;
 y:=mouse.y;
 case apen of
   PEN_VRAM     :{nic takoveho nikdy nema smysl};
   PEN_VIRTUAL  :{pro TScreen nema smysl, az pro TScrolScreen};
   PEN_VIRT_AREA:{pro TScreen nema smysl, az pro TScrolScreen};
   PEN_SCREEN   :{je ok};
   end;
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
 if (mouse.X<>mouseDrawnTo.X) or (mouse.Y<>mouseDrawnTo.Y) then
  if mouseFlag then begin
    MouseHide;
    MouseShow;
    end;
end;


{€€€€€€€€€€€€€€€€ E V E N T Y €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Vraci kolik milisekund ubehlo od posledniho eventu (stisk klavesy,
 pohyb mysi). Eventy detekuje jen kdyz jsou zavesene handlery!
 ---------------------------------------------------------------------------}
var fromlastevent:TStopky;

FUNCTION TimeFromLastEvent:longint;
begin
 if mouseDirty or kDirty or userDirty then begin
   fromlastevent.Start;
   mouseDirty    :=false;
   kDirty        :=false;
   userDirty     :=false;
   end;
 TimeFromLastEvent:=fromlastevent.LookAt;
end;

{---------------------------------------------------------------------------
 Zpracuje signaly z klavesnice, ovsem jen ty, co jdou pres dos.
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
 function try1(flag,code:word):boolean;
 begin
  if (mouseActions and flag)=0 then try1:=false else begin
    dec(mouseActions,flag);
    event:=MakeEvent(code,#0,#0);
    try1:=true;
    end
 end;
 function try2(flag,code:word):boolean;
 begin
  if (mouse.Z and flag)=0 then try2:=false else begin
    event:=MakeEvent(code,#0,#0);
    try2:=true;
    end
 end;
begin
 if mouseActions>0 then begin
   pos        :=mousePress;
   if not try1(maLeftReleased  ,mcLeftReleased  ) then
   if not try1(maLeftPressed   ,mcLeftPressed   ) then
   if not try1(maRightReleased ,mcRightReleased ) then
   if not try1(maRightPressed  ,mcRightPressed  ) then
   if not try1(maCenterReleased,mcCenterReleased) then
   if not try1(maCenterPressed ,mcCenterPressed ) then;
   pos        :=mousePress;
   GetEvent   :=true;
   end else
 if events>0 then begin
   event      :=eventbuf[1];
   dec(events);
   move(eventbuf[2],eventbuf[1],events*sizeof(TEvent));
   pos        :=mouse;
   GetEvent   :=true;
   end else
 if (mouse.Z>0) and mouseGenerateHold then begin
   if not try2(mLeft  ,mcLeftHold  ) then
   if not try2(mRight ,mcRightHold ) then
   if not try2(mCenter,mcCenterHold) then;
   mouseGenerateHold:=false;
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
 presnost:=minW(1,presnost);
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
FUNCTION IsVesamode(testModel:byte;testMode:word):boolean;
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
 SizeXb     :=longint(SizeX)*ByPP;
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
 Vraci zdetekovane udaje o aktualnim modu (model se predpoklada model_text).
 Pouzito pro navrat do puvodniho rozliseni pri ukoncovani prvni TScreen.
 ---------------------------------------------------------------------------}
FUNCTION GetPrevMode:word;
begin
 if bios_GetMode=3
  then GetPrevMode:=bios_GetYres
  else GetPrevMode:=25;
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
   bit 12        - nastavit jen 40 sloupcu misto 80
 ---------------------------------------------------------------------------}
Function TScreen.SetMode(newModel,newMode:word):boolean;
begin
 {pokud existuje podezreni ze tento objekt dosud nebyl inicializovan...}
 if CurScreen<>@self then begin

   {inicializuje se. kdyby se inicializoval pri kazdem nastaveni modu,
    ztracely by se udaje jako PrevScreen}
   inherited Init(newModel,{rozmery zatim neznam}0,0);

   {zapamatuje si prevscreen}
   if CurScreen<>nil then PrevScreen:=CurScreen else begin
     PrevModel:=model_text;
     PrevMode:=GetPrevMode;
     end;
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
   model_BGR15,                                         {standardni HiColor 15bit}
   model_RGB15,                                         {nestandardni HiColor 15bit,
                                                          v Cechach nepozorovan, jen u prastarych SVGA}
   model_BGR16,                                         {standardni HiColor 16bit}
   model_RGB16,                                         {nestandardni HiColor 16bit, viz RGB15}
   model_BGR24,                                         {standardni TrueColor 24bit}
   model_RGB24,                                         {nestandardni TrueColor 24bit, viz RGB24}
   model_BGRA32,
   model_RGBA32:      SetMode:=SetMode_VESA(newModel,newMode);{standardni TC 32bit}
   else               SetMode:=false;                        {nepodporovany mod}
  end;

 {pokud ma mod paletu, nastavi ji nowbright=255 aby se pri alokacich barev
  tyto ihned nastavovaly}
 if pal<>nil then pal^.nowbright:=255;
end;

{---------------------------------------------------------------------------
 Obnovi stav obrazovky (rozliseni fyzicke i virtualni, split, mys...
  ale ne bitmapu a paletu).
 Pozor: kdyz pred reinitem zmenis LoadFont, muze se nastavit mod s jinym
  poctem radek nez byl prve, tim vznikne pekny chaos.
 ---------------------------------------------------------------------------}
Procedure TScreen.ReInit;
var biosmode:byte;
begin
 if CurScreen=@self then exit;
 if (CurScreen=nil) or (CurScreen^.ModeID<>ModeID) or (CurScreen^.MapModel<>MapModel)
  {znova nastavi mod, ale uz nemusi detekovat kdeco}
  then begin
    if VesaMode then begin
      asm les bx,self;mov bx,[es:bx+ModeID];or bx,8000h;mov ax,4f02h;int 10h;end;
      vesa_NowBank:=0;
     end
    else
     case MapModel of
      model_packed,
      model_unchained:SetXMode(MapModel,ModeID);
      model_text:begin
                  if (modeID and $1000)=0 then biosmode:=3 else biosmode:=1;
                  biosmode:=biosmode or (modeID and $80);
                  asm mov al,biosmode;mov ah,0;int 10h;end;
                  {na prani natvrdo setne sirku znaku v pixelech}
                  vga_SetCharXres(charXres);
                 end;
      end
    end
  {prevezme aktualni mod, ale pri tom musi opravit nowbank}
  else begin
    vesa_NowBank:=CurScreen^.vesa_NowBank;
    end;
 if MapModel=model_text then LoadFont(ZadanaVyskaZnaku);
 CurScreen:=@self;
 if MapModel in models_8 then BlackHWPal;{zcerna paletu protoze nasledujici
   radky muzou na obrazovku dostat nesmazanou vramku}
 ReadIrq2Enabled;
 SetVramXRes(vramXres);
 if VgaCompat then vga_SetLineCompare(DoubleScan*(nowSplitY+1)-1);
 SetVis(vramVisX,vramVisY);
 mouseAdjustJump;
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
 Prevezme jinou obrazovku jako sveho predka,
 ktereho nastavi (ReInit) pri sve destrukci (Done).
 ---------------------------------------------------------------------------}
Procedure TScreen.GetThisParent(s:PScreen);
begin
 prevScreen:=s;
 prevModel :=0;
 prevMode  :=0;
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
procedure qqq;begin bioswriteln('#');end;
Function TScreen.SetVramXRes(virtualX:word):boolean;
var   newcrtc:word;
      ret_vramXres,ret_lineOffset:word;
      exp:boolean;
      {$ifdef dpmi}
      RealModeRegs:dpmiRealCallRegs;
      {$endif}
label doneOk,doneBad;
begin
 {$ifdef testvga}bioswriteln('setvramxres init');{$endif}
 {$ifdef beta}
 if CurScreen<>@self then erBetaMsg('setvramxres 1');
 {$endif}

 {nastavi neuspech, pri neuspechu pak uz staci jen exitnout}
 SetVramXRes:=false;

 exp:=sizeY>Yres;

 IF VesaMode then
  begin
   virtualX:=virtualX*charXres;{prevede udaj ze znaku na pixely}

   {$ifdef testvga}bioswriteln('setvramxres 1, virtualx='+stri(virtualX)+' pixels');{$endif}
   asm
       {db 66h;xor ax,ax
       db 66h;xor bx,bx
       db 66h;xor cx,cx
       db 66h;xor dx,dx
       db 66h;xor si,si
       db 66h;xor di,di
       db 66h;dec ax
       db 66h;dec bx
       db 66h;dec cx
       db 66h;dec dx
       db 66h;dec di
       db 66h;dec si}

       mov ax,4f06h;mov bl,0          {sluzba set virtual length}
       mov bh,0                       {diky tomu nepada na banshee}
       mov cx,virtualX                {nastavi parametry v pixelech}
       {$ifdef testvga}pusha;call qqq;popa;{$endif}
       int 10h                        {vola vesabios}
       {$ifdef testvga}pusha;call qqq;popa;{$endif}
       cmp ax,4fh;jnz donebad         {probehla sluzba uspesne?}
{
 with RealModeRegs do begin
    ClrRegs(RealModeRegs);
    rEAX:=$4f06;
    rEBX:=0;
    rECX:=virtualX;
    qqq;
    erCheck(TError(dpmiRealModeInt($10,@RealModeRegs)));
    qqq;
    if LoWord(rEAX)<>$4f then goto donebad;
    end;
asm}
       mov ax,4f06h;mov bl,1          {sluzba get virtual length}
       int 10h                        {vola vesabios}
       {$ifdef testvga}pusha;call qqq;popa;{$endif}
       cmp ax,4fh;jnz donebad         {probehla sluzba uspesne?}
       mov ret_lineOffset,bx          {ulozi lineoffset v bajtech}
       mov ret_vramXres,cx            {ulozi lineoffset v pixelech}
   end;

   {$ifdef testvga}bioswriteln('setvramxres 2');{$endif}
   virtualX:=virtualX div charXres;{prevede udaje z pixelu na znaky}
   {$ifdef testvga}bioswriteln('setvramxres 3');{$endif}
   ret_vramXres:=ret_vramXres div charXres;
   {$ifdef testvga}bioswriteln('setvramxres 4');{$endif}

{
tady musi do vramxres nacpat aspon priblizne kolik pixelu se vejde
do lineoffset. kdyz se vejde neco a tretina, staci neco. snad.
kdyz nenacpe dobry cislo, scrolling engine je zmateny a spocita
si jinak velky scrolbuffer
}

(*
{bioswriteln('!!!! old_lineoffset='+stri(lineOffset)+' new_lineoffset='+stri(ret_lineOffset));
{bioswriteln('!!!! old_vramxres='+stri(vramxres)+' new_vramxres='+stri(ret_vramxres));
   {if vbe daz heavy kaoz..}
   if (ret_lineOffset=lineOffset) xor (ret_vramXres=vramXres) then begin
     {try to return old state}
     virtualX:=vramXres*charXres;
     asm mov ax,4f06h;mov bl,0;mov cx,virtualX;int 10h;end;
     goto donebad;
     end;
*)

   lineOffset:=ret_lineOffset;
   vramXres  :=ret_vramXres;
{bioswriteln('xres='+stri(xres));{}
{bioswriteln('vramxres='+stri(vramxres));{}
{bioswriteln('lineoffset='+stri(lineoffset));{}
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
  {$ifdef testvga}bioswriteln('setvramxres 5');{$endif}
  {toto provadi po uspesnem nastaveni, presto jeste muze vratit false
   pokud vesa bios nastavil min nez mel (ma nastavovat nejblizsi VYSSI hodnotu)}
  SetVramXRes       :=vramXres>=virtualX;
  vramYres          :=Bounded(longint(VramSizeKB)*1024 div (vramXres*ByPP),0,22222);
  {udaj z vramX/Yres musi prenest do sizeX/Y}
  ExpandFul(exp);
 doneBad:
 {$ifdef testvga}bioswriteln('setvramxres done');{$endif}
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
var oldReporter:TReporter;
begin
 oldReporter:=ReportErr;
 ReportErr:=erWrite;
 if not SilentDone then MouseHide;
 MouseKillPointer(true);
 if not SilentDone then
  if PrevScreen<>nil
    then PrevScreen^.ReInit
    else SetMode(PrevModel,PrevMode);
 ReportErr:=oldReporter;
 inherited Done;
 if CurScreen=@self then CurScreen:=nil;
end;





{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ Object ABSTRACT MAP ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

Constructor TAbstractMap.Init(newmodel,sir,vys:word);
begin
 inherited Init;
 MapModel   :=newmodel;
 BiPP       :=BiPPlist[newmodel];
 ByPP       :=ByPPlist[newmodel];
 SizeX      :=sir;
 SizeY      :=vys;
 SizeXb     :=sir*ByPP;
 if newmodel in models_8 then begin
   if nextPal<>nil then pal:=PPal(NewCat(nextPal)) else New(pal,Init);
   if pal=nil then Fail;
   end;
 nextPal:=nil;
end;

Destructor TAbstractMap.Done;
begin
 KillCat(pal);
 inherited Done;
end;

Procedure TAbstractMap.Have(p:PPal);
begin
 KillCat(pal);
 pal:=PPal(NewCat(p));
end;

Procedure TAbstractMap.Take(p:PPal);
begin
 if pal<>nil then pal^.Take(p);
end;

Procedure TAbstractMap.SetBright(n:byte);
begin
 if pal<>nil then pal^.SetBright(n);
end;

Function TAbstractMap.Color(r,g,b,a:byte):longint;
begin
 Color:=_Color(MapModel,pal,r,g,b,a);
end;

Procedure TAbstractMap.RGB(pixel:longint;var r,g,b:byte);
var a:byte;
begin
 _RGBA(MapModel,pal,pixel,r,g,b,a);
end;

Procedure TAbstractMap.RGBA(pixel:longint;var r,g,b,a:byte);
begin
 _RGBA(MapModel,pal,pixel,r,g,b,a);
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
 nextPal:=pal;
 New(map,Init(MapModel,Sirka,Vyska));
 if map<>nil then Box2BtF(map,srcX,srcY);
 BoxCopy:=map;
end;

Function TAbstractMap.FulCopy:PBitmap;
begin
 FulCopy:=BoxCopy(0,0,sizeX,sizeY);
end;

Function TAbstractMap.ResizeBoxCopy(method:byte;srcX,srcY,srcSir,srcVys,destSir,destVys:word):PBitmap;
var   map:PBitmap;
begin
 nextPal:=pal;
 New(map,Init(MapModel,destSir,destVys));
 if map<>nil then ResizeBox2BtF(method,map,srcX,srcY,srcSir,srcVys);
 ResizeBoxCopy:=map;
end;

Function TAbstractMap.ResizeFulCopy(method:byte;destSir,destVys:word):PBitmap;
begin
 ResizeFulCopy:=ResizeBoxCopy(method,0,0,sizeX,sizeY,destSir,destVys);
end;

Function TBitmap.BoxCopy(srcX,srcY,Sirka,Vyska:word):PBitmap;
var   map:PBitmap;
      oldtransp:boolean;
begin
 oldtransp:=transparent;
 transparent:=false;
 map:=inherited BoxCopy(srcX,srcY,Sirka,Vyska);
 if map<>nil then begin
   map^.transparent:=oldtransp;
   end;
 BoxCopy:=map;
 transparent:=oldtransp;
end;

Function TBitmap.ResizeBoxCopy(method:byte;srcX,srcY,srcSir,srcVys,destSir,destVys:word):PBitmap;
var   map:PBitmap;
      oldtransp:boolean;
begin
 oldtransp:=transparent;
 transparent:=false;
 map:=inherited ResizeBoxCopy(method,srcX,srcY,srcSir,srcVys,destSir,destVys);
 if map<>nil then begin
   map^.transparent:=oldtransp;
   end;
 ResizeBoxCopy:=map;
 transparent:=oldtransp;
end;


Procedure TAbstractMap.Box2Box(p:PAbstractMap;srcX,srcY,Sirka,Vyska,destX,destY:word);
var   map:PBitmap;
      y:word;
begin
 map:=BoxCopy(srcX,srcY,Sirka,Vyska);
 if map=nil then begin
   if (sirka=0) or (vyska=0) then exit;
   {malo pameti -> zkusi kopcit po mensich blocich}
   New(map,Init(MapModel,Sirka,1));
   if map=nil then Halt(erLowMem);
   for y:=0 to sizeY-1 do begin
     Box2BtF(map,srcX,srcY+y);
     p^.BtF2Box(map,destX,destY+y);
     end;
   end
 else
   p^.BtF2Box(map,destX,destY);
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
{$ifndef dpmi}
     {v protektu nealokuje az nadoraz, protoze borlandi memory manager pak
     vetsinou zuchne!}
     if blocklines>1 then begin
       blocklines:=blocklines div 2;
       if blocklines*sir>4096{heaplimit} then continue;
       {skonci kdyz hrozi ze naalokuje dva navazujici bloky a FreeMap by je uvolnil jako jeden}
       end;
{$endif}
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



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ RGB MODIFIERS ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

Type TRgbModifier=procedure(var r,g,b:byte);

var _Modifier:TRgbModifier;


var _Bright:word;
procedure _SetBright(var r,g,b:byte);far;
begin
 r:=HiByte(r*_Bright);
 g:=HiByte(g*_Bright);
 b:=HiByte(b*_Bright);
end;

Procedure rgbSetBright(bright:word);
begin
 _Modifier:=_SetBright;
 _Bright  :=bright;
end;


var _Blend:TCol;
procedure _BlendTo(var r,g,b:byte);far;
begin
 r:=HiByte(r*_Bright+_Blend.r*(256-_Bright));
 g:=HiByte(g*_Bright+_Blend.g*(256-_Bright));
 b:=HiByte(b*_Bright+_Blend.b*(256-_Bright));
end;

Procedure rgbBlendTo(blend:TCol;bright:word);
begin
 _Modifier:=_BlendTo;
 _Blend   :=blend;
 _Bright  :=bright;
end;


Procedure TAbstractMap.pixModify(x,y:word);
var r,g,b,a:byte;
begin
 if (x<0) or (x>=sizeX) or (y<0) or (y>=sizeY) then exit;
 RGBA(GetPixel(x,y),r,g,b,a);
 _Modifier(r,g,b);
 PutPixel(x,y,Color(r,g,b,a))
end;

Procedure TAbstractMap.boxModify(ax,ay,w,h:word);
var x,y:word;
begin
 for x:=ax to ax+w-1 do
  for y:=ay to ay+h-1 do
   pixModify(x,y);
end;


Procedure ShadeBorder(b:PAbstractMap);
var max:word;
    i,j:word;
begin
 with b^ do begin
   max:=(sizeX+sizeY) div 30;
   if max>0 then
    for i:=0 to max do begin
     rgbSetBright(round(sqrt(2*i*max-i*i)*256/max));
     boxModify(i,0,1,sizeY);
     boxModify(sizeX-1-i,0,1,sizeY);
     boxModify(0,i,sizeX,1);
     boxModify(0,sizeY-1-i,sizeX,1);
     end;
   end;
end;

Procedure CastShadow(b:PAbstractMap;ax,ay,sir,vys:word);
const i=20;
var   black:longint;

 procedure boxDarkOdd(x,y,w,h:word);
 var maxy:word;
 begin
  x:=MaxW(0,x);
  y:=MaxW(0,y);
  w:=MinW(w,b^.sizeX-x);
  h:=MinW(h,b^.sizeY-y);
  maxy:=y+h;
  while y<maxy do begin
    b^.Col2Box(x,y,w,1,black);
    inc(y,2);
    end;
 end;

begin
 if b^.MapModel in models_direct then begin
   rgbSetBright(150);
   if (sir<i) and (vys<i) then
     b^.boxModify(ax+i,ay+i,sir,vys)
   else begin
     b^.boxModify(ax+i,ay+vys,sir,i);
     b^.boxModify(ax+sir,ay+i,i,vys-i);
     end;
   end
 else begin
   black:=b^.Color(0,0,0,255);
   if (sir<i) and (vys<i) then
     boxDarkOdd(ax+i,ay+i,sir,vys)
   else begin
     boxDarkOdd(ax+i,ay+vys,sir,i);
     boxDarkOdd(ax+sir,ay+i,i,vys-i);
     end;
   end;
end;

Procedure WhiteBorder(b:PAbstractMap;ax,ay,sir,vys,power:word);
var   hicol,locol:longint;
begin
 with b^ do begin
   hicol:=Color(power,power,power,255);
   locol:=Color(power*2 div 3,power*2 div 3,power*2 div 3,255);
   Col2Box(ax,ay,sir,1,hicol);
   Col2Box(ax,ay,1,vys,hicol);
   Col2Box(ax,ay+vys-1,sir,1,locol);
   Col2Box(ax+sir-1,ay,1,vys,locol);
   end;
end;

{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ Object BITMAP ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}


{---------------------------------------------------------------------------
 Alokuje bitmapu. Spodek bitmapy, na ktery nestacila pamet, zaplni
 posledni naalokovanou linkou.
 ---------------------------------------------------------------------------}
Constructor TBitmap.InitPart(newmodel,sir,vys:word);
var   i:word;
begin
 {$ifdef beta}
 if vys>16380 then begin
   ReportErr('TBitmap.InitPart(y>16380)');
   Fail;
   end;
 {$endif}
 if newmodel=model_unchained then newmodel:=model_packed;
 inherited Init(newmodel,sir,vys);
 {alokuje tabulku linek}
 if not GetMem(pointer(tab),4*vys) then begin TBitmap.Done;Fail;end;
 tabsize:=vys;
 {alokuje linky}
 allocatedX:=sizeXb;
 allocatedY:=AllocMap(tab,allocatedX,vys,1);
 if allocatedY=0 then begin TBitmap.Done;Fail;end;
 {zajisti aby slo psat i do nenaalokovanejch linek}
 for i:=allocatedY to vys-1 do tab^[i]:=tab^[allocatedY-1];
end;

{---------------------------------------------------------------------------
 Alokuje bitmapu. Kdyz pamet nestaci na celou, selze.
 ---------------------------------------------------------------------------}
Constructor TBitmap.Init(newmodel,sir,vys:word);
var   i:word;
begin
{ InitPart(newmodel,sir,vys);
 if allocatedY<vys then begin TBitmap.Done;Fail;end;}
 {$ifdef beta}
 if vys>16380 then begin
   ReportErr('TBitmap.Init(y>16380)');
   Fail;
   end;
 {$endif}
 if newmodel=model_unchained then newmodel:=model_packed;
 inherited Init(newmodel,sir,vys);
 {alokuje tabulku linek}
 if not GetMem(pointer(tab),4*vys) then begin TBitmap.Done;Fail;end;
 tabsize:=vys;
 {alokuje linky}
 allocatedX:=sizeXb;
 allocatedY:=AllocMap(tab,allocatedX,vys,vys);
 if allocatedY=0 then begin TBitmap.Done;Fail;end;
 {zajisti aby slo psat i do nenaalokovanejch linek}
 for i:=allocatedY to vys-1 do tab^[i]:=tab^[allocatedY-1];
end;

{---------------------------------------------------------------------------
 Uvolni bitmapu.
 ---------------------------------------------------------------------------}
Destructor TBitmap.Done;
begin
 if not static then FreeMap(tab,allocatedX,allocatedY);
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
FUNCTION InitStaticBitmap(model,sir,vys:word;p:pointer;trans:boolean):PBitmap;
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
 toalloc:=sizeY-allocatedY;
 if toalloc>0 then begin
   lines:=AllocMap(PLines(@tab^[allocatedY]),allocatedX,toalloc,0);
   inc(allocatedY,lines);
   if allocatedY=0 then exit;
   for i:=allocatedY to tabsize-1 do tab^[i]:=tab^[allocatedY-1];
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
 if not static then FreeMap(tab,allocatedX,allocatedY);
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
 if not static then FreeMap(tab,allocatedX,allocatedY);
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
 if not static then FreeMap(tab,allocatedX,allocatedY);
 static     :=true;
 for i:=0 to sizeY-1 do tab^[i]:=PLine(@map^.tab^[(srcY+i) mod map^.sizeY]^[srcX]);
end;


{---------------------------------------------------------------------------
 Klasicky getpixel a putpixel.
 ---------------------------------------------------------------------------}
var onepixmap:TBitmap;
    onepix:longint;

Function TAbstractMap.GetPixel(x,y:word):longint;
begin
 onepixmap.MapModel:=MapModel;
 Box2BtF(@onepixmap,x,y);
 onepixmap.MapModel:=model_BGRA32;
 GetPixel:=onepix;
end;

Procedure TAbstractMap.PutPixel(x,y:word;pix:longint);
begin
 Col2Box(x,y,1,1,pix);
end;

Procedure TAbstractmap.Col2Circ(destX,destY,r:word;pixel:longint);
var xl,xr,y,w,line:integer;
begin
 for y:=maxi(0,integer(desty)-r+1) to mini(sizeY-1,desty+r-1) do begin
   line:=abs(desty-y);
   w:=round(sqrt(r*r-line*line));
   xl:=maxi(0,integer(destx)-w+1);
   xr:=mini(sizex,integer(destx)+w);
   col2box(xl,y,xr-xl,1,pixel);
   end;
end;

Function  TBitmap.GetPixel(x,y:word):longint;assembler;
 asm
      les di,self
      mov cl,[es:di+ByPP]
      mov ch,0
      les di,[es:di+tab]
      mov ax,y
      shl ax,2
      add di,ax
      les di,[es:di]
      mov ax,x
      mul cx
      add di,ax
      xor ax,ax
      xor dx,dx
      mov al,[es:di+0];dec cl;jz @end
      mov ah,[es:di+1];dec cl;jz @end
      mov dl,[es:di+2];dec cl;jz @end
      mov dh,[es:di+3]
      @end:
 end;

Procedure TBitmap.PutPixel(x,y:word;pix:longint);assembler;
 asm
      les di,self
      mov cl,[es:di+ByPP]
      mov ch,0
      les di,[es:di+tab]
      mov ax,y
      shl ax,2
      add di,ax
      les di,[es:di]
      mov ax,x
      mul cx
      add di,ax
      db 66h;mov ax,word ptr pix
      @1:
      stosb
      db 66h;shr ax,8
      loop @1
 end;

Procedure TBitmap.Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);assembler;
 asm
      cmp sirka,0;jz @end
      cmp vyska,0;jz @end

      les di,self
      db 26h,0fh,0b4h,9dh;dw TBitmap.tab{LFS BX,[ES:DI+TBitmap.tab]}
      mov cx,destY
      shl cx,2
      add bx,cx

      mov al,[es:di+ByPP]
      dec al;jz @MODEL_1
      dec al;jz @MODEL_2
      dec al;jz @MODEL_3
      dec al;jz @MODEL_4
      jmp @END

     @MODEL_1:
      mov al,byte ptr pixel
      @nextline1:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      mov cx,sirka
      call REP_STOSB
      dec Vyska
      jnz @nextline1
      jmp @END

     @MODEL_2:
      shl destX,1
      mov ax,word ptr pixel
      @nextline2:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      mov cx,sirka
      call REP_STOSW_no
      dec Vyska
      jnz @nextline2
      jmp @END

     @MODEL_3:
      mov ax,destX;add ax,ax;add destX,ax
      mov ax,word ptr pixel
      mov dl,byte ptr pixel+2
      @nextline3:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      mov cx,sirka
      call REP_STOS_AX_DL_nz
      dec Vyska
      jnz @nextline3
      jmp @END

     @MODEL_4:
      shl destX,2
      db 66h;mov ax,word ptr pixel
      @nextline4:
      db 64h,0c4h,3fh{LES DI,[FS:BX]}
      add bx,4
      add di,destX
      mov cx,sirka
      call REP_STOSD
      dec Vyska
      jnz @nextline4
      jmp @END

     @END:
 end;

{---------------------------------------------------------------------------
 Zkopiruje jeden obdelnik do druheho. Obe bitmapy musi byt stejneho modelu.
 Pri kopceni do sebe sama za vysledek ani trochu nerucim :).
 ---------------------------------------------------------------------------}
PROCEDURE _Copy(srcmap,destmap:PBitmap;srcX,srcY,sirka,vyska,destX,destY:word);assembler;
 var rutina:pointer;
 asm
     push ds

     {checks}
     cmp sirka,0;jz @done
     cmp vyska,0;jz @done

     {$ifdef beta}
     db 66h;cmp word ptr srcmap,0;jz @beta
     db 66h;cmp word ptr destmap,0;jz @beta
     cmp srcX,0;js @beta
     cmp srcY,0;js @beta
     cmp destX,0;js @beta
     cmp destY,0;js @beta
     les di,srcmap
     mov al,byte ptr [es:di+TBitmap.MapModel]
     les di,destmap
     cmp al,byte ptr [es:di+TBitmap.MapModel]
     je @zabeta
     @beta:
      push cs
      push offset @msg1
      call chyby.erBetaMsg
      @msg1:
       db 7,'_copy 1'
     @zabeta:
     {$endif}

     {load params}
     lds si,srcmap
     db 0fh,0b4h,9ch;dw TBitmap.Tab{LFS BX,[SI+TRawmap.Tab]}
     mov ax,srcY;shl ax,2;add bx,ax
     mov cl,[si+TBitmap.transparent]
     lds si,destmap
     db 0fh,0b5h,94h;dw TBitmap.Tab{LGS DX,[SI+TRawmap.Tab]}
     mov ax,destY;shl ax,2;add dx,ax
     mov di,dx
     xchg si,bx

     {do promenne rutina da pointer na prislusny kopirak}
     mov bl,[bx+TBitmap.ByPP]
     mov bh,0
     mov ax,bx;mul srcX;mov srcX,ax
     mov ax,bx;mul destX;mov destX,ax
     cmp cl,false
     je @notransp
     add bl,4
     @notransp:
     shl bx,2
     db 66h;mov ax,[cs:bx+offset @rutiny-4]
     db 66h;mov word ptr rutina,ax
     jmp @zarutiny
     @RUTINY:
      dd REP_MOVSB_si
      dd REP_MOVSW_si
      dd REP_MOVS3_si
      dd REP_MOVSD_si
      dd REP_MOVS_1_nz_t
      dd REP_MOVS_2_nz_t
      dd REP_MOVS_3_nz_t
      dd REP_MOVS_4_nz_t
     @zarutiny:

     {doit}
     mov bx,si
     mov dx,di
     @nextline:
     db 64h,0c5h,37h{lds si,[FS:BX]};add bx,4;xchg bx,dx;add si,srcX
     db 65h,0c4h,3fh{les di,[GS:BX]};add bx,4;xchg bx,dx;add di,destX
     mov cx,sirka
     test di,1
     call rutina
     dec vyska
     jnz @nextline

    @DONE:
     pop ds
 end;

{---------------------------------------------------------------------------
 Namapuje jeden obdelnik do druheho.
 Pri kopceni do sebe sama za vysledek ani trochu nerucim :).
 method 0: nearest pixel, obe bitmapy musi byt stejneho modelu!
 method 1: quick-hack bilinear, oproti 0 velmi pomale
 ---------------------------------------------------------------------------}
PROCEDURE _Resize(method:byte;srcmap,destmap:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
var rutina:pointer;
    i,j:integer;x,y,stepx,stepy:double;{vse souradnice v srcmap}
    r1,g1,b1,a1,r2,g2,b2,a2,r3,g3,b3,a3,r4,g4,b4,a4:byte;
begin
 if method=0 then asm

     push ds

     {checks}
     cmp srcSir,0;jz @done
     cmp srcVys,0;jz @done
     cmp destSir,0;jz @done
     cmp destVys,0;jz @done

     {$ifdef beta}
     db 66h;cmp word ptr srcmap,0;jz @beta
     db 66h;cmp word ptr destmap,0;jz @beta
     cmp srcX,0;js @beta
     cmp srcY,0;js @beta
     cmp destX,0;js @beta
     cmp destY,0;js @beta
     les di,srcmap
     mov al,byte ptr [es:di+TBitmap.MapModel]
     les di,destmap
     cmp al,byte ptr [es:di+TBitmap.MapModel]
     je @zabeta
     @beta:
      push cs
      push offset @msg1
      call chyby.erBetaMsg
      @msg1:
       db 9,'_resize 1'
     @zabeta:
     {$endif}

     {load params}
     lds si,srcmap
     db 0fh,0b4h,9ch;dw TBitmap.Tab{LFS BX,[SI+TRawmap.Tab]}
     mov ax,srcY;shl ax,2;add bx,ax
     mov cl,[si+TBitmap.transparent]
     lds si,destmap
     db 0fh,0b5h,94h;dw TBitmap.Tab{LGS DX,[SI+TRawmap.Tab]}
     mov ax,destY;shl ax,2;add dx,ax
     mov di,dx
     xchg si,bx

     {do promenne rutina da pointer na prislusny resizer}
     mov bl,[bx+TBitmap.ByPP]
     mov bh,0
     mov ax,bx;mul srcX;mov srcX,ax
     mov ax,bx;mul destX;mov destX,ax
     cmp cl,false
     je @notransp
     add bl,4
     @notransp:
     shl bx,2
     db 66h;mov ax,[cs:bx+offset @rutiny-4]
     db 66h;mov word ptr rutina,ax
     jmp @zarutiny
     @RUTINY:
      dd ResizeCX2DX_1_nz
      dd ResizeCX2DX_2_nz
      dd ResizeCX2DX_3_nz
      dd ResizeCX2DX_4_nz
      dd ResizeCX2DX_1_nz_t
      dd ResizeCX2DX_2_nz_t
      dd ResizeCX2DX_3_nz_t
      dd ResizeCX2DX_4_nz_t
     @zarutiny:

     {doit}
      mov ax,srcVys
      xor dx,dx
      div destVys
      PUSH AX
      xor ax,ax
      div destVys
      POP DX
      {cx=?}xor cx,cx
      xor bx,bx
     @full:
      pusha
        shl bx,2
        db 64h{FS};LDS SI,[SI+BX];add si,srcX
        db 65h{GS};LES DI,[DI];add di,destX
        mov cx,srcSir
        mov dx,destSir
        call rutina
      popa
      add cx,ax
      adc bx,dx
      add di,4
      dec destVys
      jnz @full

    @DONE:
     pop ds
     end

 else begin

     y:=srcY+0.1;
     stepx:=(srcSir-0.2)/(2*destSir);
     stepy:=(srcVys-0.2)/(2*destVys);
     for j:=0 to destVys-1 do begin
       x:=srcX+0.1;
       for i:=0 to destSir-1 do begin
         srcmap^.RGBA(srcmap^.GetPixel(trunc(x      ),trunc(y      )),r1,g1,b1,a1);
         srcmap^.RGBA(srcmap^.GetPixel(trunc(x      ),trunc(y+stepy)),r2,g2,b2,a2);
         srcmap^.RGBA(srcmap^.GetPixel(trunc(x+stepx),trunc(y      )),r3,g3,b3,a3);
         srcmap^.RGBA(srcmap^.GetPixel(trunc(x+stepx),trunc(y+stepy)),r4,g4,b4,a4);
         x:=x+stepx*2;
         destmap^.PutPixel(destX+i,destY+j,destmap^.Color(
           (r1+r2+r3+r4) div 4,(g1+g2+g3+g4) div 4,(b1+b2+b3+b4) div 4,(a1+a2+a3+a4) div 4));
         end;
       y:=y+stepy*2;
       end;

     end;
end;


Procedure TAbstractMap.ResizeBtB2Box(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
var   b:PBitmap;
begin
 if (srcSir=destSir) and (srcVys=destVys)
  then BtB2Box(p,srcX,srcY,srcSir,srcVys,destX,destY)
  else begin
   new(b,Init(MapModel,destSir,destVys));
   if b=nil then Halt(erLowMem);
   Xchg(b^.transparent,p^.transparent,1);
   _Resize(method,p,b,srcX,srcY,srcSir,srcVys,0,0,destSir,destVys);
   p^.transparent:=b^.transparent;
   BtF2Box(b,destX,destY);
   KillObj(b);
   end;
end;

Procedure TAbstractMap.ResizeBtB2Ful(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys:word);
begin
 ResizeBtB2Box(method,p,srcX,srcY,srcSir,srcVys,0,0,sizeX,sizeY);
end;

Procedure TAbstractMap.ResizeBtF2Box(method:byte;p:PBitmap;destX,destY,destSir,destVys:word);
begin
 ResizeBtB2Box(method,p,0,0,p^.sizeX,p^.sizeY,destX,destY,destSir,destVys);
end;

Procedure TAbstractMap.ResizeBtF2Ful(method:byte;p:PBitmap);
begin
 ResizeBtB2Box(method,p,0,0,p^.sizeX,p^.sizeY,0,0,sizeX,sizeY);
end;


Procedure TAbstractMap.ResizeBox2BtB(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
var   b:PBitmap;
begin
 b:=BoxCopy(srcX,srcY,srcSir,srcVys);
 if b=nil then Halt(erLowMem);
 _Resize(method,b,p,0,0,srcSir,srcVys,destX,destY,destSir,destVys);
 KillObj(b);
end;

Procedure TAbstractMap.ResizeFul2BtB(method:byte;p:PBitmap;destX,destY,destSir,destVys:word);
begin
 ResizeBox2BtB(method,p,0,0,sizeX,sizeY,destX,destY,destSir,destVys);
end;

Procedure TAbstractMap.ResizeBox2BtF(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys:word);
begin
 ResizeBox2BtB(method,p,srcX,srcY,srcSir,srcVys,0,0,p^.sizeX,p^.sizeY);
end;

Procedure TAbstractMap.ResizeFul2BtF(method:byte;p:PBitmap);
begin
 ResizeBox2BtB(method,p,0,0,sizeX,sizeY,0,0,p^.sizeX,p^.sizeY);
end;


Procedure TBitmap.BtB2Box(p:PBitmap;srcX,srcY,sirka,vyska,destX,destY:word);
begin
 _Copy(p,@self,srcX,srcY,sirka,vyska,destX,destY);
end;

Procedure TBitmap.Box2BtB(p:PBitmap;srcX,srcY,sirka,vyska,destX,destY:word);
begin
 _Copy(@self,p,srcX,srcY,sirka,vyska,destX,destY);
end;

Procedure TBitmap.ResizeBtB2Box(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
begin
 _Resize(method,p,@self,srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys);
end;

Procedure TBitmap.ResizeBox2BtB(method:byte;p:PBitmap;srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys:word);
begin
 _Resize(method,@self,p,srcX,srcY,srcSir,srcVys,destX,destY,destSir,destVys);
end;




{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ SCREEN BITBLTS ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

Procedure TScreen.Col2Box(destX,destY,sirka,vyska:word;pixel:longint);assembler;
 var  bit:word;
      currentsir4:word;
      local_lineOffset:word;
      sirka_by:word;
      local_bypp:word;
 asm
     {
      ES:DI-videopamet
     }
     cmp Sirka,0;jz @done
     cmp Vyska,0;jz @done

     les di,self
     mov ax,[es:di+lineOffset];mov local_lineOffset,ax
     mov al,byte ptr [es:di+MapModel]
     mov ah,[es:di+ByPP]
     mov es,[es:di+SegVram]

     cmp al,model_unchained;jz @UNCHAINED
     cmp al,model_text     ;jz @TEXT

   @PACKED_AND_DIRECT:
      shr ax,8
      mov local_bypp,ax
      {prevede destX na bajty}
      mul destX
      mov destX,ax
      {spocita Sirka_by}
      mov ax,local_bypp
      mul sirka
      mov Sirka_by,ax
      {spocita cilovou adresu leveho horniho rohu a bankne}
      mov ax,destY
      mul local_lineOffset
      mov di,ax
      add di,destX
      adc dx,0
      push dx
      db 66h;push word ptr self;call vesa_SetBank

      mov dx,Vyska
      jmp @packed_nextseg

   @PACKED_IncBank:
      db 66h;push word ptr self;call vesa_IncBank
   @PACKED_NextSeg:
      {spocita do AX kolik radek muze kreslit bez bankingu, snizi Vyska}
      xor dx,dx
      mov ax,di
      neg ax
      sbb dx,-1
      div local_lineOffset
      cmp dx,Sirka_by
      sbb ax,-1
      sub Vyska,ax
      jnc @neni_posledni_blok
      add ax,Vyska
      mov Vyska,0
      @neni_posledni_blok:
      mov bx,ax{AX je potreba na pixel, proto obsah AX presouva do BX}
      db 66h;mov ax,word ptr pixel
      {kresli AX radek v jednom banku}
      @next_packed_line:
      dec bx
      js @ax_lines_done
      mov cx,Sirka
        {kresli: Sirka pixelu}
        {call REP_STOSB}
        call near ptr @StosCxPixels
      sub di,Sirka_by
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
      mov si,di
      add si,Sirka_by
      mov cx,di
      neg cx
        {kresli: cx=65536-di bajtu konce neuplnym pixelem}
        {prebankuje}
        {kresli: si=Sirka_by+old_di bajtu pocinaje neuplnym pixelem}
        {puvodni varianta pro pixel=byte:
         call REP_STOSB
         push ax
         db 66h;push word ptr self;call vesa_IncBank
         pop ax
         pop cx
         add cx,Sirka_by
         call REP_STOSB
        }
        {1}cmp local_bypp,1;jne @no1b
           call REP_STOSB
           call @IncBank
           call REP_STOSB
           jmp @donb;@no1b:
        {2}cmp local_bypp,2;jne @no2b
           shr cx,1;call REP_STOSW_no
           call @IncBank
           shr cx,1;call REP_STOSW_no
           jmp @donb;@no2b:
        {4}cmp local_bypp,4;jne @no4b
           shr cx,2;db 66h;rep stosw
           call @IncBank
           shr cx,2;db 66h;rep stosw
           jmp @donb;@no4b:
        {3}xchg ax,cx;xor dx,dx;div local_bypp;xchg ax,cx{cx=celych pixelu,dx=bajtu navic}
           db 66h;PUSH AX
           jcxz @skip1;call REP_STOS3_nz;@skip1:
           @loop31:dec dl;js @don31b;stosb;db 66h;ror ax,8;jmp @loop31;@don31b:
           call @IncBank
           xchg ax,cx;xor dx,dx;div local_bypp;xchg ax,cx{cx=celych pixelu,dx=bajtu navic}
           @loop32:dec dl;js @don32b;stosb;db 66h;ror ax,8;jmp @loop32;@don32b:
           db 66h;POP AX
           jcxz @skip2;call REP_STOS3_nz;@skip2:
           @don3b:
        @donb:
      pop di
      add di,local_lineOffset
      {nebyl-li tento radek posledni, pokracuje}
      dec Vyska
      jnz @packed_nextseg
      jmp @done

     @StosCxPixels:
      {1}cmp local_bypp,1;jne @no1;call REP_STOSB   ;retn;@no1:
      {2}cmp local_bypp,2;jne @no2;call REP_STOSW_no;retn;@no2:
      {4}cmp local_bypp,4;jne @no4;db 66h;rep stosw ;retn;@no4:
      {3}push dx;mov dl,byte ptr pixel+2;call REP_STOS_AX_DL_nz;pop dx;retn

     @IncBank:
      push ax
      db 66h;push word ptr self
      call vesa_IncBank
      pop ax
      mov cx,si
      retn

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


{---------------------------------------------------------------------------
 Zkopiruje BtB do na screenu, resi transparenci, resizing, mys.
  srcMap    - bitmapa z ktere kopirujes
  bkgMap    - virtualni obrazovka ze ktere se nacita pozadi
              pokud zadas nil, nacte se primo z fyzicke obrazovky,
              coz je na pomalych kartach pomalejsi
  mixingBuf - smesovaci buffer velikosti alespon destRect
              vsechny tri bitmapy musi mit stejny model
  srcRect   - odkud se kopiruje
  destRect  - kam se kopiruje
 ---------------------------------------------------------------------------}
Procedure TScreen.SuperResizeBtB2Box(method:byte;srcMap:PBitmap;bkgMap:PAbstractMap;mixingBuf:PBitmap;srcRect,destRect:TRect);
var   oldpen:byte;
      mys:boolean;
      r:TRect;
begin
 {copying}
 oldpen:=pen;
 pen:=PEN_VIRT_AREA;
 {skryti mysi jen je-li nutne}
 MouseGetRect(r);
 r.intersect(destRect);
 mys:=not r.Empty and MouseHide;
 if not srcMap^.transparent
  and (srcRect.b.x-srcRect.a.x=destRect.b.x-destRect.a.x)
  and (srcRect.b.y-srcRect.a.y=destRect.b.y-destRect.a.y) then begin
  {and (srcsize.x=destrect.b.x-destrect.a.x)
  and (srcsize.y=destrect.b.y-destrect.a.y) then begin}
   {copy flic do vramky}
   BtB2Box(srcMap,
     srcRect.a.x, srcRect.a.y, srcRect.b.x- srcRect.a.x, srcRect.b.y- srcRect.a.y,
     destRect.a.x,destRect.a.y)
   end
 else begin
   {pozadi do bufu}
   if srcMap^.transparent then begin
     if bkgMap=nil then bkgMap:=@self;
     bkgMap^.Box2BtB(mixingBuf,
      destRect.a.x,destRect.a.y,destRect.b.x-destRect.a.x,destRect.b.y-destRect.a.y,0,0);
     end;
   {resize directflic do bufu}
   {srcMap^.transparent:=transp;}
   mixingBuf^.ResizeBtB2Box(method,srcMap,
     srcRect.a.x, srcRect.a.y, srcRect.b.x-srcRect.a.x,
     srcRect.b.y-srcRect.a.y, 0,0,destRect.b.x-destRect.a.x,destRect.b.y-destRect.a.y);
   {buf do vramky}
   BtB2Box(mixingBuf,0,0,destRect.b.x-destRect.a.x,destRect.b.y-destRect.a.y,destRect.a.x,destRect.a.y);
   end;
 if mys then MouseShow;
 pen:=oldpen;
end;



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
 if not Search(KeyOf(Item),I) or Duplicates then begin
    AtInsert(I,Item);
    {$ifdef testvga}
    if item<>nil then
     with PResItem(item)^ do
      BiosWriteln('nalezen mod '+stri(amode)+' : '+stri(ax)+'x'+stri(ay)+'/'+stri(bipplist[amodel])+'('+stri(amodel)+')');
    {$endif}
    end
  {na rozdil od defaultniho insertu, co nezaradi, to killne}
  else begin
    {$ifdef testvga}
    if item<>nil then
     with PResItem(item)^ do
      BiosWriteln('(mod '+stri(amode)+' : '+stri(ax)+'x'+stri(ay)+'/'+stri(bipplist[amodel])+'('+stri(amodel)+') uz mam)');
    {$endif}
    KillObj(Item);
    end;
end;

function TResCollection.Compare(p1,p2:pointer):integer;
var   a,b,i:integer;
begin
 a:=PResItem(p1)^.ax+PResItem(p1)^.ay;
 b:=PResItem(p2)^.ax+PResItem(p2)^.ay;
 if a<>b then Compare:=ord(a>b)-ord(a<b) else begin
   a:=PResItem(p1)^.ax;
   b:=PResItem(p2)^.ax;
   if a<>b then Compare:=ord(a>b)-ord(a<b) else begin
     a:=PResItem(p1)^.amodel;
     b:=PResItem(p2)^.amodel;
     if a<>b then Compare:=ord(a>b)-ord(a<b) else begin
       Compare:=0;
       end;
     end;
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
  if bios_GetMode<>3 then lines:=400 else begin
    lines:=vga_GetScanlines div (vga_GetDoubleScan+1);
    if lines<150 then lines:=400;
    end;
  for i:=minCharYres to maxCharYres do begin
    Insert(New(PResItem,Init(model_text,80,lines div i,lines div i)));
    Insert(New(PResItem,Init(model_text,40,lines div i,lines div i+$1000)));
    end;
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
 Zde probiha i vyber modelu z mnoziny modelu zadanych parametrem.
 ---------------------------------------------------------------------------}
FUNCTION GetBestMode(mm,xx,yy:word):PResItem;
var   i,mza:word;
      d,mind:integer;
      found:boolean;

  procedure TestSimilarity(p:PResItem);far;
  begin
   with p^ do
    if ( (amodel=mm)
         or ((mm=model_8      ) and (amodel in models_8      ))
         or ((mm=model_15     ) and (amodel in models_15     ))
         or ((mm=model_16     ) and (amodel in models_16     ))
         or ((mm=model_24     ) and (amodel in models_24     ))
         or ((mm=model_32     ) and (amodel in models_32     ))
         or ((mm=model_hc     ) and (amodel in models_hc     ))
         or ((mm=model_tc     ) and (amodel in models_tc     ))
         or ((mm=model_direct ) and (amodel in models_direct ))
         or ((mm=model_gfx    ) and (amodel in models_gfx    ))
         or ((mm=model_scrol  ) and (amodel in models_scrol  ))
       ) then begin
           d:=0;
           if ax>xx then begin if higherSux=0 then exit;inc(d,higherSux*(ax-xx));end else
           if ax<xx then begin if  lowerSux=0 then exit;inc(d, lowerSux*(xx-ax));end;
           if ay>yy then begin if higherSux=0 then exit;inc(d,higherSux*(ay-yy));end else
           if ay<yy then begin if  lowerSux=0 then exit;inc(d, lowerSux*(yy-ay));end;
           case mm of
             model_8      :if amodel=model_unchained then inc(d);
             model_15,
             model_16,
             model_24,
             model_32     :;
             model_hc     :if BiPPlist[amodel]=15 then inc(d);
             model_tc     :if ByPPlist[amodel]=3 then inc(d);
             model_direct :inc(d,4-ByPPlist[amodel]+24-BiPPlist[amodel]);
             model_gfx    :begin
                           inc(d,4-ByPPlist[amodel]+24-BiPPlist[amodel]);
                           if amodel=model_unchained then inc(d);
                           end;
             model_scrol  :begin
                           inc(d,4-ByPPlist[amodel]+24-BiPPlist[amodel]);
                           if amodel=model_unchained then inc(d);
                           {odhadne jestli jde doublebufferin}
                           {1) predpoklada ze nebude pouzita lista}
                           if HiWord(longint(ax)*ay*ByPPlist[amodel]*9 div 4{+2.21})>=vesa_BanksTotal then inc(d,30);
                           {2) predpoklada ze je pouzita lista vysky zhruba 1/6 obrazovky}
                           if HiWord(longint(ax)*ay*ByPPlist[amodel]*33 div 16{+2.01})>=vesa_BanksTotal then inc(d,30);
                           {odhadne jestli jde splittin nebo wrappin}
                           if HiWord(longint(ax)*ay*ByPPlist[amodel]*5 div 4{+1.21})>=vesa_BanksTotal then inc(d,30);
                           {znevyhodni 8bit modely}
                           if (amodel in models_8) then inc(d,90);
                           end;
             end;
           {znevyhodni pametove neunosne modely}
           if ByPPlist[amodel]>maxByPP then inc(d,1000*(ByPPlist[amodel]-maxByPP));

           if d<mind then begin mind:=d;GetBestMode:=p;found:=true;end;
           end;
  end;

begin
 GetBestMode:=nil;
 found:=false;
 mind:=30000;
 mza:=mm and $ff00;{zadana mnozina modelu}
 mm:=mm and $00ff;{zadane presne cislo modelu}
 if (mm<>0) or (mza=0) then
   ResList.ForEach(@TestSimilarity);{nejdriv zkusi presny model}
 if (not found) and (mza<>0) then begin
   mm:=mza;
   ResList.ForEach(@TestSimilarity);{pote modely z mnoziny}
   end;
end;

{---------------------------------------------------------------------------
 Pri volani TScreen.Init zadavas ctyri parametry, viz o 50 radek niz.
 Dopredu nelze se 100% jistotou urcit ktery mod se pritom nastavi,
 ve hre je prilis mnoho faktoru.
 Ale pokud ti staci 99% jistota, zavolej tuto funkci se stejnymi parametry
 s jakymi budes volat Init a ona ti v nich vrati presne parametry modu.
 ---------------------------------------------------------------------------}
FUNCTION ModeDoplnInfo(var model:word;var sir,vys,mode:integer):boolean;
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
var bestmode:PResItem;
begin
 if mode=0 then begin
   bestmode:=GetBestMode(model,sir,vys);
   ModeDoplnInfo:=bestmode<>nil;
   if bestmode<>nil then
    with bestmode^ do begin
     mode:=amode;
     model:=amodel;
     sir:=ax;
     vys:=ay;
     end;
   end
 else begin
   ModeDoplnInfo:=false;
   ResList.FirstThat(@Matching);
   end;
end;

FUNCTION ModeSupported(mode:word):boolean;
begin
 ModeSupported:=GetResItem(mode)<>nil;
end;

FUNCTION Mode2Supported(model,mode:word):boolean;
begin
 Mode2Supported:=GetResItem2(model,mode)<>nil;
end;

{---------------------------------------------------------------------------
 Pri nenulovem newMode nastavi presne tento mod.
 V opacnem pripade vybere z ResListu nejblizsi rozliseni k newSir*newVys
 s modelem newModel.
 V InitResult vraci jak to dopadlo.

 Paleta, vramXres, setvis, split a obsah vram nemusi byt po nastaveni modu
 na defaultnich hodnotach. Treba jses-li v modu $101 a nechas nastavit
 mod $101, vsechna nastaveni i obraz ve videopameti zustanou beze zmen.
 Tomu lze zabranit pomoci forbid_alreadyset:=true.
 ---------------------------------------------------------------------------}
Constructor TScreen.Init(newModel,newSir,newVys,newMode:word);

  {Je-li dany mod uz nastaven, nemaze obrazovku ani nemeni split,setvis...
   zkopci atributy do selfu (zfalsovany init) a vrati true.}
  function _AlreadySet(tryModel,trySir,tryVys,tryMode:word):boolean;
  type Image = record  Link: Word; Data: record end; end;
       PImage=^Image;
  var  xpal:PPal;
  begin
   _AlreadySet:=false;
   if (CurScreen<>nil) and
      (not CurScreen^.forbid_alreadyset) and
      (CurScreen^.MapModel=tryModel) and
      ( ((tryMode<>0) and (CurScreen^.ModeID=tryMode)) or
        ((CurScreen^.Xres=trySir) and (CurScreen^.Yres=tryVys)) ) then
     begin
      if @self<>CurScreen then begin
        CurScreen^.MouseHide;
        inherited Init(tryModel,trySir,tryVys);
        {zkopiruje pouze TScreen z CurScreen do self}
        {prikaz self:=CurScreen^ by moh zkopirovat vic nez ma,
         a to sizeof(CurScreen^)}
        xpal:=pal;
        move(PImage(CurScreen)^.Data,PImage(@self)^.Data,sizeof(TScreen)-sizeof(TObject));
        pal:=xpal;
        PrevScreen:=CurScreen;
        CurScreen:=@self;
        {aby mel VLASTNI mousebitmap/mousebuffer}
        mouseBitmap:=nil;
        mouseBuffer:=nil;
        MouseSetPointer(nil,0,0,0,0);
        {natahne udaje cachovane v cfg}
        LoadCfg;
        end;
      InitResult:=alreadyset;
      _AlreadySet:=true;
     end;
  end;

  function _NewSet(tryModel,tryMode:word):boolean;
  var ResItem:PResItem;
  begin
   _NewSet:=false;
   {$ifdef testvga}bioswriteln('zkusim nastavit mod '+stri(trymode));{$endif}
   if SetMode(tryModel,tryMode) then begin
     {$ifdef testvga}bioswriteln('mod nastaven');{$endif}
     stopky.Start;
     {natahne udaje cachovane v reslistu}
     ResItem:=GetResItem2(tryModel,tryMode);
     if (ResItem<>nil) and ResItem^.optional then with ResItem^ do begin
       {vytazeni z reslistu}
       {$ifdef testvga}bioswriteln('udaje beru z cache');{$endif}
       retraceLen        :=aretracelen;
       s_irq2_enabled    :=as_irq2_enabled;
         {update irq2 state}
         ReadIrq2Enabled;
         aretraceLen     :=retracelen;
         as_irq2_enabled :=s_irq2_enabled;
       screenfreq        :=ascreenfreq;
       vesa_setvissyncuje:=avesasetvissyncuje;
       timerscrsync      :=atimerscrsync;
       if timerscrsync=0 then begin
         {$ifdef testvga}bioswriteln('detekuji tmrscrsync');{$endif}
         timerscrsync      :=DetectTmrScrSync;{timer detekovat posledni, zavisi na predchozich}
         atimerscrsync     :=timerscrsync;
         end;
       end
     else begin
       {detekce}
       {$ifdef testvga}bioswriteln('detekuji retracelen');{$endif}
       vga_DetectRetraceLen;
       s_irq2_enabled    :=irq2_enabled;
       {$ifdef testvga}bioswriteln('detekuji setvissync');{$endif}
       if VesaMode then vesa_DetectSetvisSync;
       {$ifdef testvga}bioswriteln('detekuji tmrscrsync');{$endif}
       timerscrsync      :=DetectTmrScrSync;{timer detekovat posledni, zavisi na predchozich}
       {ulozeni do reslistu}
       if ResItem<>nil then with ResItem^ do begin
         {$ifdef testvga}bioswriteln('udaje ukladam do cache');{$endif}
         optional          :=true;
         aretracelen       :=retraceLen;
         as_irq2_enabled   :=s_irq2_enabled;
         ascreenfreq       :=screenfreq;
         avesasetvissyncuje:=vesa_setvissyncuje;
         atimerscrsync     :=timerscrsync;
         end;
       end;
     {natahne udaje cachovane v cfg}
     LoadCfg;
     {velikost virtualni obrazovky nastavi co nejvetsi}
     if MapModel=model_unchained
      then vramXres  :=lineoffset*4 div ByPP
      else vramXres  :=lineoffset   div ByPP;
     vramYres  :=Bounded(longint(VramSizeKB)*1024 div (vramXres*ByPP),0,22222);
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
     {$ifdef testvga}bioswriteln('pripravuji mys');{$endif}
     mouseAdjustJump;
     {$ifdef testvga}bioswriteln('newset-setpointer');{$endif}
     mouseSetPointer(nil,0,0,0,0);
     {$ifdef testvga}bioswriteln('newset-setpos');{$endif}
     mouseSetPos(Xres div 2,Yres div 2);
     {$ifdef testvga}bioswriteln('newset-adjustspeed');{$endif}
     mouseAdjustSpeed;
     {uz znam rozmery, tak je nastavim do atributu abstractmap}
     ExpandFul(false);
     {aktivni jsem ted ja}
     CurScreen:=@self;
     InitResult:=newset;
     _NewSet:=true;
     {$ifdef testvga}bioswriteln('vse ok, mod lze pouzivat');{$endif}
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
    {$ifdef testvga}bioswriteln('chci mod '+stri(newmode));{$endif}
    if _AnySet(newModel,newSir,newVys,newMode) then exit;
   end
 else
   begin
    {$ifdef testvga}bioswriteln('chci '+stri(newsir)+'x'+stri(newvys)+'/mdl='+stri(newmodel));{$endif}
    while true do begin
     bestmode:=GetBestMode(newModel,newSir,newVys);
     if bestmode=nil then break;
     with bestmode^ do if _AnySet(amodel,ax,ay,amode) then begin
       if (ax<>Xres) or (ay<>Yres) then begin
         ResList.Delete(bestmode);
         ax:=Xres;
         ay:=Yres;
         amode:=amode-amode mod 128{stary pocet radek}+Yres{novy pocet radek};
         ResList.Insert(bestmode);
         end;
       exit;
       end;
     ResList.Free(bestmode);
     end;
   end;

 {mod nejde nastavit}
 if wasinited and (CurScreen<>nil)
  then InitResult:=stillold
  else InitResult:=chaos;
 Fail;
end;

{---------------------------------------------------------------------------
 Inicializuje funkce spojene s VESA BIOSem.
  -nastavi do vesa_BanksTotal pocet 64KB banku, pri nepritomnosti vesy 0
  -nastavi VesaVersion, pri nepritomnosti vesy 0
  -nastavi VesaID
  -do ResListu prida vesa mody
 Kdyz narazi na "stub" VBE, nastavi VesaID a vesa_BanksTotal, ale VesaVersion=0.
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

type
      tDirectModel=record
                    BPP1            : byte;  {BitsPerPixel}
                    RMS1           : byte;  {Red Mask Size}
                    RFP1           : byte;  {Red Field Position}
                    GMS1            : byte;  {Green Mask Size}
                    GFS1            : byte;  {Green Field Size}
                    BMS1            : byte;  {Blue Mask Size}
                    BFS1            : byte;  {Blue Field Size}
                    MModel1         : byte;  {Type of MemoryModel}
                   end;

const
      KnownDirectModels=10;

      DirectModels:array[1..KnownDirectModels] of tDirectModel=(
        (BPP1:15; RMS1:5; RFP1:10; GMS1:5; GFS1:5; BMS1:5; BFS1:0;  MModel1:model_BGR15),
        (BPP1:16; RMS1:5; RFP1:10; GMS1:5; GFS1:5; BMS1:5; BFS1:0;  MModel1:model_BGR15),
        (BPP1:15; RMS1:5; RFP1:0;  GMS1:5; GFS1:5; BMS1:5; BFS1:10; MModel1:model_RGB15),
        (BPP1:16; RMS1:5; RFP1:0;  GMS1:5; GFS1:5; BMS1:5; BFS1:10; MModel1:model_RGB15),

        (BPP1:16; RMS1:5; RFP1:11; GMS1:6; GFS1:5; BMS1:5; BFS1:0;  MModel1:model_BGR16),
        (BPP1:16; RMS1:5; RFP1:0;  GMS1:6; GFS1:5; BMS1:5; BFS1:11; MModel1:model_RGB16),

        (BPP1:24; RMS1:8; RFP1:16; GMS1:8; GFS1:8; BMS1:8; BFS1:0;  MModel1:model_BGR24),
        (BPP1:24; RMS1:8; RFP1:0;  GMS1:8; GFS1:8; BMS1:8; BFS1:16; MModel1:model_RGB24),

        (BPP1:32; RMS1:8; RFP1:16; GMS1:8; GFS1:8; BMS1:8; BFS1:0;  MModel1:model_BGRA32),
        (BPP1:32; RMS1:8; RFP1:0;  GMS1:8; GFS1:8; BMS1:8; BFS1:16; MModel1:model_RGBA32)
	);

var   VesaInfo:PVesaInfoBlock;
      ModeInfo:PModeInfoBlock;
      ModeInfoSeg:word;
      segment:word;
      {$ifdef dpmi}
      RealModeRegs:dpmiRealCallRegs;
      {$endif}

 procedure TestMode(mode:integer);
 var i:integer;
     m,x,y:word;
 begin
   {$ifdef testvga}
   BiosWrite(stri(mode)+' ');
   {$endif}
   if mode>=256{jen vesa mody} then
    if GetModeInfo(mode,ModeInfo,ModeInfoSeg) then
     if ModeInfoSupported(ModeInfo) then
      with ModeInfo^ do
       if (ModeAttributes and 2)>0 then begin
         {je k dispozici rozsirene info, nacte informace odtud}
         m:=MemoryModel;
         x:=XResolution;
         y:=YResolution;
         {jeste je potreba upresnit model}
         if (VesaVersion>=$102)
          and (MemoryModel in [model_packed, model_direct_]) then
                                              {model_packed - ARK Logic pouziva i pro Hi/TrueColor}
                                              {model_direct_ - Jedna se o HiColor nebo TrueColor}
           for i:=1 to KnownDirectModels do   {Zanalyzuj umisteni barevnych kanalu}
            with DirectModels[i] do
             if (BitsPerPixel=BPP1)           {Odpovida BitsPerPixel?}
               and (RMS=RMS1) and (RFP=RFP1)  {cervena}
               and (GMS=GMS1) and (GFS=GFS1)  {zelena}
               and (BMS=BMS1) and (BFS=BFS1)  {modra}
              then begin
                m:=MModel1;
                break;
                end;
         {pokud se podarilo upresnit model a je z podporovanych, da mod do reslistu}
         if BiPPlist[m]<>0
          then ResList.Insert(new(PResItem,Init(m,x,y,mode)));
         end
       else
         {neni rozsirene info, hleda informace v seznamu modu vesa 1.2}
         for i:=0 to ModesSupported-1 do
          with ModeInfoConst[i] do
           if VMode=mode then
            ResList.Insert(new(PResItem,Init(MModel,XSize,YSize,mode)));
 end;

 procedure Analyza;
 var   i:word;
       sz,sc,ss:string[70];
       app:string[20];
       limit:longint;
       modu0:word;
       pokusu:word;
 label nodpmierr;
 begin
  {$ifdef testvga}BiosWriteln('analyza vesainfo');{$endif}
  with vesainfo^ do
   if magic<>'VESA' then begin
     {neni tu}
     {$ifdef testvga}bioswriteln('Nesplnuje normu VBE2 ani nizsi, magic='+magic+'.');{$endif}
     VesaVersion:=0;
     vesa_BanksTotal:=0;
     VesaID:='NO VBE';
     end
    else begin
     {je tu}
     VesaVersion:=verze;
     vesa_BanksTotal:=MinW(totalmemory,256{16MB});
     {$ifdef dpmi}
     {$ifdef testvga}BiosWrite('NT risk: Seg2Desc ');{$endif}
     Seg2Desc(PtrRec(OEMStrPtr).Seg);
     Seg2Desc(PtrRec(VideoModePtr).Seg);
     Seg2Desc(PtrRec(ProductStrPtr).Seg);
     {$ifdef testvga}BiosWriteln('OK');{$endif}
     {$endif}
     VesaID:=Pc2Str(OEMStrPtr);
     {vykickuje duplicitni slova}
     sz:=VesaID;sc:=' '+Pc2Str(ProductStrPtr);
     while sz<>'' do begin
       ss:=CutString(sz,' ');
       if pos(ss,sc)=0 then sc:=sc+' '+ss;
       end;
     for i:=1 to length(VesaID) do
      if (VesaID[i]<' ') then VesaID[i]:=' ';
     app:=' ('+stri(vesa_BanksTotal*64)+')';
     if VideoModePtr^=-1 {"stub" vbe} then begin
       {$ifdef testvga}bioswriteln('Je to jen "stub VBE", je nutne nahrat plne VBE.');{$endif}
       VesaVersion:=0;
       if pos('stub',LoCased(VesaID))=0 then app:=app+' stub';
       end
     else begin
       {projde normalni modelist}
       {$ifdef testvga}BiosWriteln('---normalni modelist---');{$endif}
       while VideoModePtr^<>-1 do begin
         TestMode(VideoModePtr^);
         inc(VideoModePtr);
         end;
       {nektere biosy maji oem mody az za -1 na konci modelistu}
       {$ifdef testvga}BiosWriteln('---mody za modelistem---');{$endif}
       inc(VideoModePtr);
       inc(VideoModePtr);
       modu0:=ResList.count;
       pokusu:=0;
       {$ifdef dpmi}
       {v protektu musime hlidat abysme nehrabli mimo limit}
       limit:=PtrRec(VideoModePtr).Seg;
       asm
        mov ax,0bh
        mov bx,word ptr limit
        push ds
        pop es
        lea di,freeb
        int 31h
        jnc nodpmierr
       end;
       fillchar(freeb,8,0);
       nodpmierr:
       {spocita limit}
       limit:=MakeLong(freeb[6] and $f,freew[0]);
       {vezme v uvahu granularitu}
       if (freeb[6] and $80)>0 then limit:=limit*4096;
       {v 16bit me beztak vic nez 65535 nezajima, -1 protoze ctu po wordech}
       limit:=Bounded(limit-1,0,65534);
       {pokud nebude VBE mimoradne stupidni, zadny problem se segmenty
        rostoucimi dolu ((freeb[5] and $1c)=$14) nevznikne}
       {ted teda pracuje pouze pokud pointer neleze mimo limit}
       if PtrRec(VideoModePtr).Ofs<=limit then
       {$endif}
(* Nasledujici kod hleda mody neobsazene v modelistu.
   Snazi se to delat korektne, ale presto na nekterych kartach pada.
   Nemel jsem cas hledat proc.
        if not ModeSupported(VideoModePtr^) then
         if GetModeInfo(VideoModePtr^,ModeInfo,ModeInfoSeg) then
           while
            {aby nehrab za limit}
            {$ifdef dpmi}(PtrRec(VideoModePtr).Ofs<=limit) and{$endif}
            {aby nepokracoval za koncem}
            (VideoModePtr^<>-1) and
            {aby nezkoumal 32000 nahodnejch cisel, po 50 neuspesich konci}
            (pokusu+modu0-ResList.count<50)
           do begin
              TestMode(VideoModePtr^);
              inc(VideoModePtr);
              inc(pokusu);
              end;*)
       {co kdyz zapomneli dat std.mody do modelistu?}
       {$ifdef testvga}BiosWriteln('---zcela utajny mody---');{$endif}
       for i:=$100 to $11b do TestMode(i);
       {$ifdef testvga}BiosWriteln('---vga mody---');{$endif}
       end;
     VesaID:=copy(GetCore(VesaID),1,70-length(app))+app;
     end;
 end;

label freee;
Begin
 {nejprve nastavi neuspech}
 VesaVersion:=0;
 vesa_BanksTotal:=0;

 {naalokuje pamet pro vesainfo}
 {$ifdef testvga}BiosWrite('NT risk: GetMemDos ');{$endif}
 if not GetMemDos(segment,pointer(VesaInfo),sizeof(VesaInfo^)) then exit;
 {$ifdef testvga}BiosWriteln('OK');{$endif}
 fillchar(VesaInfo^,sizeof(VesaInfo^),0);
 vesainfo^.magic:='VBE2';

 asm mov ax,13h;int 10h             {WIN: prepne do fullscreenu!!}
     mov ax, 3h;int 10h;end;        {a zpet aby aplikace nekoncila v 13h}

 {do vesainfa necha nahrat informace o vese a otestuje si je}
 {$ifndef dpmi}
  asm
     mov ax,4f00h;les di,vesainfo   {nastavi parametry pro getvesainfo}
     int 10h                        {vola vesabios}
     cmp ax,4fh;jnz freee           {prvni test pritomnosti vesy}
  end;
 {$else}
  with RealModeRegs do begin
    ClrRegs(RealModeRegs);
    rEAX:=$4f00;
    rES:=Segment;
    {$ifdef testvga}BiosWrite('NT risk: dpmiRealModeInt ');{$endif}
    if erDumb(TError(dpmiRealModeInt($10,@RealModeRegs)))<>erOk then goto freee;
    {$ifdef testvga}BiosWrite('OK ');{$endif}
    {je sluzba vesa.getinfo podporovana ?}
    if LoWord(rEAX)<>$4f then goto freee;
    {$ifdef testvga}BiosWriteln('supported');{$endif}
    end;
 {$endif}

 {analyzuje ziskane udaje}
 ModeInfo:=nil;
 Analyza;
 LeaveModeInfo(ModeInfo);

 {uvolni pamet}
 freee:
 {$ifdef testvga}BiosWrite('NT risk: FreeMemDos ');{$endif}
 FreeMemDos(pointer(VesaInfo),sizeof(VesaInfo^));
 {$ifdef testvga}BiosWriteln('OK');{$endif}
End;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞CMDLINE RESLIST HOLOCAUST∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}
{
 +bits        lets only models with this # of bits per pixel
  bits        lets only -"-
 -bits        removes   -"-
               where "4 bits" is textmode
 AxisRelLimit lets only resolutions which pass this test, where
               Axis  is X or Y
               Rel   is one from
                         <
                         <=
                         =<
                         =
                         ==
                         !=
                         =>
                         >=
                         >
                         lt (Less Than)
                         eq (EQual to)
                         gt (Greater Than)
                         le (Less or Equal to)
                         ne (Not Equal to)
                         ge (Greater or Equal to)
               Limit is number of pixels (chars in textmode)

 Note that < and > symbols have special meaning (redirection) in DOS.
 If you want to use them in parameter, enclose whole parameter into ""
  (it works under MS-DOS 7.00, not yet tested elsewhere).
 Example: xlt800 "y<600"
}

Const ll=1;{Let Lower than this}
      le=2;{Let Equal to this}
      lh=4;{Let Higher than this}

Procedure FilterReslist(xy:char;let:byte;limi:word;onlybypp:byte);
var i:word;
    res:word;
begin
 with ResList do
  if Count>0 then
   for i:=Count-1 downto 0 do
    with PResItem(Items^[i])^ do
     if (onlybypp=0) or (ByPPlist[amodel]=onlybypp) then begin
       if xy in ['x','X'] then res:=ax else
        if xy in ['y','Y'] then res:=ay else
         continue;
       if (((let and ll)=0) and (res<limi))
       or (((let and le)=0) and (res=limi))
       or (((let and lh)=0) and (res>limi))
        then begin
         {$ifdef testvga}bioswriteln(' rkill '+stri(ax)+'x'+stri(ay)+'/mdl='+stri(amodel));{$endif}
         AtFree(i);
         end;
       end;
end;


 var   killvga,
       killvesa   :boolean;

Procedure CmdlinePass1;

 var   killed     :boolean;

 procedure initkill;
 begin
  killed  :=false;
  killvga :=false;
  killvesa:=false;
 end;

 procedure kill;
 begin
  if not killed then begin
    killvga :=true;
    killvesa:=true;
    killed:=true;
    end;
 end;

 var   i:word;
       st:string;
 label 1;
Begin
 InitKill;
 for i:=1 to paramcount do
  if not paramUsed[i] then begin
    st:=locased(paramstr(i));
    if st='vga' then begin kill;killvga:=false;end else
    if st='vesa' then begin kill;killvesa:=false;end else
    if st='novga' then killvga:=true else
    if st='novesa' then killvesa:=true else goto 1;
    paramUsed[i]:=true;
    1:
    end;
End;


Procedure CmdlinePass2;

 var   killed     :boolean;
       kill4,
       kill8,
       kill15,
       kill16,
       kill24,
       kill32     :boolean;

 procedure initkill;
 begin
  killed:=false;
  kill4 :=false;
  kill8 :=false;
  kill15:=false;
  kill16:=false;
  kill24:=false;
  kill32:=false;
 end;

 procedure kill;
 begin
  if not killed then begin
    kill4 :=true;
    kill8 :=true;
    kill15:=true;
    kill16:=true;
    kill24:=true;
    kill32:=true;
    killed:=true;
    end;
 end;

 procedure KillModels;
 var i:word;
 begin
  with ResList do
   if Count>0 then
    for i:=Count-1 downto 0 do
     with PResItem(Items^[i])^ do
      if
       ((amodel = model_text) and kill4 ) or
       ((amodel in models_8 ) and kill8 ) or
       ((amodel in models_15) and kill15) or
       ((amodel in models_16) and kill16) or
       ((amodel in models_24) and kill24) or
       ((amodel in models_32) and kill32)
       then begin
         {$ifdef testvga}bioswriteln(' mkill '+stri(ax)+'x'+stri(ay)+'/mdl='+stri(amodel));{$endif}
         AtFree(i);
         end;
 end;

 var   i,e:word;
       st:string;
       xy:char;
       limit:word;
 const eqs=15;
       eqa:array[1..eqs] of record s:string[2];let:byte;end=(
        (s:'==';let:   le   ),
        (s:'!=';let:ll+   lh),
        (s:'<=';let:ll+le   ),
        (s:'=<';let:ll+le   ),
        (s:'>=';let:   le+lh),
        (s:'=>';let:   le+lh),
        (s:'<' ;let:ll      ),
        (s:'=' ;let:   le   ),
        (s:'>' ;let:      lh),
        (s:'lt';let:ll      ),
        (s:'eq';let:   le   ),
        (s:'gt';let:      lh),
        (s:'le';let:ll+le   ),
        (s:'ne';let:ll+   lh),
        (s:'ge';let:   le+lh)
        );
 label 0,1;
Begin
 InitKill;
 {na voodoo3, banshee a bohuzel asi i na par jinejch kartach
  vyhodi ty mody co na voodoo3 padaj}
 if (VesaID='3dfx Interactive, Inc. (16384)')
 or (VesaID='3Dfx Interactive, Inc. (16384)') then begin
   FilterReslist('x',lh,320,1{8bit});
   FilterReslist('x',lh,320,2{15/16bit});
   FilterReslist('x',lh,640,3{24bit});
   end;
 for i:=1 to paramcount do
  if not paramUsed[i] then begin
    st:=locased(paramstr(i));
    case valu(st) of
      -4 :kill4 :=true;
      -8 :kill8 :=true;
      -15:kill15:=true;
      -16:kill16:=true;
      -24:kill24:=true;
      -32:kill32:=true;
      +4 :begin kill;kill4 :=false;end;
      +8 :begin kill;kill8 :=false;end;
      +15:begin kill;kill15:=false;end;
      +16:begin kill;kill16:=false;end;
      +24:begin kill;kill24:=false;end;
      +32:begin kill;kill32:=false;end;
      else begin
        if (st[1]='"') and (st[length(st)]='"') and (length(st)>=2)
         then st:=copy(st,2,length(st)-2);{strip ""}
        if (st[1] in ['x','y']) then begin
          xy:=CutChar(st);
          for e:=1 to eqs do
           with eqa[e] do
            if copy(st,1,length(s))=s then begin
              delete(st,1,length(s));
              limit:=valu(st);
              if limit<>0 then begin
                FilterReslist(xy,let,limit,0);
                goto 0;
                end;
              end;
          end;
        goto 1;
        end;
      end;
    0:
    paramUsed[i]:=true;
    1:
    end;
 KillModels;
End;

{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='vga';
var result:TError;
    OldShutDown:procedure;

procedure ShutDown;far;
 begin
  ShutDownInts:=OldShutDown;
  {vynilovat abychom pozdeji mohli mov ax,3;int 10h a nikdo si nestezoval}
  CurScreen:=nil;
 end;

procedure UserInit;
 begin
  irq2_enabled     :=false;
  mouseSpeed       :=mouseSpeedAvg;
  mouseSize        :=mouseSizeAvg;
  debugpal         :=false;
  CurScreen        :=nil;
  UserFont         :=nil;
  _LoadDiskFont    :=nil;
  badretrace[false]:=false;
  badretrace[true] :=false;
  userDirty        :=true;
  higherSux        :=1;
  lowerSux         :=3;
  nextPal          :=nil;
  updateHead       :=0;
  updateAll        :=255;
  maxByPP          :=4;
  retrace_clock    :=ptr(Seg0040,$6c);
  OldShutDown      :=ShutDownInts;
  ShutDownInts     :=ShutDown;
  fromlastevent.Start;
  New(updateRect);
  if onepixmap.init(model_bgra32,1,1) then begin
    onepixmap.StaticMem(@onepix,4);
    if ResList.Init(100,100) then begin
      CmdlinePass1;
      if not killvesa then InitVesa;{nejdriv nahraje vesa mody}
      if not killvga then InitVga; {pak uz pridava jen ty vga mody, ktere vesa neumi}
      CmdlinePass2;
      exit;
      end;
    end;
  result:=erLowMem;
 end;

procedure UserDone;
 begin
  ResList.Done;
  onepixmap.Done;
  Dispose(updateRect);
  {if CurScreen<>nil then CurScreen^.Done;
   Ac by to vypadalo logicky, prikaz na minule radce nemuzeme provest.
   Proc? Protoze pri chybe prepne unita chyby do textmodu, vypise hlasku
   a az potom zavola mimo jine i tuto proceduru. Mohli bychom ho dat do
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