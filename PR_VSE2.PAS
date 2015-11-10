{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: vse v jednom

 Vse v jednom upravene pro virtualni obrazovku (vyuziva unitu scrol).
 Vyzaduje soubory PRIKLAD.INI, PRIKLAD.GIF, MODERN.FN, MODER_NP.FN.
 Sipkami a mysi lze scrollovat, numpad emuluje mys.
 Pribyla ukazka reakce na eventy a ukazka dialogu.
 Obrazovka S neni TScreen ale TScrolScreen. Z toho plynou tyto odlisnosti:
   - odpada zapinani handleru klavesnice, o to se stara SetActivity
   - pribyva volani MapInit/MapDone a SetActivity
   - na obrazovku se nekresli primo (s.MouseHide;s.BtF2Box;s.MouseShow)
     ale pres jeji bitmapu (s.map^.BtF2Box;s.MapRedrawBox)
   - INI soubor nema jen jednu sekci, ale hned dve, proto je zde SecSelector
   - pozadi neni cerne, dal jsem na nej zvetseny obrazek priklad.gif
   - po nastaveni modu je paleta cerna, vse si musime nastavit sami
}

{$i define.inc}
{$m 20000,80000,80000}

{$ifndef dpmi}
 kompiluj pro protekt (v borland pascalu), v realu by nebylo dost pameti.
 a ne abys dal tuhle hlasku do komentare a jel dal v realu :)
{$endif}

Uses Chyby,Memo,Dos,Objects,
     Stringy,Sys,Ini,Vga,Scrol,Cache,Fonty,Dialogy,Fajly,Key,Tools,LangFile,
     Loadery,LdGIF,LdTXT;

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
    name   :PathStr;

Const
    napis1='Ahoj!';
    napis2='Uk zka pou‘it¡ CiA 1.00.';
    napis3='F1 - seznam funkc¡.';

  {---------------------------------------------------------------------------
  Seznam promennych v INI souboru.
  Podporovane typy a flagy jsou nadeklarovane na zacatku ini.pas.
  SYNTAXE: nazev malymi pismeny,0,flags,typ,offset promenne v datasegmentu;
           uplne na konci nula
  ---------------------------------------------------------------------------}
  Procedure Vars;assembler;
   asm
    db 'mousespeed',0,0,i_byte;dw offset MouseSpeed {globalni promenna z vga}
    db 'mys.x'     ,0,0,i_intg;dw offset mx         {mistni promenne}
    db 'mys.y'     ,0,0,i_intg;dw offset my
    db 'view.x'    ,0,0,i_intg;dw offset vx
    db 'view.y'    ,0,0,i_intg;dw offset vy
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

  {---------------------------------------------------------------------------
  Predvede menu.
  ---------------------------------------------------------------------------}
  FUNCTION TestMenu:TEvent;
  var
    c:TMenuCollection;
  begin
    {inicializuje nesetrizenou kolekci a zaradi do ni hlasky}
    with c do
    begin
     Init(false);
     InsertStr('Toto menu.                         (F1)',kF1);
     InsertStr('Uk zka GUI dialogu.                (F2)',kF2);
     InsertStr('Fileselector a viewer.             (F3)',kF3);
     InsertStr('Pathbrowser.                       (F4)',kF4);
     InsertStr('GUI dialog: zadej string.          (F5)',kF5);
     InsertStr('Nejjednodu¨¨¡ dialog: zpr va.      (F6)',kF6);
     InsertStr('GUI dialog: choice.                (F7)',kF7);
     InsertStr('Dos shell.                          (D)',kD);
     InsertStr('Zvˆt¨¡ my¨.              (lev‚ my¨¡tko)',mcLeftPressed);
     InsertStr('Zmen¨¡ my¨.        (prost©edn¡ my¨¡tko)',mcCenterPressed);
     InsertStr('Konec s dialogem.       (prav‚ my¨¡tko)',mcRightPressed);
     InsertStr('Konec hned.                       (Esc)',kEsc);
    end;
    {zavola dialog a pak kolekci zrusi}
    dlgHotkeys:=true;{=kody polozek lze povazovat za kody hotkey klaves}
    TestMenu:=MakeEvent(dlgMenuKod('',@c,kF1),#0,#0);
    dlgHotkeys:=false;
    c.Done;
  end;

  {---------------------------------------------------------------------------
  Predvede schopnosti GUI.
  ---------------------------------------------------------------------------}
  var Vol_data: record
        MusicVol,EffectsVol: Byte;
        Mute: Boolean;
      end;
      Vol_txt1,Vol_txt2,Vol_txt3: PGuiText;
  procedure Vol_Idle; far;
  var S: String;
      Hodn: Byte;
  begin
    { Vypocitam procenta a zapisu textovou hodnotu do objektu: }
    Hodn := Trunc((Vol_data.MusicVol-1)/20*100);
    S := Stri(Hodn); while Length(S)<3 do S := ' '+S;
    Vol_txt1^.txt := S+'%';

    Hodn := Trunc((Vol_data.EffectsVol-1)/20*100);
    S := Stri(Hodn); while Length(S)<3 do S := ' '+S;
    Vol_txt2^.txt := S+'%';

    { Kdyz je zapnuto MUTE nebo kdyz je nastavena hlasitost hudby i efektu
      na nulu, tak se zobrazi info, ze zadny zvuk nehraje. }
    Vol_txt3^.txt := eitherS((Vol_data.Mute) or
                             (Vol_data.MusicVol+Vol_data.EffectsVol=2),
                             '‘ dn˜ zvuk',Rep(' ',10));
  end;
  procedure GuiHlasitost;
  var
    P: PCollection;
  begin
    { Vytvorime kolekci a dame do ni objekty: }
    New(P,Init(20,20));
    with P^ do begin
      Insert(New(PGuiText, Init(-1,1,'Nastaven¡ hlasitosti:',$30)));
      Insert(New(PGuiText, Init(-1,2,Rep('Ä',40-2),$31)));
      Insert(New(PGuiText, Init(2,3,'Hudba:',$30)));
      Insert(New(PGuiText, Init(2,4,'Efekty:',$30)));
      Insert(New(PGuiHorizScroll, Init(12,3,21,20)));
      Insert(New(PGuiHorizScroll, Init(12,4,21,20)));
      Vol_txt1 := New(PGuiText, Init(34,3,'%',$30));
      Vol_txt2 := New(PGuiText, Init(34,4,'%',$30));
      Vol_txt3 := New(PGuiText, Init(12,6,'k',$31));
      Insert(Vol_txt1);
      Insert(Vol_txt2);
      Insert(Vol_txt3);
      Insert(New(PGuiCheck, Init(2,6,'Mute',False)));
      Insert(New(PGuiButton, Init(28,6,10,'Ok',MakeEvent(mcRightPressed,#0,#0),1)));
    end;
    Vol_Data.MusicVol := 21;
    Vol_Data.EffectsVol := 21;
    Vol_Data.Mute := False;
    dlgGUI(40,8,p,Vol_Data,Vol_Idle);
    Dispose(P,Done);
  end;
  procedure GuiFormular(Jmeno,Prijmeni: String);
  var
    P: PCollection;
    data: record
      Jmeno,Prijmeni,Heslo,Vek: String;
    end;
  begin
    data.Jmeno := Jmeno;
    data.Prijmeni := Prijmeni;
    data.Heslo := '‘ dn‚';
    data.Vek := '? let';
    New(P,Init(20,20));
    with P^ do begin
      Insert(New(PGuiText, Init(-1,1,'Nˆjak˜ formul ©:',$30)));
      Insert(New(PGuiText, Init(-1,2,Rep('Ä',40-2),$31)));
      Insert(New(PGuiText, Init(2,3,'Jm‚no:',$30)));
      Insert(New(PGuiText, Init(21,3,'P©¡jmen¡:',$30)));
      Insert(New(PGuiInputLine, Init(2,4,15,64,'',True)));
      Insert(New(PGuiInputLine, Init(21,4,15,64,'',False)));
      Insert(New(PGuiText, Init(2,5,'Heslo:',$30)));
      Insert(New(PGuiText, Init(26,5,'Vˆk:',$30)));
      Insert(New(PGuiInputLine, Init(2,6,20,64,'',False)));
      Insert(New(PGuiInputLine, Init(26,6,10,64,'',False)));
      Insert(New(PGuiButton, Init(15,8,10,'Ok',MakeEvent(mcRightPressed,#0,#0),1)));
    end;
    dlgGUI(40,10,p,Data,nil);
    Dispose(P,Done);
  end;
  var CdP_data: record
        Volume: Byte;
      end;
  procedure CdP_Idle; far;
  begin
    case guiCommand of
      1:dlgMsg('<<');
      2:dlgMsg('>>');
      3:dlgMsg('Play');
      4:dlgMsg('Stop');
      5:dlgMsg('Eject');
    end;
    if guiCommand < 6 then guiCommand := 0;
  end;
  procedure GuiCDplayer;
  var
    P: PCollection;

  begin
    CdP_data.Volume := 16;
    New(P,Init(20,20));
    with P^ do begin
      Insert(New(PGuiText, Init(29,1,'CD p©ehr va‡',$30)));
      Insert(New(PGuiButton, Init(2,1,6,'<<',0,1)));
      Insert(New(PGuiButton, Init(9,1,6,'>>',0,2)));
      Insert(New(PGuiButton, Init(16,1,5,'',0,3)));
      Insert(New(PGuiButton, Init(22,1,5,'þ',0,4)));
      Insert(New(PGuiButton, Init(2,3,9,'Eject',0,5)));
      Insert(New(PGuiHorizScroll, Init(13,3,16,0)));
      Insert(New(PGuiButton, Init(31,3,10,'Exit',MakeEvent(mcRightPressed,#0,#0),6)));
    end;
    dlgGUI(43,5,p,CdP_Data,CdP_Idle);
    Dispose(P,Done);
  end;
  procedure GuiPicture;
  var
    P: PCollection;
    data: byte;
  begin
    New(P,Init(20,20));
    with P^ do begin
      Insert(New(PGuiPicture, Init(4,2,-1,-1,Ahoj)));
      Insert(New(PGuiButton, Init(2,6,10,'Ok',MakeEvent(mcRightPressed,#0,#0),1)));
    end;
    dlgGUI(14,8,p,Data,nil);
    Dispose(P,Done);
  end;
  var
   tg_Data: record
     Jmeno: String;
   end;
  procedure tg_Idle; far;
  begin
    case guiCommand of
      1: GuiHlasitost;
      2: GuiFormular(Copy(tg_Data.Jmeno,1,System.Pos(' ',tg_Data.Jmeno)-1),
                     Copy(tg_Data.Jmeno,System.Pos(' ',tg_Data.Jmeno)+1,Length(tg_Data.Jmeno)));
      3: GuiCDplayer;
      4: GuiPicture;
    end;
    if guiCommand <> 5 then guiCommand := 0;
  end;
  PROCEDURE TestGui;
  var
    P: PCollection;   { kolekce objektu }
  begin
    { vytvorim kolekci objektu: }
    New(P,Init(20,20));
    with P^ do begin
      Insert(New(PGuiText, Init(-1,1,'Vyber si uk zku:',$30)));
      Insert(New(PGuiText, Init(-1,2,Rep('Ä',30-2),$31)));
      Insert(New(PGuiButton, Init(2,3,26,'Nastaven¡ hlasitosti',0,1)));
      Insert(New(PGuiButton, Init(2,5,26,'Vyplnˆn¡ formul ©e',0,2)));
      Insert(New(PGuiButton, Init(2,7,26,'CD-p©ehr va‡',0,3)));
      Insert(New(PGuiButton, Init(2,9,26,'Obr zek',0,4)));
      Insert(New(PGuiButton, Init(2,11,26,'Zpˆt',MakeEvent(mcRightPressed,#0,#0),5)));
      Insert(New(PGuiText, Init(-1,12,'Napi¨ sv‚ jm‚no:',$30)));
      Insert(New(PGuiInputLine, Init(2,13,24,64,'',True)));
    end;

    { nastavim promenne: }
    tg_Data.Jmeno := 'J  €lovˆk';

    { pustim dialog: }
    dlgGUI(30,15,p,tg_Data,tg_Idle);

    { a nakonec vse uvolnim: }
    Dispose(P,Done);
  end;

Begin

 {povoli interaktivni testy (umozni plynulejsi scrolling)}
 t_interact:=true;

 {nahraje obrazek}
 pic:=picLoad('priklad.gif');
 if pic=nil then Halt(_erWritten);
 MarkColorsIn(pic);

 {cte promenne z ini}
 iniSetup(SecSelector,nil);
 iniRead('priklad.ini');

 {nahraje si do pameti nejaky font}
 {v teto ukazce kvuli vypsani Ahoj!}
 f:=cacheGetFont(fnDefault);
 if f=nil then Halt(_erWritten);

 {toto je pouze optimalizace, lze bez ujmy vymazat}
 nextPal:=pic^.pal;
 {Vysvetleni:
  Pri nejblizsi nasledujici inicializaci bitmapy pro ni nevytvari novou
  zatim prazdnou paletu, ale da ji paletu nextPal, tedy paletu obrazku pic.
  Jelikoz nasleduje s.Init, bude to obrazovka, kdo obdrzi pic^.pal.
  Diky tomu bude v obehu mene ruznych palet a pozdejsi s.MapInit bude mit
  mene prace s jejich slucovanim do jedne. Tim muzeme usetrit spoustu casu.
  V direct modelech (bez palety) to samozrejme zadny efekt nema.}

 {nastavi nejaky graficky mod (nejblizsi k tomuto rozliseni)}
 if not s.Init(model_packed,640,480,0) then Halt(_erBadMode);
 {muzes si zkusit i jine mody}
 {kdybys chtel nastavit konkretni mod a zadny jiny, volej init treba takto:
  if not s.Init(model_packed,0,0,P640x480) then Halt(erBadMode);
  viz seznam modelu a modu na zacatku vga.pas}

 {nastavi polohu mysi tak, jak ji nacet z priklad.ini}
 s.MouseSetPos(mx,my);

 {vygeneruje pozadi nad kterym se scrolluje}
 {muzes si nastavit libovolne rozmery zvetseniny, ale aspon 800x800
  at se nedostane poletujici "ahoj" mimo rozsah}
 pozadi:=pic^.ResizeFulCopy(0,1200,1200);
 if pozadi=nil then Halt(erLowMem);

 {vygeneruje bitmapku s napisem "ahoj"}
 nextPal:=s.pal;                     {aby mela paletu shodnou s obrazovkou}
 New(ahoj,Init(s.MapModel,50,50));                 {alokuje malou bitmapku}
 if ahoj=nil then Halt(erLowMem);                  {pri neuspechu skonci}
 with ahoj^ do begin
   Col2Ful(Color(0,0,0,255));                      {vymaze ji cernou barvou}
   Col2Box(1,1,47,47,Color(255,255,255,255));      {vnitrek vyplni bilou}
   Col2Box(2,2,44,44,Color(0,0,220,255));          {vnitrek vyplni modrou}
   OutStr(napis1,ahoj,7,27,f,0,Color(255,255,255,255));{text pise bilou}
   end;

 {vygeneruje listu pro dolni cast obrazovky}
 lista:=pic^.ResizeFulCopy(0,s.Xres,s.Yres div 6);
 if lista=nil then Halt(erLowMem);
 with lista^ do begin
   Clr2Box(0,0,sizeX,1);
   OutStr(napis2,lista,50,sizeY div 3*1,f,0,Color(255,255,255,255));
   OutStr(napis3,lista,90,sizeY div 3*2,f,0,Color(255,255,255,255));
   end;

 {predani pozadi a listy obrazovce}
 {obrazovka je prijme a nakonec v MapDone i znici}
 {vx,vy je pocatecni poloha nad pozadim}
 s.MapInit(pozadi,lista,vx,vy);

 {zahodi original obrazku na pozadi}
 KillObj(pic);
 {pocatecni vykresleni obrazovky}
 s.MapRedraw;
 {rozsviti paletu behem 15 snimku}
 s.Fade(+15);
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
   xx:=(s.map^.sizeX-ahoj^.sizeX) div 2+round(x/1);
   yy:=(s.map^.sizeY-ahoj^.sizeY) div 2+round(y/1);
   s.map^.BtF2Box(ahoj,xx,yy);             {kresli bitmapku ahoj do bitmapy s.map}
   s.MapRedrawBox(xx,yy,ahoj^.sizeX,ahoj^.sizeY);{vyrez bitmapy prekresli na obrazovku}

   s.Sync;                                 {zabezpeceni scrollingu}

   {kdyz prijde event (tj. kdyz neco stisknes, mys ci klavesnici)...}
   if s.GetEvent(event,pos) then

     {reaguje podle kodu klavesy/tlacitka - CODE(event)}
     {jsou i jine moznosti, muze reagovat podle CHAR(event) a EXTCHAR(event)}
     case code(event) of

       {ukazka par dialogu kdyz stisknes F1,F2,F3...}
       kF1:begin
           event:=TestMenu;
           if event<>0 then s.PushEvent(event);
           end;
       kF2:TestGui;
       kF3:begin
            name:=dlgSelector(0,'Co si chce¨ prohl‚dnout?' ,fileMask(isLoadable),'');
            if name<>'' then Viewer(picLoad(name));
           end;
       kF4:dlgStr(dlgPathBrowser(0,'Path Browser','*.*',dirCur+'az'));
       kF5:dlgLine(0,'Baf. Tv–j obl¡ben˜ muzikant?','James Brown');
       kF6:dlgMsg('Prohl‚dni si zdroj k a nastav libovoln‚ rozli¨en¡.'#13#10+
                  'Ale pozor, t©eba v 320x200 se tahle zpr va nevejde'#13#10+
                  'na obrazovku :).');
       kF7:dlgChoice('V¡ce© dkov˜ popisek.'#13'Brekeke','Ano;Ne');

       k1..k5:dlgStr(s.GetDebugInfo(code(event)-k1+1));

       {dalsi ukazka dialogu, umoznuje skoncit kdyz nezadas Continue}
       mcRightPressed:if dlgExit<>'C' then break;

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

       {leve a prostredni tlacitko zvetsuji a zmensuji sipku}
       mcLeftPressed,
       mcLeftHold:begin
                   if mouseSize<200 then inc(mouseSize);
                   s.mouseSetPointer(nil,0,0,0,0);
                  end;
       mcCenterPressed,
       mcCenterHold:begin
                     if mouseSize>5 then dec(mouseSize);
                     s.mouseSetPointer(nil,0,0,0,0);
                    end;

       {na pousteni tlacitek mysi nereaguje}
       mcLeftReleased,
       mcRightReleased,
       mcRightHold,
       mcCenterReleased:;

       {vsechny ostatni eventy ohlasi kratkou zpravickou}
       else dlgStr('Event code='+stri(        CODE(event) )+
                        ' char='+stri(byte(   CHAR(event)))+
                     ' extchar='+stri(byte(EXTCHAR(event)))+
                       '.');
       end;

 {smycka bezi dokud ji nekdo nebreakne}
 until false;

 {ukonceni scrollingu}
 s.SetActivity(syncHolocaust);
 s.Fade(-15);
 {uvolneni bitmapy}
 s.MapDone(true{i listu});

 {uvolni bitmapku "ahoj"}
 KillObj(ahoj);

 {nastavi polohu mysi do promennych, ktere pote ulozi do INI}
 mx:=s.mouse.X;
 my:=s.mouse.Y;
 {totez pro polohu obrazovky nad bitmapou}
 vx:=s.posNow.X;
 vy:=s.posNow.Y;

 {vrati puvodni (textovy) mod}
 s.Done;

 {zahodi font}
 caLeave(f);

 {zapise promenne do ini}
 iniWrite('priklad.ini',0);

 {rozlouci se}
 writeln('Bye!');
End.