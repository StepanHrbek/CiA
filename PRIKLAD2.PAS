{
 Priklad1 upraveny pro virtualni obrazovku (vyuziva unitu scrol).
 Pracuje s velkou bitmapou, proto je nutne kompilovat pro protekt.
 Vyzaduje soubory PRIKLAD.INI, PRIKLAD.X, MODERN.FN.
 Sipkami a mysi lze scrollovat, numpad emuluje mys.
 Zdrojak se od prikladu 1 bez virtualni obrazovky lisi minimalne:
  - S neni TScreen ale TScrolScreen
  - odpada testovani klavesnice a mysi, o eventy se stara GetEvent
  - odpada zapinani handleru klavesnice, o to se stara SetActivity
  - pribyva volani InitMap/DoneMap a SetActivity
  - na obrazovku se nekresli primo (s.MouseHide;s.BtF2Box;s.MouseShow)
    ale pres jeji bitmapu (s.map^.BtF2Box;s.MapRedrawBox)
  - INI soubor nema jen jednu sekci, ale hned dve, proto je zde SecSelector
  - pozadi neni cerne, dal jsem na nej zvetseny obrazek priklad.x
  - jen tak pro zajimavost vypisuje koncovou hlasku Bye! uplne jinym zpusobem
}

{$i define.inc}

{$ifndef dpmi}kompiluj pro protekt, v realu by nebylo dost pameti{$endif}

Uses Chyby,Dos,Objects,Sys,Mys,Ini,Vga,Scrol,Cache,Fonty;

Var s      :TScrolScreen;{obrazovka}
    b      :PBitmap;{nejaka bitmapka}
    pic    :PBitmap;{original obrazku na pozadi (pred zvetsenim)}
    f      :PFont;  {nejaky font}
    mx,my  :integer;{poloha mysi}
    vx,vy  :integer;{poloha obrazovky nad bitmapou}
    i      :word;
    x,y,r,dx,dy:real;{promenne pro vypocty pohybu se setrvacnosti}
    event  :word;
    pos    :TPoint;
    xx,yy  :integer;

Const
    napis  :string[6]='Ahoj!';
    mezer  :word=0;
    sirmez :word=0;

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

 {nastavi nejaky mod (nejblizsi k tomuto rozliseni)}
 if not s.Init(model_packed,640,480,0) then Halt(erBadMode);
 {muzes si zkusit jine packed a unchained mody}
 {kdybys chtel nastavit konkretni mod a zadny jiny, volej init takto:
 if not s.Init(model_packed,0,0,P640x480) then Halt(erBadMode);}

 {nastavi polohu mysi tak, jak ji nacet z priklad.ini}
 s.MouseSetPos(mx,my);

 {vygeneruje bitmapku s napisem "ahoj"}
 New(b,Init(model_packed,50,50));    {alokuje malou bitmapku}
 if b=nil then Halt(erLowMem);       {pri neuspechu skonci}
 b^.Col2Ful(0);                      {vyplni ji jednou barvou}
 b^.Col2Box(1,1,47,47,251);          {vnitrek vyplni jinou}
 b^.Col2Box(2,2,44,44,252);          {vnitrek vyplni jinou}
 OutText(length(napis),@napis[1],mezer,sirmez,b,7,27,f,0,31);

 {nastavi na karte paletu sipky}
 s.MousePalShow;

 {inicializace pohybu}
 dx:=1000;
 dy:=0;
 x:=100;
 y:=200;

 {predani bitmapy obrazovce, predava se zvetsenina pic}
 {muzes si nastavit libovolne rozmery zvetseniny, ale aspon 800x800
  at se nedostane poletujici "ahoj" mimo rozsah}
 s.MapInit(pic^.ResizeFulCopy(1200,1200),nil,vx,vy);
 {pocatecni nastaveni palety}
 s.Fade(0);
 {pocatecni vykresleni obrazovky}
 s.MapRedraw;
 {zahajeni scrollingu}
 s.SetActivity(syncLetsRock);

 {dokud nezareagujes, neco dela}
 {btw, kdyz GetEvent skonci uspechem, mas udalost ulozenou v event a pos}
 while not s.GetEvent(event,pos) do begin
   r:=sqrt(x*x+y*y)+1;                     {vygeneruje nejake souradnice}
   dx:=dx-r/100*x+random(100)-50;
   dy:=dy-r/100*y+random(100)-50;
   x:=x+dx/101;
   y:=y+dy/100;
   xx:=s.map^.sizeX div 2+round(x);
   yy:=s.map^.sizeY div 2+round(y);
   s.map^.BtF2Box(b,xx,yy);                {kresli bitmapku b do bitmapy s.map}
   s.MapRedrawBox(xx,yy,b^.sizeX,b^.sizeY);{vyrez bitmapy prekresli na obrazovku}
   s.Sync;                                 {zabezpeceni scrollingu}
   end;

 {ukonceni scrollingu}
 s.SetActivity(syncHolocaust);
 {uvolneni bitmapy}
 s.MapDone;

 {uvolni bitmapku "ahoj"}
 {btw, zde neni nutne, po skonceni programu se pamet odalokuje automaticky}
 b^.Free;

 {nastavi polohu mysi do promennych, ktere pote ulozi do INI}
 mx:=s.mouse.X;
 my:=s.mouse.Y;
 {totez pro polohu obrazovky nad bitmapou}
 vx:=s.posNow.X;
 vy:=s.posNow.Y;

 {vrati puvodni (textovy) mod}
 s.Done;

 {zahodi font}
 {btw, zde neni nutne, po skonceni programu se pamet odalokuje automaticky}
 caLeave(f);

 {zapise promenne do ini}
 iniWrite('priklad.ini',0);

 {vyprazdni buffer klavesnice a skonci}
 FlushKey;
 {na konci programu se generuje Halt(0),
  vypise se hlaska prirazena chybe 0=erOk}
End.
