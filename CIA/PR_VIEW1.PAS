{旼컴C.I.A.컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴훩erze 2.00컴커
 쿞 timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi�
 퀆 dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.�
 읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

 Priklad: prohlizec souboru

}

{$m 30000,0,60000}

Uses Fajly,Ini,Dialogy,Vga,Scrol,
     Loadery,LdGif,LdPcx,LdTga,LdX,LdTxt,
     Tools,Lang1;

Var soubor:string;
    mapa:PBitmap;
    s:TScreen;

Begin
 {pokud nebylo jmeno zadano z prikazove radky, pustime fileselector}
 soubor:=paramstr(1);
 if soubor='' then begin
   {fileselector potrebuje nastaveny mod, proto mu nejaky
    (muzeme se rozhodnout pro jakykoliv, textovy ci graficky) nastavime}
   s.Init(model_text,80,50,0);
   soubor:=dlgSelector(dlgRatherBig,'',fileMask(isLoadable),'');
   s.Done;
   end;

 {nacteme soubor do bitmapy}
 mapa:=picLoad(soubor);

 {pustime prohlizec bitmapy}
 if not Viewer(mapa) then begin
  writeln('Prohlizec obrazku, popr. i malych textovych souboru.');
  writeln('(pozn: u velkych textovych souboru ohlasi nedostatek pameti)');
  writeln('Lze spustit s parametrem jmeno_souboru.');
  end;
End.