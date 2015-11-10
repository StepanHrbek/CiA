{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: grafika pro kazdeho pomoci unity Baby

}

{$ifndef dpmi}
 kompiluj pro protected mode, v realu by nebylo pro beh dost pameti
{$endif}

Uses Baby,    {grafika pro kazdeho}
     Vga,     {nutne kvuli deklaraci PBitmap}
     Lang1,   {abys mel misto pripadnych nicnerikajicich chybovych kodu hlasky}

     {pro pokrocile operace}
     Sys,     {kvuli deklaraci TEvent}
     Objects, {kvuli deklaraci TPoint}
     Dialogy, {pouzijeme dilog dlgStr}
     Stringy; {budeme prevadet cisla na stringy}

Var  pic  :PBitmap;
     event:TEvent;
     pos  :TPoint;

Begin

 {------bezne operace------}

 {nastavime nejake rozliseni}
 {kdyby neslo presne toto, automaticky se nastavi nejblizsi mozne}
 {s babyAuto bude automaticky vybrana optimalni bitova hloubka}
 babySetMode(babyAuto,640,480);

  {nahrajeme obrazek}
  {automaticky se zkonvertuje do stejneho modelu/palety jako ma obrazovka}
  pic:=babyMapLoad('priklad.gif');

  {neco do nej vepiseme bilou barvou}
  babyWrite(pic,5,20,babyColor(pic,255,255,255),'modern.fn','Ahoj!');

  {roztahneme ho pres celou obrazovku}
  babyResize(pic,0,0,pic^.sizeX,pic^.sizeY,babyScreen,0,0,babyScreen^.Xres,babyScreen^.Yres);

 {----pokrocile operace----}

 {z nejakeho obskurniho duvodu se rozhodneme prejit do modu s 256 barvami}
 babySetMode(model_8,800,600);

  {aby sel zobrazit pic, musime ho nejdriv prevest do stejneho modelu/palety}
  babyMapConvert(pic,babyScreen);

  {ted muzeme zobrazovat podle libosti}
  babyResize(pic,0,0,pic^.sizeX,pic^.sizeY,babyScreen,0,0,babyScreen^.Xres,babyScreen^.Yres);

  {s pouzitim nebabyovskych funkci ukazeme mys a pockame na udalost}
  babyScreen^.MouseShow;
  while not babyScreen^.GetEvent(event,pos) do begin
    {behem cekani musime volat Sync - prekresluje mys a ceka na paprsek}
    babyScreen^.Sync;
    end;
  babyScreen^.MouseHide;

  {oznamime co to bylo za udalost}
  {kody udalosti od klaves (kA,kEsc atd) jsou deklarovane v key.pas,
   kody udalosti od mysi (mcLeftPressed,mcRightReleased atd) ve vga.pas}
  dlgStr('Udalost na pozici x='+stri(pos.x)+',y='+stri(pos.y)+'.'#13#10+
         'Kod='+stri(code(event))+' char='+stri(byte(char(event)))+' extchar='+stri(byte(extchar(event)))+'.');

 {----------konec----------}

 {uvolnime pamet, i kdyz zde na konci programu je to uz zbytecne}
 babyMapDestroy(pic);

 {vratime puvodni textovy mod}
 babyRestoreTextmode;

End.