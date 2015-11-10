{
 Priklad1 upraveny pro virtualni obrazovku (vyuziva unitu scrol).
 Vyzaduje soubory PRIKLAD.INI, PRIKLAD.X, MODERN.FN, MODER_NP.FN.
 Sipkami a mysi lze scrollovat, numpad emuluje mys.
 Pribyla ukazka reakce na eventy a ukazka dialogu.
 Jen tak pro zajimavost vypisuje koncovou hlasku Bye! uplne jinym zpusobem.
 Obrazovka S neni TScreen ale TScrolScreen. Z toho plynou tyto odlisnosti:
   - odpada zapinani handleru klavesnice, o to se stara SetActivity
   - pribyva volani InitMap/DoneMap a SetActivity
   - na obrazovku se nekresli primo (s.MouseHide;s.BtF2Box;s.MouseShow)
     ale pres jeji bitmapu (s.map^.BtF2Box;s.MapRedrawBox)
   - INI soubor nema jen jednu sekci, ale hned dve, proto je zde SecSelector
   - pozadi neni cerne, dal jsem na nej zvetseny obrazek priklad.x
   - po nastaveni modu je paleta cerna, vse si musime nastavit sami
   - aby nedochazelo ke kolizim v palete, je pouzit alokator palety dlgPal

 Vesela historka z nataceni - jak jsem hledal chybu.
  Kdyz zkusis klikanim levym mysitkem menit sipku mysi a vzdy zajedes
  az k pravemu kraji obrazovky, nekdy tam zustane skvira na 1 pixel.
  Zoufale jsem hledal chybu nekde v zoomovani textur... Teprv po delsi
  dobe mi doslo, ze mi mys skace po dvou pixelech a pri liche sirce 'sipky'
  to proste ke kraji sednout nemuze :).
  Mam jeden z mnoha hloupych driveru, ktere v SVGA modech skacou po 8
  pixelech. Tento problem by zcela osetril prikaz mouseSetJump(8,8),
  ale 8x by klesla maximalni rychlost (citlivost) mysi. Radsi volim kompromis
  s mouseSetJump(4,4) (je to pouzito v unite vga), hloupe drivery pak skacou
  po 2 pixelech.
}

{$i define.inc}

{$ifndef dpmi}
 kompiluj pro protekt (v borland pascalu), v realu by nebylo dost pameti.
 a ne abys dal tuhle hlasku do komentare a jel dal v realu :)
{$endif}

Uses Chyby,Memo,Dos,Objects,
     Stringy,Sys,Ini,Vga,Scrol,Cache,Fonty,Dialogy,Fajly,Key;

Var s      :TScrolScreen;{obrazovka}
    s2     :PScreen;{jina obrazovka, pouzita pro dosshell}
    ahoj   :PBitmap;{nejaka bitmapka}
    pozadi :PBitmap;{bitmapa na pozadi}
    lista  :PBitmap;{lista v dolni casti obrazovky}
    pic    :PBitmap;{original obrazku na pozadi (pred zvetsenim)}
    f      :PFont;  {nejaky font}
    mx,my  :integer;{poloha mysi}
    vx,vy  :integer;{poloha obrazovky nad bitmapou}
    i      :word;
    x,y,r,dx,dy:real;{promenne pro vypocty pohybu se setrvacnosti}
    event  :TEvent;
    pos    :TPoint;
    xx,yy  :integer;
    strcol :TdlgCollection;

Const
    napis1='Ahoj!';
    napis2='Uk zka pou‘it¡ CiA 0.50.';
    napis3='F1 - seznam funkc¡.';

  {---------------------------------------------------------------------------
  Loader obrazku, pro maximalni jednoduchost umi pouze format X bez komprese,
  ktery vypada takto:
   -sirka(word)
   -vyska(word)
   -pocet barev(byte)
   -paleta setresena nahoru(3*pocet barev, hodnoty 0..63)
   -bitmapa(sirka*vyska)
  K tvorbe X muzes pouzit PictView, nezapomen ale vypnout kompresi (pod F7).
  ---------------------------------------------------------------------------}
  var xsirka,xvyska:word;xbarev:byte;{"header", musi byt v datasegmentu}
  FUNCTION PicLoad(name:PathStr):PBitmap;
  var f:file;
      b:PBitmap;
      y:word;
  begin
   b:=nil;
   assign(f,name);
   reset(f,1);
   if ioresult=0 then begin
     blockread(f,xsirka,5);
     new(b,init(model_packed,xsirka,xvyska));
     if b<>nil then begin
       with b^.MainPal^ do begin
         first:=256-xbarev;
         blockread(f,pal[3*first],3*xbarev);
         end;
       for y:=0 to b^.sizeY-1 do blockread(f,b^.tab^[y]^,xsirka);
       end;
     close(f);
     end;
   PicLoad:=b;
  end;

  {---------------------------------------------------------------------------
  Seznam promennych v INI souboru.
  SYNTAXE: nazev malymi pismeny,0,flags,typ,offset promenne v datasegmentu;
           uplne na konci nula
  ---------------------------------------------------------------------------}
  Procedure Vars;assembler;
   asm
    db 'mousespeed',0,     0,i_word;dw offset MouseSpeed {globalni promenna z vga}
    db 'mys.x'     ,0,i_wral,i_intg;dw offset mx         {mistni promenne}
    db 'mys.y'     ,0,i_wral,i_intg;dw offset my
    db 'view.x'    ,0,i_wral,i_intg;dw offset vx
    db 'view.y'    ,0,i_wral,i_intg;dw offset vy
    db 0
   end;

  {---------------------------------------------------------------------------
  SecSelector - funkce pro spravu sekci v INI souboru. Strucne receno,
  podle nazvu sekce prepina na tabulku ve ktere je obsah sekce popsan.
  Zde mame dve tabulky: lokalni Vars a VgaVars z unity scrol.
  ---------------------------------------------------------------------------}
  var iniMode:char;
  FUNCTION SecSelector(var sekce:openstring;var varstab:pointer):PathStr;far;
  begin
   {Implicitne nastavi tabulku promennych na vars, protoze tam je vetsina
    promennych. Nekdy ale nastaveni jeste zmeni, viz nize.}
   varstab:=@vars;
   {prijem signalu pro zmenu modu}
   if Str2Char(sekce) in [iniModeR,iniModeU,iniModeA,iniModeC,iniModeD,iniModeW]
    then iniMode:=sekce[1]
   {vetveni podle modu}
    else case iniMode of
       iniModeR,{cte, pise a upgraduje vse, pro sekci scrol prepne varstab}
       iniModeW,
       iniModeU:begin
                 SecSelector:='x';
                 if sekce='scrol' then varstab:=@vgavars;
                end;
       iniModeA,{zadne sekce nepridava}
       iniModeC,{nezname sekce ignoruje, do nove verze je neprenese}
       iniModeD:SecSelector:='';
       end;
  end;


Begin
 {zaregistruje hlasku odpovidajici chybovemu kodu erOk, tedy korektnimu
  ukonceni. hlasky s mezerou na konci negeneruji cekani na stisk klavesy}
 BugList.Register(erOk,'Bye! ');

 {nahraje obrazek}
 pic:=PicLoad('priklad.x');
 if pic=nil then erFile('priklad.x');

 {cte promenne z ini}
 iniSetup(nil,SecSelector,nil);
 iniRead('priklad.ini');

 {nahraje si do pameti nejaky font}
 {v teto ukazce kvuli vypsani Ahoj!}
 f:=caFontGet(fnDefault);
 if f=nil then erFile(fnDefault);

 {pri nastaveni modu nebude testovat wrapping}
 {nevyhoda: za urcitych okolnosti zhorsi scrolling}
 {vyhoda: uvodni interaktivni testy budou o dost kratsi}
 t_test:=t_all-t_WrappingAt;

 {nastavi nejaky mod s 256 barvami (nejblizsi k tomuto rozliseni)}
 if not s.Init(model_256,640,480,0) then Halt(erBadMode);
 {muzes si zkusit i jine mody}
 {kdybys chtel nastavit konkretni mod a zadny jiny, volej init takto:
  if not s.Init(model_packed,0,0,P640x480) then Halt(erBadMode);}

 {vytvori alokator palety pro dialogy}
 New(dlgPal,Init);
 if dlgPal=nil then Halt(erLowMem);
 {ten do sebe vstreba paletu obrazku a mysi, aby moh pouzivat jejich barvy}
 dlgPal^.Take(pic^.MainPal);
 dlgPal^.Take(s.mousePal);

 {nastavi polohu mysi tak, jak ji nacet z priklad.ini}
 s.MouseSetPos(mx,my);

 {vygeneruje bitmapku s napisem "ahoj"}
 New(ahoj,Init(model_packed,50,50));               {alokuje malou bitmapku}
 if ahoj=nil then Halt(erLowMem);                  {pri neuspechu skonci}
 ahoj^.Clr2Ful;                                    {vymaze ji cernou barvou}
 ahoj^.Col2Box(1,1,47,47,dlgPal^.Alloc(63,63,63)); {vnitrek vyplni bilou}
 ahoj^.Col2Box(2,2,44,44,dlgPal^.Alloc(0,0,55));   {vnitrek vyplni modrou}
 OutStr(napis1,ahoj,7,27,f,0,dlgPal^.Alloc(63,63,63));{text pise bilou}

 {vygeneruje listu}
 lista:=pic^.ResizeFulCopy(s.Xres,s.Yres div 6);
 if lista=nil then Halt(erLowMem);
 lista^.Clr2Box(0,0,lista^.sizeX,1);
 OutStr(napis2,lista,50,lista^.sizeY div 3*1,f,0,dlgPal^.Alloc(63,63,63));
 OutStr(napis3,lista,90,lista^.sizeY div 3*2,f,0,dlgPal^.Alloc(63,63,63));

 {vygeneruje pozadi nad kterym se scrolluje}
 {muzes si nastavit libovolne rozmery zvetseniny, ale aspon 800x800
  at se nedostane poletujici "ahoj" mimo rozsah}
 pozadi:=pic^.ResizeFulCopy(1200,1200);
 if pozadi=nil then Halt(erLowMem);

 {predani pozadi a listy obrazovce}
 {obrazovka je prijme a nakonec v MapDone i znici}
 {vx,vy je pocatecni poloha nad pozadim}
 s.MapInit(pozadi,lista,vx,vy);
 {priradi dlgPal k obrazku na pozadi (s.map)}
 {pri navratu z dosshellu se totiz obnovi pouze paleta obrazku na pozadi}
 {pozor: dlgPal bude automaticky zrusena zaroven se zrusenim s.map}
 dlgPal^.flags:=pfStill+pfOnScreen+pfActive;
 s.map^.AddPal(dlgPal);
 {zahodi original obrazku na pozadi}
 pic^.Free;
 {pocatecni nastaveni palety}
 s.Fade(0);
 {pocatecni vykresleni obrazovky}
 s.MapRedraw;
 {zahajeni scrollingu}
 s.SetActivity(syncLetsRock);

 {inicializace pohybu}
 dx:=1000;
 dy:=0;
 x:=100;
 y:=200;

 {hlavni smycka}
 repeat

   r:=sqrt(x*x+y*y)+1;                     {vygeneruje nejake souradnice}
   dx:=dx-r/100*x+random(100)-50;
   dy:=dy-r/100*y+random(100)-50;
   x:=x+dx/101;
   y:=y+dy/100;
   xx:=s.map^.sizeX div 2+round(x);
   yy:=s.map^.sizeY div 2+round(y);
   s.map^.BtF2Box(ahoj,xx,yy);             {kresli bitmapku ahoj do bitmapy s.map}
   s.MapRedrawBox(xx,yy,ahoj^.sizeX,ahoj^.sizeY);{vyrez bitmapy prekresli na obrazovku}

   s.Sync;                                 {zabezpeceni scrollingu}

   {kdyz prijde event (tj. kdyz neco stisknes, mys ci klavesnici)...}
   if s.GetEvent(event,pos) then

     {reaguje podle kodu klavesy/tlacitka - CODE(event)}
     {jsou i jine moznosti, muze reagovat podle CHAR(event) a EXTCHAR(event)}
     case code(event) of

       {ukazka par dialogu kdyz stisknes F2,F3...}
       kF2:dlgLine(dlgInsert,'Baf. Tv–j obl¡ben˜ muzikant?',30,'James Brown','');
       kF3:dlgFile(0,'Dˆsiv˜ fileselector.','*.pas','p©edvolba');
       kF4:dlgMsg('Prohl‚dni si zdroj k a nastav libovoln‚ rozli¨en¡.'#13#10+
                  'Ale pozor, t©eba v 320x200 se tahle zpr va nevejde'#13#10+
                  'na obrazovku :).');
       kF5:dlgMsg(Str2TempPc(s.GetDebugInfo(1)));
       kF6:dlgMsg(Str2TempPc(s.GetDebugInfo(2)));
       kF7:dlgMsg(Str2TempPc(s.GetDebugInfo(3)));
       kF8:dlgMsg(Str2TempPc(s.GetDebugInfo(4)));
       kF9:dlgMsg(Str2TempPc(s.GetDebugInfo(5)));

       {dalsi ukazka dialogu, umoznuje skoncit kdyz nezadas Continue}
       mbRight:if dlgExit<>'C' then break;

       kEsc:break;

       {ukazka jednoduchosti dos shellu, resp. sily TScreen}
       kD:begin
          {vytvorime obrazovku, treba textmod 80x36}
          {kdyz se to povede, zavolame dos. pak obrazovku zas zrusime}
          New(s2,Init(model_text,80,36,0));
          if s2<>nil then begin
            CallCommand('');
            KillObj(s2);
            end;
          {takto reaguje na male i velke D. kdybys mezi nimi chtel rozlisovat,
           v char(event) mas 'd' nebo 'D'.}
          end;

       {kdyz kliknes levym tlacitkem, misto sipky nastavi ahoj}
       {kdyz prostrednim, vrati zpet implicitni sipku}
       mbLeft:s.mouseSetPointer(ahoj^.ResizeFulCopy(1+random(100),1+random(100)),0,0);
       mbMid :s.mouseSetPointer(nil,0,0);

       kF1:begin
           {inicializuje kolekci stringu a zaradi do ni hlasky}
           strcol.Init(10,10);
           strcol.InsertStr('Toto menu.                        (F1)',kF1);
           strcol.InsertStr('Uk zka dialogu: zadej string.     (F2)',kF2);
           strcol.InsertStr('Uk zka dialogu: fileselector.     (F3)',kF3);
           strcol.InsertStr('Uk zka dialogu: zpr va.           (F4)',kF4);
           strcol.InsertStr('Dos shell.                         (D)',kD);
           strcol.InsertStr('Jin  my¨.               (lev‚ my¨¡tko)',mbLeft);
           strcol.InsertStr('Norm ln¡ my¨.     (prost©edn¡ my¨¡tko)',mbMid);
           strcol.InsertStr('Konec s dialogem.      (prav‚ my¨¡tko)',mbRight);
           strcol.InsertStr('Konec hned.                      (Esc)',kEsc);
           {zavola dialog a pak kolekci zrusi}
           i:=dlgMenuCol(@strcol,1+dlgHotkeys);
           strcol.Done;
           {v HiByte(i) ted mame kod klavesy, treba pro treti radek to je kF3}
           {chceme aby se provedla akce odpovidajici klavese F3, proto}
           {kod kF3 pushneme do fronty eventu}
           s.PushEvent(MakeEvent(HiByte(i),#0,#0));
           {v dalsim prubehu programu se event vyzvedne a zpracuje}
           end;

       end;

 {smycka bezi dokud ji nekdo nebreakne}
 until false;

 {ukonceni scrollingu}
 s.SetActivity(syncHolocaust);
 {uvolneni bitmapy}
 s.MapDone;

 {uvolni bitmapku "ahoj"}
 {btw, zde neni nutne, po skonceni programu se pamet odalokuje automaticky}
 ahoj^.Free;

 {nastavi polohu mysi do promennych, ktere pote ulozi do INI}
 mx:=s.mouse.X;
 my:=s.mouse.Y;
 {totez pro polohu obrazovky nad bitmapou}
 vx:=s.posNow.X;
 vy:=s.posNow.Y;

 {vrati puvodni (textovy) mod}
 s.Done;

 {zahodi font}
 {btw, zde neni nutne, pri skonceni programu se cache vyprazdni sama}
 caLeave(f);

 {zapise promenne do ini}
 iniWrite('priklad.ini',0);

 {vyprazdni buffer klavesnice}
 FlushKey;

 {na konci programu se generuje Halt(0),
  vypise se hlaska prirazena chybe 0=erOk}
End.
