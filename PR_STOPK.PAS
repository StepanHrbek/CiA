{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: mikrosekundove stopky

}

{$m 4000,0,20000}

Uses Sys;

Var  stopky:TStopky;

Begin
 {implicitni presnost je 5 milisekund, mikrosekundovou si musime vyzadat}
 SetPreciseClock(true);

 {pustime stopky}
 stopky.Start;

 {operace jejiz casovou slozitost merime}
 write('Vypsat tento text trvalo...');

 {zastavime je, cimz se do mikro ulozi cas v mikrosekundach}
 stopky.Stop;

 writeln(stopky.mikro,' mikrosekund.');

 {dalsi metody stopek jsou nadeklarovany v sys.pas}
End.