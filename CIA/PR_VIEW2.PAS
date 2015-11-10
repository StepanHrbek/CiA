{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: prohlizec souboru - pro plynulejsi scrolling testujici gr.kartu

}

{$ifndef dpmi}
 v real modu nebude dost pameti, kompiluj pro protekt
{$endif}

{$m 30000,0,60000}

Uses Fajly,Ini,Dialogy,Vga,Scrol,
     Loadery,LdGif,LdPcx,LdTga,LdTxt,LdX,
     Tools,Lang1;

Var soubor:string;
    mapa:PBitmap;
    s:TScreen;

Begin
 {povolime interaktivni testy gr.karty, umozni to plynulejsi scrolling}
 t_interact:=true;

 {nacteme z ini souboru vysledky pripadnych drivejsich testu}
 iniSetup(nil,@vgavars);
 iniRead(dirExe+'priklad.ini');

 {pokud nebylo jmeno zadano z prikazove radky, pustime fileselector}
 soubor:=paramstr(1);
 if soubor='' then begin
   {fileselector potrebuje nastaveny mod, proto mu nejaky
    (muzeme se rozhodnout pro jakykoliv, textovy ci graficky) nastavime}
   s.Init(model_gfx,640,480,0);
   soubor:=dlgSelector(dlgRatherBig+dlgForbidNew,'',fileMask(isLoadable),'');
   s.Done;
   end;

 {nacteme soubor do bitmapy}
 mapa:=picLoad(soubor);

 {pustime prohlizec bitmapy}
 if not Viewer(mapa) then
  writeln('Prohlizec obrazku, popr. i malych textovych souboru.');
  writeln('(pozn: u velkych textovych souboru ohlasi nedostatek pameti)');
  writeln('Lze spustit s parametrem jmeno_souboru.');

 {ulozime do ini souboru vysledky pripadnych testu}
 iniWrite('priklad.ini',0);
End.