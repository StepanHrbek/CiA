{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: INI soubor

}

{$m 10000,0,30000}

Uses Ini;

Var  mys_x:integer;
     mys_y:integer;

{Seznam promennych v INI souboru, se kterymi chceme pracovat.
 Podporovane typy a flagy jsou nadeklarovane na zacatku ini.pas.
 SYNTAXE: nazev malymi pismeny,0,flagy,typ,offset promenne v datasegmentu;
          uplne na konci nula}
Procedure Vars;assembler;
 asm
  db 'mys.x',0,0,i_intg;dw offset mys_x
  db 'mys.y',0,0,i_intg;dw offset mys_y
  db 0
 end;

Begin
 {nacteme promenne z ini souboru}
 iniSetup(nil,@vars);
 iniRead('priklad.ini');

 {zvysime treba mys_x o 1 at je videt nejaka zmena}
 inc(mys_x);
 writeln('Menim mys.x na ',mys_x,' a ukladam zpet do ini souboru.');

 {promenne opet ulozime do ini souboru}
 iniWrite('priklad.ini',0);
End.