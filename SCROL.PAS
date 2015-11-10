{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.50ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Scrol;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects,Strings, Cache,Sys,Mys,Key,Vga,Fonty,Stringy,INI{$ifdef timer},Timer{$endif};
Function  Init:word;
Procedure Done;

{

===========================================================================
                          Co tato unita umi
===========================================================================

 Obsahem unity je objekt TScrolScreen - potomek TScreen z unity Vga.
 TScrolScreen je opet obrazovka, tentokrat ale obohacena o jednu az dve
 bitmapy. Nad jednou z nich se scrolluje, volitelna druha je pevna lista dole.
 Tento layout vychazi z hardwarovych moznosti VGA karet, cilem bylo aby slo
 ve vetsine pripadu scrollovat hardwarove, zmenou registru.
 Prace s TScrolScreen vypada priblizne takto:

   Init              - nastaveni modu
   MapInit           - predani vyse zminovanych bitmap
   MapRedraw         - prekresleni obrazovky
   SetActivity       - zapnuti vybranych aktivit
   repeat
    Sync             - synchronizace (zde je postarano o scrolling)
    GetEvent         - prijimani eventu
    reakce na eventy
   until konec
   SetActivity       - vypnuti aktivit (nepovinne)
   MapDone           - zruseni bitmap (nepovinne)
   Done              - navrat do predchoziho modu

 SetActivity nastavuje jake aktivity maji byt provadeny "na pozadi"
 (provadeny castecne pomoci timeru, castecne volanim Sync).
 Aktivity jsou:

   syncTimer         - k lepsi synchronizaci pouzit timer
   syncMoving        - scrollovat
   syncDrawing       - dokreslovat o co se odscrollovalo
   syncAutoscrol     - mys u kraje obrazovky vytvari pozadavek na scrolling
   syncMHandler      - k rychlejsi praci s mysi pouzit handler
   syncMouse         - zobrazovat mys
   syncEmulMouse     - emulovat mys pomoci numericke klavesnice
   syncKScrol        - sipky/pgup/dwn/home/end generuji pozadavky na scrolling
   syncKHandler      - pouzit keyboard handler (nutne k syncKScrol,syncEmulMouse)

   syncAll           - zapne/vypne vse krome handleru
   syncHolocaust     - vypne vse vcetne handleru, volat pred shellem do dosu


 Dulezity vyznam ziskava atribut pen zdedeny z TScreen. Rika jestli jsou
 souradnice vztazeny k obrazovce (PEN_SCREEN), k videopameti (PEN_VRAM),
 k virtualni videopameti (PEN_VIRTUAL) nebo k bitmape nad kterou se
 scrolluje (PEN_VIT_AREA). Takze ma vyznam pro vsechny bitmapove operace
 s obrazovkou, pro GetEvent a pro GotoXY.
 Po Initu je nastaven na PEN_VRAM, po MapInitu na PEN_VIRT_AREA.


===========================================================================
                       Jak tato unita pracuje
===========================================================================


Slovnicek:

 Wrappingem rozumim to, ze od urcite adresy videopameti se zacina zobrazovat
 opet od nuly. Idealni by bylo, kdyby obraz wrapoval az na konci videopameti
 nebo se to dalo nastavit. Skutecnost je takova, ze nekdy wrapuje po 64KB
 (vetsina karet ve Vga packed), nekdy na 256KB (vetsina karet ve Vga unchained),
 nekdy na 512KB (muj Trident v lowres256 vesa modech a 16color vesa modech),
 nekdy newrapuje ani na konci videopameti (muj byvaly Tseng).

 Splitscreen je hardwarove deleni obrazovky na dve okna, s hornim jde
 scrollovat, dolni je staticke. Je to funkce VGA karty (line compare
 registr), ve vesa modech nemusi fungovat.


---------------------------------------------------------------------------
                          Pouzite metody
---------------------------------------------------------------------------

  MOVSD
   scrol do vsech smeru zajistuje movsd (fyzicke kopirovani)

  SPLITTINg
   vyuziva splitscreen k jakesi emulaci wrappingu,
   data poklada na radek (chciradek mod maxradku),
   (vylucuje se s: scrol do stran, lista)

  WRAPPINg
   vyuziva toho ze obraz wrapuje na urcite hranici,
   data poklada do banku (chcibank mod maxbanku)
   (vylucuje se s: lista)

  DOUBLEBUFFERINg
   vyuziva dostatku videopameti pro dvojity buffer,
   vetsinu dat zapisuje dvakrat,
   (vylucuje se s: lista nelze-li splitovat)

   Ulozeni bitmapy ve videopameti pri doublebufferingu (po radkach):

                0 -
                  ≥   botYres radek - lista na spodnim okraji obrazovky
     buflineFirst -
                  ≥   prvni buffer
                  ≥   buflines radek
                  ≥   pouze v tomto useku se pohybuje disp.addr.start
                  ≥
                  -
                  ≥   druhy buffer - kopie zacatku prvniho bufferu
                  ≥   topYres radek
     blizko konce -
     dostupne videopameti, ta muze koncit uprostred radku


---------------------------------------------------------------------------
                          Vadne karty a biosy
---------------------------------------------------------------------------

Jsme jen lidi a delame chyby. Autori grafickych karet a jejich biosu
maji obzvlast velkou fantazii a do svych dilek komponuji neslychane
bugance. Tato unita se tvari jako by se nic nedelo, jako by bylo vsechno
v poradku. Ale uvnitr svadi tvrdy zapas, kazdy detail musi overit,
na nic nemuze spolehat, karta rekne X, unita musi udaj overit z nezavislych
zdroju. To zahrnuje i spolupraci s uzivatelem, interaktivni testy.
Jednou zdetekovane udaje si muzes ulozit (VgaVars do INI souboru).

Seznam vsech chyb ktere znam (Dement's VBE buglist), vysel v Imphobii #13.
S drtivou vetsinou chyb tato unita pocita.

Unita scrol predstavuje dva roky tvrde prace. Mela by fungovat i na vetsine
vadnych karet a biosu, ale zarucit to samozrejme nemuzu. Kdyz narazis
na nejakou situaci ve ktere nefunguje jak by mela, dej mi vedet.

}

const
      {scrolling/timer}
      syncTimerOn      = 1;
      syncTimerOff     = 2;
      syncMovingOn     = 4;
      syncMovingOff    = 8;
      syncDrawingOn    = 16;
      syncDrawingOff   = 32;
      syncAutoscrolOn  = 64;
      syncAutoscrolOff = 128;
      {mys}
      syncMHandlerOn   = 256;
      syncMHandlerOff  = 512;
      syncMouseOn      = 1024;
      syncMouseOff     = 2048;
      {klavesnice}
      syncEmulMouseOn  = 4096;
      syncEmulMouseOff = 8192;
      syncKScrolOn     = 16384;
      syncKScrolOff    = 32768;
      syncKHandlerOn   = $10000;
      syncKHandlerOff  = $20000;
      {zkratky}
      syncAllOn        = 1+4+16+64+1024+4096+16384;{vse krome handleru}
      syncAllOff       = 2*syncAllOn;
      syncLetsRock     = syncAllOn+syncMHandlerOn+syncKHandlerOn;{vse vcetne handleru}
      syncHolocaust    = 2*syncLetsRock;{vypne vse, volat pred dos shellem}
var
      AutoscrolSpeed   :byte;
      CitlivostSipek   :byte;
      CitlivostNumpadu :byte;
      usetimer         :boolean;{smi pouzivat timer k synchronizaci?}
      SafeMode         :boolean;{nouzovy bezpecny mod (movsd+notimer)}
type
      PScrolScreen=^TScrolScreen;

      TAct=longint;
      TSpocitej=procedure(s:PScrolScreen);
      TScrolMethod=(movsd,splittin,wrappin,doublebufferin);

      TScrolScreen=object(TScreen)

         {nastaveni modu}
          reinitSpeed        :integer;{jak rychle se ma pri reinitu rozsvitit paleta}
          constructor        Init(newModel:byte;newSir,newVys,newMode:word);
          procedure          ReInit;virtual;
          destructor         Done;virtual;

         {hlavni bitmapa}
         public
          map                :PBitmap;{bitmapa nad kterou se scrolluje}
          mapsleep           :string[30];{buffer pro ukladani nekterych atributu map kdyz je nutno map docasne zrusit}
          procedure          MapInit(amap,alista:PBitmap;startX,startY:integer);
          procedure          MapRedraw;
          procedure          MapRedrawBox(srcX,srcY,Sirka,Vyska:integer);
          procedure          MapDone;

         {lista}
         public
          lista              :PBitmap;{bitmapa na liste}
          topYres            :integer;{vyska pohyblive obrazovky nad listou (v pixelech nebo znacich)}
          botYres            :integer;{vyska pevne listy dole (v pixelech nebo znacich)}
          procedure          ListaRedraw;
          procedure          ListaRedrawBox(srcX,srcY,Sirka,Vyska:integer);

         {testy parametru karty}
                             private
                              Splitting          :shortint;{lze pouzivat split = mit dole listu ? 1=lze, 0=nelze, -1=nevim}
                              SetvisStepX        :shortint;{po kolika pixelech lze menit disp.addr.start v ose x ?, 0=nelze,
                                                            -1=nevim, 8=jde po 8 a mozna i min, viz hruba detekce SetvisStepX}
                              VirtXStep          :shortint;{po kolika pixelech lze menit virt Xres ?, 0=nelze, -1=nevim}
                              WrappingAt         :shortint;{po kolika 64KB segmentech obraz wrapuje, 0=nikdy, -1=nevim}
                              PanUpBug           :shortint;{odchylka v casovani PanUpu?, 1=Tseng-like, 0=standard, -1=nevim}
                              PanLeftBug         :shortint;{odchylka v casovani PanLeftu?, 1=mach64-like, 0=standard, -1=nevim}
                              function           GetNeededTests(test:word;forcetest:word):word;
                              function           MatchingCfg:word;
                              procedure          SaveCfg;
                              procedure          LoadCfgOf(toVesamode:boolean;toModel:byte);
                              procedure          LoadCfg;virtual;
                              procedure          TestVga(test,forcetest:word);
                             public

         {scrolling/sync}
          posNow             :TPoint; {posledni pozice nad bitmapou (PEN_VIRTUAL) v pixelech}
          posCil             :TPoint; {vzdalena cilova pozice nad bitmapou v pixelech}
          posOk              :boolean;{je pozice posNow platna? (neni behem prekreslovani a v dobe kdy uz je
                                       zapsano do registru ale jeste se to nestacilo projevit na obrazovce)}
          userSpocitej       :TSpocitej;{uzivatelska procedura rikajici KAM se bude scrollovat}
          userSync           :Procedure;{uzivatelska procedura volana pri syncu vzdy}

          function           GetActivity:TAct;
          procedure          SetActivity(act:TAct);
          procedure          SwapMoving(var move:boolean);virtual;
          procedure          Sync;virtual;

                             private
                              posNext          :TPoint; {pristi pozice nad bitmapou (PEN_VIRTUAL) v pixelech}
                              speedX,speedY    :integer;{rychlost scrolu (kvuli setrvacnosti)}
                              syncDrawing      :boolean;{dela sync prubezne dokreslovani bitmapy ?}
                              syncMoving       :boolean;{dela sync setvis ?}
                              syncAutoScrol    :boolean;{zpusobuje mys u kraje obrazu scrol danym smerem ?}
                              syncEmulMouse    :boolean;{emului prave mys numpadem?}
                              syncKScrol       :boolean;{ovladaji sipky scrolling?}
                              toPanLeft        :byte;
                              toPanUp          :byte;
                              toSetvisHi       :word;
                              toSplitY         :word;
                              toVesaX          :word;
                              toVesaY          :word;
                              procedure        PrepSetvisRegisters(x,y:word);
                              procedure        ScrolSetvis;
                             public

         {eventy}
          function           GetEvent(var event:TEvent;var pos:TPoint):boolean;virtual;
                             private
                              mouseEmulZ       :integer;
                              procedure        KeyboardRescan;virtual;
                             public

         {bitblts}
          procedure          Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);virtual;
          procedure          BtB2Box(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;
          procedure          Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);virtual;

         {paleta}
          procedure          Fade(time:integer);virtual;
          procedure          SyncPal;virtual;

         {kurzor}
          procedure          GotoXY(x,y:integer);virtual;

         {mys}
          procedure          MouseGetRect(var rect:TRect);virtual;

         {crashe do sten}
          function           GetCrashLevel:word;

                             private
                              crashLevel       :word;{sila narazu okraje bitmapy na okraj obrazovky}
                             public

         {scrolbuffer}
          function           GetDebugInfo(n:byte):string;
          procedure          GetClipping(var rect:TRect);virtual;

                             private
                              scrolMethod      :TscrolMethod;{metoda pouzita pro scrolling v tomto modu}
                              freePred         :integer;{kolik pixelu/znaku volneho mista je na obrazovce}
                              freeZa           :integer; {pred a za bitmapou}
                              freeNad          :integer;
                              freePod          :integer;
                              writtenTop       :integer;{prvni z momentalne vykreslenych linek (PEN_VIRTUAL)}
                              writtenBot       :integer;{posledni z momentalne vykreslenych linek (PEN_VIRTUAL)}
                              writtenLeft      :integer;{nejlevejsi vykresleny pixel/znak (PEN_VIRTUAL)}
                              writtenRight     :integer;{nejpravejsi vykresleny pixel/znak (PEN_VIRTUAL)}
                              buflineFirst     :integer;{prvni linka bufferu}
                              buflines         :integer;
                              bufmaxrezervaX   :integer;
                              bufmaxrezervaY   :integer;
                              procedure        Dokreslit(var dx,dy:integer);
                              procedure        Dokresli(dx,dy:integer);
                             public

         {timer}
          function           TimerAllRight:boolean;
          function           DetectTmrScrSync:word;virtual;
          procedure          SetUseTimer(use:boolean);

                             private
                              phase            :byte;{ktera faze setvisu je na rade?}
                              function         posWantsFreshup:boolean;
                              procedure        SetvisPhase1;
                              procedure        SetvisPhase2;
                              procedure        SetvisPhase3;
                              procedure        SetvisPhase4;
                              procedure        TmrScrolStart;
                              procedure        TmrScrolStop;
                              procedure        SyncSpocitej;{spocita kam se ma scrollovat}
                              procedure        SyncDokresli;{dokresli kus bitmapy o ktery se odscrollovalo}
         end;

var   CurScrolScreen  :PScrolScreen;{defaultni scrolpage se kterou pracuji vsechny ostatni rutiny}

PROCEDURE VgaVars;
FUNCTION  TimeFromLastEvent:longint;

{co vsechno testovat pri nastaveni modu?}
const
      t_Splitting        =1;
      t_SetvisStepX      =2;      {hruby test zda vubec setvis jde (zkousi to po 16 pixelech)}
      t_SetvisStepXp     =4;      {jemny test po kolika pixelech to jde}
      t_SetvisYBug       =8;
      t_VirtXStep        =16;
      t_WrappingAt       =32;
      t_GotoYBug         =64;
      t_PanUpBug         =128;
      t_PanLeftBug       =256;
      t_all              =1+2+8+16+32+64+128+256;{kdyz chces nechat otestovat vsechno dulezite}
var
      t_test             :word;   {parametry s jakymi vola TestVga}
      t_forcetest        :word;   {jsou souctem konstant t_XXXX}
                                  {muzes nastavit co vsechno testovat}
                                  {viz komentar k TestVga}

{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


const
      autoscrolprocent   =15;{kolik procent rozmeru vyrezu pro pohyb mysi
                             tvori okraj pro autoscrol}
var
      wanttimer          :boolean;{chce pouzit timer k synchronizaci? (nezavisi na tom jestli smi)}
      usingtimer         :boolean;{je prave pouzit timer k synchronizaci? (az kdyz chce+smi+dalsi_podminky)}

      backstack          :pointer;{pointer na zalozni stack (1KB)}



{---------------------------------------------------------------------------
 Nastavi scrolmod pro scrol nad libovolne velkou bitmapou.
 Po nastaveni je cerna paleta.
 ---------------------------------------------------------------------------}
Constructor TScrolScreen.Init(newModel:byte;newSir,newVys,newMode:word);
begin
{$ifdef beta}
 if wanttimer then erBetaMsg('scrol.init: minuly mod neuvolnil timer');
{$endif}

 if not inherited Init(newModel,newSir,newVys,newMode) then Fail;
 if newModel<>model_text then BlackHwPal;

 {zakaze scrol spodni pulky obrazu ve splitscreenu}
 vga_EnableSplitScrol(false);

 {ful=cela vramka}
 ExpandFul(true);

 {otestuje parametry karty}
 if not safemode then TestVga(t_test,t_forcetest);

 {poznamena si stranku nad kterou scrolluje}
 CurScrolScreen:=@self;
end;

{---------------------------------------------------------------------------
 Reinicializuje mod.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.ReInit;
begin
 if pointer(CurScreen)<>@self then begin
 {kdyby tu^^^ bylo CurScrolScreen, selhal by v pripade ze po scrolscreene
  byla nastavena obyc screen a v CurScrolScreen zustal neaktualni udaj}
   inherited ReInit;
   vga_EnableSplitScrol(false);
   {CurScrolScreen nastavit jeste pred setvisem, ktery ji vyuziva (v tmrScrol1/2/3)}
   CurScrolScreen:=@self;
   if map<>nil then begin
     {zacerni paletu behem prekreslovani}
     {rychlejsi by bylo vypnout paprsek, ale tohle je kompatibilnejsi}
     if map^.MainPal<>nil then BlackHwPal;
     MapRedraw;
     if (map^.MainPal<>nil) and (reinitSpeed>=0) then map^.Fade(+reinitSpeed);
     reinitSpeed:=0;
     end;
   ListaRedraw;
   end;
end;

{---------------------------------------------------------------------------
 Ukonci praci s modem a vrati se do predchoziho.
 ---------------------------------------------------------------------------}
Destructor TScrolScreen.Done;
begin
 MapDone;
 inherited Done;
 if CurScreen=nil then CurScrolScreen:=nil;
end;

{---------------------------------------------------------------------------
 Vraci silu posledniho narazu okraje bitmapy na okraj obrazovky.
 ---------------------------------------------------------------------------}
Function TScrolScreen.GetCrashLevel:word;
begin
 GetCrashLevel:=CrashLevel;
 CrashLevel:=0;
end;

{---------------------------------------------------------------------------
 Je-li time>0, behem time snimku rozsviti obraz (paletu),
 v opacnem pripade behem -time snimku ztmavi.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.Fade(time:integer);
begin
 if (map=nil) or (map^.MainPal=nil) then inherited Fade(time)
  else map^.Fade(time);
end;

{---------------------------------------------------------------------------
 Synchronizuje paletu tak, aby odpovidala poloze do ktere se zrovna
 doscrollovalo.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.SyncPal;
var   scrwin:TRect;
begin
 if map<>nil then
  with map^ do
   if MainPal<>nil then begin
    scrwin.Assign(posNext.X,posNext.Y,posNext.X+Xres,posNext.Y+topYres);
    map^.SyncPal(scrwin,MainPal^.nowbright>0);
    end;
end;


{€€€€€€€€€€€€€€€€ B U F F E R €€€€€€€€€€€€€€€€}

{---------------------------------------------------------------------------
 Do rect nastavi jaky vyrez bitmapy je skutecne ve videopameti.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.GetClipping(var rect:TRect);
begin
 rect.a.x:=writtenLeft;
 rect.a.y:=writtenTop;
 rect.b.x:=writtenRight+1;
 rect.b.y:=writtenBot+1;
end;

{---------------------------------------------------------------------------
 Vraci ve stringu nejake debugovaci informace.
 ---------------------------------------------------------------------------}
Function TScrolScreen.GetDebugInfo(n:byte):string;

const stri_boolean:array[false..true] of string[3]=('no','yez');
      stri_method:array[movsd..doublebufferin] of string[8]=('movsd','splittin','wrappin','bufferin');
      stri_model:array[model_text..model_yuv] of string[9]=('text','cga','hercules','ega','packed','unchained','direct','yuv');
begin
 case n of
   1:GetDebugInfo:='VRAM INFOORMA'#13#10+
       #13#10'vesamode='      +stri_boolean[VesaMode]+
       #13#10'model='         +stri_model[MapModel]+
       #13#10'method='        +stri_method[scrolmethod]+
       #13#10'SCREEN='        +stri(Xres)+'x'+stri(Yres)+
       #13#10'VRAM='          +stri(sizeX)+'x'+stri(sizeY)+
       #13#10'VIRTUAL='       +stri(map^.sizeX)+'x'+stri(map^.sizeY)+
       #13#10'doublescan='    +stri(doublescan)+
       #13#10'nowsplit='      +stri(nowsplity)+
       #13#10'maxsplit='      +stri(maxsplity);
   2:GetDebugInfo:='TIMING INFOORMA'#13#10+
       #13#10'eventwaitOk='   +stri_boolean[EventWaitOk]+
       #13#10'retracelen='    +stri(retracelen)+
       #13#10'vesasetvissync='+stri_boolean[vesasetvissyncuje]+
       #13#10'screenfreq='    +stri(screenfreq)+
       #13#10'tmrscrsync='    +stri(timerscrsync)+
       #13#10'usetimer='      +stri_boolean[usetimer]+
       #13#10'wanttimer='     +stri_boolean[wanttimer]+
       #13#10'usingtimer='    +stri_boolean[usingtimer];
   3:GetDebugInfo:='HW SCROL INFOORMA'#13#10+
       #13#10'splitting='     +stri(splitting)+
       #13#10'setvisstepx='   +stri(setvisstepx)+
       #13#10'setvisybug='    +stri(setvisybug)+
       #13#10'virtxstep='     +stri(virtxstep)+
       #13#10'wrappingat='    +stri(wrappingat)+
       #13#10'gotoybug='      +stri(gotoybug)+
       #13#10'panupbug='      +stri(panupbug)+
       #13#10'panleftbug='    +stri(panleftbug);
   4:GetDebugInfo:='BUFFER INFOORMA'#13#10+
       #13#10'buflinefirst='  +stri(buflinefirst)+
       #13#10'buflines='      +stri(buflines)+
       #13#10'bufmaxrezervaX='+stri(bufmaxrezervaX)+
       #13#10'bufmaxrezervaY='+stri(bufmaxrezervaY);
   5:GetDebugInfo:='SYSTEM INFOORMA'#13#10+
       #13#10'os='            +Pc2Str(os[ops])+
       #13#10'memavail='      +stri(memavail)+
       #13#10'maxavail='      +stri(maxavail);
   else
     GetDebugInfo:='';
   end;
end;


{---------------------------------------------------------------------------
 Prekresli cast listy.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.ListaRedrawBox(srcX,srcY,Sirka,Vyska:integer);
var   destX:integer;
      oldpen:byte;
begin
 if lista<>nil then begin
   destX:=(Xres-sirka) div 2+srcX;
   if destX<0 then begin
     inc(sirka,destX);
     dec(srcX,destx);
     destX:=0;
     end;
   if sirka>0 then begin
     oldpen:=pen;
     pen:=PEN_SCREEN;
     BtB2Box(lista,srcx,0,sirka,lista^.sizeY,destx,topYres);
     pen:=oldpen;
     end;
   end;
end;

{---------------------------------------------------------------------------
 Prekresli celou listu.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.ListaRedraw;
begin
 if lista<>nil then ListaRedrawBox(0,0,lista^.sizeX,lista^.sizeY);
end;

{---------------------------------------------------------------------------
 Prijme mapu a volitelne listu a prizpusobi se jim.
 Pozor, lista nekdy vyrazne hodne zhorsi scrolling.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.MapInit(amap,alista:PBitmap;startX,startY:integer);
var   usefulX,usefulY:word;

 function mySetVramXRes(usefulX:word):boolean;
 begin
  if SetVramXRes(usefulX) then begin
    mySetVramXRes:=true;
    usefulX:=vramXres;{upravi usefulX aby nemusel opakovane setvramxresovat}
    end
   else
    mySetVramXRes:=false;
 end;

 function TryWrappin:boolean;
 begin
  TryWrappin:=
    {kdyz funguje wrapping}
    (VramSizeKB=WrappingAt*64) and
    {a neni v textmodu}
    ((MapModel<>model_text)) and
    {a funguje setvis}
    ((setvisStepX>0)) and
    {a nechci listu}
    ((botYres=0)) and
    {a vypada to ze bude dost vram}
    ((longint(VramSizeKB)*1024>=longint(usefulX)*usefulY)) and
    {a jde nastavit vramXres}
    ((usefulX=vramXres) or ((virtXstep>0) and mySetVramXRes(usefulX))) and
    {a porad je dost vram}
    ((vramYres>=usefulY));
 end;

 function TrySplittin:boolean;
 begin
  TrySplittin:=
    {kdyz funguje splitting}
    (splitting=1) and
    {a neni v textmodu}
    (MapModel<>model_text) and
    {a funguje setvis}
    (setvisStepX>0) and
    {a nechci listu}
    (botYres=0) and
    {a nechci scrollovat do stran}
    (amap^.sizeX<=Xres) and
    {a jde nastavit vramXres}
    ((usefulX=vramXres) or ((virtXstep>0) and mySetVramXRes(usefulX))) and
    {a je dost vram}
    (vramYres>=usefulY);
 end;

 function TryBufferin(lines:word):boolean;
 begin
  TryBufferin:=
    {a funguje setvis}
    (setvisStepX>0) and
    {a dokazu zaridit pripadnou listu}
    ((botYres=0) or (splitting>0)) and
    {a vypada to ze bude dost vram}
    (longint(VramSizeKB)*1024>=longint(usefulX)*lines) and
    {a jde nastavit vramXres}
    ((usefulX=vramXres) or ((virtXstep>0) and mySetVramXRes(usefulX))) and
    {a porad je dost vram}
    (vramYres>=lines);
 end;

 function TrySingleBufferin:boolean;
 begin
  TrySingleBufferin:=
   {funguje jen bez listy}
   (botYres=0) and
   {a asi jen v grafice}
   (MapModel<>model_text) and
   TryBufferin(maxI(topYres,amap^.sizeY)+botYres);
 end;

 function TryDoubleBufferin:boolean;
 begin
  TryDoubleBufferin:=
   TryBufferin(usefulY+topYres +amap^.sizeX div usefulX);
                                {^odhad poctu radek, ktere zabere rezerva pro scrol doprava}
 end;

begin
 if alista=nil then botYres:=0 else botYres:=alista^.sizeY;
 topYres:=Yres-botYres;
 if amap=nil then erMsg('MapInit: ë†dn† bitmapa.');
 if topYres<=0 then erMsg('MapInit: p©°li® velk† li®ta.');

 {spocita minimalni vramXYres}
 usefulX:=maxI(   Xres,minI(   Xres*11 div 10,amap^.sizeX));
 usefulY:=maxI(topYres,minI(topYres*11 div 10,amap^.sizeY))+botYres;

 {volba metody}
 if SafeMode          then scrolmethod:=movsd else
 if TryWrappin        then scrolmethod:=wrappin else
 if TrySingleBufferin then begin scrolmethod:=wrappin;WrappingAt:=0;{nesmi byt -1}end else
 if TryDoubleBufferin then scrolmethod:=doublebufferin else
 if TrySplittin       then scrolmethod:=splittin
                      else scrolmethod:=movsd;

 {nastavi sizex,y aby 'ful' znamenalo celou videopamet, ne jen celou screenu}
 {behem volby metody se mohly rozmery zmenit}
 {v movsd nepotrebuje ful}
 ExpandFul(scrolmethod<>movsd);

 {zpracuje listu}
 lista:=alista;
 if scrolmethod=movsd
  then begin
   SplitY(maxSplitY);
   if (vramVisX<>0) or (vramVisY<>0) then Setvis(0,0);
   end
  else begin
   SplitY(maxSplitY-charYres*botYres);
   Setvis(0,charYres*botYres);
   end;
 ListaRedraw;

 {nastavi kdejake atributy}
 pen              :=PEN_VIRT_AREA;
 map              :=amap;
 if scrolMethod=movsd
  then buflineFirst:=0
  else buflineFirst:=botYres;
 buflines         :=vramYres-buflineFirst;
 if scrolMethod=doublebufferin
  then dec(buflines,topYres +amap^.sizeX div usefulX{presne urceni});
 writtenTop       :=startY;
 writtenBot       :=startY-1;
 writtenLeft      :=startX;
 writtenRight     :=startX-1;
 bufmaxrezervaY   :=(buflines-topYres) div 2;
 bufmaxrezervaX   :=(vramXres-Xres) div 2;

 freePred         :=MaxI(0,   Xres-map^.sizeX) div 2;
 freeNad          :=MaxI(0,topYres-map^.sizeY) div 2;
 freeZa           :=   Xres-map^.sizeX-freePred;
 freePod          :=topYres-map^.sizeY-freeNad;

 posNow.X         :=writtenLeft*charXres;
 posNow.Y         :=writtenTop*charYres;
 posNext          :=posNow;
 posCil           :=posNow;
 posOk            :=false;   {obraz zatim nedefinovan}
end;

{---------------------------------------------------------------------------
 Zahodi mapu a listu.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.MapDone;
begin
 if not SilentDone then SetActivity(syncAllOff);
 caLeave(map);
 caLeave(lista);
end;

{$define clr}
{$i sbit2scr.inc}
{$undef clr}
{$define smer1}
{$i sbit2scr.inc}
{$undef smer1}
{$i sbit2scr.inc}


{---------------------------------------------------------------------------
 Volat byla-li behem scrollingu modifikovana bitmapa (ne rozmery, jen obsah).
 Ihned prekresli tu cast zadaneho boxu, ktera lezi i ve videopameti.
 Souradnice se berou od zacatku bitmapy.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.MapRedrawBox(srcX,srcY,Sirka,Vyska:integer);
var   cut:integer;
      oldpen:byte;
      oldmouse:boolean;
begin
 if (srcY+Vyska<=writtenTop) or (srcY>writtenBot)
  or (srcX+Sirka<=writtenLeft) or (srcX>writtenRight) then exit;
 cut:=maxI(0,writtenTop -srcY);dec(Vyska,cut);inc(srcY,cut);
 cut:=maxI(0,writtenLeft-srcX);dec(Sirka,cut);inc(srcX,cut);
 Vyska:=minI(Vyska,writtenBot  -srcY+1);
 Sirka:=minI(Sirka,writtenRight-srcX+1);
 oldpen:=pen;
 oldmouse:=MouseHide;
 pen:=PEN_VIRT_AREA;
 BtB2Box(map,srcX,srcY,Sirka,Vyska,srcX,srcY);
 pen:=oldpen;
 if oldmouse then MouseShow;
end;


{---------------------------------------------------------------------------
 Jumpne do posNext.
 Tj. zkopci vyrez bitmapy a setvisne.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.MapRedraw;
var   sir,vys:integer;
      oldpen:byte;
begin
 writtenTop:=posNext.Y div charYres;
 writtenBot:=writtenTop-1;
 writtenLeft:=posNext.X div charXres;
 writtenRight:=writtenLeft-1;
 sir:=minI(   Xres+1,map^.sizeX-writtenLeft);
 vys:=minI(topYres+1,map^.sizeY-writtenTop);
 {pri uzke vysoke bitmape a non movsd metode se o vymaz okraju obrazu
  postara dokresli, v ostatnich pripadech tato podminka}
 if (map^.sizeY<topYres) or ((map^.sizeX<Xres) and (scrolMethod=movsd)) then begin
   oldpen:=pen;
   pen:=PEN_SCREEN;
   Clr2Box(0,0,Xres,topYres);
   pen:=oldpen;
   end;
 {sirka i vyska jsou +1 kvuli textmodu kde muze byt videt i pulka dalsi radky/sloupce}
 ScrolSetvis;
 Dokresli(sir,vys);
 {vymaze okraje kolem uzke nebo placate bitmapy}
end;

{---------------------------------------------------------------------------
 Scrollovaci GotoXY (pocita se splitem, doublebufferingem apod).
 Souradnice jsou relativni k zacatku scrolbufferu (zacina za splitem).
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.GotoXY(x,y:integer);
var   yy:integer;
label 1,2;
begin
 case pen of
   PEN_VRAM   :1:inherited GotoXY(x,y);
   PEN_SCREEN   :inherited GotoXY(x+vramVisX div charXres,buflineFirst+(vramVisY div charYres+y-buflineFirst) mod buflines);
   PEN_VIRTUAL:2:begin
                 if scrolMethod=movsd then begin
                   x:=maxI(0,x-writtenLeft);
                   y:=maxI(0,y-writtenTop);
                   end
                 else begin
                   yy:=freeNad+buflineFirst+y mod buflines;
                   if (scrolMethod=doublebufferin) {ze doublebufferuje}
                    and (posNow.Y div charYres mod buflines>=buflines-topYres) {setvis je ve druhym bufferu}
                    and (y mod buflines<topYres) {a kurzor je v prvnim bufferu}
                    then inc(yy,buflines);
                   y:=yy;
                   end;
                 goto 1;
                 end;
   PEN_VIRT_AREA:begin
                 inc(x,freePred);
                 inc(y,freeNad);
                 goto 2;
                 end;
   end;
end;

{---------------------------------------------------------------------------
 Do rect nastavi jakou oblast zabira sipka.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.MouseGetRect(var rect:TRect);
begin
 case pen of
   PEN_SCREEN:inherited MouseGetRect(rect);
   PEN_VIRTUAL:begin inherited MouseGetRect(rect);rect.Move(posNow.x,posNow.y);end;
   PEN_VIRT_AREA:begin inherited MouseGetRect(rect);rect.Move(posNow.x-freePred,posNow.y-freeNad);end;
   PEN_VRAM:{$ifdef beta}erBetaMsg('mousegetrect pen=vram'){$endif};
   end;
end;

{---------------------------------------------------------------------------
 Priprava scrollovaciho setvisu (pocita se splitem, doublebufferingem apod).
 Souradnice jsou v pixelech (i v textmodu), relativni k zacatku scrolbufferu.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.PrepSetvisRegisters(x,y:word);assembler;
 asm
     {
      SI    - x
      ES:DI - self
     }
     les di,self
     mov si,x

   {---ZAROVNA SOURADNICE PODLE POUZITE METODY---}

     mov al,[es:di+scrolMethod]
     cmp al,wrappin;jz @WRAPPING
     cmp al,splittin;jz @SPLITTING
     cmp al,doublebufferin;jz @DOUBLEBUFFERING
     jmp @done

   @WRAPPING:{zjednoduseno pro charXYres=1, nelze pouzit v textmodu}
     mov ax,[es:di+vramXres];mul y
     add ax,si;adc dx,0{ax:dx=poradi pixelu ve videopameti}
     mov bx,ax
     mov cl,[es:di+BiPP];mov ch,0
     mov ax,dx;mul cx
     xchg ax,bx;mul cx
     add dx,bx{ax:dx=poradi bitu ve videopameti}
     mov cl,[es:di+WrappingAt];mov ch,0;shl cx,3;dec cx;and dx,cx{ax:dx=wrapnuty bit}
     push dx;push ax;db 66h;pop ax;db 66h;xor dx,dx{eax:edx=wrapnuty bit}
     db 66h;xor bx,bx;mov bl,[es:di+BiPP]
     db 66h;div bx{eax=wrapnuty pixel}
     db 66h;push ax;pop ax;pop dx{ax:dx=wrapnuty pixel}
     div [es:di+vramXres]{ax:dx rozlozi zpatky do souradnic x,y}
     mov si,dx
     mov y,ax
     jmp @continue

   @DOUBLEBUFFERING:{pocita i s charXYres<>1}
   @SPLITTING:
     mov ax,[es:di+buflines];mul [es:di+charYres];mov bx,ax{bx=buflines*charYres}
     mov ax,y;xor dx,dx;div bx;mov cx,dx{cx=y mod (buflines*charYres)}
     sub bx,cx;dec bx;mov [es:di+toSplitY],bx{push for splitY}
     mov ax,[es:di+buflineFirst];mul [es:di+charYres]{ax=buflineFirst*charYres}
     add ax,cx
     mov y,ax
     jmp @continue

   {---SPOCITA VYSTUPY PODLE POUZITEHO MODELU---}

   @continue:
     mov [es:di+vramVisX],si
     mov ax,y
     mov [es:di+vramVisY],ax

     cmp [es:di+VesaMode],0;  jnz @VESA
     mov al,[es:di+MapModel]
     cmp al,model_text;       jz @TEXT
     cmp al,model_packed;     jz @PACKED
     cmp al,model_unchained;  jz @UNCHAINED
     jmp @done

   @VESA:
     mov [es:di+toVesaX],si
     mov ax,y
     mov [es:di+toVesaY],ax
     jmp @done

   @TEXT:
     mov ax,si;xor dx,dx;div [es:di+charXres];mov bx,ax{bx=Hi(X),dx=LoX}
     mov [es:di+toPanLeft],dl{push for panleft}
     mov ax,y;xor dx,dx;div [es:di+charYres]{ax=rawLine(Y),dx=LoY}
     mov [es:di+toPanUp],dl{push for panup}
     mov dx,[es:di+lineOffset];shr dx,1;mul dx;add ax,bx{ax=Hi(XY)}
     mov [es:di+toSetvisHi],ax{push for setvishi}
     jmp @done

   @PACKED:
     mov ax,y;mul [es:di+lineOffset]
     mov bx,si
     mov [es:di+toPanLeft],bl{push for panleft}
     shr bx,2;add ax,bx
     mov [es:di+toSetvisHi],ax{push for setvishi}
     jmp @done

   @UNCHAINED:
     mov ax,y;mul [es:di+lineOffset]
     mov bx,si
     mov [es:di+toPanLeft],bl{push for panleft}
     shr bx,2;add ax,bx
     mov [es:di+toSetvisHi],ax{push for setvishi}
     jmp @done

   @DONE:
 end;



{---------------------------------------------------------------------------
 Spocita o kolik je treba dokreslit nahore nebo dole.
 V textmodu se vypocty interne provadi ve znacich, ne pixelech.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.Dokreslit(var dx,dy:integer);
const rezervit        =24;            {kolik musi mit pripraveno v zaloze vzdy}
      speed           =rezervit div 1;{jak rychle dokreslovat kdyz nepospicha}
{pozn: pri fast scrolu nestiha dokreslovat vrsek proto, ze nahore je paprsek
  hned, dole je az o frame pozdejc kdy uz je dokresleno.
  kdyz scrolnu o rezervit+10, nahore bude chybet 10 radek.}
var   rezervaNahore   :integer;
      rezervaDole     :integer;
      maxrezervaNahore:integer;
      maxrezervaDole  :integer;

  function GetPosun:integer;
  var posun:integer;
  begin
   { NAHORE ? }
   if (maxrezervaNahore>rezervaNahore) and
      ((rezervaNahore<rezervaDole) or (maxrezervaDole=rezervaDole)) then begin
        posun:=rezervit-rezervaNahore;{kolik dokreslit abych mel rezervu}
        if (posun<speed) or (maxrezervaNahore<rezervit) then begin
          posun:=maxrezervaNahore-rezervaNahore;{dokresleni az na doraz}
          if posun>speed then posun:=speed;{nikam nepospicham}
          end;
        GetPosun:=-posun;
        end
   else
   { DOLE ? }
   if (maxrezervaDole>rezervaDole) and
      ((rezervaDole<=rezervaNahore) or (maxrezervaNahore=rezervaNahore)) then begin
        posun:=rezervit-rezervaDole;{kolik dokreslit abych mel rezervu}
        if (posun<speed) or (maxrezervaDole<rezervit) then begin
          posun:=maxrezervaDole-rezervaDole;{dokresleni az na doraz}
          if posun>speed then posun:=speed;{nikam nepospicham}
          end;
        GetPosun:=posun;
        end
   else
   { NIKDE }
     GetPosun:=0;
  end;

var   X,Y             :integer;
begin
 if scrolMethod=movsd then begin dx:=0;dy:=0;exit;end;

 {spocita stavajici rezervy a maximalni dosazitelne rezervy}
 Y               :=posNow.Y div charYres;
 rezervaNahore   :=Y-writtenTop;
 rezervaDole     :=writtenBot-(Y+topYres-1);
 maxrezervaNahore:=minI(bufmaxrezervaY,Y);
 maxrezervaDole  :=minI(bufmaxrezervaY,map^.sizeY-(Y+topYres));
 {vybere nejvhodnejsi blok k dokresleni}
 dy              :=GetPosun;

 {spocita stavajici rezervy a maximalni dosazitelne rezervy}
 X               :=posNow.X div charXres;
 rezervaNahore   :=X-writtenLeft;
 rezervaDole     :=writtenRight-(X+Xres-1);
 maxrezervaNahore:=minI(bufmaxrezervaX,X);
 maxrezervaDole  :=minI(bufmaxrezervaX,map^.sizeX-(X+Xres));
 {vybere nejvhodnejsi blok k dokresleni}
 dx              :=GetPosun;
end;


{---------------------------------------------------------------------------
 Dokresli kus stranky nahore nebo dole. Pohlida si mys a prekresli ji
 pokud neni nastaven mouseRedrawFlag.
 V textmodu jsou udaje ve znacich, ne pixelech.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.Dokresli(dx,dy:integer);

  procedure Draw(x,y,sir,vys:integer;smer:char);
  var oldpen:byte;
  begin
   oldpen:=pen;
   pen:=PEN_VIRT_AREA;
   BtB2Box(Map, x,y, sir,vys, x,y);
   pen:=PEN_VIRTUAL;
   case smer of
    'x':begin
        if freePred>0 then Clr2Box(0,y, freePred,vys);
        if freeZa  >0 then Clr2Box(Xres-freeZa,y, freeZa,vys);
        end;
    'y':begin
        if freeNad >0 then Clr2Box(x,0, sir,freeNad);
        if freePod >0 then Clr2Box(x,topYres-freePod, sir,freePod);
        end;
    end;
   pen:=oldpen;
  end;

var   oldmouse:boolean;
      oldpen:byte;
      dokres_onscreen:boolean;
begin
 dokres_onscreen:=(writtenLeft>posNow.X) or (writtenRight<posNow.X+Xres)
               or (writtenTop >posNow.Y) or (writtenBot  <posNow.Y+topYres);
 if not dokres_onscreen and not mouseRedrawFlag then MouseRedraw;

 if ((dx=0) and (dy=0)) or (scrolMethod=movsd) then begin
   if dokres_onscreen and not mouseRedrawFlag then MouseRedraw;
   exit;
   end;

 oldpen:=pen;
 pen:=PEN_VIRTUAL;

 if dokres_onscreen then oldmouse:=MouseHide;

 if dy<0 then begin
   {$ifdef beta}
   if dy+writtenTop<0 then erBetaMsg('dokresli nahoru 1');
   {$endif}
   inc(writtenTop,dy);
   if writtenTop+buflines<=writtenBot then writtenBot:=writtenTop+buflines-1;
   {$ifdef beta}
   if writtenBot>=map^.sizeY then erBetaMsg('dokresli nahoru 2');
   {$endif}
   Draw(writtenLeft,writtenTop, writtenRight+1-writtenLeft,-dy, 'x');
   end else
 if dy>0 then begin
   {$ifdef beta}
   if dy+writtenBot>=map^.sizeY then erBetaMsg('dokresli dolu 1');
   {$endif}
   Draw(writtenLeft,writtenBot+1, writtenRight+1-writtenLeft,dy, 'x');
   inc(writtenBot,dy);
  
   if writtenTop+buflines<=writtenBot then writtenTop:=writtenBot-buflines+1;
   {$ifdef beta}
   if writtenTop<0 then erBetaMsg('dokresli dolu 2');
   {$endif}
   end;

 if dx<0 then begin
   {$ifdef beta}
   if dx+writtenLeft<0 then erBetaMsg('dokresli vlevo 1');
   {$endif}
   inc(writtenLeft,dx);
   if writtenLeft+vramXres<=writtenRight then writtenRight:=writtenLeft+vramXres-1;
   {$ifdef beta}
   if writtenRight>=map^.sizeX then erBetaMsg('dokresli vlevo 2');
   {$endif}
   Draw(writtenLeft,writtenTop, -dx,writtenBot+1-writtenTop, 'y');
   end else
 if dx>0 then begin
   {$ifdef beta}
   if dx+writtenRight>=map^.sizeX then erBetaMsg('dokresli vpravo 1');
   {$endif}
   Draw(writtenRight+1,writtenTop, dx,writtenBot+1-writtenTop, 'y');
   inc(writtenRight,dx);
   if writtenLeft+vramXres<=writtenRight then writtenLeft:=writtenRight-vramXres+1;
   {$ifdef beta}
   if writtenLeft<0 then erBetaMsg('dokresli vpravo 2');
   {$endif}
   end;

 if dokres_onscreen and oldmouse then MouseShow;
 pen:=oldpen;
end;




{€€€€€€€€€€€€€€€€ T I M E R €€€€€€€€€€€€€€€€}

Function TScrolScreen.PosWantsFreshup:boolean;
begin
 posWantsFreshup:=(not posOk) or (posNext.X<>posNow.X) or (posNext.Y<>posNow.Y);
end;

Procedure TScrolScreen.SetvisPhase1;
begin
 {pokud doslo k pohybu:}
 if posWantsFreshup then begin
   {spocita hodnoty registru odpovidajici zadanym souradnicim}
   PrepSetvisRegisters(posNext.X,posNext.Y);
   {setvis ve vesa modech}
   if VesaMode then begin
     posOk:=VesaSetvisSyncuje;{kdyz nesyncuje, obraz se srovna az v phase4}
     VesaSetvis(toVesaX,toVesaY);
     end;
   {da vedet ktera faze je na rade}
   phase:=2;
   end;
end;

Procedure TScrolScreen.SetvisPhase2;
begin
 {pracuje jen kdyz je na rade}
 if phase=2 then begin
   if not VesaMode then begin
     posOk:=false;
     {nastavi hlavni registr pro disp.addr.start}
     SetVisHi(toSetvisHi);
     {>tohle<}
     {v textovem modu nastavi panning nahoru}
     if (MapModel=model_text) and (PanUpBug=1) then PanUp(toPanUp);
     {nastavi panning doleva}
     if (PanLeftBug<>1) then PanLeft(toPanLeft);
     {>bylo<}
     end;
   {da vedet ktera faze je na rade}
   inc(phase);
   end;
end;

Procedure TScrolScreen.SetvisPhase3;
begin
 {pracuje jen kdyz je na rade}
 if phase=3 then begin
   {>tady<}
   if not VesaMode then begin
     {v textovem modu nastavi panning nahoru}
     if (MapModel=model_text) and (PanUpBug<>1) then PanUp(toPanUp);
     {nastavi panning doleva}
     if (PanLeftBug=1) then PanLeft(toPanLeft);
     end;
   {pri scrolmetode splitting emuluje wrapping na urcite radce}
   if scrolMethod=splittin then SplitY(toSplitY);
   {>tady<}
   {da vedet ktera faze je na rade}
   inc(phase);
   end;
end;

Procedure TScrolScreen.SetvisPhase4;
var   oldmouse:boolean;
      old:TBankRegs;
begin
 {pracuje jen kdyz je na rade}
 if phase=4 then begin
   {posune mys a nastavi nove souradnice}
   if mouseWarning=0 then begin
     old     :=GetBankRegs;
     oldmouse:=MouseHide;
     end;
   posNow   :=posNext;
   posOk    :=true;
   if mouseWarning=0 then begin
     if oldmouse then MouseShow;
     SetBankRegs(old);
     end;
   {syncne plovouci paletu}
   SyncPal;
   {da vedet ktera faze je na rade}
   inc(phase);
   end;
end;

{---------------------------------------------------------------------------
 Scrollovaci setvis (pocita se splitem, doublebufferingem apod,
 tj. souradnice jsou v systemu PEN_VIRTUAL).
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.ScrolSetvis;
var   oldmouse:boolean;
      oldpen:byte;
      myY:integer;
      sir,vys:integer;
      posNextChar:TPoint;
begin
 if scrolMethod=movsd then
   begin
   oldmouse     :=MouseHide;
   oldpen       :=pen;
   pen          :=PEN_VIRT_AREA;
   sir          :=minW(Xres,map^.sizeX);
   vys          :=minW(topYres,map^.sizeY);
   posOk        :=false;
   posNow       :=posNext;
   posNextChar.X:=posNext.X div charXres;
   posNextChar.Y:=posNext.Y div charYres;
   BtB2Box(map,posNextChar.X,posNextChar.Y, sir,vys, posNextChar.X,posNextChar.Y);
   posOk        :=true;
   writtenLeft  :=posNextChar.X;
   writtenRight :=posNextChar.X+sir-1;
   writtenTop   :=posNextChar.Y;
   writtenBot   :=posNextChar.Y+vys-1;
   pen          :=oldpen;
   if oldmouse then MouseShow;
   SyncPal;
   end
  else if VesaMode and VesaSetvisSyncuje then begin
   SetvisPhase1;
   SetvisPhase2;
   SetvisPhase3;
   SetvisPhase4;
   end
  else begin
   SetvisPhase1;
   WaitForTrace;
   SetvisPhase2;
   WaitForRetrace;
   SetvisPhase3;
   SetvisPhase4;
   synced       :=true;
   end;
end;


{Pokud nejak manipulujes se stackem a obcas se nachazi v nejakem divnem
 stavu, je tu riziko ze zrovna v tu chvili nabehne timer a vola tmrScrol*.
 Ty potrebuji kolem 200 bajtu na stacku. Muzes tedy pouzit define
 safestack a nechat je nastavovat si vlastni stack. Ale predtim musis
 do safestack nejak dostat pointer na svuj zalozni stack.}
{$ifdef safestack}
var oldstack:pointer;
{$endif}

procedure TmrScrol1;far;
begin
 {$ifdef safestack}
 asm mov oldstack.word[0],sp;mov oldstack.word[2],ss;db 0fh,0b2h,26h;dw offset backstack;end;
 {$endif}
 CurScrolScreen^.SetvisPhase2;
 {$ifdef safestack}
 asm db 0fh,0b2h,26h;dw offset oldstack;end;
 {$endif}
end;

procedure TmrScrol2;far;
begin
 {$ifdef safestack}
 asm mov oldstack.word[0],sp;mov oldstack.word[2],ss;db 0fh,0b2h,26h;dw offset backstack;end;
 {$endif}
 CurScrolScreen^.SetvisPhase3;
 {$ifdef safestack}
 asm db 0fh,0b2h,26h;dw offset oldstack;end;
 {$endif}
end;

procedure TmrScrol3;far;
begin
 {$ifdef safestack}
 asm mov oldstack.word[0],sp;mov oldstack.word[2],ss;db 0fh,0b2h,26h;dw offset backstack;end;
 {$endif}
 with CurScrolScreen^ do begin
   ret:=true;
   SetvisPhase4;
   SyncSpocitej;
   SetvisPhase1;
   end;
 {$ifdef safestack}
 asm db 0fh,0b2h,26h;dw offset oldstack;end;
 {$endif}
end;

procedure TmrScrol4;far;
begin
 {$ifdef safestack}
 asm mov oldstack.word[0],sp;mov oldstack.word[2],ss;db 0fh,0b2h,26h;dw offset backstack;end;
 {$endif}
 with CurScrolScreen^ do begin
   ret:=true;
   SyncSpocitej;
   end;
 {$ifdef safestack}
 asm db 0fh,0b2h,26h;dw offset oldstack;end;
 {$endif}
end;

{---------------------------------------------------------------------------
 Je vse ok pro pouziti timeru?
 ---------------------------------------------------------------------------}
Function TScrolScreen.TimerAllRight:boolean;
begin
 TimerAllRight:=usetimer
      and not SafeMode
      and not (ops=windows)
      and not (RetraceLen>0)
      and not (VesaMode and VesaSetvisSyncuje);
end;

{---------------------------------------------------------------------------
 Ma zjistit kolik vraci tmrGetScrSync.
 Tuhle metodu ignoruj, kdyby to slo tak je private.
 ---------------------------------------------------------------------------}
Function TScrolScreen.DetectTmrScrSync:word;
var   scrSync:word;
begin
 scrSync:=0;
{$ifdef timer}
 if TimerAllRight then tmrGetScrSync(@scrSync);
{$endif}
 DetectTmrScrSync:=scrSync;
end;

{---------------------------------------------------------------------------
 Zapne timer na podporu scrollingu.
 Sam pozna kdy timer pouzit nelze a nezapne ho.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.TmrScrolStart;
begin
 {$ifdef timer}
 if not usingTimer then
  if TimerAllright then begin
   {zavesi to vsechno na timer}
   phase            :=1;{aby zacal prvni fazi}
   if scrolMethod=movsd
    then tmrSyncScr(timerScrSync,nil,nil,@TmrScrol4)
    else tmrSyncScr(timerScrSync,@TmrScrol1,@TmrScrol2,@TmrScrol3);
   usingTimer       :=true;
   beziNahazovacRet :=true;
   end;
 {$endif}
end;

{---------------------------------------------------------------------------
 Vypne podporu scrollingu timerem.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.TmrScrolStop;
begin
 {$ifdef timer}
 if usingTimer then begin
   {zastavi timer}
   beziNahazovacRet :=false;
   usingTimer       :=false;
   TmrStopScrSync;
   {dokonci timerem rozbehnutej setvis}
   SetvisPhase2;
   SetvisPhase3;
   SetvisPhase4;
   ret              :=true;
   end;
 {$endif}
end;


{---------------------------------------------------------------------------
 Nastavi zda ma byt scrolling podporovan timerem.
 Lze volat kdykoliv (i behem scrollingu).
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.SetUseTimer(use:boolean);
begin
 {$ifdef timer}
 usetimer:=use;
 if wanttimer then TmrScrolStart else TmrScrolStop;
 {$endif}
end;




{€€€€€€€€€€€€€€€€ S C R O L L I N G €€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Vraci stav ruznych aktivit.
 Vysledek je soucet konstant syncXXXX.
 ---------------------------------------------------------------------------}
Function TScrolScreen.GetActivity:TAct;
var   i:TAct;
begin
 i:=0;
 if usingTimer    then i:=i or syncTimerOn     else i:=i or syncTimerOff;
 if syncMoving    then i:=i or syncMovingOn    else i:=i or syncMovingOff;
 if syncDrawing   then i:=i or syncDrawingOn   else i:=i or syncDrawingOff;
 if syncAutoscrol then i:=i or syncAutoscrolOn else i:=i or syncAutoscrolOff;
 if mouseFlag     then i:=i or syncMouseOn     else i:=i or syncMouseOff;
 if mouseHandler  then i:=i or syncMHandlerOn  else i:=i or syncMHandlerOff;
 if kHandler      then i:=i or syncKHandlerOn  else i:=i or syncKHandlerOff;
 if syncEmulMouse then i:=i or syncEmulMouseOn else i:=i or syncEmulMouseOff;
 if syncKScrol    then i:=i or syncKScrolOn    else i:=i or syncKScrolOff;
 GetActivity:=i;
end;

{---------------------------------------------------------------------------
 Zapne/vypne ruzne aktivity.
 Parametr je soucet konstant syncXXXX.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.SetActivity(act:TAct);
var   t:longint;
begin
 if (act and syncTimerOn     )<>0 then begin wanttimer:=true;TmrScrolStart;end;
 if (act and syncTimerOff    )<>0 then begin wanttimer:=false;TmrScrolStop;end;
 if (act and syncMovingOn    )<>0 then syncMoving:=true;
 if (act and syncMovingOff   )<>0 then syncMoving:=false;
 if (act and syncDrawingOn   )<>0 then syncDrawing:=true;
 if (act and syncDrawingOff  )<>0 then syncDrawing:=false;
 if (act and syncAutoscrolOn )<>0 then syncAutoscrol:=true;
 if (act and syncAutoscrolOff)<>0 then syncAutoscrol:=false;
 if (act and syncMHandlerOn  )<>0 then mouseSetHandler(true);
 if (act and syncMHandlerOff )<>0 then mouseSetHandler(false);
 if (act and syncMouseOn     )<>0 then MouseShow;
 if (act and syncMouseOff    )<>0 then MouseHide;
 if (act and syncKHandlerOn  )<>0 then kSetHandler(true);
 if (act and syncKHandlerOff )<>0 then kSetHandler(false);
 if (act and syncEmulMouseOn )<>0 then syncEmulMouse:=true;
 if (act and syncEmulMouseOff)<>0 then syncEmulMouse:=false;
 if (act and syncKScrolOn    )<>0 then syncKScrol:=true;
 if (act and syncKScrolOff   )<>0 then syncKScrol:=false;

 if (act and syncMovingOff   )<>0 then
   {pocka az na pozadi dobehne setvis}
   if usingtimer then begin
     {$ifdef beta}
     t:=GetMs;
     repeat until posOk or (GetMs>t+1000);
     if not posOk and not dumb then erBetaMsg('posOk chaos');
     {$else}
     repeat until posOk;
     {$endif}
     end;
end;

{---------------------------------------------------------------------------
 Tuhle metodu uplne ignoruj. Nechtel jsem zbytecne komplikovat TScreen
 tim ze bych tam taky zaved SetActivity. Ale zapinani a vypinani syncMovingu
 tam byt musi (aby si dialogy mohly docasne vypnout moving i kdyz pracujou
 jen s PScreen a ne s PScrolScreen), tak jsem udelal aspon takovouhle malou
 virtualni metodu, ktera to zaridi. Zapne/vypne syncMoving a do move da
 puvodni stav movingu.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.SwapMoving(var move:boolean);
var   old:boolean;
begin
 old:=(GetActivity and syncMovingOn)>0;
 if move then SetActivity(syncMovingOn) else SetActivity(syncMovingOff);
 move:=old;
end;

{---------------------------------------------------------------------------
 Synchronizace scrollingu. Je treba ji behem scrollingu obcas volat.
 Je-li pouzit timer, tato rutina pouze dokresluje bitmapu - to je operace
 casove narocna, a proto nevhodna pro veseni primo na timer (ovsem jde to).
 Neni-li pouzit timer, tato rutina navic setvisuje a ceka na retrace -
 kdyz chces plynuly scrol tak nikdy necekej na retrace sam, pouzivej tohle.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.Sync;
begin
 mouseRedrawFlag:=false;
 if not usingTimer then SyncSpocitej;
 if (not usingTimer or (scrolMethod=movsd))
    and syncMoving and posWantsFreshup then ScrolSetvis;
 SyncRet;
 KeyboardRescan;
 MouseRescanPress;
 MouseRescanState;
 mouse.Z:=mouse.Z or mouseEmulZ;{pri zmene mouse.Z opravi mouse.Z podle mouseEmulZ}
 if syncDrawing
  then SyncDokresli{dokresli, pripadne s vynucenym prekreslenim mysi}
  else if not mouseRedrawFlag then MouseRedraw;{jen prekresli mys}
 IncMs(1000 div screenfreq);
 kDecPressed;
 if @userSync<>nil then userSync;
end;

{---------------------------------------------------------------------------
 Vraci true a udalost se souradnicemi
  nebo false, kdyz se nic nedeje.
 Udalost je bud znak z klavesnice nebo neco z mbXXXX (stisk mysi).
 ---------------------------------------------------------------------------}
Function TScrolScreen.GetEvent(var event:TEvent;var pos:TPoint):boolean;
begin
 GetEvent:=false;
 if inherited GetEvent(event,pos) then begin
   case pen of
    PEN_VIRTUAL:begin inc(pos.x,posNow.X);inc(pos.y,posNow.Y);end;
    PEN_SCREEN:;
    PEN_VIRT_AREA:begin inc(pos.x,posNow.X-freePred);inc(pos.y,posNow.Y-freeNad);end;
    PEN_VRAM:{$ifdef beta}erBetaMsg('getevent pen=vram'){$endif};
    end;
   GetEvent:=true;
   end;
end;


{---------------------------------------------------------------------------
 Zapocita do pohybu z Now do Cil setrvacnost.
 Speed je momentalni rychlost pohybu. Pohybovat se lze od 0 do Max.
 ---------------------------------------------------------------------------}
PROCEDURE Smoothin(var now,cil,speed:integer;fast,max:integer;var CrashLevel:word);
const setrv=0.8;
var   oldnow,i:integer;
begin
 oldnow:=now;
 inc(now,fast);
 inc(cil,fast);
 if max<0 then max:=0;
 if cil<=now then speed:=round(speed*setrv-sqrt(now-cil)*(1-setrv)) else
 if cil>now then speed:=round(speed*setrv+sqrt(cil-now)*(1-setrv));
 inc(now,speed);
 if now<0 then now:=0 else if now>max then now:=max else exit;

 {pouze pri narazu do kraje:}
 cil:=now;
 speed:=-speed div 2;
 if CurScreen=nil then i:=3 else i:=maxW(3,(CurScreen^.Xres+CurScreen^.Yres) div 200);
 if abs(speed)<i then speed:=0;{bez toho zpusobi drzeny home/end nepretrzite male odrazy}
 if now<>oldnow then inc(CrashLevel,abs(speed+fast));
end;

{---------------------------------------------------------------------------
 Pomocne vypocty pro generovani dynamickeho scrolu z virtVisY do cilY.
 Spocita neco jako silu tahu podle vzdalenosti od kraje obrazovky.
 ---------------------------------------------------------------------------}
function HahaDiv(x,y:word):integer;inline($59/$33/$C0/$5A/$F7/$F1);
function Haha(i:integer):longint;
const mez=65536*autoscrolprocent div 100;
begin
 case i of 0..mez-1:i:=mez-i;
           -mez..-1:i:=-mez-1-i;
               else i:=0;
           end;
 Haha:=longint(-i)*autoscrolspeed*10 div mez;
end;


var   presslength:longint;

{---------------------------------------------------------------------------
 Spocita do posNext kam se ma scrollovat (nekam mezi posNext a posCil).
 Podle okolnosti upravi i posCil.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.SyncSpocitej;
var   fastX,fastY:integer;
      myspeedX,myspeedY:integer;
      oldmouseZ:integer;
      p:pointer absolute userSpocitej;
label 2,3;
begin
 fastX:=0;
 fastY:=0;

 if p<>nil then userSpocitej(@self);

 if syncMoving and syncAutoScrol then begin
   fastX:=Haha(HahaDiv(mouse.X-mouseRng.a.x,mouseRng.b.x-mouseRng.a.x+1))*Xres   *charXres div 640 div 25;
   fastY:=Haha(HahaDiv(mouse.Y-mouseRng.a.y,mouseRng.b.y-mouseRng.a.y+1))*topYres*charYres div 480 div 25;
   end;

 if syncMoving and syncKScrol then begin
   if kPressed[kLeft ] then dec(posCil.X,longint(CitlivostSipek)*Xres   *charXres div 640);
   if kPressed[kRight] then inc(posCil.X,longint(CitlivostSipek)*Xres   *charXres div 640);
   if kPressed[kUp   ] then dec(posCil.Y,longint(CitlivostSipek)*topYres*charYres div 480);
   if kPressed[kDown ] then inc(posCil.Y,longint(CitlivostSipek)*topYres*charYres div 480);
   end;

 if syncEmulMouse then begin
   inc(presslength);
   myspeedY:=minW(2+presslength div 10,6)*16*CitlivostNumpadu;
   myspeedX:=maxW(1,HiByte(myspeedY div charXres));
   myspeedY:=maxW(1,HiByte(myspeedY div charYres));
   if kPressed[kk1] then begin MouseShift(-myspeedX,+myspeedY);goto 2;end;
   if kPressed[kk2] then begin MouseShift(        0,+myspeedY);goto 2;end;
   if kPressed[kk3] then begin MouseShift(+myspeedX,+myspeedY);goto 2;end;
   if kPressed[kk4] then begin MouseShift(-myspeedX,        0);goto 2;end;
   if kPressed[kk6] then begin MouseShift(+myspeedX,        0);goto 2;end;
   if kPressed[kk7] then begin MouseShift(-myspeedX,-myspeedY);goto 2;end;
   if kPressed[kk8] then begin MouseShift(        0,-myspeedY);goto 2;end;
   if kPressed[kk9] then begin MouseShift(+myspeedX,-myspeedY);goto 2;end;
   presslength:=0;
   goto 3;
   2:
   MouseRedraw;
   3:
   oldmouseZ:=mouseEmulZ;
   mouseEmulZ:=0;
   if kPressed[kkNum]   then inc(mouseEmulZ);
   if kPressed[kkMul]   then inc(mouseEmulZ,2);
   if kPressed[kkSlash] then inc(mouseEmulZ,4);
   mouse.Z:=mouse.Z or mouseEmulZ;{pri zmene mouseEmulZ opravi mouse.Z}
   if ((oldmouseZ and 1)<(mouseEmulZ and 1))
   or ((oldmouseZ and 2)<(mouseEmulZ and 2))
   or ((oldmouseZ and 4)<(mouseEmulZ and 4)) then mousePres:=mouse;
   end;

 if syncMoving then begin
   Smoothin(posNext.X,posCil.X,speedX,fastX,Long2Int(longint(map^.sizeX-   Xres)*charXres),CrashLevel);
   Smoothin(posNext.Y,posCil.Y,speedY,fastY,Long2Int(longint(map^.sizeY-topYres)*charYres),CrashLevel);
   end;

end;

{---------------------------------------------------------------------------
 Zpracuje signaly z klavesnice, ovsem jen ty co jdou pres dos.
 Duvodem vycleneni ze SyncSpocitej jsou problemy s nereentrantnosti
 dosu, tahle metoda nemuze byt volana z timeru.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.KeyboardRescan;
var   event:TEvent;
begin
 while keypressed do begin
   event:=ReadEvent;
   if syncMoving and syncKScrol then case code(event) of
       kPgUp  :dec(posCil.Y,topYres*charYres);
       kPgDwn :inc(posCil.Y,topYres*charYres);
       kHome  :begin posCil.X:=-charXres*Xres;posCil.Y:=-charYres*Yres;{aby se nahore i dole odrazel stejne silne}end;
       kEnd   :begin posCil.X:=map^.sizeX*charXres;posCil.Y:=map^.sizeY*charYres;end;
       end;
   if not (syncEmulMouse and (code(event) in [kk1,kk2,kk3,kk4,kk6,kk7,kk8,kk9,kkNum,kkSlash,kkMul])) and
      not (syncMoving and syncKScrol and (code(event) in [kUp,kDown,kLeft,kRight,kPgUp,kPgDwn,kHome,kEnd]))
      then PushEvent(event);
   end;
end;

{---------------------------------------------------------------------------
 Dokresli kus bitmapy o ktery se odscrollovalo.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.SyncDokresli;
var   dx,dy:integer;
begin
 Dokreslit(dx,dy);
 Dokresli(dx,dy);
end;




{€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€ CFG €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€}


Type  TCfg = record
               Ves :boolean; {Vesamode}
               Mdl :byte;    {MapModel}
               Spl :shortint;{Splitting}
               StX :shortint;{SetvisStepX}
               StY :shortint;{SetvisYBug}
               ViX :shortint;{VirtXStep}
               Wrp :shortint;{Wrapping}
               GtY :shortint;{GotoYBug}
               PaU :shortint;{PanUpBug}
               PaL :shortint;{PanLeftBug}
             end;
Const cfgs=5;
      cfg:array[0..cfgs] of TCfg=(
       (Ves:false;Mdl:255            ;Spl:-1;StX:-1;StY: 0;ViX:-1;Wrp:-1;GtY:-1;PaU:-1;PaL:-1),
       (Ves:false;Mdl:model_text     ;Spl: 1;StX: 1;StY: 0;ViX: 2;Wrp: 0;GtY:-1;PaU:-1;PaL:-1),
       (Ves:false;Mdl:model_packed   ;Spl: 1;StX: 1;StY: 0;ViX: 4;Wrp:-1;GtY: 0;PaU: 0;PaL:-1),
       (Ves:false;Mdl:model_unchained;Spl: 1;StX: 1;StY: 0;ViX: 8;Wrp:-1;GtY: 0;PaU: 0;PaL:-1),
       (Ves:true ;Mdl:model_text     ;Spl:-1;StX:-1;StY:-1;ViX:-1;Wrp: 0;GtY:-1;PaU: 0;PaL: 0),
       (Ves:true ;Mdl:model_packed   ;Spl:-1;StX:-1;StY:-1;ViX:-1;Wrp:-1;GtY: 0;PaU: 0;PaL: 0)
       );
{Poznamky k tabulce:
  Prvni dva udaje v recordu jsou pouze popis skupiny modu kterych se to tyka.
  V nasledujicich jsou vlastni udaje.
  Ve VGA modech znam na 99.9% Splitting,SetvisStepX,Y,VirtXStep, jsou v tabulce.
  V textmodech je pouziti wrappingu znacne omezene, takze jsem
   tam nastavil 0 (jako ze newrapuje), aby se usetrila jedna detekce.
  Vse ostatni je nastaveno na -1 neboli "dosud nezjisteno".

  WrappingAt ve VGA Packed je asi u 70-95% karet 1; lisi se Trident, Tseng.
  WrappingAt ve VGA Unchained je asi na 50-90% karet 4; lisi se Tseng, WD Accel, UMC, nektere S3.
  SetvisYBug a GotoYBug ma hodne karet s S3.
  PanUpBug ma Tseng.
  PanLeftBug ma AtiMach64.
}


{---------------------------------------------------------------------------
 Najde v tabulce polozku s konfiguraci zadaneho modu a vrati jeji index.
 Nenajde nebo neni inicializovan zadny mod -> vrati 0.
 ---------------------------------------------------------------------------}
FUNCTION  CfgMatchingTo(toVesamode:boolean;toModel:byte):word;
var   i:word;
begin
 for i:=1 to cfgs do
  with cfg[i] do
   if (toVesamode=Ves) and (toModel=Mdl)
    then begin CfgMatchingTo:=i;exit;end;
 CfgMatchingTo:=0;
end;


{---------------------------------------------------------------------------
 Najde v tabulce polozku s konfiguraci aktualniho modu a vrati jeji index.
 Nenajde nebo neni inicializovan zadny mod -> vrati 0.
 ---------------------------------------------------------------------------}
Function TScrolScreen.MatchingCfg:word;
begin
 MatchingCfg:=CfgMatchingTo(Vesamode,MapModel);
end;

{---------------------------------------------------------------------------
 Ulozi konfiguraci aktualniho modu do tabulky konfiguraci.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.SaveCfg;
var   i:word;
begin
 i:=MatchingCfg;
 {nasel v tabulce polozku s timto modem -> ulozi tam udaje}
 if i>0 then
  with cfg[i] do begin
    Spl:=Splitting;
    StX:=SetvisStepX;
    StY:=SetvisYBug;
    ViX:=VirtXStep;
    Wrp:=WrappingAt;
    GtY:=GotoYBug;
    PaU:=PanUpBug;
    PaL:=PanLeftBug;
   end;
end;

{---------------------------------------------------------------------------
 Natahne konfiguraci zadaneho modu z tabulky konfiguraci.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.LoadCfgOf(toVesamode:boolean;toModel:byte);
var   i:word;
begin
 with cfg[CfgMatchingTo(toVesamode,toModel)] do begin
   Splitting  :=Spl;
   SetvisStepX:=StX;
   SetvisYBug :=StY;
   VirtXStep  :=ViX;
   WrappingAt :=Wrp;
   GotoYBug   :=GtY;
   PanUpBug   :=PaU;
   PanLeftBug :=PaL;
  end;
end;

{---------------------------------------------------------------------------
 Natahne konfiguraci aktualniho modu z tabulky konfiguraci.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.LoadCfg;
begin
 LoadCfgOf(Vesamode,MapModel);
 {snizi velikost videopameti pri wrappingu pred jejim koncem}
 if (WrappingAt>0) then
  if VramSizeKB>WrappingAt*64 then VramSizeKB:=WrappingAt*64;
end;




{€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€ TESTY €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€}


{---------------------------------------------------------------------------
 Parametry test a forcetest (co vse ma testovat) jsou souctem konstatnt t_*.
   test  - testuje jen to co je unsure
   force - testuje vsechno
 Funkce odstrani potrebu forcetestu tim, ze pozadovane jiz otestovane
 veci oznaci za dosud neotestovane.
 ---------------------------------------------------------------------------}
Function TScrolScreen.GetNeededTests(test:word;forcetest:word):word;
begin
 {obstara parametr forcetest}
 test:=(test or forcetest) and t_all;
 if (forcetest and t_Splitting    )>0 then Splitting    :=-1;
 if (forcetest and t_SetvisStepX  )>0 then SetvisStepX  :=-1;
 if (forcetest and t_SetvisStepXp )>0 then SetvisStepX  :=-1;
 if (forcetest and t_SetvisYBug   )>0 then SetvisYBug   :=-1;
 if (forcetest and t_VirtXStep    )>0 then VirtXStep    :=-1;
 if (forcetest and t_WrappingAt   )>0 then WrappingAt   :=-1;
 if (forcetest and t_GotoYBug     )>0 then GotoYBug     :=-1;
 if (forcetest and t_PanUpBug     )>0 then PanUpBug     :=-1;
 if (forcetest and t_PanLeftBug   )>0 then PanLeftBug   :=-1;

 {obstara parametr test}
 if Splitting   <>-1 then test:=test and (65535-t_Splitting   );
 if SetvisStepX <>-1 then test:=test and (65535-t_SetvisStepX );
 if SetvisStepX <>-1 then test:=test and (65535-t_SetvisStepXp);
 if SetvisYBug  <>-1 then test:=test and (65535-t_SetvisYBug  );
 if VirtXStep   <>-1 then test:=test and (65535-t_VirtXStep   );
 if WrappingAt  <>-1 then test:=test and (65535-t_WrappingAt  );
 if GotoYBug    <>-1 then test:=test and (65535-t_GotoYBug    );
 if PanUpBug    <>-1 then test:=test and (65535-t_PanUpBug    );
 if PanLeftBug  <>-1 then test:=test and (65535-t_PanLeftBug  );

 {preda vysledek}
 GetNeededTests:=test;
end;

{---------------------------------------------------------------------------
 Interaktivni kontrola nejistych informaci o gfx karte.
 Vola se automaticky pri inicializaci modu.
 Cim vic toho otestuje, tim vetsi je sance ze bude scrollovat plynule,
 ale pokud te testy obtezuji a radsi risknes horsi scrolling, muzes
 zmenit t_test a t_forcetest - to jsou parametry se kterymi
 je TestVga volana pri inicializaci modu.
 Parametry test a forcetest (co vse ma testovat) jsou souctem konstatnt t_*.
   test  - testuje jen to co je unsure
   force - testuje vsechno
 Pred volanim musi byt nastaven mod, ve kterem to chces merit,
 vsechny speciality jako split/setvis musi byt v zakladnim stavu.
 Testem se mod nezmeni, pouze se smaze obrazovka, pripadne na ni zustanou
 nejake nesmazane hlasky, muze byt rozhozeny vramXres apod.
 ---------------------------------------------------------------------------}
Procedure TScrolScreen.TestVga(test,forcetest:word);
const textcolor         =1;
var   b                 :PBitmap;
      f                 :PFont;
      rezervaX          :integer;
      rezervaY          :integer;
      testvga_intromsg  :boolean;
      testvga_oldexpand :boolean;

 function MyAskKey:boolean;
  begin
   SetHwCol(textcolor,63,63,63);
   MyAskKey:=AskKey(#13#27)=#13;
   SetHwCol(textcolor,0,0,0);
  end;

 {vycentruje text a hodi ho na obrazovku do vysky outY,
  do rezervaX,Y nastavi pocet volnych pixelu mezi krajem textu a obrazovky}
 procedure outtext(deltaX:integer;outY:word;st:string);
  var   y,prop,sirka,kraj:word;
  begin
   if MapModel=model_text then st:=Kamenici2Ascii(st);
   b^.Clr2Ful;
   if b^.MapModel=model_text then begin prop:=1;y:=0;end
                             else begin prop:=0;y:=-f^.maxnad;end;
   sirka:=Fonty.OutStr(st,b,0,y,f,prop,textcolor);
   kraj:=(Xres-sirka) div 2;
   rezervaX:=minI(rezervaX,kraj);
   rezervaY:=minI(rezervaY,(Yres-(2*maxI(f^.sizeOver,f^.sizeUnder)+1)) div 2);
   b^.transparent:=true;
   BtF2Box(b,kraj+deltaX,outY);
  end;

 {uvodni hlaska pred interakcemi}
 procedure intromsg;
  begin
   {pripravi font a bitmapku pro outtext}
   if f=nil then f:=caFontGet(fnDefault);
   if f=nil then erFile(fnDefault);
   if b=nil then New(b,Init(MapModel,minW(Xres,320),16));
   if b=nil then Halt(erLowMem);
   {zobrazi info}
   Clr2Ful;
   if testvga_intromsg then begin
     SetVis(0,0);
     OutText(0,round(Yres*0.20),'- TEST GRAFICKê KARTY -');
     OutText(0,round(Yres*0.42),'ûiÉ se instrukcemi na obrazovce.');
     OutText(0,round(Yres*0.52),'Pokud jsi v oknà, p©epni do fullscreenu!');
     OutText(0,round(Yres*0.80),'...ENTER - pokraáov†n°...');
     testvga_intromsg:=false;
     repeat until MyAskKey;
     Clr2Ful;
     end;
  end;

 function  testSplit:shortint;
  var i,j:integer;
  label 1;
  begin
   testsplit:=-1;
   IntroMsg;
   i:=0;
   j:=1;
   OutText(0,round(Yres*0.46),'Jestli se text hòbe, stiskni ENTER.');
   OutText(0,round(Yres*0.54),'V opaánÇm p©°padà ESC.');
   1:
   SetHwCol(textcolor,63,63,63);
   repeat
     inc(i,j);
     if (i=0) or (i=maxSplitY div 4) then j:=-j;
     SplitY(i);
     SyncRet;
   until keypressed;
   SetHwCol(textcolor,0,0,0);
   case readkey of #13:testsplit:=1;
                   #27:testsplit:=0;
                   else goto 1;
                   end;
   SplitY(maxSplitY);
  end;

 function  testSetvis(presnost:word):integer;
  var   step:integer;
        j,w1,w2:word;
        result:integer;
  label 0,2;
  begin
   result:=-1;
   if VesaMode then begin
     {zkusi autodetekci}
     if not VesaSetvis(0,1) then result:=0 else begin
        if MapModel=model_text then begin
          {neni vertikalni scrol fast (napr po znacich)?}
          w1:=vga_ReadCrtcW($c);
          VesaSetvis(0,0);
          w2:=vga_ReadCrtcW($c);
          if (w2=0) and (w1<>0) then begin
            result:=0;
            goto 2;
            end;
          {neni horizontalni scrol fast (napr po znacich)?}
          VesaSetvis(40,0);
          w1:=vga_ReadCrtcW($c);
          if (w2=0) and (w1>10) then begin
            result:=0;
            goto 2;
            end;
          end;
        {hybe se crtc zhruba tak jak ma?}
        for j:=0 to 4 do begin
          VesaSetvis(1 shl j,0);
          w1:=vga_ReadCrtcW($c);
          if w1>0 then begin
            VesaSetvis(2 shl j,0);
            w2:=vga_ReadCrtcW($c);
            if w2=2*w1 then begin
              result:=1 shl j;{urcite jde X po tolika pixelech}
              goto 0;
              end;
            end;
          end;
        end;
     end;
   0:
   if (result>=0) and (result<=presnost) then goto 2;
   {testuje rucne}
   IntroMsg;
   OutText(0,round(Yres*0.50),'ENTER jestli se text cuk†, jinak ESC');
   if ((result>4) or (result<0)) and (presnost<=4)
    then step:=4
    else step:=presnost;
   SetHwCol(textcolor,63,63,63);
   repeat
     setvis(0,0);
     refresh(6);
     setvis(step,0);
     refresh(3);
     if keypressed then
      case readkey of
                   #13:begin
                       result:=step;
                       if step<=presnost then break;
                       step:=step shr 1;
                       end;
                   #27:begin
                       if step>=16 then begin result:=0;break;end;
                       step:=step shl 1;
                       end;
                   end;
   until false;
   SetHwCol(textcolor,0,0,0);
   2:
   SetVis(0,0);
   testsetvis:=result;
  end;

 function  testWrap:integer;
  const pixs=500;
  var i,j,x,y,sy,posun:integer;
  label 1;
  begin
   testwrap:=-1;
   if setvisStepX<1 then exit;{bez toho nelze detekovat}
   testwrap:=0;
   IntroMsg;
   OutText(0,0,'Stiskni ENTER.');
   i:=1;
   {do I*64KB spocita nejmensi mocninu dvou do ktere se vejde cela obrazovka}
   {ve VGA packed necha 1*64KB}
   if Vesamode or (MapModel<>model_packed) then begin
     j:=HiWord(longint(Xres)*Yres*BiPP div 8-1);
     while j>0 do begin i:=i shl 1;j:=j shr 1;end;
     end;
   {zkousi jestli newrapuje I*64KB nebo na nasledujicich mocninach dvou az do konce vram}
   while i*64<VramSizeKB do begin
     y:=65536*i div vramXres;
     if y<Yres then sy:=0 else sy:=y-Yres;
     Setvis(0,sy+16);
     if i<VramSizeKB div 64 then OutText(0,y,'Stiskni ESC.');
     if MyAskKey then begin testwrap:=i;goto 1;end;
     if i<VramSizeKB div 64 then Clr2Box(0,y,Xres,16);
     i:=i shl 1;
     refresh(5);
     end;
   {zkousi jestli newrapuje presne na konci vram}
   if i*64=VramSizeKB then begin
     Clr2Ful;
     sy:=vramYres-Yres div 2;
     Setvis(0,sy);
     posun:=Xres-longint(VramSizeKB)*1024 mod sizeXb;
     for j:=0 to pixs do begin
       x:=Xres div 2+round(Xres/4*cos(j/pixs*pi));
       y:=round(Yres/3*sin(j/pixs*pi));
       Col2Box(x+posun,y,1,1,textcolor);
       Col2Box(x,vramYres-1-y,1,1,textcolor);
       end;
     OutText(0,vramYres-Yres div 4,'Je-li vidàt jen pñlkruënice, stiskni ESC.');
     OutText(posun,Yres div 4,'Stiskni ENTER, je-li cel†.');
     if MyAskKey then begin testwrap:=i;goto 1;end;
     end;
   1:
   SetVis(0,0);
  end;

 function  testVirtXStep:integer;
  var oldvramXres:word;
      i,result:word;
      oldcrtc,newcrtc:word;
  label 1,2;
  begin
   result:=0;
   {zkusi autodetekci}
   oldvramXres:=vramXres;
   oldcrtc:=vga_GetLineOffset;
   if not SetVramXres(vramXres+1) then goto 2;
   newcrtc:=vga_GetLineOffset;
   if (oldcrtc<>0) and (newcrtc<>0) and (oldcrtc<>newcrtc) and (vramXres<>oldvramXres)
    then begin result:=vramXres-oldvramXres;goto 2;end;
   {testuje rucne}
   IntroMsg;
   OutText(0,0,'Stiskni ESC.');
   oldvramXres:=vramXres;
   for i:=1 to 16 do begin
     if not SetVramXres(oldvramXres+i) then goto 2;
     if vramXres>oldvramXres then begin
       OutText(0,Yres div 2,'Stiskni ENTER.');
       if MyAskKey then result:=vramXres-oldvramXres;
       goto 2;
       end;
     end;
   2:
   SetVramXres(Xres);

   {*dodelat (tohle je kvuli matroxum)}
   if (result<0) or (result>32) then result:=0;

   testVirtXStep:=result;
  end;

 function  testSetvisYBug:integer;
  function CheckIt(n:integer):boolean;
    var sy,x,y:word;
        st:string;
    begin
     IntroMsg;
     SetvisYBug:=n;
     sy:=(Xres div 3) div (vramXres-Xres);
     Setvis(0,sy);
     st:='Je-li sloupec textu uprost©ed obrazovky, stiskni ENTER. Je-li vychòlen doprava nebo doleva, stiskni ESC.';
     y:=0;
     while st<>'' do begin
       inc(y,Yres div 20);
       OutText(0,sy+y,CutString(' ',st));
       end;
     CheckIt:=MyAskKey;
    end;
  var   i,w:word;
  label 2;
  begin
   testSetvisYBug:=-1;
   if not VesaMode then begin testSetvisYBug:=0;exit;end;{test se tyka jen vesa modu}
   if (virtXstep<1) or (setvisStepX<1) then exit;{nelze detekovat}
   if not SetVramXRes(Xres+32) then goto 2;
   if not VesaSetvis(0,1) then goto 2;
   {zkusi autodetekci}
   w:=vga_ReadCrtcW($c);
   if w>0 then
    for i:=1 to 5 do
     if (1 shl i)*w=vramXres then begin testSetvisYBug:=0;goto 2;end else
     if (1 shl i)*w=    Xres then begin testSetvisYBug:=1;goto 2;end;
   {testuje rucne}
   if CheckIt(0) then testSetvisYBug:=0 else{vse ok}
    if CheckIt(1) then testSetvisYBug:=1 else{nalezen YBug}
     begin testSetvisYBug:=-1;SetvisStepX:=0;end;{ani ok ani YBug -> zakaze setvis}
   2:
   SetVis(0,0);
   SetVramXRes(Xres);
  end;

 function  testGotoYBug:integer;
  var i,old1,old2:integer;
      w:word;
      oldcursor:boolean;
  label 2;
  begin
   testGotoYBug:=-1;
   if MapModel<>model_text then begin testGotoYBug:=0;exit;end;{test se tyka jen textmodu}
   if virtXstep<1 then exit;{bez toho nelze detekovat}
   old1:=buflineFirst; buflineFirst:=0;
   old2:=buflines;     buflines:=30000;
   if not SetVramXRes(Xres+4) then goto 2;
   {zkusi autodetekci}
   inherited GotoXY(0,1);
   w:=vga_ReadCrtcW($e);
   if w>0 then
    if w=vramXres then begin testGotoYBug:=0;goto 2;end else
    if w=    Xres then begin testGotoYBug:=1;goto 2;end;
   {testuje rucne}
   IntroMsg;
   OutText(0,Yres div 2,'Pokud se kurzor pohybuje kolmo (v jednom sloupci), stiskni ENTER. Jinak ESC.');
   oldcursor:=vga_ShowCursor;
   i:=0;
   SetHwCol(textcolor,63,63,63);
   repeat
     refresh(5);
     i:=(i+1) mod Yres;
     inherited GotoXY(Xres div 2,i);
     if keypressed then
      case readkey of
                   #13:begin
                       testGotoYBug:=0;
                       break;
                       end;
                   #27:begin
                       testGotoYBug:=1;
                       break;
                       end;
                   end;
   until false;
   SetHwCol(textcolor,0,0,0);
   if not oldcursor then vga_HideCursor;
   2:
   SetVramXRes(Xres);
   buflineFirst:=old1;
   buflines:=old2;
  end;

 function  testPanUpBug:integer;
  var i,old1,old2,oldbug:integer;
      oldmet:TScrolMethod;
  begin
   testPanUpBug:=-1;
   if MapModel<>model_text then begin testPanUpBug:=0;exit;end;{test se tyka jen textmodu}
   if setvisStepX<1 then exit;{bez toho nelze detekovat}
   old1:=buflineFirst;  buflineFirst:=0;
   old2:=buflines;      buflines:=30000;
   oldbug:=PanUpBug;    PanUpBug:=0;
   oldmet:=scrolMethod; scrolMethod:=doublebufferin;
   IntroMsg;
   OutText(0,Yres*2 div 3,'Pokud se text pohybuje plynule, stiskni ENTER. Jinak ESC.');
   i:=0;
   posNext.x:=0;
   SetHwCol(textcolor,63,63,63);
   repeat
     i:=(i+1) mod (charYres*Yres);
     posNext.y:=abs(charYres*Yres div 2-i);
     ScrolSetVis;
     SyncRet;
     if keypressed then
      case readkey of
                   #13:begin
                       testPanUpBug:=0;
                       break;
                       end;
                   #27:begin
                       testPanUpBug:=1;
                       break;
                       end;
                   end;
   until false;
   SetHwCol(textcolor,0,0,0);
   SetVis(0,0);
   buflineFirst:=old1;
   bufLines:=old2;
   PanUpBug:=oldbug;
   scrolMethod:=oldmet;
  end;

 function  testPanLeftBug:integer;
  var i,old1,old2,oldbug:integer;
      oldmet:TScrolMethod;
  begin
   testPanLeftBug:=-1;
   if VesaMode then begin testPanLeftBug:=0;exit;end;{test se tyka jen vga}
   if setvisStepX<1 then exit;{bez toho nelze detekovat}
   old1:=buflineFirst;  buflineFirst:=0;
   old2:=buflines;      buflines:=30000;
   oldbug:=PanUpBug;    PanUpBug:=0;
   oldmet:=scrolMethod; scrolMethod:=doublebufferin;
   IntroMsg;
   OutText(Xres div 4,Yres*6 div 16,'Pokud se text');
   OutText(Xres div 4,Yres*7 div 16,'pohybuje plynule,');
   OutText(Xres div 4,Yres*8 div 16,'stiskni ENTER.');
   OutText(Xres div 4,Yres*10 div 16,'Jinak ESC.');
   i:=0;
   posNext.y:=0;
   SetHwCol(textcolor,63,63,63);
   repeat
     i:=(i+1) mod (charXres*Xres);
     posNext.x:=abs(charXres*Xres div 2-i);
     ScrolSetVis;
     SyncRet;
     if keypressed then
      case readkey of
                   #13:begin
                       testPanLeftBug:=0;
                       break;
                       end;
                   #27:begin
                       testPanLeftBug:=1;
                       break;
                       end;
                   end;
   until false;
   SetHwCol(textcolor,0,0,0);
   SetVis(0,0);
   buflineFirst:=old1;
   bufLines:=old2;
   PanUpBug:=oldbug;
   scrolMethod:=oldmet;
  end;

var   i,j:integer;
      oldpen:byte;
Begin
 testvga_intromsg  :=true;
 testvga_oldexpand :=ExpandFul(true);

 f:=nil;
 b:=nil;

 {zrusi parametr forcetest}
 test:=GetNeededTests(test,forcetest);

 {je vubec neco co je treba testovat?  ne->skonci uspechem}
 if test<>0 then begin

   {je-li v textmodu, schova kurzor}
   if MapModel=model_text then vga_HideCursor;

   oldpen:=pen;
   pen:=PEN_VRAM;

   if (test and t_Splitting   )>0 then Splitting   :=testSplit;     {hned}
   if (test and t_SetvisStepX )>0 then SetvisStepX :=testSetvis(16);{hned}
   if (test and t_SetvisStepXp)>0 then SetvisStepX :=testSetvis(1); {hned}
   if (test and t_WrappingAt  )>0 then WrappingAt  :=testWrap;      {az po setvis}
   if (test and t_VirtXStep   )>0 then VirtXStep   :=testVirtXStep; {hned}
   if (test and t_SetvisYBug  )>0 then SetvisYBug  :=testSetvisYBug;{az po setvis! a virtxstep}
   if (test and t_GotoYBug    )>0 then GotoYBug    :=testGotoYBug;  {az po virtxstep}
   if (test and t_PanUpBug    )>0 then PanUpBug    :=testPanUpBug;  {az po setvis}
{*enablovat az po odladeni s mach64
  ted to koriguje bug v textmodu ale selhava v grafice (nebo obracene?)
   if (test and t_PanLeftBug  )>0 then PanLeftBug  :=testPanLeftBug;{az po setvis}

   {zabrani bliknuti obrazu, v textmodu zachova paletu, jinde ne}
   Clr2Ful;
   if MapModel=model_text then SetHwCol(textcolor,0,0,40);

   pen:=oldpen;

   {je-li v textmodu, zas kurzor obnovi}
   if MapModel=model_text then vga_ShowCursor;

   {uvolni bitmapku a font pouzite pro outtext}
   KillObj(b);
   caLeave(f);

   {ulozi zjistene udaje}
   {pozdeji uz nevolat SaveCfg abych mohl volne menit Cfg lokalniho modu}
   SaveCfg;
   end;

 {zakaze splitting ve velkych vesa modech}
 {zakaz se neuklada (SaveCfg), protoze se tyka jen nekterych modu}
 {predpokladam ze u vetsich rozliseni je DoubleScan=1}
 if VesaMode and (Yres>=1024) then Splitting:=0;

 ExpandFul(testvga_oldexpand);
End;


{---------------------------------------------------------------------------
 Vraci kolik milisekund ubehlo od posledniho eventu (stisk klavesy,
 pohyb mysi). Eventy detekuje jen kdyz jsou zavesene handlery!
 ---------------------------------------------------------------------------}
var lasteventtime:longint;

FUNCTION TimeFromLastEvent:longint;
begin
 if mouseDirty or kDirty then begin
   lasteventtime:=GetMs;
   mouseDirty:=false;
   kDirty:=false;
   end;
 TimeFromLastEvent:=GetMs-lasteventtime;
end;

{---------------------------------------------------------------------------
 Pomocna data pro INI soubory:
  Seznam promennych lisicich se kartu od karty.
 SYNTAXE: nazev malymi pismeny,0,flags,typ,offset promenne v datasegmentu
 ---------------------------------------------------------------------------}
PROCEDURE VgaVars;assembler;
 asm
  db 'vgatext'                 ,0,i_use1,i_8sho;dw offset Cfg+2+10*1
  db 'vgapacked'               ,0,i_use1,i_8sho;dw offset Cfg+2+10*2
  db 'vgaunchained'            ,0,i_use1,i_8sho;dw offset Cfg+2+10*3
  db 'vesatext'                ,0,i_use1,i_8sho;dw offset Cfg+2+10*4
  db 'vesapacked'              ,0,i_use1,i_8sho;dw offset Cfg+2+10*5
  db 0
 end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='scrol';
var result:integer;
    OldShutDown:procedure;

procedure ShutDown;far;
 begin
  if CurScrolScreen<>nil then CurScrolScreen^.TmrScrolStop;
  if @OldShutDown<>nil then OldShutDown;
 end;

procedure UserInit;
 begin
  autoscrolspeed   :=30;
  SafeMode         :=false;
  usetimer         :=false;
  wanttimer        :=false;
  usingtimer       :=false;
  CitlivostSipek   :=30;
  CitlivostNumpadu :=30;
  CurScrolScreen   :=nil;
  presslength      :=0;
  lasteventtime    :=GetMs;
  t_test           :=t_all;
  t_forcetest      :=0;
  OldShutDown      :=ShutDownInts;
  ShutDownInts     :=ShutDown;
  {$ifdef safestack}
  tady je to reseno tak, ze safestack nastavi o 30000 bajtu niz na hlavnim stacku,
  musis tam ale mit misto! ...{$M 31000}
  asm mov ax,sp;sub ax,30000;mov backstack.word[0],ax;mov backstack.word[2],ss;end;
  {$endif}
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